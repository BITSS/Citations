#!/usr/bin/env python3
'''
Select articles first published in years 2006 to 2014.
'''

import csv
import sys
from dateutil import parser

select_after = parser.parse('January 1 2006')
select_before = parser.parse('January 1 2015')

input_file = 'bld/ajps_articles_2003_2016.csv'
output_file = 'bld/ajps_articles_2006_2014.csv'

# Increase field size to deal with long article contents.
csv.field_size_limit(sys.maxsize)

with open(input_file) as fh_in:
    csv_reader = csv.DictReader(fh_in)
    with open(output_file, mode='w', newline='') as fh_out:
        csv_writer = csv.DictWriter(fh_out,
                                    fieldnames=csv_reader.fieldnames)
        csv_writer.writeheader()
        for line in csv_reader:
            first_published = parser.parse(line['first_published'])
            if (select_after <= first_published < select_before):
                csv_writer.writerow(line)
