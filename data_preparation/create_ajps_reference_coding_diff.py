#!/usr/bin/env python3
"""
Create spreadsheet of differences in data entry.
"""

import warnings
from collections import OrderedDict

from pyexcel_ods3 import get_data
import pandas as pd
import numpy as np
from tools import fill_columns_down

urap_initials = ['KJK', 'RK', 'RP', 'TC']
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

    fill_columns_down(entry, ['article_ix', 'doi', 'title'])

    # Add identifier to entry column.
    entry.rename(columns={'reference_category':
                          'reference_category_' + person},
                 inplace=True)

    entries[person] = entry

columns_merge_on = ['doi', 'article_ix', 'title', 'match', 'context']
merged_entries = pd.merge(left=entries['KJK'], right=entries['RK'],
                          suffixes=('_KJK', '_RK'), how='outer',
                          on=columns_merge_on, left_index=True,
                          right_index=True, indicator='KJK_with_RK')

merged_entries = pd.merge(left=merged_entries, right=entries['RP'],
                          suffixes=('_KJK_RK', '_RP'), how='outer',
                          on=columns_merge_on, left_index=True,
                          right_index=True, indicator='KJK_RK_with_RP')

merged_entries = pd.merge(left=merged_entries, right=entries['TC'],
                          suffixes=('_KJK_RK_RP', '_TC'), how='outer',
                          on=columns_merge_on, left_index=True,
                          right_index=True, indicator='KJK_RK_RP_with_TC')

consistent_template = np.all(merged_entries[['KJK_with_RK', 'KJK_RK_with_RP',
                                             'KJK_RK_RP_with_TC']] == 'both',
                             axis=(0, 1))

if consistent_template:
    reference_columns = ['reference_category_' + x for x in urap_initials]
    merged_entries = merged_entries[columns_merge_on + reference_columns]

    data_entered = merged_entries[reference_columns].notnull()
    merged_entries['number_of_entries'] = np.sum(data_entered, axis=1)
    merged_entries['conflict'] = merged_entries[reference_columns]\
        [data_entered].apply(pd.Series.nunique, axis=1) > 1
    bool_printing = {True: 'True', False: ''}
    merged_entries.replace({'conflict': bool_printing}, inplace=True)

    merged_entries.to_csv(output_file, index=None)

else:
    warnings.warn('''Some lines could not be matched consistently across files.
                  Please investigate output file.''')
    merged_entries.to_csv(output_file, index_label='row_ix')
