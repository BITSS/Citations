#!/usr/bin/env python3
'''
Update resolution of differences, if individual entry has changed.
'''
import pandas as pd
import numpy as np
from pyexcel_ods3 import get_data

new_diff_resolution_template = 'bld/ajps_reference_coding_diff_resolution'
diff_resolution_data_entry_prefix = ('data_entry/' +
                                     'ajps_reference_coding_diff_resolution')
output_file_prefix = ('bld/ajps_reference_coding_diff_resolution_updated')

resolution_pairs = [('KJK', 'RP'), ('RK', 'TC')]

for pair in resolution_pairs:
    suffix = '_' + '_'.join(pair)

    diff_file = new_diff_resolution_template + suffix + '.csv'
    diff_resolution_file = diff_resolution_data_entry_prefix + suffix + '.ods'
    output_file = output_file_prefix + suffix + '.csv'

    diff = pd.read_csv(diff_file)

    sheet = (get_data(diff_resolution_file)['ajps_reference_coding'])
    header = sheet[0]
    content = sheet[1:]
    diff_resolved = pd.DataFrame(columns=header, data=content)

    reference_columns = ['reference_category_' + x for x in pair]
    resolution_column = 'reference_category' + suffix + '_resolved'

    # Take care of encoding differences from reading from csv and ods.
    entry_in_sync = np.all(diff[reference_columns].fillna('').astype(str) ==
                           diff_resolved[reference_columns].fillna('').
                           astype(str),
                           axis=1)

    # If individual entry has changed, create file that indicates updates.
    if np.all(entry_in_sync):
        print(('All individual entries in {pair} are identical to {file_in}.\n'
               'File with updates {file_out} will be not generated.').
              format(pair=pair, file_in=diff_resolution_file,
                     file_out=output_file))
    else:
        diff.loc[entry_in_sync, resolution_column] = \
            diff_resolved.loc[entry_in_sync, resolution_column]
        diff['updated'] = ~entry_in_sync

        bool_printing = {True: 'True', False: ''}
        diff.replace({'updated': bool_printing}, inplace=True)

        diff.to_csv(output_file, index=None)
