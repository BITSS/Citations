#!/usr/bin/env python3
'''
Combine output files from Octoparse into single file with one row per article.

Output files from Octoparse
1. are seperated by year, because of memory issues
2. have multiple rows for the same article, only differing in the content
variable
'''

import sys
import csv

input_files = ['octoparse/' + f for f in [
    'ajps_article_content_2003_2007.txt',
    'ajps_article_content_2008_2012.txt',
    'ajps_article_content_2013_2016.txt']]
output_file = 'bld/ajps_articles_2003_2016.csv'

# Increase field size to deal with long article contents.
csv.field_size_limit(sys.maxsize)

with open(output_file, mode='w', newline='') as fh_out:
    csv_writer = csv.writer(fh_out, delimiter=',', quotechar='"',
                            quoting=csv.QUOTE_MINIMAL)
    for file_counter, file_name in enumerate(input_files):
        # Use encoding set by Octoparse (Western 1252).
        with open(file_name, encoding='cp1252') as fh_in:
            csv_reader = csv.reader(fh_in,
                                    delimiter='\t', skipinitialspace=True,
                                    strict=True)
            header = [x.strip() for x in next(csv_reader)]
            if file_counter == 0:
                csv_writer.writerow(header)
            title_ix = header.index('title')
            content_ix = header.index('content')
            # Merge content lines of one article into a single line.
            merged_line = None
            for line in csv_reader:
                line = [x.strip() for x in line]
                # Identify beginning of new article by non-empty title
                # and correct number of fields.
                if line[title_ix] != '' and len(line) == 12:
                    if merged_line is not None:
                        csv_writer.writerow(merged_line)
                    merged_line = line
                # Octoparse deviates from csv format by sometimes
                # exportings lines containing only one field.
                # If a line has only one field, interpret it as content.
                elif len(line) == 1:
                    merged_line[content_ix] += ' ' + line[0]
                else:
                    merged_line[content_ix] += ' ' + line[content_ix]
