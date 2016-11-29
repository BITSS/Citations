#!/usr/bin/env python3

import warnings

import pandas as pd
import numpy as np
from tools import read_data_entry, hyperlink_google_search


def harmonize_author_website_coding(template_file, index_column, entry_columns,
                                    merge_on_columns, inputs, output_file):
    '''
    Combine author website coding entries into single file with one entry per
    article*website.
    '''
    df = read_data_entry(template_file)
    template_columns = df.columns
    for import_ix, input_dict in enumerate(inputs):
        data_entry = read_data_entry(input_dict['file_in'])
        data_entry.fillna('', inplace=True)
        for column, func in input_dict.get('df_apply_func', []):
            data_entry[column] = data_entry[column].apply(func)
        merge_indicator = '_merge_{}'.format(import_ix)
        df = pd.merge(df, data_entry, how='left', on=merge_on_columns,
                      suffixes=('', '_import'), indicator=merge_indicator)
        importable = np.all([input_dict['index_range'][0] <= df[index_column],
                             df[index_column] <= input_dict['index_range'][1],
                             df[merge_indicator] == 'both'], axis=0)
        if np.sum(df[merge_indicator] != 'both') > 0:
            warnings.warn('Some entries of input file {} could not be found in'
                          ' or matched to template file {}.'.format(
                              input_dict['file_in'], template_file))
            print(df.loc[df[merge_indicator] != 'both', ['article_ix', 'title',
                                                         'author',
                                                         merge_indicator]])
        df.loc[importable, entry_columns] = df.loc[
            importable, input_dict['entry_column']]

    return df.to_csv(output_file, columns=template_columns, index=None)

# AJPS
ajps = {'template_file': 'bld/ajps_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [{'file_in': 'data_entry/ajps_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    'entry_column': 'website_category_RK_TC_resolved',
                    'df_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (1, 304)},
                   {'file_in': 'data_entry/ajps_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    'entry_column': 'website_category_KJK_RP_resolved',
                    'df_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (305, 608)}],
        'output_file': 'bld/ajps_author_website_coding_harmonized.csv'}
harmonize_author_website_coding(**ajps)


# APSR
apsr = {'template_file': 'bld/apsr_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [{'file_in': 'data_entry/apsr_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    'entry_column': 'website_category_RK_TC_resolved',
                    'df_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (252, 515)},
                   {'file_in': 'data_entry/apsr_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    'entry_column': 'website_category_KJK_RP_resolved',
                    'df_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (1, 251)}],
        'output_file': 'bld/apsr_author_website_coding_harmonized.csv'}
harmonize_author_website_coding(**apsr)
