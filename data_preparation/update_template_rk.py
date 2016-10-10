#!/usr/bin/env python3
"""
Updates RK's data entered on old template to new template.

RK did a week of data entry using an outdated template, that did not include
a doi. Take the data entered on the outdated template and add a doi column.
A doi is necessary to import the entered data later on.

Note: This file create a csv file as output. For the data import you need to
convert this file to ods manually using LibreOffice Calc, name the sheet (not
the file) 'ajps_reference_coding'.

Also this script is missing the hyperlinking of match and context of
url matches. Implementing this logic would take extra time. Since
hyperlinking does neither affect the entries nor their order, simply copy
existing data entry into the correct template by hand.
"""
from tools import add_doi, hyperlink_title

target = 'data_entry/ajps_reference_coding_rk_V4.ods'
source = 'bld/ajps_articles_2003_2016.csv'
output = 'data_entry/ajps_reference_coding_rk_V4_doi_and_hyperlink.csv'

hyperlink_title(add_doi(target, source), output)
