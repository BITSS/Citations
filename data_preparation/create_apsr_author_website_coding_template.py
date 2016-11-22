#!/usr/bin/env python3
'''
Create template for APSR author website coding.
'''

from dateutil import parser

import numpy as np
import pandas as pd
from tools import hyperlink_google_search


def extract_authors(article):
    authors = [x.strip() for x in article['authors'].split(';')]
    return (pd.Series(authors, index=['author_{}'.format(i)
                                      for i in range(len(authors))]))


input_file = 'bld/apsr_article_info_from_issue_toc.csv'
output_file = 'bld/apsr_author_website_coding_template.csv'

select_after = parser.parse('January 1 2006')
select_before = parser.parse('January 1 2015')

df = pd.read_csv(input_file, parse_dates=['issue_date'])

df = df[np.all([select_after <= df['issue_date'],
                df['issue_date'] < select_before], axis=0)]

df.reset_index(inplace=True)
df['article_ix'] = df.index + 1

# Convert to one row per paper*author.
df['authors'].fillna('', inplace=True)
df = pd.concat([df, df.apply(extract_authors, axis=1)],
               axis=1)
df = pd.melt(df, id_vars=[x for x in df.columns.values
                          if not x.startswith('author_')],
             value_vars=[c for c in df.columns.values
                         if c.startswith('author_')],
             var_name='author_ix', value_name='author')
df.sort_values(by=['article_ix', 'author_ix'], inplace=True)
df.dropna(subset=['author'], inplace=True)
df.drop('author_ix', axis=1, inplace=True)

df['author'] = df['author'].apply(hyperlink_google_search)
df['website_category'] = np.nan
df['website'] = np.nan

df.to_csv(output_file, index=None,
          columns=['article_ix', 'doi', 'title', 'author', 'website_category',
                   'website'])
