#!/usr/bin/env python3
'''
Create template for author website coding.
'''

import re
from collections import OrderedDict

import pandas as pd

from tools import strip_tags, unique_elements


def extract_authors(article):
    authors = []
    for column, regex in re_dict.items():
        matches = regex.findall(article[column])
        if matches is not None:
            authors.extend(matches)
    return ','.join(unique_elements(authors))

input_file = 'bld/ajps_articles_2006_2014.csv'
output_file = 'bld/ajps_author_website_coding_template.csv'

uniquely_identifying_columns = ['doi', 'article_ix', 'title', 'author']

df = pd.read_csv(input_file, header=0,
                 usecols=['doi', 'title', 'authors', 'authors_description',
                          'biographies', 'footnote_1', 'footnote_2',
                          'first_published'],
                 parse_dates=['first_published'], infer_datetime_format=True,
                 converters={'biographies': strip_tags})
df.fillna('', inplace=True)

re_dict = OrderedDict([('authors',
                        re.compile('(?:^|Search for more papers by this'
                                   ' author)(.+?),{0,1}[ ]{13}',
                                   re.IGNORECASE)),
                       ('authors_description',
                        re.compile('(?:\)\. |^)(.+?)(?= is .*?.)',
                                   re.IGNORECASE)),
                       ('biographies',
                       re.compile('(?:\)\. |^Biograph(?:ies|y))(.+?)(?= is .*?.)',
                                  re.IGNORECASE))])

df['extracted_authors'] = df.apply(extract_authors, axis=1)
df.to_csv('bld/authorstring.csv', index=None)
