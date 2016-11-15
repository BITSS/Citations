#!/usr/bin/env python3
'''
Clean output from APSR Octoparse scraping.
'''
import re
import warnings

import pandas as pd
from bs4 import BeautifulSoup
from tools import strip_tags


def extract_article_information(article, script=None):
    if script == 'apsr_issue_toc.otd':
        issue_regex = 'Volume (\d+)-Issue (\d+)  - (\w+ \d+)'
        issue_match = re.match(issue_regex, article['issue'])
        if issue_match:
            article['volume'], article['issue'], article['issue_date'] = \
                issue_match.groups()

        article['publication_date'] = (article['publication_date'] +
                                       article['publication_date2'])

        article['pages'] = article['pages'] + article['pages2']

    elif script == 'apsr_article_content_2006_2014.otd':
        issue_regex = ('American Political Science Review,'
                       'Volume (\d+),Issue (\d+)')
        issue_match = re.match(issue_regex, article['issue'])
        if issue_match:
            article['volume'], article['issue'] = issue_match.groups()

        article['title'] = strip_tags(article['title'])

        article['citation_count'] = article[
            'citation_count'].split('Cited by ')[-1]

        soup = BeautifulSoup(article['authors_affiliations'], 'html.parser')
        article['authors_affiliations'] = ';'.join(
            [tag.string for tag in soup.find_all('institution')])

    else:
        warnings.warn('No cleaning template found for script {}.'.
                      format(script))

    article['doi'] = ''.join(article['doi'].split('https://doi.org/'))

    article['pages'] = article['pages'].split('p. ')[-1]

    soup = BeautifulSoup(article['authors'], 'html.parser')
    article['authors'] = ';'.join(
        [tag.string for tag in soup.find_all('a')])

    return article

octoparse_files = [('octoparse/apsr_issue_toc.csv',
                    'bld/apsr_article_info_from_issue_toc.csv',
                    'apsr_issue_toc.otd',
                    ['volume', 'issue', 'issue_date', 'publication_date',
                     'pages', 'authors', 'title']),
                   ('octoparse/apsr_article_content_2006_2014.csv',
                    'bld/apsr_article_content_2006_2014.csv',
                    'apsr_article_content_2006_2014.otd',
                    ['volume', 'issue', 'publication_date', 'doi',
                     'pages', 'authors', 'authors_affiliations', 'title',
                     'content'])]

for input_file, output_file, script, output_columns in octoparse_files:
    for ix, df in enumerate(pd.read_csv(input_file, encoding='utf-16',
                                        chunksize=100)):
        df.fillna('', inplace=True)
        df = df.apply(extract_article_information, axis=1, script=script)
        if ix == 0:
            df.to_csv(output_file, mode='w', encoding='utf-8',
                      index=None, columns=output_columns)
        else:
            df.to_csv(output_file, mode='a', encoding='utf-8',
                      header=None, index=None, columns=output_columns)
