# Various tools used in this project that can be useful otherwhere.
import pandas as pd
import numpy as np
from html.parser import HTMLParser
from pyexcel_ods3 import get_data


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


def unique_elements(list_in):
    seen = {}
    list_out = []
    for element in list_in:
        if element in seen:
            continue
        seen[element] = 1
        list_out.append(element)
    return list_out


def regex_url_pattern():
    '''
    Return regular expression pattern that matches URLs

    Extracting URLs from text is non-trivial.
    Beautify solution provided by 'dranxo' and match characters around URLs
    for additional context.
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


def fill_columns_down(df, columns):
    '''
    Fill in fields from last occurence.
    '''
    for column in columns:
        df[column] = df[column].replace('', np.nan)
        df[column].fillna(method='ffill', inplace=True)


def import_data_entries(source, target, output, entry_column, log=False):
    '''
    Import data entries from one spreadsheet into an other.
    '''
    sheets = {}
    article_level_columns = ['article_ix', 'doi', 'title']
    for name, fh in {'source': source, 'target': target}.items():
        file_ending = fh.split('.')[-1]
        if file_ending == 'ods':
            # Choose first sheet from workbook.
            sheet = list(get_data(fh).values())[0]
            header = sheet[0]
            content = sheet[1:]
            # Take care of completely empty trailing columns.
            header_length = len(header)
            content = [row + [None] * max(header_length-len(row), 0)
                       for row in content]
            sheet = pd.DataFrame(columns=header, data=content)
        elif file_ending == 'csv':
            sheet = pd.read_csv(fh)
        else:
            raise NotImplementedError('File ending {} not supported.'.
                                      format(file_ending))
        fill_columns_down(sheet, article_level_columns)

        sheets[name] = sheet

    # Exclude article_ix as selection of articles has changed
    # over protocols (restriction to certain years).
    columns_merge_on = [c for c in sheets['target'].columns
                        if c in ['doi', 'title', 'match', 'context']]

    # Import data only for empty rows with unique matching columns values.
    sheets['target']['import_candidate'] = \
        np.all([sheets['target'][entry_column].isnull(),
                ~sheets['target'].duplicated(subset=columns_merge_on,
                                             keep=False)],
               axis=0)

    # Export data only for non-empty rows with unique matching column values.
    sheets['source']['export_candidate'] = \
        np.all([sheets['source'][entry_column].notnull(),
                ~sheets['source'].duplicated(subset=columns_merge_on,
                                             keep=False)],
               axis=0)

    sheets['target'].index.name = 'target_row_ix'
    sheets['target'].reset_index(inplace=True)
    merged = sheets['target'].merge(right=sheets['source'], how='outer',
                                    suffixes=('_target', '_source'),
                                    on=columns_merge_on, indicator='_merge')

    # Find rows whose value are imported
    import_dummy = np.all([x.fillna(False) for x in
                           [merged['_merge'] != 'right_only',
                               merged['import_candidate'],
                               merged['export_candidate']]],
                          axis=0)

    # Mark previously and newly imported entries.
    if 'import_dummy_target' in merged.columns:
        merged['import_dummy'] = merged['import_dummy_target']
    merged.loc[import_dummy, 'import_dummy'] = 'imported'

    # Create log file showing result from merge and data entry for both files.
    if log:
        merged.to_csv(log, index_label='merged_row_ix')

    # Import values to reference category.
    merged.rename(columns={entry_column + '_target': entry_column,
                           'article_ix_target': 'article_ix'},
                  inplace=True)
    merged.loc[import_dummy, entry_column] = \
        merged.loc[import_dummy, entry_column + '_source']

    # For rows in target that have several matches in source, drop duplicates.
    merged.drop_duplicates(subset='target_row_ix', inplace=True)
    merged.set_index('target_row_ix', inplace=True, verify_integrity=True)

    # Write article level information only once per article.
    merged.loc[merged[article_level_columns].duplicated(),
               article_level_columns] = ''

    # Write resulting sheet to output.
    merged = merged.loc[merged['_merge'] != 'right_only',
                        [x for x in sheets['target'].columns
                         if x not in ['import_candidate', 'target_row_ix',
                                      'import_dummy']] +
                        ['import_dummy']]
    merged.to_csv(output, index=False)


def article_url(doi):
    'Return article url inferred from DOI.'
    return 'http://onlinelibrary.wiley.com/doi/' + doi + '/full'


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


def hyperlink_title(input, file_out):
    '''
    Make title value clickable
    '''
    if isinstance(input, str):
        df_in = pd.read_csv(input)
    else:
        df_in = input
    article_info = df_in['title'] != ''

    df_in['hyperlink_title'] = ('=HYPERLINK("' +
                                df_in['doi'].apply(article_url) +
                                '","' + df_in['title'] + '")')

    df_in.loc[article_info, 'title'] = df_in.loc[article_info,
                                                 'hyperlink_title']
    df_in.drop('hyperlink_title', axis=1, inplace=True)
    df_in.to_csv(file_out, index=None)
