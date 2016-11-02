#!/usr/bin/env python3
'''
Convert output from Octoparse to csv format.
'''
import re

import pandas as pd
import numpy as np


def extract_version_date(text):
    version_date = re.search('(?:^Version of Record online: )(.*)'
                             '(?: \| DOI: )',
                             text, re.IGNORECASE)
    if version_date is None:
        version_date = ''
    else:
        version_date = version_date.group(1)
    return version_date.strip()


def extract_doi(text):
    doi = re.search('(?:^Version of Record online: .*? \| DOI: )(.*)', text,
                    re.IGNORECASE)
    if doi is None:
        doi = ''
    else:
        doi = doi.group(1)
    return doi.strip()

input_file = 'octoparse/article_info_from_issue_toc.csv'
output_file = 'bld/ajps_article_info_from_issue_toc.csv'

# Increase field size to deal with long article contents.
df = pd.read_csv(input_file, encoding='utf-16')

# Octoparse has a bug that changes order of fields, when fields
# are missing, and moves the missing fields to the end.
# Assume that the only missing field is 'author' and adjust accordingly.
missing_author = df[df.columns[-1]].isnull()
misplaced_version = (df['authors'].
                     apply(lambda x:
                           x.startswith('Version of Record online: ')))
broken = np.all([missing_author, misplaced_version], axis=0)
df.loc[broken, 'version_date_and_doi'] = df.loc[broken, 'authors']
df.loc[broken, 'authors'] = np.nan

# Version date and doi are collected jointly by Octoparse. Separate these
# into two variables.
df['version_date'] = df['version_date_and_doi'].apply(extract_version_date)
df['doi'] = df['version_date_and_doi'].apply(extract_doi)
df.drop('version_date_and_doi', axis=1, inplace=True)

df.to_csv(output_file, encoding='utf-8', index=None)
