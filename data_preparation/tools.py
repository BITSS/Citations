# Various tools used in this project that can be useful otherwhere.
import numpy as np
import pandas as pd
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


def import_data_entries(source, target, output_file, log_file):
    '''
    Import data entries from one spreadsheet into an other.
    '''
    sheets = {}
    # Mark columns that have been only filled once per article.
    article_level_columns = ['article_ix', 'doi', 'title']
    for name, fh in {'source': source, 'target': target}.items():
        sheet = get_data(fh)['ajps_reference_coding']
        header = sheet[0]
        content = sheet[1:]
        sheet = pd.DataFrame(columns=header, data=content)

        # Add article info to every row.
        for column in article_level_columns:
            sheet[column] = sheet[column].replace('', np.nan)
            sheet[column].fillna(method='ffill', inplace=True)

        # Add identifier to sheet column.
        sheet.rename(columns={'reference_category':
                              'reference_category_' + name},
                     inplace=True)
        sheets[name] = sheet

    columns_merge_on = [c for c in header if c != 'reference_category']
    merged = pd.merge(left=sheets['target'], right=sheets['source'],
                      how='outer', suffixes=('_target', '_source'),
                      on=columns_merge_on, indicator='_merge')

    merged.to_csv(log_file, index_label='row_ix')
    source_with_imports = source
    additional_entries = np.all(merged['_merge'] != 'right_only',
                                merged['reference_category_target'] == '')
    source_with_imports[additional_entries, 'reference_category'] = \
        merged[additional_entries, 'reference_category_source']
    source_with_imports.loc[source_with_imports[article_level_columns].
                            duplicated(), article_level_columns] = ''
    source_with_imports.to_csv(output_file, index=False)
