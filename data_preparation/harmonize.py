#!/usr/bin/env python3

import warnings

import pandas as pd
import numpy as np
from tools import (read_data_entry, hyperlink_google_search, fill_columns_down,
                   apply_func_to_df, hyperlink_title)


def harmonize(template_file, index_column, entry_columns, merge_on_columns,
              inputs, output_file, template_apply_func=[]):
    '''
    Combine data entries into single file based on template.
    '''
    df = read_data_entry(template_file)
    df.fillna('', inplace=True)
    apply_func_to_df(df, template_apply_func)
    template_columns = df.columns
    for import_ix, input_dict in enumerate(inputs):
        data_entry = read_data_entry(input_dict['file_in'])
        data_entry.fillna('', inplace=True)
        apply_func_to_df(data_entry, input_dict.get('input_apply_func', []))

        merge_indicator = '_merge_{}'.format(import_ix)
        df = pd.merge(df, data_entry, how='left', on=merge_on_columns,
                      suffixes=('', '_import'), indicator=merge_indicator)

        if np.sum(df[merge_indicator] != 'both') > 0:
            warnings.warn('Some entries of input file {} could not be found in'
                          ' or matched to template file {}.'.format(
                              input_dict['file_in'], template_file))
            print(df.loc[df[merge_indicator] != 'both', merge_on_columns +
                         [merge_indicator]])

        in_index_range = np.full(shape=df.shape[0], fill_value=False,
                                 dtype=bool)
        for lower_bound, upper_bound in input_dict['index_ranges']:
            in_index_range = np.any([in_index_range,
                                     np.all([lower_bound <= df[index_column],
                                             df[index_column] <= upper_bound],
                                            axis=0)],
                                    axis=0)
        importable = np.all([in_index_range, df[merge_indicator] == 'both'],
                            axis=0)
        df.loc[importable, entry_columns] = df.loc[
            importable, input_dict['entry_column']]

    return df.to_csv(output_file, columns=template_columns, index=None, encoding='utf-8')

# Author website coding
# AJPS
author_website_ajps = \
    {'template_file': 'bld/ajps_author_website_coding_template.csv',
     'index_column': 'article_ix',
     'entry_columns': ['website_category'],
     'merge_on_columns': ['doi', 'title', 'author'],
     'inputs': [{'file_in': 'data_entry/ajps_author_website_coding'
                 '_diff_resolution_RK_TC.ods',
                 'entry_column': 'website_category_RK_TC_resolved',
                 'input_apply_func': [(None, lambda x: fill_columns_down(x, ['doi', 'title', 'author']))],
                 'index_ranges': [(1, 304)]},
                {'file_in': 'data_entry/ajps_author_website_coding'
                 '_diff_resolution_KJK_RP.ods',
                 'entry_column': 'website_category_KJK_RP_resolved',
                 'input_apply_func': [(None, lambda x: fill_columns_down(x, ['doi', 'title', 'author']))],
                 'index_ranges': [(305, 608)]}],
     'output_file': 'bld/ajps_author_website_coding_harmonized.csv'}
harmonize(**author_website_ajps)

# APSR
author_website_apsr = \
    {'template_file': 'bld/apsr_author_website_coding_template.csv',
     'index_column': 'article_ix',
     'entry_columns': ['website_category'],
     'merge_on_columns': ['doi', 'title', 'author'],
     'inputs': [{'file_in': 'data_entry/apsr_author_website_coding'
                 '_diff_resolution_RK_TC.ods',
                 'entry_column': 'website_category_RK_TC_resolved',
                 'input_apply_func': [(None, lambda x: fill_columns_down(x, ['doi', 'title', 'author']))],
                 'index_ranges': [(252, 515)]},
                {'file_in': 'data_entry/apsr_author_website_coding'
                 '_diff_resolution_KJK_RP.ods',
                 'entry_column': 'website_category_KJK_RP_resolved',
                 'input_apply_func': [(None, lambda x: fill_columns_down(x, ['doi', 'title', 'author']))],
                 'index_ranges': [(1, 251)]}],
     'output_file': 'bld/apsr_author_website_coding_harmonized.csv'}
harmonize(**author_website_apsr)

# Reference coding
fill_article_columns = (lambda x: fill_columns_down(x, ['doi',
                                                        'article_ix',
                                                        'title']))
# AJPS
reference_ajps = \
    {'template_file': 'bld/ajps_reference_coding_template.csv',
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
                 'index_ranges': [(1, 304)]},
                {'file_in': 'data_entry/ajps_reference_coding'
                 '_diff_resolution_KJK_RP.ods',
                 'entry_column': 'reference_category_KJK_RP_resolved',
                 'input_apply_func': [(None, lambda x:
                                       hyperlink_title(x, 'ajps')),
                                      (None, fill_article_columns)],
                 'index_ranges': [(305, 608)]}],
     'output_file': 'bld/ajps_reference_coding_harmonized.csv'}
harmonize(**reference_ajps)

# APSR
# Pages columns has entries like '133-145' and '886'. Reading these from
# ods will make these 'string' and 'int' types, but reading from csv
# will consistently make both 'string'. Hence convert pages column to
# string.

# Exclude 'authors' and 'authors_affiliations' as they are sometimes
# empty and 'fill_columns_down' would fill these fields ignoring article
# boundaries.
reference_apsr_article_level_merge_on_columns = \
    ['volume', 'issue', 'pages', 'publication_date', 'doi',
     'article_ix', 'title']

reference_apsr = \
    {'template_file': 'bld/apsr_reference_coding_template.csv',
     'index_column': 'article_ix',
     'entry_columns': ['reference_category'],
     'merge_on_columns': (reference_apsr_article_level_merge_on_columns +
                          ['reference_ix', 'match', 'context']),
     'inputs': [{'file_in': 'data_entry/apsr_reference_coding'
                 '_diff_resolution_RP_TC.ods',
                 'input_apply_func':
                 [('pages', str),
                  (None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, reference_apsr_article_level_merge_on_columns))],
                 'entry_column': 'reference_category_RP_TC_resolved',
                 'index_ranges': [(1, 110), (220, 319)]},
                {'file_in': 'data_entry/apsr_reference_coding'
                 '_diff_resolution_KJK_RK.ods',
                 'input_apply_func':
                 [('pages', str),
                  (None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, reference_apsr_article_level_merge_on_columns))],
                 'entry_column': 'reference_category_KJK_RK_resolved',
                 'index_ranges': [(111, 219), (320, 447)]}],
        'output_file': 'bld/apsr_reference_coding_harmonized.csv'}
harmonize(**reference_apsr)

# AJPS article type coding
ajps_article_level_merge_on_columns = \
    ['doi', 'article_ix']

ajps_article_topic_coding = \
    {'template_file': 'bld/ajps_article_coding_template.csv',
     'index_column': 'article_ix', 
     'entry_columns': ['article_topic1'],   
     'merge_on_columns': (ajps_article_level_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/ajps_article_coding_diff_topic1_resolution_EH_RP.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'ajps')),
                  (None, lambda x: fill_columns_down(x, ajps_article_level_merge_on_columns))],
                 'entry_column': 'article_topic1_EH_RP_resolved',
                 'index_ranges': [(1, 152), (303, 453)]},
                {'file_in': 'data_entry/ajps_article_coding_diff_topic1_resolution_BC_TC.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'ajps')),
                  (None, lambda x: fill_columns_down(x, ajps_article_level_merge_on_columns))],
                 'entry_column': 'article_topic1_BC_TC_resolved',
                 'index_ranges': [(153, 302), (454, 608)]}],
                 'output_file': 'bld/ajps_article_topic_coding_harmonized.csv'}
harmonize(**ajps_article_topic_coding)

ajps_data_type_coding = \
    {'template_file': 'bld/ajps_article_coding_template.csv',
     'index_column': 'article_ix', 
     'entry_columns': ['article_data_type'],   
     'merge_on_columns': (ajps_article_level_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/ajps_article_coding_diff_data_type_resolution_EH_RP.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'ajps')),
                  (None, lambda x: fill_columns_down(x, ajps_article_level_merge_on_columns))],
                 'entry_column': 'article_data_type_EH_RP_resolved',
                 'index_ranges': [(1, 152), (303, 453)]},
                {'file_in': 'data_entry/ajps_article_coding_diff_data_type_resolution_BC_TC.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'ajps')),
                  (None, lambda x: fill_columns_down(x, ajps_article_level_merge_on_columns))],
                 'entry_column': 'article_data_type_BC_TC_resolved',
                 'index_ranges': [(153, 302), (454, 608)]}],
                 'output_file': 'bld/ajps_article_data_type_coding_harmonized.csv'}
harmonize(**ajps_data_type_coding)

# APSR article type coding
apsr_article_level_merge_on_columns = \
    ['doi', 'article_ix']

apsr_article_topic_coding = \
    {'template_file': 'bld/apsr_article_coding_template.csv',
     'index_column': 'article_ix', 
     'entry_columns': ['article_topic1'],   
     'merge_on_columns': (apsr_article_level_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/apsr_article_coding_diff_topic1_resolution_BC_EH.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, apsr_article_level_merge_on_columns))],
                 'entry_column': 'article_topic1_BC_EH_resolved',
                 'index_ranges': [(1, 113), (224, 336)]},
                {'file_in': 'data_entry/apsr_article_coding_diff_topic1_resolution_RP_TC.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, apsr_article_level_merge_on_columns))],
                 'entry_column': 'article_topic1_RP_TC_resolved',
                 'index_ranges': [(114, 223), (337, 447)]}],
                 'output_file': 'bld/apsr_article_topic_coding_harmonized.csv'}
harmonize(**apsr_article_topic_coding)

apsr_data_type_coding = \
    {'template_file': 'bld/apsr_article_coding_template.csv',
     'index_column': 'article_ix', 
     'entry_columns': ['article_data_type'],   
     'merge_on_columns': (apsr_article_level_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/apsr_article_coding_diff_data_type_resolution_BC_EH.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, apsr_article_level_merge_on_columns))],
                 'entry_column': 'article_data_type_BC_EH_resolved',
                 'index_ranges': [(1, 113), (224, 336)]},
                {'file_in': 'data_entry/apsr_article_coding_diff_data_type_resolution_RP_TC.ods',
                 'input_apply_func':
                 [(None, lambda x: hyperlink_title(x, 'apsr')),
                  (None, lambda x: fill_columns_down(x, apsr_article_level_merge_on_columns))],
                 'entry_column': 'article_data_type_RP_TC_resolved',
                 'index_ranges': [(114, 223), (337, 447)]}],
                 'output_file': 'bld/apsr_article_data_type_coding_harmonized.csv'}
harmonize(**apsr_data_type_coding)

# Merge article type coding files


# Dataverse
dataverse_merge_on_columns = ['article_ix', 'result_ix', 'dataverse_name']
apsr_dataverse = \
    {'template_file': 'bld/apsr_dataverse_search.ods',
     'index_column': 'article_ix',
     'entry_columns': ['result_category'],
     'merge_on_columns': (dataverse_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/apsr_dataverse_diff_resolution_RP_TC.ods',
                 'entry_column': 'result_category_RP_TC_resolved',
                 'index_ranges': [(1, 1000)]}],
     'output_file': 'bld/apsr_dataverse_harmonized.csv'}
harmonize(**apsr_dataverse)

ajps_dataverse = \
    {'template_file': 'bld/ajps_dataverse_search.ods',
     'index_column': 'article_ix',
     'entry_columns': ['result_category'],
     'merge_on_columns': (dataverse_merge_on_columns),
     'inputs': [{'file_in': 'data_entry/ajps_dataverse_diff_resolution_RP_TC.ods',
                 'entry_column': 'result_category_RP_TC_resolved',
                 'index_ranges': [(1, 1000)]}],
     'output_file': 'bld/ajps_dataverse_harmonized.csv'}
harmonize(**ajps_dataverse)
