#!/usr/bin/env python3
from dateutil import parser
from itertools import chain

import requests
import pandas as pd
import numpy as np
from tools import extract_authors_apsr, unique_elements, hyperlink


def dataverse_search(article, api_token, result_variables_dataverse,
                     result_variables_df):
    authors = [x.strip() for x in article['authors_apsr_toc'].split(';')]
    results = []
    for author in authors:
        query = '"{title}" AND "{author}"'.format(title=article['title'],
                                                  author=author)
        print(query)
        start_result = 0
        results_per_page = 1000
        parsed_all_results = False
        while(not parsed_all_results):
            r = requests.get('https://dataverse.harvard.edu/api/search',
                             params={'q': query,
                                     'key': api_token,
                                     'start': start_result,
                                     'per_page': results_per_page})
            query_result = r.json()['data']
            # Add query information
            for result in query_result['items']:
                result['query'] = hyperlink(r.url.replace('/api/search', '') +
                                            '&page={}'.format(start_result //
                                                              results_per_page + 1))
            results += query_result['items']

            start_result += results_per_page
            parsed_all_results = start_result >= query_result['total_count']

    results = [dataverse_parse_result(result) for result in results]
    results = unique_elements(results, idfun=tuple)
    index = ['{variable}{i}'.format(variable=variable, i=i)
             for i in range(len(results))
             for variable in result_variables_df]
    return pd.Series(list(chain.from_iterable(results)),
                     index=index)


def dataverse_parse_result(item):
    # Convert list of authors to string.
    if item.get('authors', None):
        item['authors'] = ';'.join(item['authors'])
    return [item.get(dataverse_variable, '')
            for dataverse_variable in result_variables_dataverse]


def result_is_files(article_result):
    # Ignore 'Replication data for: ' prefix when comparing
    # Dataverse result name with article title.
    return (article_result['dataverse_name'].
            split('Replication data for: ')[-1].lower() ==
            article_result['title'].lower())

input_file = 'bld/apsr_article_info_from_issue_toc.csv'
api_token_file = 'data_preparation/dataverse_api_token.txt'
output_file = 'bld/apsr_dataverse_search.csv'

select_after = parser.parse('July 1 2014')
select_before = parser.parse('January 1 2015')

# Select variables to collect from Dataverse API response, and
# how to call them in dataframe.
result_variables_dataverse = ['name', 'authors', 'description', 'query']
result_variables_df = ['dataverse_' +
                       var for var in result_variables_dataverse]

with open(api_token_file) as f:
    api_token = f.read()

df = pd.read_csv(input_file, parse_dates=['issue_date'])

df = df[np.all([select_after <= df['issue_date'],
                df['issue_date'] < select_before], axis=0)]

df.reset_index(inplace=True)
df['article_ix'] = df.index + 1

# Convert to one row per paper*author.
df.rename(columns={'authors': 'authors_apsr_toc'}, inplace=True)
df['authors_apsr_toc'].fillna('', inplace=True)

df = pd.concat([df, df.apply(dataverse_search, axis=1, api_token=api_token,
                             result_variables_dataverse=result_variables_dataverse,
                             result_variables_df=result_variables_df)],
               axis=1)
df = pd.wide_to_long(df, [variable
                          for variable in result_variables_df],
                     i='article_ix', j='result_ix')

df.sort_index(inplace=True)
df.dropna(how='all', subset=result_variables_df, inplace=True)
df.drop_duplicates(subset=[x for x in df.columns if x != 'dataverse_query'],
                   inplace=True)
df.reset_index(inplace=True)

# df = df[df['result_ix'] != '']
df['result_ix'] = df['result_ix'].astype(float) + 1

df.loc[df.apply(result_is_files, axis=1), 'result_category'] = 'files'

df.to_csv(output_file, index=None)
