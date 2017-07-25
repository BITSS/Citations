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

    skipped = df[entry_columns].fillna('') == 'skip'

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


# Resolve ajps author website coding diffs.
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


# Resolve ajps reference coding diffs.
resolution_pairs = [('KJK', 'RK'), ('RP', 'TC')]

input_file = 'bld/ajps_reference_coding_diff.csv'
output_file_prefix = 'bld/ajps_reference_coding_diff_resolution'

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

# Resolve ajps article coding diffs.
ajps_resolution_pairs = [('BC', 'TC'), ('RP', 'EH')]

# Article topic 1
input_file = 'bld/ajps_article_coding_diff_topic1.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_topic1_resolution'

for pair in ajps_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic1_' + x for x in pair]
    resolution_column = 'article_topic1' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article topic 2
input_file = 'bld/ajps_article_coding_diff_topic2.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_topic2_resolution'

for pair in ajps_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic2_' + x for x in pair]
    resolution_column = 'article_topic2' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article data type
input_file = 'bld/ajps_article_coding_diff_data_type.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_data_type_resolution'

for pair in ajps_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_data_type_' + x for x in pair]
    resolution_column = 'article_data_type' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Resolve apsr article coding diffs.
apsr_resolution_pairs = [('BC', 'EH'), ('RP', 'TC')]

# Article topic 1
input_file = 'bld/apsr_article_coding_diff_topic1.csv'
output_file_prefix = 'bld/apsr_article_coding_diff_topic1_resolution'

for pair in apsr_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic1_' + x for x in pair]
    resolution_column = 'article_topic1' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article topic 2
input_file = 'bld/apsr_article_coding_diff_topic2.csv'
output_file_prefix = 'bld/apsr_article_coding_diff_topic2_resolution'

for pair in apsr_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic2_' + x for x in pair]
    resolution_column = 'article_topic2' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article data type
input_file = 'bld/apsr_article_coding_diff_data_type.csv'
output_file_prefix = 'bld/apsr_article_coding_diff_data_type_resolution'

for pair in apsr_resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_data_type_' + x for x in pair]
    resolution_column = 'article_data_type' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Resolve ajps article coding diffs.
resolution_pairs = [('BC', 'TC'), ('EH', 'RP')]

# Article topic 1
input_file = 'bld/ajps_article_coding_diff_topic1.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_topic1_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic1_' + x for x in pair]
    resolution_column = 'article_topic1' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article topic 2
input_file = 'bld/ajps_article_coding_diff_topic2.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_topic2_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_topic2_' + x for x in pair]
    resolution_column = 'article_topic2' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)

# Article data type
input_file = 'bld/ajps_article_coding_diff_data_type.csv'
output_file_prefix = 'bld/ajps_article_coding_diff_data_type_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['article_data_type_' + x for x in pair]
    resolution_column = 'article_data_type' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['doi', 'title', 'article_ix', 'abstract'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


# Dataverse
resolution_pairs = [('RP', 'TC')]
input_file = 'bld/ajps_dataverse_diff.csv'
output_file_prefix = 'bld/ajps_dataverse_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['result_category_' + x for x in pair]
    resolution_column = 'result_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['article_ix', 'result_ix', 'issue_date', 'issue_number',
                       'issue_pages', 'doi', 'title', 'authors_ajps_toc',
                       'dataverse_name', 'dataverse_authors',
                       'dataverse_description', 'dataverse_query'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)


input_file = 'bld/apsr_dataverse_diff.csv'
output_file_prefix = 'bld/apsr_dataverse_diff_resolution'

for pair in resolution_pairs:
    diff = pd.read_csv(input_file)

    suffix = '_' + '_'.join(pair)

    entry_columns = ['result_category_' + x for x in pair]
    resolution_column = 'result_category' + suffix + '_resolved'
    conflict_column = 'conflict_ignore_skip' + suffix

    output_columns = (['article_ix', 'result_ix', 'index', 'volume', 'issue',
                       'issue_date', 'publication_date', 'doi', 'pages',
                       'authors_apsr_toc', 'title', 'dataverse_name',
                       'dataverse_authors', 'dataverse_description',
                       'dataverse_query'] +
                      entry_columns + [resolution_column,
                                       conflict_column])

    add_resolution_columns(diff, entry_columns=entry_columns,
                           conflict_column=conflict_column,
                           resolution_column=resolution_column)

    bool_printing = {True: 'True', False: ''}
    diff.replace({conflict_column: bool_printing}, inplace=True)

    diff.to_csv(output_file_prefix + suffix + '.csv',
                columns=output_columns, index=None)
