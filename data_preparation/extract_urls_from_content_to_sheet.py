#!/usr/bin/env python3
'''
Extract list of urls used in each article content to excel sheet.
'''

# TODO Commit to GitHub repo.
# TODO Add non-url search parameters.
# TODO Display parameter results in sentence context.
# TODO Add column to indicate basis for RA's decision.

import csv
import sys
import re
from itertools import filterfalse
from collections import OrderedDict
from html.parser import HTMLParser

from openpyxl import Workbook
from openpyxl.styles import Alignment


def unique(list):
    'Return unique elements of a list, preserving order.'
    output = []
    seen = set()
    for element in list:
        if element not in seen:
            output.append(element)
            seen.add(element)
    return output


def article_url(doi):
    'Return article url inferred from DOI.'
    return 'http://onlinelibrary.wiley.com/doi/' + doi + '/full'


# Remove HTML tags.
# Source: http://stackoverflow.com/a/925630/3435013
class MLStripper(HTMLParser):
    def __init__(self):
        super().__init__()
        self.reset()
        self.strict = False
        self.convert_charrefs = True
        self.fed = []

    def handle_data(self, d):
        self.fed.append(d)

    def get_data(self):
        return ''.join(self.fed)


def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()

# Extracting URLs from text is non-trivial.
# Beautify solution provided by 'dranxo' and match characters around URLs
# for additional context.
# https://stackoverflow.com/a/28552670/3435013
char_match_pre = 100
char_match_post = char_match_pre

tlds = (r'com|net|org|edu|gov|mil|aero|asia|biz|cat|coop'
        r'|info|int|jobs|mobi|museum|name|post|pro|tel|travel'
        r'|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw'
        r'|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt'
        r'|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr'
        r'|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh'
        r'|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh'
        r'|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht'
        r'|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg'
        r'|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt'
        r'|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr'
        r'|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np'
        r'|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw'
        r'|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja'
        r'|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg'
        r'|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us'
        r'|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw')
regex_url = re.compile('(.{,' + str(char_match_pre) + '})'
                       r'((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.]'
                       r'(?:' + tlds + ')'
                       r'/)(?:[^\s()<>{}\[\]]+'
                       r'|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+'
                       r'(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)'
                       r'''|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])'''
                       r'|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.]'
                       r'(?:' + tlds + ')'
                       r'/?(?!@)))'
                       '(.{,' + str(char_match_post) + '})'
                       )

input_file = 'bld/ajps_articles_2003_2016.csv'
output_file = 'bld/ajps_article_links.xlsx'

# Assume that URLs linking to wiley are referring to article internals
# such as graphs and figures. Exclude these.
regex_wiley = re.compile(r'''http://(api.)?onlinelibrary.wiley.com''')

# Increase field size to deal with long article contents.
csv.field_size_limit(sys.maxsize)

# Initialize sheet.
wb = Workbook()
ws = wb.active
ws.title = 'ajps_urls'

# Format columns to make list of URLs easier for humans to read.
for column in ['A', 'B']:
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
    ws.append(['title', 'urls', 'RepRef', 'RepFilesAv', 'CodeRepRef',
               'CodeRepFilesAv'])

    # Write rows.
    for line in csv_reader:
        content_html = line[ix_dict['content']]

        # Remove HTML tags for easier extraction of url context.
        content_text = strip_tags(content_html)

        urls = [match.group() for match
                in regex_url.finditer(content_text)]
        # urls = unique([match.group() for match
        #                in regex_url.finditer(content_text)])
        urls = list(filterfalse(regex_wiley.search, urls))
        print(urls)

        title_cell = ('=HYPERLINK("' + article_url(line[ix_dict['doi']])
                      + '","' + line[ix_dict['title']] + '")')

        if urls == []:
            ws.append([title_cell, '', 0, '', 0, ''])
            continue

        # List article URLs numerically in separate cells, as
        # Excel only allows one clickable links per cell.
        for ix, url in enumerate(urls):
            url_cell = '=HYPERLINK("' + url + '")'
            if ix == 0:
                ws.append([title_cell, url_cell])
            else:
                ws.append(['', url_cell])
        # urls_cell = '\n'.join(['{}. {}'.format(ix+1,
        #                                        '=HYPERLINK("' + url + '")')
        #                        for ix, url in enumerate(urls)])
        #
        # ws.append([('=HYPERLINK("' + article_url(line[ix_dict['doi']])
        #             + '","' + line[ix_dict['title']] + '")'),
        #            urls_cell])

wb.save(output_file)
