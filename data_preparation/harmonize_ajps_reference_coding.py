#!/usr/bin/env python3
'''
Combine reference coding entries into single file with one entry per match.
'''


from collections import OrderedDict

import pandas as pd
import numpy as np
from tools import fill_columns_down, hyperlink_title, read_data_entry

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
    resolution_column = 'reference_category' + suffix + '_resolved'

    entry = read_data_entry(input_file_data_entry_prefix + suffix + '.ods')
    entry = hyperlink_title(entry, 'ajps')

    fill_columns_down(entry, article_level_columns)
    import_entry = np.all([article_range[0] <= entry['article_ix'],
                           article_range[1] >= entry['article_ix']], axis=0)
    entry = entry.loc[import_entry, merge_columns + [resolution_column]]

    # Data entry files potentially have duplicate matches. If
    # reference_category is identical for all duplicates, import that value.
    # Otherwise make it empty. In both cases, drop duplicates.
    duplicate_id = entry.duplicated(subset=merge_columns, keep=False)
    duplicate_coding = entry.duplicated(subset=merge_columns +
                                        [resolution_column], keep=False)
    conflicting_duplicate = np.all([duplicate_id, ~duplicate_coding], axis=0)
    entry.loc[conflicting_duplicate, resolution_column] = np.nan
    entry.drop_duplicates(subset=merge_columns + [resolution_column],
                          inplace=True)
    df = pd.merge(left=df, right=entry, on=merge_columns, how='left',
                  indicator='_merge' + suffix)

    df.loc[df['_merge' + suffix] == 'both', 'reference_category'] = \
        df.loc[df['_merge' + suffix] == 'both', resolution_column]

df.to_csv(output_file, columns=merge_columns + ['reference_category'],
          index=None)
