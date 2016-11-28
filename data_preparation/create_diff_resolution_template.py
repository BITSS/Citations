#!/usr/bin/env python3
'''
Create sheet to manually resolve differences in data entry.
'''
import pandas as pd
import numpy as np


def add_resolution_columns(df, entry_columns, conflict_column,
                           resolution_column):
    '''
    Add columns that indicate and resolve conflicts in data entry.

    Two entries conflict if they are non-empty, different, and neither
    is 'skip'.

    Resolve automatically as follows:

    1. If there is only one entry take that entry.
    2. If entries agree, take the left entry.
    3. If there are two entries and entries are different, and
    one of the entries is 'skip', take 'skip'.

    Otherwise leave blank for manual resolution.
    '''
    data_entered = df[entry_columns].notnull()
    number_of_entries_unique = (df[entry_columns][data_entered].
                                replace('skip', value=np.nan).
                                apply(pd.Series.nunique, axis=1))
    conflict = number_of_entries_unique > 1

    skipped = df[entry_columns] == 'skip'

    for entry_column in entry_columns:
        take_it = np.all([data_entered[entry_column], ~skipped[entry_column],
                          number_of_entries_unique == 1], axis=0)
        df.loc[take_it, resolution_column] = df.loc[take_it, entry_column]

    agree_skip = np.all([np.any(skipped, axis=1),
                         number_of_entries_unique == 0], axis=0)
    df.loc[agree_skip, resolution_column] = 'skip'

    df[conflict_column] = conflict

# Resolve AJPS reference coding diffs.
resolution_pairs = [('KJK', 'RP'), ('RK', 'TC')]

input_file = 'bld/ajps_reference_coding_diff.csv'
output_file_prefix = 'bld/ajps_reference_coding_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['reference_category_' + x for x in pair]
    resolution_column = 'reference_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'article_ix', 'title', 'match', 'context'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Resolve AJPS author website coding diffs.
resolution_pairs = [('KJK', 'RP'), ('RK', 'TC')]

input_file = 'bld/ajps_author_website_coding_diff.csv'
output_file_prefix = 'bld/ajps_author_website_coding_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['website_category_' + x for x in pair]
    resolution_column = 'website_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['article_ix', 'doi', 'title', 'author'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Resolve APSR author website coding diffs.
resolution_pairs = [('KJK', 'RP'), ('RK', 'TC')]

input_file = 'bld/apsr_author_website_coding_diff.csv'
output_file_prefix = 'bld/apsr_author_website_coding_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['website_category_' + x for x in pair]
    resolution_column = 'website_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['article_ix', 'doi', 'title', 'author'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Resolve AJPS link coding diffs.
urap_initials = ['KJK', 'RP', 'RK', 'TC']

input_file = 'bld/ajps_link_coding_diff.csv'
output_file = 'bld/ajps_link_coding_diff_resolution.csv'

entry_columns = ['link_category_' + x for x in urap_initials]
resolution_column = 'link_category_resolved'
conflict_column = 'conflict_ignore_skip'
output_columns = (['article_ix', 'doi', 'title', 'match', 'context',
                   'reference_category', 'clickable_link'] +
                  entry_columns + [resolution_column, conflict_column])
diff = pd.read_csv(input_file)

add_resolution_columns(diff, entry_columns=entry_columns,
                       conflict_column=conflict_column,
                       resolution_column=resolution_column)

bool_printing = {True: 'True', False: ''}
diff.replace({conflict_column: bool_printing}, inplace=True)

diff.to_csv(output_file, columns=output_columns, index=None)


# Resolve APSR reference coding diffs.
resolution_pairs = [('KJK', 'RK'), ('RP', 'TC')]

input_file = 'bld/apsr_reference_coding_diff.csv'
output_file_prefix = 'bld/apsr_reference_coding_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['reference_category_' + x for x in pair]
    resolution_column = 'reference_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['volume', 'issue', 'pages', 'publication_date', 'doi',
                       'authors', 'authors_affiliations', 'title',
                       'article_ix', 'reference_ix', 'match', 'context'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)
