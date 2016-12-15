#!/usr/bin/env python3
'''
Create template for manual coding of link references.
'''

import re

import pandas as pd
import numpy as np
from tools import regex_url_pattern


def extract_clickable_url(string):
    url = regex_url.search(string)

    if url:
        # Remove footnote references identified by trailing .[0-9]+
        url = regex_footnote.split(url.group(0))[0]

        return '=HYPERLINK("{}")'.format(url)


def create_link_coding_template(input_file, output_file):
    df = pd.read_csv(input_file)
    link_reference = df['reference_category'].isin(link_reference_values)

    match_contains_url = df['match'].fillna('').apply(lambda x:
                                                      regex_url.search(x)
                                                      is not None)

    match_is_link = np.all([match_contains_url, link_reference], axis=0)
    df.loc[match_is_link, 'clickable_link'] =\
        df.loc[match_is_link, 'match'].fillna('').apply(extract_clickable_url)

    context_provides_link = np.all(
        [~match_contains_url, link_reference], axis=0)
    df.loc[context_provides_link, 'clickable_link'] =\
        df.loc[context_provides_link, 'context']

    df['link_category'] = np.nan
    df['fixed_link'] = np.nan

    # Code duplicate entries only once.
    uniquely_identifying_columns = ['doi', 'title', 'match', 'context',
                                    'reference_category']
    df.drop_duplicates(subset=uniquely_identifying_columns, inplace=True)

    df.to_csv(output_file, index=None)

# Assume that ending .[0-9]+ refers to the end of a sentence together with a
# footnote. Remove this part from the url.
regex_footnote = re.compile(r'\.[0-9]+$')
regex_url = re.compile(regex_url_pattern(), re.IGNORECASE)
link_reference_values = ['data_full_link', 'files_full_link', 'code_full_link']

# AJPS
ajps_input_file = 'bld/ajps_reference_coding_harmonized.csv'
ajps_output_file = 'bld/ajps_link_coding_template.csv'
create_link_coding_template(input_file=ajps_input_file,
                            output_file=ajps_output_file)


# APSR
apsr_input_file = 'bld/apsr_reference_coding_harmonized.csv'
apsr_output_file = 'bld/apsr_link_coding_template.csv'
create_link_coding_template(input_file=apsr_input_file,
                            output_file=apsr_output_file)
