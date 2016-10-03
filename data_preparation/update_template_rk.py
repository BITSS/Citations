#!/usr/bin/env python3
"""
Updates RK's data entered on old template to new template.

RK did a week of data entry using an outdated template, that did not include
a doi. Take the data entered on the outdated template and add a doi column.
A doi is necessary to import the entered data later on.

Note: This file create a csv file as output. For the data import you need to
convert this file to ods manually using LibreOffice Calc.
"""
from tools import add_doi

target = 'data_entry/ajps_reference_coding_rk_V1.ods'
source = 'bld/ajps_articles_2003_2016.csv'
output = 'data_entry/ajps_reference_coding_rk_V1_with_doi.csv'

add_doi(target, source, output)
