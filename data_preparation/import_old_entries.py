#!/usr/bin/env python3
"""
Import old entries from older protocol versions.
"""

from tools import import_data_entries

urap_initials = ['KJK', 'rk', 'RP', 'TC']
imports = [{'target': 'data_entry/ajps_reference_coding_KJK.ods',
            'source': 'data_entry/ajps_reference_coding_KJK.ods_V1',
            'log': 'data_entry/ajps_reference_coding_KJK.ods_V1_log',
            'output': 'data_entry/ajps_reference_coding_KJK_imported_V1.csv'},
           {'target': 'data_entry/ajps_reference_coding_rk_with_doi.ods',
            'source': 'data_entry/ajps_reference_coding_rk.ods_V1',
            'log': 'data_entry/ajps_reference_coding_rk.ods_V1_log',
            'output': 'data_entry/ajps_reference_coding_rk_imported_V1.csv'},
           {'target': 'data_entry/ajps_reference_coding_RP.ods',
            'source': 'data_entry/ajps_reference_coding_RP.ods_V2',
            'log': 'data_entry/ajps_reference_coding_RP.ods_V2_log',
            'output': 'data_entry/ajps_reference_coding_RP_imported_V2.csv'},
           {'target': 'data_entry/ajps_reference_coding_TC.ods',
            'source': 'data_entry/ajps_reference_coding_TC.ods_V3',
            'log': 'data_entry/ajps_reference_coding_TC.ods_V3_log',
            'output': 'data_entry/ajps_reference_coding_TC_imported_V3.csv'}]

for import_action in imports:
    import_data_entries(**import_action)
