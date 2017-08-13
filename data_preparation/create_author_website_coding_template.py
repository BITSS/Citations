#!/usr/bin/env python3
'''
Create template for author website coding.
'''

import re

import numpy as np
import pandas as pd

from tools import (hyperlink_google_search, hyperlink_doi,
                   extract_authors_aer, extract_authors_qje)


def create_author_website_coding_template(df_input, output_file,
                                          extract_authors_function,
                                          df_authors=None):
    # Separate author and input file is useful if other article information
    # like 'title' is stored separately from author information.
    if df_authors is None:
        df = df_input
    else:
        df = df_authors

    # Extract author names.
    df = pd.concat([df, df.apply(extract_authors_function, axis=1)],
                   axis=1)

    # Convert to one row per paper*author.
    if 'author' in df.columns:
        df.drop('author', axis=1, inplace=True)
    df = pd.melt(df, id_vars=[x for x in df.columns.values
                              if not x.startswith('author_')],
                 value_vars=[c for c in df.columns.values
                             if c.startswith('author_')],
                 var_name='author_ix', value_name='author')

    # Sort by author names to avoid duplicate lookups
    df.dropna(subset=['author'], inplace=True)
    df = df[df['author'] != '']
    df.sort_values(by=['author', 'article_ix', 'author_ix'], inplace=True)
    df.drop('author_ix', axis=1, inplace=True)

    if df_authors:
        df = pd.merge(left=df_input,
                      right=df,
                      how='left', on='doi', suffixes=('', '_from_author_file'))

    df['author'] = df['author'].apply(hyperlink_google_search)
    df['doi'] = df['doi'].apply(hyperlink_doi)
    df['website_category'] = np.nan
    df['website'] = np.nan

    df.to_csv(output_file,
              columns=['article_ix', 'doi', 'title', 'author',
                       'website_category', 'website'], index=None)

# AER
input_columns = ['doi', 'title', 'author', 'selected_into_sample']
df = pd.read_csv('data_collection_econ/aer_with_sample_selection.csv',
                 header=0, usecols=input_columns)
df = df.loc[df['selected_into_sample']]
df['article_ix'] = df.index + 1
df['author'].fillna('', inplace=True)

create_author_website_coding_template(df_input=df,
                                      output_file='bld/aer_author_website_coding_template.csv',
                                      extract_authors_function=extract_authors_aer)

# QJE
input_columns = ['doi', 'title', 'author']
df = pd.read_csv('data_collection_econ/qje.csv',
                 header=0, usecols=input_columns)
df['article_ix'] = df.index + 1
df['author'].fillna('', inplace=True)

create_author_website_coding_template(df_input=df,
                                      output_file='bld/qje_author_website_coding_template.csv',
                                      extract_authors_function=extract_authors_qje)
