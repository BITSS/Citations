#!/usr/bin/env python3
'''
Extract list of urls used in each article content to spreadsheet.
'''

# TODO URL finding via href
# TODO Fix regex sentence exclusion.
# re.compile(r'\s\w+\.([A-Z][a-z]|[a-z][A-Z])')
# -> re.compile(r'\s\w+\.([A-Z][a-z]|[a-z][A-Z])\w*\s')
# Does exclude "here www.Berkeley.edu fuond"?
# TODO Add year (first_published), author's names
# TODO Include two words with . urls only if they have href
# one dot, spaces exclude if not href

import csv
import sys
import re
import time

from collections import OrderedDict

from bs4 import BeautifulSoup
from openpyxl import Workbook
from openpyxl.styles import Alignment
from tools import strip_tags, regex_url_pattern


def article_url(doi):
    'Return article url inferred from DOI.'
    return 'http://onlinelibrary.wiley.com/doi/' + doi + '/full'


def find_regex_and_context(regex, text):
    'Yield regex match and included in surrounding context from text'
    text_length = len(text)
    for match in regex.finditer(text):
        start, end = match.span()
        start = max(0, start - char_match_pre)
        end = min(text_length, end + char_match_post)
        yield (match.group(), text[start:end])

regex_url = re.compile(regex_url_pattern(), re.IGNORECASE)

# Assume that URLs linking to wiley are referring to article internals
# such as graphs and figures. Exclude these.
regex_wiley = re.compile(r'''http://(api.)?onlinelibrary.wiley.com''',
                         re.IGNORECASE)

# Assume that URLs matches which are two words joint by '.' with first two
# letters in mixed case are actually end and start of a sentence.
# Exclude these.
regex_sentence_url = re.compile(r'^\w+\.([A-Z][a-z]|[a-z][A-Z])\w*$')

# Define search terms other than URLs to check for explicit reference to data
# or code. Order increasingly by false positive likelihood.
# Match all indicators only at beginning of word.
repref_indicators = ['code[^d]', 'replicat', 'reposito', 'dataverse',
                     'archive', 'data', 'availab', r'\bfound\b',
                     'website', 'homepage', 'webpage']

regex_repref_indicators = re.compile('(?:' + '|'.join(repref_indicators) + ')',
                                     re.IGNORECASE)

char_match_pre = 100
char_match_post = char_match_pre

# Increase field size to deal with long article contents.
csv.field_size_limit(sys.maxsize)

input_file = 'bld/ajps_articles_2003_2016.csv'
output_file = 'bld/ajps_reference_coding_template.xlsx'

# Initialize sheet.
wb = Workbook()
ws = wb.active
ws.title = 'ajps_reference_coding'

# Format columns to make list of URLs easier for humans to read.
for column in ['B', 'D']:
    ws.column_dimensions[column].alignment = Alignment(wrapText=True)
    ws.column_dimensions[column].width = 80

with open(input_file) as fh_in:
    csv_reader = csv.reader(fh_in, strict=True)

    header = [x.strip() for x in next(csv_reader)]

    # Locate variable positions in input csv file.
    ix_dict = OrderedDict()
    for var in ['title', 'content', 'doi']:
        ix_dict[var] = header.index(var)

    # Write header.
    ws.append(['article_ix', 'title', 'match', 'context',
               'reference_category'])

    # Write rows.
    for article_ix, article in enumerate(csv_reader, 1):
        print(article_ix)

        content_html = article[ix_dict['content']]

        content_soup = BeautifulSoup(content_html, 'lxml')
        urls_from_href = [link['href'] for link in content_soup.find_all('a')]
        # Exclude email and internal links, e.g. to footnotes.
        urls_from_href = [u for u in urls_from_href
                          if not u.startswith(('#', 'mailto:'))]

        # Remove HTML tags for easier extraction of url context.
        content_text = strip_tags(content_html)

        urls = list(find_regex_and_context(regex_url, content_text))
        repref_indicators = list(find_regex_and_context
                                 (regex_repref_indicators, content_text))

        # Exclude URLs following set of exceptions.
        urls_from_href = [url for url in urls_from_href
                          if regex_wiley.search(url) is None]
        urls = [url for url in urls if (regex_wiley.search(url[0]) is None
                                        and
                                        regex_sentence_url.search(url[0])
                                        is None)]

        urls_from_regex = [u[0] for u in urls]
        for u in urls_from_href:
            if u not in urls_from_regex:
                urls.append((u, 'HREF'))

        title_cell = ('=HYPERLINK("' + article_url(article[ix_dict['doi']])
                      + '","' + article[ix_dict['title']] + '")')

        if urls == [] and repref_indicators == []:
            ws.append([article_ix, title_cell, '', '', 0])
            continue

        # List article URLs numerically in separate cells, as
        # Excel only allows one clickable links per cell.
        for ix, url in enumerate(urls):
            match_cell = '=HYPERLINK("' + url[0] + '")'
            context_cell = '=HYPERLINK("' + url[0] + '","' + url[1] + '")'
            if ix == 0:
                ws.append([article_ix, title_cell, match_cell, context_cell])
            else:
                ws.append(['', '', match_cell, context_cell])

        # List repref indicator matches after URLs.
        # Highlight matches in context.
        for ix, indicator_match in enumerate(repref_indicators):
            match_cell = indicator_match[0]
            match_length = len(indicator_match[0])
            context_cell = (indicator_match[1][0:char_match_pre]
                            + indicator_match[0].upper()
                            + indicator_match[1][char_match_pre + match_length:
                                                 ])
            if ix == 0 and urls == []:
                ws.append([article_ix, title_cell, match_cell, context_cell])
            else:
                ws.append(['', '', match_cell, context_cell])

wb.save(output_file)
