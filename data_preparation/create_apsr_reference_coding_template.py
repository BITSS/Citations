#!/usr/bin/env python3
'''
Create template for manual coding of references.
'''

import re

import pandas as pd
import numpy as np
from bs4 import BeautifulSoup
from tools import hyperlink_title


def find_references(article):
    references = []
    soup = BeautifulSoup(article['content'], 'html.parser')

    # Find all URLs that are hyperlinked by APSR website.
    for tag in soup.find_all('a', class_=re.compile('(url)|(uri simple)')):
        url = tag.string

        url_context_pre = ''.join(tag.find_all_previous(string=True,
                                                        limit=char_match_pre)
                                  [::-1])
        url_context_pre = url_context_pre[-min(char_match_pre,
                                               len(url_context_pre)):]

        # URL will be matched again by find_all_next function. Remove
        # this duplicate matching.
        url_context_post = ''.join(list(tag.
                                        find_all_next(string=True,
                                                      limit=char_match_post +
                                                      1))[1:])
        url_context_post = url_context_post[:min(char_match_post,
                                                 len(url_context_post))]

        references.append((url,
                           ''.join([url_context_pre,
                                    url.upper(),
                                    url_context_post])))

    # Find references based on indicators, ignoring any tags.
    references += list(find_regex_and_context(regex_reference_indicators,
                                              soup.get_text()))
    if references == []:
        matches, contexts = [], []
    else:
        matches, contexts = zip(*references)
    return (pd.Series(matches + contexts,
                      index=['match_{}'.format(i)
                             for i in range(len(references))] +
                            ['context_{}'.format(i)
                             for i in range(len(references))]))


def find_regex_and_context(regex, text):
    'Yield regex match and included in surrounding context from text.'
    text_length = len(text)
    for match in regex.finditer(text):
        start, end = match.span()
        context_start = max(0, start - char_match_pre)
        context_end = min(text_length, end + char_match_post)
        yield (match.group(), text[context_start:start] +
               text[start:end].upper() + text[end:context_end])

# Define search terms other than URLs to check for explicit reference to data
# or code. Order increasingly by false positive likelihood.
reference_indicators = ['code[^d]', 'replicat', 'reposito', 'dataverse',
                        'archive', 'data', 'availab', r'\bfound\b',
                        'website', 'homepage', 'webpage']

regex_reference_indicators = re.compile('(?:' +
                                        '|'.join(reference_indicators) + ')',
                                        re.IGNORECASE)

char_match_pre = 100
char_match_post = char_match_pre

# input_file = 'bld/apsr_article_content_2006_2014.csv'
# output_file = 'bld/apsr_reference_coding_template.csv'
# # Centennial Issue
input_file = 'bld/apsr_centennial_article_content.csv'
output_file = 'bld/apsr_centennial_reference_coding_template.csv'

output_columns = ['volume', 'issue', 'pages', 'publication_date', 'doi',
                  'authors', 'authors_affiliations', 'title', 'article_ix',
                  'reference_ix', 'match', 'context', 'reference_category']

# Process article content chunkwise to reduce memory usage.
for ix, df in enumerate(pd.read_csv(input_file, chunksize=50)):
    df.fillna('', inplace=True)
    df['article_ix'] = df.index + 1

    # Find references.
    df = pd.concat([df, df.apply(find_references, axis=1)],
                   axis=1)

    # Drop content to speed up code.
    df.drop('content', 1, inplace=True)

    # Reshape to one row per article level reference.
    df = pd.wide_to_long(df, ['match_', 'context_'],
                         i='article_ix', j='reference_ix')
    df.rename(columns={'match_': 'match', 'context_': 'context'}, inplace=True)

    df.sort_index(inplace=True)
    df.dropna(how='all', subset=['match', 'context'], inplace=True)
    df.drop_duplicates(inplace=True)

    df.reset_index(inplace=True)
    df['reference_ix'] = df['reference_ix'] + 1

    df = hyperlink_title(df, 'apsr', hyperlink_separator=';')
    df['reference_category'] = np.nan

    if ix == 0:
        df.to_csv(output_file, mode='w', encoding='utf-8', index=None,
                  columns=output_columns)
    else:
        df.to_csv(output_file, mode='a', encoding='utf-8', index=None,
                  header=None, columns=output_columns)
