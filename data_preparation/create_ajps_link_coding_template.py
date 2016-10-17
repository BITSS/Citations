#!/usr/bin/env python3
'''
Create template for manual coding of link references.
'''

import re

import pandas as pd
import numpy as np
from tools import regex_url_pattern, article_url


def extract_clickable_url(string):
    url = regex_url.search(string)

    if url:
        # Remove footnote references identified by trailing .[0-9]+
        url = regex_footnote.split(url.group(0))[0]

        return '=HYPERLINK("{}")'.format(url)

input_file = 'bld/ajps_reference_coding_harmonized.csv'
output_file = 'bld/ajps_link_coding_template.csv'

regex_url = re.compile(regex_url_pattern(), re.IGNORECASE)

# Assume that ending .[0-9]+ refers to the end of a sentence together with a
# footnote. Remove this part from the url.
regex_footnote = re.compile(r'\.[0-9]+$')

df = pd.read_csv(input_file)

link_reference_values = ['data_full_link', 'files_full_link', 'code_full_link']
link_reference = df['reference_category'].isin(link_reference_values)

df.loc[link_reference, 'clickable_link'] = (df.loc[link_reference, 'context'].
                                            apply(extract_clickable_url))
df['link_category'] = np.nan
df['fixed_link'] = np.nan

# Hyperlink title to article.
df['title'] = df.apply(lambda row: '=HYPERLINK("' +
                       article_url(row['doi']) +
                       '","' + row['title'] + '")', axis=1)

df.to_csv(output_file, index=None)
