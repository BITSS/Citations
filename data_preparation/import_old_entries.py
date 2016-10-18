#!/usr/bin/env python3
'''
Import entries from older protocol versions.
'''

from tools import import_data_entries

urap_initials = ['KJK', 'rk', 'RP', 'TC']
imports = [{'target': 'data_entry/ajps_reference_coding_KJK_V16.ods',
            'source': 'data_entry/ajps_reference_coding_KJK_V1.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_KJK_V16_+_V1.csv'},
           {'target': 'data_entry/ajps_reference_coding_KJK_V16_+_V1.csv',
            'source': 'data_entry/ajps_reference_coding_KJK_V23.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.csv'},
           {'target': 'data_entry/ajps_reference_coding_RK_V8.ods',
            'source': 'data_entry/ajps_reference_coding' +
                      '_rk_V4_doi_and_hyperlink.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RK_V8_+' +
                   '_rk_V4_doi_and_hyperlink.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink.csv'},
           {'target': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink.csv',
            'source': 'data_entry/ajps_reference_coding' +
                      '_RK_V11.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.csv'},
           {'target': 'data_entry/ajps_reference_coding_RP_V5.ods',
            'source': 'data_entry/ajps_reference_coding_RP_V2.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_RP_V5_+_V2.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RP_V5_+_V2.csv'},
           {'target': 'data_entry/ajps_reference_coding_TC_V5.ods',
            'source': 'data_entry/ajps_reference_coding_TC_V3.ods',
            'log': 'data_entry/ajps_reference_coding' +
                   '_TC_V5_+_V3.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_TC_V5_+_V3.csv'}]

for import_action in imports:
    print(import_action.items())
    import_data_entries(**import_action)
