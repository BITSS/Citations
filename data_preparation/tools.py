'''
Functions that are used repeatedly across multiple files.
'''
from html.parser import HTMLParser
import re

import numpy as np
import pandas as pd
from pyexcel_ods3 import get_data


def unique_elements(list_in, idfun=None):
    if idfun is None:
        def idfun(x): return x
    seen = {}
    list_out = []
    for element in list_in:
        marker = idfun(element)
        if marker in seen:
            continue
        seen[marker] = 1
        list_out.append(element)
    return list_out


def apply_func_to_df(df, func_list):
    '''Take a list of (column, function) tuples to apply function to column of
    dataframe.'''
    for column, func in func_list:
        # 'None' applies function to whole dataframe.
        if column is None:
            df = func(df)
        else:
            df[column] = df[column].apply(func)


def fill_columns_down(df, columns):
    '''
    Fill in fields from last occurence.
    '''
    for column in columns:
        # Replace with 'None' instead 'np.nan' to avoid upcasting of
        # 'int' to 'float'. See
        # http://pandas.pydata.org/pandas-docs/stable/gotchas.html#nan-integer-na-values-and-na-type-promotions
        df[column] = df[column].replace('', None)
        df[column].fillna(method='ffill', inplace=True)
        # If top row is na, interpret it as '' and fill it forward.
        df[column].fillna('', inplace=True)


def read_data_entry(file_in, **pandas_kwargs):
    '''
    Read data from data entry in ods or csv format.
    '''
    file_ending = file_in.split('.')[-1]
    if file_ending == 'ods':
        # Choose first sheet from workbook.
        sheet = list(get_data(file_in).values())[0]
        header = sheet[0]
        content = sheet[1:]
        # Take care of completely empty trailing columns.
        header_length = len(header)
        content = [row + [None] * max(header_length - len(row), 0)
                   for row in content]
        # Handle 'dtypes' manually as pd.DataFrame does not accept it as a
        # dictionary.
        dtypes = pandas_kwargs.pop('dtype', None)
        sheet = pd.DataFrame(columns=header, data=content,
                             **pandas_kwargs)
        if dtypes:
            string_columns = [k for k, v in dtypes.items() if v == 'str']
            sheet[string_columns] = sheet[string_columns].fillna('')
            sheet = sheet.astype(dtypes)

    elif file_ending == 'csv':
        sheet = pd.read_csv(file_in, **pandas_kwargs)

    else:
        raise NotImplementedError('File ending {} not supported.'.
                                  format(file_ending))
    return sheet


def import_data_entries(source, target, output, entry_column, merge_on,
                        log=False, apply_functions={},
                        deduplicate_article_info=True):
    '''
    Import data entries from source spreadsheet into target.
    '''
    sheets = {}
    article_level_columns = ['article_ix', 'doi', 'title']
    # Make dtypes consistent across dataframes for merging.
    merge_on_dtypes = dict([(column, 'str') for column in merge_on])
    for file_role, fh in {'source': source, 'target': target}.items():
        sheet = read_data_entry(fh, dtype=merge_on_dtypes)
        sheet[merge_on] = sheet[merge_on].fillna('')
        for merge_column in merge_on:
            sheet[merge_column] = sheet[merge_column].astype('str')

        fill_columns_down(sheet,
                          [x for x in article_level_columns if x != 'title'])
        function_list = apply_functions.get(file_role, ())
        for function in function_list:
            function(sheet)
        fill_columns_down(sheet, ['title'])

        sheets[file_role] = sheet

    # Import data only for empty rows with unique matching columns values.
    sheets['target']['import_candidate'] = \
        np.all([np.any([sheets['target'][entry_column].fillna('') == ''], axis=0),
                ~sheets['target'].duplicated(subset=merge_on,
                                             keep=False)],
               axis=0)

    # Export data only for non-empty rows with unique matching column values.
    sheets['source']['export_candidate'] = \
        np.all([sheets['source'][entry_column].fillna('') != '',
                ~sheets['source'].duplicated(subset=merge_on,
                                             keep=False)],
               axis=0)

    sheets['target'].index.name = 'target_row_ix'
    sheets['target'].reset_index(inplace=True)
    merged = sheets['target'].merge(right=sheets['source'], how='outer',
                                    suffixes=('', '_source'),
                                    on=merge_on, indicator='_merge')

    # Find rows whose value are imported.
    import_dummy = np.all([x.fillna(False) for x in
                           [merged['_merge'] != 'right_only',
                               merged['import_candidate'],
                               merged['export_candidate']]],
                          axis=0)

    # Mark previously and newly imported entries.
    merged.loc[import_dummy, 'import_dummy'] = 'imported'

    # Create log file showing result from merge and data entry for both files.
    if log:
        merged.to_csv(log, index_label='merged_row_ix')

    # Import values to reference category.
    merged.loc[import_dummy, entry_column] = \
        merged.loc[import_dummy, entry_column + '_source']

    # For rows in target that have several matches in source, drop duplicates.
    merged.drop_duplicates(subset='target_row_ix', inplace=True)
    merged.set_index('target_row_ix', inplace=True, verify_integrity=True)

    # Write article level information only once per article.
    if deduplicate_article_info:
        merged.loc[merged[article_level_columns].duplicated(),
                   article_level_columns] = ''

    # Write resulting sheet to output.
    merged = merged.loc[merged['_merge'] != 'right_only',
                        [x for x in sheets['target'].columns
                         if x not in ['import_candidate', 'target_row_ix',
                                      'import_dummy']] +
                        ['import_dummy']]
    merged.to_csv(output, index=False)


def article_url(doi, journal):
    if journal == 'ajps':
        return 'http://onlinelibrary.wiley.com/doi/' + doi + '/full'
    elif journal == 'apsr':
        return 'https://doi.org/' + doi
    else:
        UserWarning.warn('{} is an unknown journal.'.format(journal) +
                         'Could not create article url.')


def hyperlink(string):
    return '=HYPERLINK("{}")'.format(string)


def hyperlink_title(input, journal):
    '''
    Link title to article url.
    '''
    # If input is pd.Series intrepret it as article.
    if isinstance(input, pd.core.series.Series):
        article = input
        # Do not hyperlink empty cells.
        if article['title'] in ['', np.nan]:
            return article['title']
        else:
            return ('=HYPERLINK("' + article_url(article['doi'], journal) +
                    '","' + article['title'] + '")')

    # If input is a string, interpret is as file.
    elif isinstance(input, str):
        df_in = pd.read_csv(input)
    # If input is a pd.DataFrame, hyperlink the 'title' column.
    elif isinstance(input, pd.core.frame.DataFrame):
        df_in = input
    else:
        UserWarning.warn('Unknown input type.')
    df_in['title'] = df_in.apply(hyperlink_title, axis=1, journal=journal)
    return df_in


def hyperlink_google_search(text):
    '''Hyperlink to search for text with Google.

    Show 15 results, and turn off personalization of results.
    '''
    return ('=HYPERLINK("https://google.com/search?q={x}&num=15&pws=0",'
            '"{x}")'.format(x=text))


def extract_authors_ajps(article, authors_column='authors'):
    authors = [x.strip() for x in re.split('(?:, | and )',
                                           article[authors_column])]

    authors = [a for a in authors if a != '(contact author)']
    name_suffixes = ['Jr', 'Jr.', 'III']
    for ix, author in enumerate(authors):
        if author in name_suffixes:
            print(author)
            authors[ix - 1] = authors[ix - 1] + ', ' + author
    authors = [a for a in authors if a not in name_suffixes]

    return (pd.Series(authors, index=['author_{}'.format(i)
                                      for i in range(len(authors))]))


def extract_authors_apsr(article, authors_column='authors'):
    authors = [x.strip() for x in article[authors_column].split(';')]
    return (pd.Series(authors, index=['author_{}'.format(i)
                                      for i in range(len(authors))]))


def add_doi(target, source, output=False):
    '''
    Add doi column to target using information from source.
    '''
    matching_columns = ['title']
    df_source = pd.read_csv(source, usecols=matching_columns + ['doi'])

    sheet = get_data(target)['ajps_reference_coding']
    header = sheet[0]
    content = sheet[1:]
    df_target = pd.DataFrame(columns=header, data=content)

    # Add doi information only for unique articles.
    df_target = df_target.assign(doi='', add_doi='')
    article_start = df_target['article_ix'] != ''
    df_target.loc[article_start, 'add_doi'] = \
        ~df_target.loc[article_start, matching_columns].duplicated(keep=False)

    # Merge doi information from source for selected articles.
    fill_columns_down(df_target,
                      matching_columns + ['add_doi'])
    df_target[df_target['add_doi']] = df_target[df_target['add_doi']]. \
        merge(df_source, how='left', on=matching_columns,
              suffixes=('_x', '')).drop('doi_x', 1).values
    df_target.loc[df_target[matching_columns + ['doi']].duplicated(),
                  matching_columns + ['doi']] = ''
    df_target = df_target[['doi', 'article_ix', 'title', 'match', 'context',
                           'reference_category']]
    df_target.sort_index(inplace=True)
    if output:
        df_target.to_csv(output, index=None)
    else:
        return df_target


# Remove HTML tags.
# Source: http://stackoverflow.com/a/925630/3435013
class MLStripper(HTMLParser):

    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs = True
        self.fed = []

    def handle_data(self, d):
        self.fed.append(d)

    def get_data(self):
        return ''.join(self.fed)


def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()


def regex_url_pattern():
    '''
    Return regular expression pattern that matches URLs

    Extracting URLs from text is non-trivial.
    Beautify solution provided by 'dranxo'.
    https://stackoverflow.com/a/28552670/3435013
    '''

    tlds = (r'com|net|org|edu|gov|mil|aero|asia|biz|cat|coop'
            r'|info|int|jobs|mobi|museum|name|post|pro|tel|travel'
            r'|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw'
            r'|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt'
            r'|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr'
            r'|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh'
            r'|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh'
            r'|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht'
            r'|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg'
            r'|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt'
            r'|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr'
            r'|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np'
            r'|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw'
            r'|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja'
            r'|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg'
            r'|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us'
            r'|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw')

    return (r'((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.]'
            r'(?:' + tlds + ')'
            r'/)(?:[^\s()<>{}\[\]]+'
            r'|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+'
            r'(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)'
            r'''|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])'''
            r'|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.]'
            r'(?:' + tlds + ')\b'
            r'/?(?!@)))')
