#!/usr/bin/env python3
'''
Import entries from older protocol versions.

Note that importing from ods drops cell formulas. Export ods files to csv
using 'Save cell formulas instead of calculated values' option to preserve
formulas. Alternatively, use the files_add_hyperlink_title parameter to
hyperlink titles.
'''
from os.path import isfile

from tools import import_data_entries

urap_initials = ['KJK', 'rk', 'RP', 'TC']
merge_on_reference_coding = ['doi', 'title', 'match', 'context']
imports = [
           # Import entries due to changes in reference coding protocol.
           {'target': 'data_entry/ajps_reference_coding_KJK_V16.ods',
            'source': 'data_entry/ajps_reference_coding_KJK_V1.ods',
            'entry_column': 'reference_category',
     'merge_on': merge_on_reference_coding,
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_KJK_V16_+_V1.csv'},
           {'target': 'data_entry/ajps_reference_coding_KJK_V16_+_V1.csv',
            'source': 'data_entry/ajps_reference_coding_KJK_V23.ods',
            'entry_column': 'reference_category',
     'merge_on': merge_on_reference_coding,
            'log': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                   '_KJK_V16_+_V1_+_V23.csv'},
           {'target': 'data_entry/ajps_reference_coding_RK_V8.ods',
            'source': 'data_entry/ajps_reference_coding' +
                      '_rk_V4_doi_and_hyperlink.ods',
            'entry_column': 'reference_category',
     'merge_on': merge_on_reference_coding,
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
     'merge_on': merge_on_reference_coding,
            'log': 'data_entry/ajps_reference_coding' +
                   '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RK_V8_+_rk_V4_doi_and_hyperlink_+_V11.csv'},
           {'target': 'data_entry/ajps_reference_coding_RP_V5.ods',
            'source': 'data_entry/ajps_reference_coding_RP_V2.ods',
            'entry_column': 'reference_category',
     'merge_on': merge_on_reference_coding,
            'log': 'data_entry/ajps_reference_coding' +
                   '_RP_V5_+_V2.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_RP_V5_+_V2.csv'},
           {'target': 'data_entry/ajps_reference_coding_TC_V5.ods',
            'source': 'data_entry/ajps_reference_coding_TC_V3.ods',
            'entry_column': 'reference_category',
     'merge_on': merge_on_reference_coding,
            'log': 'data_entry/ajps_reference_coding' +
                   '_TC_V5_+_V3.log.csv',
            'output': 'data_entry/ajps_reference_coding' +
                      '_TC_V5_+_V3.csv'},
    {'target': 'bld/ajps_reference_coding_template.csv',
     'source': 'data_entry/ajps_reference_coding_RK_V23.ods',
     'entry_column': 'reference_category',
     'files_add_hyperlink_title': ['source'],
     'merge_on': merge_on_reference_coding,
     'log': 'data_entry/ajps_reference_coding_template_RK_V23.log.csv',
     'output': 'data_entry/ajps_reference_coding_RK_V24.csv'},
    {'target': 'bld/ajps_reference_coding_template.csv',
     'source': 'data_entry/ajps_reference_coding_TC_V12.ods',
     'entry_column': 'reference_category',
     'files_add_hyperlink_title': ['source'],
     'merge_on': merge_on_reference_coding,
     'log': 'data_entry/ajps_reference_coding_template_TC_V12.log.csv',
     'output': 'data_entry/ajps_reference_coding_TC_V13.csv'},
    {'target': 'bld/ajps_reference_coding_template.csv',
     'source': 'data_entry/ajps_reference_coding_RP_V9.ods',
     'entry_column': 'reference_category',
     'files_add_hyperlink_title': ['source'],
     'merge_on': merge_on_reference_coding,
     'log': 'data_entry/ajps_reference_coding_template_RP_V9.log.csv',
     'output': 'data_entry/ajps_reference_coding_RP_V10.csv'},
    {'target': 'bld/ajps_reference_coding_template.csv',
     'source': 'data_entry/ajps_reference_coding_KJK_V33.ods',
     'entry_column': 'reference_category',
     'files_add_hyperlink_title': ['source'],
     'merge_on': merge_on_reference_coding,
     'log': 'data_entry/ajps_reference_coding_template_KJK_V33.log.csv',
     'output': 'data_entry/ajps_reference_coding_KJK_V34.csv'},

    # With changes to reference coding, new differences need to be resolved.
    {'target': 'bld/ajps_reference_coding_diff_resolution_RK_TC.csv',
     'source': 'data_entry/ajps_reference_coding_diff_resolution_RK_TC_V7.ods',
     'entry_column': 'reference_category_RK_TC_resolved',
     'merge_on': merge_on_reference_coding + ['reference_category_RK',
                                              'reference_category_TC',
                                              'conflict_ignore_skip_RK_TC'],
     'log': ('data_entry/ajps_reference_coding_diff_resolution'
             '_RK_TC_V8.log.csv'),
     'output': ('data_entry/ajps_reference_coding_diff_resolution'
                '_RK_TC_V8.csv')},
    {'target': 'bld/ajps_reference_coding_diff_resolution_KJK_RP.csv',
     'source': ('data_entry/ajps_reference_coding_diff_resolution'
                '_KJK_RP_V2.ods'),
     'entry_column': 'reference_category_KJK_RP_resolved',
     'merge_on': merge_on_reference_coding + ['reference_category_KJK',
                                              'reference_category_RP',
                                              'conflict_ignore_skip_KJK_RP'],
     'log': ('data_entry/ajps_reference_coding_diff_resolution'
             '_KJK_RP_V3.log.csv'),
     'output': ('data_entry/ajps_reference_coding_diff_resolution'
                '_KJK_RP_V3.csv')},

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
