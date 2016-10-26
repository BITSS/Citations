#!/usr/bin/env python3
'''
Create template for author website coding.
'''

# Some buggy articles: 355, 423, 425, 563, 584, 585, empty authors

import re

import numpy as np
import pandas as pd

from tools import strip_tags, unique_elements


def extract_authors(article):
    authors = []
    for column, regex in author_extractors:
        matches = regex.findall(article[column])
        if matches is not None:
            authors.extend([m.strip() for m in matches])
    if authors == []:
        authors = ['']
    authors = unique_elements(authors, idfun=lambda x: x.lower())
    return (pd.Series(authors, index=['author_{}'.format(i)
                                      for i in range(len(authors))]))

input_file = 'bld/ajps_articles_2006_2014.csv'
output_file = 'bld/ajps_author_website_coding_template.csv'

input_columns = ['doi', 'title', 'authors', 'authors_description',
                 'biographies', 'footnote_1', 'footnote_2',
                 'first_published']
article_level_columns = ['doi', 'article_ix', 'title', 'authors']

df = pd.read_csv(input_file, header=0,
                 usecols=input_columns,
                 parse_dates=['first_published'], infer_datetime_format=True,
                 converters={'biographies': strip_tags})
df['article_ix'] = df.index + 1

author_extractors = [('authors',
                      re.compile('(?:^|Search for more papers by this'
                                 ' author)(.+?),{0,1}(?:Close author notes)'
                                 '{0,1}'
                                 ' {13}', re.IGNORECASE)),
                     ('authors', re.compile('(?:^|Search for more papers by'
                                            ' this author'
                                            '(?:\(contact author\)){0,1}'
                                            ',{0,1})'
                                            '(.+?)(?:Close author notes'
                                            '|Corresponding author.*?){0,1}'
                                            '(?: {13}.*?){0,1}'
                                            ',',
                                            re.IGNORECASE)),
                     ('authors_description',
                      re.compile('(?:\)\. |^)(.+?)'
                                 '(?: \((?:the ){0,1}'
                                 'corresponding author\)){0,1}'
                                 ' is .*?',
                                 re.IGNORECASE)),
                     ('biographies',
                      re.compile('(?:\)\. {0,1}|^Biograph(?:ies|y))(.+?)'
                                 '(?= is .*?.)', re.IGNORECASE)),
                     ('footnote_1',
                      re.compile('(?:\)\. |^)(.+?) is .*?',
                                 re.IGNORECASE))]

# Convert np.nan to '' for regex based extraction.
for column in unique_elements([x[0] for x in author_extractors]):
    df[column].fillna('', inplace=True)

df = pd.concat([df, df.apply(extract_authors, axis=1)], axis=1)

df = pd.melt(df, id_vars=input_columns + ['article_ix'],
             value_vars=[c for c in df.columns.values
                         if c.startswith('author_')],
             var_name='author_ix', value_name='author')

df.sort_values(by=['article_ix', 'author_ix'], inplace=True)
df.dropna(subset=['author'], inplace=True)
df.drop('author_ix', axis=1, inplace=True)
df.to_csv('bld/ajps_author_website_coding_template.csv', index=None)
