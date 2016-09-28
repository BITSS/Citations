#!/usr/bin/env python3
"""
Create spreadsheet of differences in data entry.
"""

# TODO Look into unmatched entries.

from collections import OrderedDict

from pyexcel_ods3 import get_data
import numpy as np
import pandas as pd

urap_initials = ['KJK', 'rk', 'RP', 'TC']
input_files = OrderedDict(zip(urap_initials,
                              [('data_entry/ajps_reference_coding_' +
                                initials + '.ods')
                               for initials in urap_initials]))
output_file = 'bld/ajps_reference_coding_diff.csv'

entries = OrderedDict()
for person, input_file in input_files.items():
    sheet = get_data(input_file)['ajps_reference_coding']
    header = sheet[0]
    content = sheet[1:]
    entry = pd.DataFrame(columns=header, data=content)

    # Add article info to every row.
    for column in ['article_ix', 'doi', 'title']:
        entry[column] = entry[column].replace('', np.nan)
        entry[column].fillna(method='ffill', inplace=True)

    # Add identifier to entry column.
    entry.rename(columns={'reference_category':
                          'reference_category_' + person},
                 inplace=True)
    entries[person] = entry

columns_merge_on = [c for c in header if c != 'reference_category']
merged_entries = pd.merge(entries['KJK'], entries['rk'],
                          how='outer', on=columns_merge_on,
                          indicator='KJK_with_rk')

merged_entries = pd.merge(merged_entries, entries['RP'],
                          how='outer', on=columns_merge_on,
                          indicator='KJK_rk_with_TC')

merged_entries = pd.merge(merged_entries, entries['TC'],
                          how='outer', on=columns_merge_on,
                          indicator='KJK_rk_RP_with_TC')

merged_entries.to_csv(output_file, index_label='row_ix')
