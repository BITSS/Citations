#!/usr/bin/env python3
'''
Clean output from APSR Octoparse scraping.
'''
import re

import pandas as pd
from bs4 import BeautifulSoup


def extract_article_information(article):
    issue_regex = 'Volume (\d+)-Issue (\d+)  - (\w+ \d+)'
    issue_match = re.match(issue_regex, article['issue'])
    if issue_match:
        article['volume'], article['issue'], article['issue_date'] = \
            issue_match.groups()
    article['doi'] = ''.join(article['doi'].split('https://doi.org/'))
    article['publication_date'] = (article['publication_date'] +
                                   article['publication_date2'])
    article['pages'] = article['pages'] + article['pages2']
    article['pages'] = article['pages'].split('p. ')[1]
    soup = BeautifulSoup(article['authors'], 'html.parser')
    article['authors'] = ';'.join([tag.string for tag in soup.find_all('a')])
    return article

input_file = 'octoparse/apsr_issue_toc.csv'
output_file = 'bld/apsr_article_info_from_issue_toc.csv'

df = pd.read_csv(input_file, encoding='utf-16')
df.fillna('', inplace=True)
df = df.apply(extract_article_information, axis=1)
df.to_csv(output_file, encoding='utf-8', index=None,
          columns=['volume', 'issue', 'issue_date', 'publication_date',
                   'pages', 'authors', 'title'])
