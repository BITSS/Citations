#!/usr/bin/env python3
'''
Combine reference coding entries into single file with one entry per match.
'''

# TODO Output template as .csv file

from collections import OrderedDict

import pandas as pd
import numpy as np
from pyexcel_ods3 import get_data as read_ods
from tools import fill_columns_down

input_file_template = 'bld/ajps_reference_coding_template.csv'
input_file_data_entry_prefix = ('data_entry/' +
                                'ajps_reference_coding_diff_resolution')
output_file = 'bld/ajps_reference_coding_harmonized.csv'

urap_pairs = OrderedDict([(('RK', 'TC'), (1, 304)),
                          (('KJK', 'RP'), (305, 608))])

article_level_columns = ['doi', 'article_ix', 'title']
merge_columns = article_level_columns + ['match', 'context']

df = pd.read_csv(input_file_template)

fill_columns_down(df, article_level_columns)

for pair, article_range in urap_pairs.items():
    suffix = '_' + '_'.join(pair)

    sheet = (read_ods(input_file_data_entry_prefix + suffix + '.ods')
             ['ajps_reference_coding'])
    header = sheet[0]
    content = sheet[1:]
    entry = pd.DataFrame(columns=header, data=content)

    fill_columns_down(entry, article_level_columns)
    import_entry = np.all([article_range[0] <= entry['article_ix'],
                           article_range[1] >= entry['article_ix']], axis=0)
    entry = entry.loc[import_entry, merge_columns + ['reference_category' +
                                                     suffix + '_resolved']]
    df = pd.merge(left=df, right=entry, on=merge_columns, how='outer',
                  indicator='_merge' + suffix)
    df.loc[df['_merge' + suffix] == 'both', 'reference_category'] = \
        df.loc[df['_merge' + suffix] == 'both',
               'reference_category' + suffix + '_resolved']

df.to_csv(output_file, columns=merge_columns + ['reference_category'],
          index=None)
