#!/usr/bin/env python3
'''
Extract list of urls used in each article to spreadsheet.
'''

import csv
import sys
import re

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

# Assume that URLs containing '@' are email addresses. Exclude these.
regex_email_url = re.compile(r'@')

# Assume that ending .[0-9]+ refers to the end of a sentence together with a
# footnote. Remove this part from the url.
regex_footnote = re.compile(r'\.[0-9]+$')

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

input_file = 'bld/ajps_articles_2006_2014.csv'
output_file = 'bld/ajps_reference_coding_template.xlsx'

# Initialize sheet.
wb = Workbook()
ws = wb.active
ws.title = 'ajps_reference_coding'

# Format columns to make list of URLs easier for humans to read.
for column in ['C', 'E']:
    ws.column_dimensions[column].alignment = Alignment(wrapText=True)
    ws.column_dimensions[column].width = 80

with open(input_file) as fh_in:
    csv_reader = csv.DictReader(fh_in)

    # Write header.
    ws.append(['doi', 'article_ix', 'title', 'match', 'context',
               'reference_category'])

    # Write rows.
    for article_ix, article in enumerate(csv_reader, 1):
        print(article_ix)

        # Combine article elements into single parsable string.
        content_html = '\n'.join([article[x] for x in ['footnote_1',
                                                       'footnote_2',
                                                       'authors_description',
                                                       'biographies',
                                                       'abstract',
                                                       'content']])

        # Remove HTML tags for easier extraction of url context.
        content_text = strip_tags(content_html)

        urls = list(find_regex_and_context(regex_url, content_text))
        repref_indicators = list(find_regex_and_context
                                 (regex_repref_indicators, content_text))

        # Remove footnote references identified by trailing .[0-9]+
        urls = [(regex_footnote.split(url[0])[0], url[1]) for url in urls]

        # Exclude URLs following set of exceptions.
        urls = [url for url in urls
                if (regex_wiley.search(url[0]) is None and
                    regex_sentence_url.search(url[0]) is None and
                    regex_email_url.search(url[0]) is None)]

        title_cell = ('=HYPERLINK("' + article_url(article['doi']) +
                      '","' + article['title'] + '")')

        if urls == [] and repref_indicators == []:
            ws.append([article['doi'], article_ix, title_cell, '', '', 0])
            continue

        # List article URLs numerically in separate cells, as
        # Excel only allows one clickable links per cell.
        for ix, url in enumerate(urls):
            match_cell = '=HYPERLINK("' + url[0] + '")'
            context_cell = '=HYPERLINK("' + url[0] + '","' + url[1] + '")'
            if ix == 0:
                ws.append([article['doi'], article_ix, title_cell, match_cell,
                           context_cell])
            else:
                ws.append(['', '', '', match_cell, context_cell])

        # List repref indicator matches after URLs.
        # Highlight matches in context.
        for ix, indicator_match in enumerate(repref_indicators):
            match_cell = indicator_match[0]
            match_length = len(indicator_match[0])
            context_cell = (indicator_match[1][0:char_match_pre] +
                            indicator_match[0].upper() +
                            indicator_match[1][char_match_pre + match_length:])

            if ix == 0 and urls == []:
                ws.append([article['doi'], article_ix, title_cell, match_cell,
                           context_cell])
            else:
                ws.append(['', '', '', match_cell, context_cell])

wb.save(output_file)
