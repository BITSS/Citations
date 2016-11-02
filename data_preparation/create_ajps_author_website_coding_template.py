#!/usr/bin/env python3
'''
Create template for author website coding.
'''


import re

import numpy as np
import pandas as pd

from tools import strip_tags, unique_elements


def extract_authors(article):
    authors = [x.strip() for x in article['authors'].split(', ')]

    authors = [a for a in authors if a != '(contact author)']
    name_suffixes = ['Jr', 'Jr.', 'III']
    for ix, author in enumerate(authors):
        if author in name_suffixes:
            print(author)
            authors[ix - 1] = authors[ix - 1] + ', ' + author
    authors = [a for a in authors if a not in name_suffixes]

    return (pd.Series(authors, index=['author_{}'.format(i)
                                      for i in range(len(authors))]))


def hyperlink_google_search(text):
    '''Hyperlink to search for text with Google.

    Show 15 results, and turn off personalization of results.
    '''
    return ('=HYPERLINK("https://google.com/search?q={x}&num=15&pws=0",'
            '"{x}")'.format(x=text))

input_file = 'bld/ajps_articles_2006_2014.csv'
author_file = 'bld/ajps_article_info_from_issue_toc.csv'
output_file = 'bld/ajps_author_website_coding_template.csv'

input_columns = ['doi', 'title', 'authors', 'authors_description',
                 'biographies', 'footnote_1', 'footnote_2',
                 'first_published']

df_authors = pd.read_csv(author_file)
df_authors['article_ix'] = df_authors.index + 1
df_authors['authors'].fillna('', inplace=True)

# Extract author names.
df_authors['authors'] = df_authors['authors'].apply(lambda x:
                                                    x.replace(' and ', ', '))
df_authors = pd.concat([df_authors, df_authors.apply(extract_authors, axis=1)],
                       axis=1)

# Convert to one row per paper*author.
df_authors = pd.melt(df_authors, id_vars=[x for x in df_authors.columns.values
                                          if not x.startswith('author_')],
                     value_vars=[c for c in df_authors.columns.values
                                 if c.startswith('author_')],
                     var_name='author_ix', value_name='author')
df_authors.sort_values(
    by=['article_ix', 'author_ix'], inplace=True)
df_authors.dropna(subset=['author'], inplace=True)
df_authors.drop('author_ix', axis=1, inplace=True)

df = pd.read_csv(input_file, header=0,
                 usecols=input_columns,
                 parse_dates=['first_published'], infer_datetime_format=True,
                 converters={'biographies': strip_tags})
df['article_ix'] = df.index + 1

df = pd.merge(left=df, right=df_authors, how='left', on='doi',
              suffixes=('', '_from_issue_toc'))

df['author'] = df['author'].apply(hyperlink_google_search)
df['website_category'] = np.nan
df['website'] = np.nan

df.to_csv('bld/ajps_author_website_coding_template.csv',
          columns=['article_ix', 'doi', 'title', 'author',
                   'website_category', 'website'], index=None)
