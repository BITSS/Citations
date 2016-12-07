#!/usr/bin/env python3

import os.path
import warnings
from collections import OrderedDict

import numpy as np
import pandas as pd

from tools import (fill_columns_down, read_data_entry, hyperlink,
                   hyperlink_google_search, hyperlink_title)


def create_diff(input_dict, output_file, entry_column, columns_merge_on):
    '''
    Create spreadsheet of differences in data entry.

    input_files: Dictionary with person identifiers as keys and file paths
    as values.
    '''
    if not input_dict:
        return None
    persons = list(input_dict.keys())
    merge_indicator_columns = []
    for ix, person in enumerate(persons):
        if ix == 0:
            merged_entries = input_dict[person]
        else:
            merge_indicator_columns.append('_'.join(persons[:ix]) +
                                           '_with_' + person)
            merged_entries = pd.merge(left=merged_entries,
                                      right=input_dict[person],
                                      suffixes=('_' + '_'.join(persons[:ix]),
                                                '_' + person),
                                      how='outer', on=columns_merge_on,
                                      left_index=True, right_index=True,
                                      indicator=merge_indicator_columns[-1])

    consistent_template = np.all(merged_entries[merge_indicator_columns] ==
                                 'both', axis=(0, 1))
    if consistent_template:
        entry_columns = [entry_column + '_' + x for x in urap_initials]
        merged_entries = merged_entries[columns_merge_on + entry_columns]

        data_entered = merged_entries[entry_columns].notnull()
        merged_entries['number_of_entries'] = np.sum(data_entered, axis=1)
        merged_entries['conflict'] = (merged_entries[entry_columns]
                                      [data_entered].apply(pd.Series.nunique,
                                                           axis=1) > 1)
        merged_entries['conflict_ignore_skip'] = (merged_entries[entry_columns]
                                                  [data_entered].
                                                  replace('skip',
                                                          value=np.nan).
                                                  apply(pd.Series.nunique,
                                                        axis=1) > 1)
        bool_printing = {True: 'True', False: ''}
        merged_entries.replace({'conflict': bool_printing,
                                'conflict_ignore_skip': bool_printing},
                               inplace=True)

        merged_entries.to_csv(output_file, index=None)

    else:
        warnings.warn('Some lines could not be matched consistently across' +
                      ' files.\nPlease investigate output file.')
        merged_entries.to_csv(output_file, index_label='row_ix')


def standard_entry_dict(coding, entry_column):
    entry_dict = OrderedDict()
    for person in urap_initials:
        input_file = 'data_entry/' + coding + '_' + person + '.ods'
        if not os.path.isfile(input_file):
            warnings.warn('''File not found: {file}.
            Returning 'None' for {coding}'''.format(file=input_file,
                                                    coding=coding))
            return None
        entry = read_data_entry(input_file)
        fill_columns_down(entry, [column for column in entry.columns
                                  if column in ['article_ix', 'doi',
                                                'title']])
        entry.rename(columns={entry_column: entry_column + '_' + person},
                     inplace=True)
        entry_dict[person] = entry
    return entry_dict


def apply_func_dict(entry_dict, columns, func):
    for person, entry in entry_dict.items():
        for column in columns:
            linkable = entry[column].notnull()
            entry.loc[linkable, column] = (entry.loc[linkable, column].
                                           apply(func))
    return entry_dict

urap_initials = ['KJK', 'RK', 'RP', 'TC']

# Diff AJPS reference coding.
create_diff(input_dict=standard_entry_dict('ajps_reference_coding',
                                           'reference_category'),
            output_file='bld/ajps_reference_coding_diff.csv',
            entry_column='reference_category',
            columns_merge_on=['doi', 'article_ix', 'title', 'match',
                              'context'])

# Diff AJPS link coding.
create_diff(input_dict=apply_func_dict(standard_entry_dict('ajps_link_coding',
                                                           'link_category'),
                                       ['clickable_link'], hyperlink),
            output_file='bld/ajps_link_coding_diff.csv',
            entry_column='link_category',
            columns_merge_on=['doi', 'article_ix', 'title', 'match',
                              'context', 'reference_category',
                              'clickable_link'])

# Diff AJPS author website coding.
create_diff(input_dict=apply_func_dict(
    standard_entry_dict('ajps_author_website_coding', 'website_category'),
    ['author'],
    hyperlink_google_search),
    output_file='bld/ajps_author_website_coding_diff.csv',
    entry_column='website_category',
    columns_merge_on=['doi', 'article_ix', 'title', 'author'])

# Diff APSR reference coding.
apsr_dict = standard_entry_dict('apsr_reference_coding', 'reference_category')
for entry in apsr_dict.values():
    entry = hyperlink_title(entry, 'apsr')

create_diff(input_dict=apsr_dict,
            output_file='bld/apsr_reference_coding_diff.csv',
            entry_column='reference_category',
            columns_merge_on=['doi', 'article_ix', 'reference_ix', 'volume',
                              'issue', 'pages', 'publication_date', 'authors',
                              'authors_affiliations', 'title', 'match',
                              'context'])

# Diff APSR author website coding.
create_diff(input_dict=apply_func_dict(
    standard_entry_dict('apsr_author_website_coding', 'website_category'),
    ['author'],
    hyperlink_google_search),
    output_file='bld/apsr_author_website_coding_diff.csv',
    entry_column='website_category',
    columns_merge_on=['doi', 'article_ix', 'title', 'author'])
