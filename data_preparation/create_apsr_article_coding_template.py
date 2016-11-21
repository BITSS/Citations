#!/usr/bin/env python3
'''
Create template for APSR article coding.
'''

import numpy as np
import pandas as pd
from bs4 import BeautifulSoup
from tools import apsr_article_url


def find_abstract(article):
    abstract = []
    soup = BeautifulSoup(article['content'], 'html.parser')

    for tag in soup.find_all('div', class_='abstract'):
        abstract.append(tag.get_text())
    if abstract == []:
        abstract = ''
    else:
        abstract = '\n'.join(abstract)

    return abstract


input_file = 'bld/apsr_article_content_2006_2014.csv'
output_file = 'bld/apsr_article_coding_template.csv'

output_columns = ['article_ix', 'doi', 'title', 'abstract', 'article_topic',
                  'article_data_type']

# Process article content chunkwise to reduce memory usage.
for ix, df in enumerate(pd.read_csv(input_file, chunksize=50)):
    df.fillna('', inplace=True)
    df['article_ix'] = df.index + 1

    # Find abstract.
    df['abstract'] = df.apply(find_abstract, axis=1)

    # Drop content to speed up code.
    df.drop('content', 1, inplace=True)

    df.drop_duplicates(inplace=True)

    df['title'] = ('=HYPERLINK("' + df['doi'].apply(apsr_article_url) +
                   '","' + df['title'] + '")')
    df['article_field'] = np.nan
    df['article_data_type'] = np.nan

    if ix == 0:
        df.to_csv(output_file, mode='w', encoding='utf-8', index=None,
                  columns=output_columns)
    else:
        df.to_csv(output_file, mode='a', encoding='utf-8', index=None,
                  header=None, columns=output_columns)
