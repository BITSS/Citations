#!/usr/bin/env python3

import warnings

import pandas as pd
import numpy as np
from tools import (read_data_entry, hyperlink_google_search, fill_columns_down,
                   apply_func_to_df, hyperlink_title)


def harmonize(template_file, index_column, entry_columns, merge_on_columns,
              inputs, output_file, template_apply_func=[]):
    '''
    Combine entries into single file based on template.
    '''
    df = read_data_entry(template_file)
    apply_func_to_df(df, template_apply_func)
    template_columns = df.columns
    for import_ix, input_dict in enumerate(inputs):
        data_entry = read_data_entry(input_dict['file_in'])
        data_entry.fillna('', inplace=True)
        apply_func_to_df(data_entry, input_dict.get('input_apply_func', []))
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
            print(df.loc[df[merge_indicator] != 'both', merge_on_columns +
                         [merge_indicator]])
        df.loc[importable, entry_columns] = df.loc[
            importable, input_dict['entry_column']]

    return df.to_csv(output_file, columns=template_columns, index=None)

# Author website coding
# AJPS
ajps = {'template_file': 'bld/ajps_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [{'file_in': 'data_entry/ajps_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    'entry_column': 'website_category_RK_TC_resolved',
                    'input_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (1, 304)},
                   {'file_in': 'data_entry/ajps_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    'entry_column': 'website_category_KJK_RP_resolved',
                    'input_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (305, 608)}],
        'output_file': 'bld/ajps_author_website_coding_harmonized.csv'}
harmonize(**ajps)

# APSR
apsr = {'template_file': 'bld/apsr_author_website_coding_template.csv',
        'index_column': 'article_ix',
        'entry_columns': ['website_category'],
        'merge_on_columns': ['doi', 'title', 'author'],
        'inputs': [{'file_in': 'data_entry/apsr_author_website_coding'
                    '_diff_resolution_RK_TC.ods',
                    'entry_column': 'website_category_RK_TC_resolved',
                    'input_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (252, 515)},
                   {'file_in': 'data_entry/apsr_author_website_coding'
                    '_diff_resolution_KJK_RP.ods',
                    'entry_column': 'website_category_KJK_RP_resolved',
                    'input_apply_func': [('author', hyperlink_google_search)],
                    'index_range': (1, 251)}],
        'output_file': 'bld/apsr_author_website_coding_harmonized.csv'}
harmonize(**apsr)

# Reference coding
fill_article_columns = (lambda x: fill_columns_down(x, ['doi',
                                                        'article_ix',
                                                        'title']))
# AJPS
ajps = {'template_file': 'bld/ajps_reference_coding_template.csv',
        'template_apply_func': [(None, fill_article_columns)],
        'index_column': 'article_ix',
        'entry_columns': ['reference_category'],
        'merge_on_columns': ['doi', 'article_ix', 'title', 'match', 'context'],
        'inputs': [{'file_in': 'data_entry/ajps_reference_coding'
                    '_diff_resolution_RK_TC.ods',
                    'entry_column': 'reference_category_RK_TC_resolved',
                    'input_apply_func': [(None, lambda x:
                                          hyperlink_title(x, 'ajps')),
                                         (None, fill_article_columns)],
                    'index_range': (1, 304)},
                   {'file_in': 'data_entry/ajps_reference_coding'
                    '_diff_resolution_KJK_RP.ods',
                    'entry_column': 'reference_category_KJK_RP_resolved',
                    'input_apply_func': [(None, lambda x:
                                          hyperlink_title(x, 'ajps')),
                                         (None, fill_article_columns)],
                    'index_range': (305, 608)}],
        'output_file': 'bld/ajps_reference_coding_harmonized.csv'}
harmonize(**ajps)
