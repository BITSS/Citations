#!/usr/bin/env python3


import pandas as pd
import numpy as np
from tools import read_data_entry

# TODO Add a hyperlinking function to read_data_entry, follow apply_func
# dict from create_diff.py


def harmonize_author_website_coding(template_file, index_column, entry_columns,
                                    merge_on_columns, inputs, output_file):
    '''
    Combine author website coding entries into single file with one entry per
    article*website.
    '''
    df = read_data_entry(template_file)
    template_columns = df.columns
    for import_ix, (input_file, input_columns, index_range) \
            in enumerate(inputs):
        data_entry = read_data_entry(input_file)
        merge_indicator = '_merge_{}'.format(import_ix)
        df = pd.merge(df, data_entry, how='left', on=merge_on_columns,
                      suffixes=('', '_import'), indicator=merge_indicator)
        importable = np.all([index_range[0] <= df[index_column],
                             df[index_column] <= index_range[1],
                             df[merge_indicator] == 'both'], axis=0)
        df.loc[importable, entry_columns] = df.loc[importable, input_columns]
    return df.to_csv(output_file, columns=template_columns, index=None)

# AJPS
ajps = {'template_file': 'bld/ajps_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [('data_entry/ajps_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    ['website_category_RK_TC_resolved'],
                    (1, 304)),
                   ('data_entry/ajps_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    ['website_category_KJK_RP_resolved'],
                    (305, 608))],
        'output_file': 'bld/ajps_author_website_coding_harmonized.csv'}
harmonize_author_website_coding(**ajps)


# APSR
apsr = {'template_file': 'bld/apsr_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [('data_entry/apsr_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    ['website_category_RK_TC_resolved'],
                    (1, 304)),
                   ('data_entry/apsr_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    ['website_category_KJK_RP_resolved'],
                    (305, 608))],
        'output_file': 'bld/apsr_author_website_coding_harmonized.csv'}
harmonize_author_website_coding(**apsr)
