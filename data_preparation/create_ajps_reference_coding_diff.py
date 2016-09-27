#!/usr/bin/env python3
"""
Create spreadsheet of differences in data entry.
"""

# TODO Why are .ods files different in number of rows?

from collections import OrderedDict

from pyexcel_ods3 import get_data
import pandas as pd

urap_initials = ['KJK', 'RP', 'TC']
input_files = OrderedDict(zip(urap_initials,
                              [('data_entry/ajps_reference_coding_' +
                                initials + '.ods')
                               for initials in urap_initials]))
output_file = 'data_entry/ajps_reference_coding_diff.ods'

entries = OrderedDict()
for person, input_file in input_files.items():
    # Skip header and only read data entry column
    sheet = get_data(input_file,
                     start_row=1)['ajps_reference_coding']
    header = sheet[0]
    content = sheet[1:]
    entry = pd.DataFrame(data=content, columns=header)
    # Add doi to every row.
    entry['doi'].fillna(method='ffill', inplace=True)

    entries[person] = entry
    print(entry)

merged_entries = pd.merge(entries['KJK'], entries['RP'],
                          how='outer', on=['doi', 'match', 'context'],
                          suffixes=['_KJK', '_RP'], indicator=True)
