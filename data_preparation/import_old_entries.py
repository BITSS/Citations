#!/usr/bin/env python3
'''
Import entries from older protocol versions.
'''
from os.path import isfile

from tools import import_data_entries

urap_initials = ['KJK', 'rk', 'RP', 'TC']
imports = [
           # Import entries due to changes in reference coding protocol.
           {'target': 'data_entry/ajps_reference_coding_KJK_V16.ods',
            'source': 'data_entry/ajps_reference_coding_KJK_V1.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_KJK_V16_+_V1.csv'},
           {'target': 'data_entry/ajps_reference_coding_KJK_V16_+_V1.csv',
            'source': 'data_entry/ajps_reference_coding_KJK_V23.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.csv'},
           {'target': 'data_entry/ajps_reference_coding_RK_V8.ods',
            'source': 'data_entry/ajps_reference_coding' +
                      '_rk_V4_doi_and_hyperlink.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RK_V8_+' +
                   '_rk_V4_doi_and_hyperlink.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink.csv'},
           {'target': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink.csv',
            'source': 'data_entry/ajps_reference_coding' +
                      '_RK_V11.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.csv'},
           {'target': 'data_entry/ajps_reference_coding_RP_V5.ods',
            'source': 'data_entry/ajps_reference_coding_RP_V2.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RP_V5_+_V2.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RP_V5_+_V2.csv'},
           {'target': 'data_entry/ajps_reference_coding_TC_V5.ods',
            'source': 'data_entry/ajps_reference_coding_TC_V3.ods',
            'entry_column': 'reference_category',
            'log': 'data_entry/ajps_reference_coding' +
                   '_TC_V5_+_V3.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_TC_V5_+_V3.csv'},

           # Import entries due to changes in link coding protocol.
           {'target': 'data_entry/ajps_link_coding_RK_V2.ods',
            'source': 'data_entry/ajps_link_coding_RK_V1.ods',
            'entry_column': 'link_category',
            'log': 'data_entry/ajps_link_coding_RK_imported.log.csv',
            'output': 'data_entry/ajps_link_coding_RK_imported.csv'}
            ]

for import_action in imports:
    if isfile(import_action['target']) and isfile(import_action['source']):
        print(import_action.items())
        import_data_entries(**import_action)
