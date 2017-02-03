#!/usr/bin/env python3
'''
Create template for APSR article coding.
'''

import numpy as np
import pandas as pd
from bs4 import BeautifulSoup
from tools import hyperlink_title


def create_article_coding_template(input_file, output_file, journal):

    output_columns = ['article_ix', 'doi', 'title', 'abstract',
                      'article_topic1', 'article_topic2', 'article_data_type']

    # Process article content chunkwise to reduce memory usage.
    for ix, df in enumerate(pd.read_csv(input_file, chunksize=50)):
        df.fillna('', inplace=True)
        df['article_ix'] = df.index + 1

        df['abstract'] = df.apply(lambda x:
                                  extract_abstract(x, journal=journal),
                                  axis=1)

        df.drop_duplicates(inplace=True)

        df = hyperlink_title(df, journal, hyperlink_separator=';')

        df['article_field'] = np.nan
        df['article_data_type'] = np.nan

        if ix == 0:
            df.to_csv(output_file, mode='w', encoding='utf-8', index=None,
                      columns=output_columns)
        else:
            df.to_csv(output_file, mode='a', encoding='utf-8', index=None,
                      header=None, columns=output_columns)


def extract_abstract(article, journal):
    if journal in ['ajps', 'apsr']:
        abstract = []
        soup = BeautifulSoup(article['content'], 'html.parser')
        if journal == 'ajps':
            abstract_tags = [x.find_all('p') for x in soup.find_all(
                'div', class_='article-section__content mainAbstract')]
            # Flatten list of lists.
            abstract_tags = [paragraph for abstract in abstract_tags
                             for paragraph in abstract]
        elif journal == 'apsr':
            abstract_tags = soup.find_all('div', class_='abstract')
        for tag in abstract_tags:
            abstract.append(tag.get_text())
        if abstract == []:
            return ''
        else:
            return '\n'.join(abstract)
    else:
        UserWarning.warn('{} is an unknown journal.'.format(journal) +
                         'Could not extract abstract.')


# AJPS
input_file = 'bld/ajps_articles_2006_2014.csv'
output_file = 'bld/ajps_article_coding_template.csv'

create_article_coding_template(input_file, output_file, 'ajps')

# APSR
input_file = 'bld/apsr_article_content_2006_2014.csv'
output_file = 'bld/apsr_article_coding_template.csv'

create_article_coding_template(input_file, output_file, 'apsr')
