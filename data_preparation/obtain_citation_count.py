import pandas as pd
import numpy as np
import requests
import time
import re
from lxml import html
from lxml.cssselect import CSSSelector
from mendeley import Mendeley
import mendeley_api_credentials

# Mendeley does not have citation count
# But Web of Science has. Can use python package wos via VPN. works well.


def mendeley_citation_count(doi):
    '''Query Mendeley API using doi and extract citation count from first
    result.'''
    mendeley = Mendeley(mendeley_api_credentials.client_id,
                        mendeley_api_credentials.client_secret)
    session = mendeley.start_client_credentials_flow().authenticate()
    document = session.catalog.by_identifier(doi=doi, view='stats')
    print(document.title, document)
    # user_agent = ('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:50.0) ' +
    #               'Gecko/20100101 Firefox/50.0')
    # results_page = requests.get('https://scholar.google.de/scholar',
    #                             params={'q': doi,
    #                                     'hl': 'en',
    #                                     # Turn off search personalization.
    #                                     'pws': 0
    #                                     },
    #                             headers={'user-agent': user_agent})

    # tree = html.fromstring(results_page.content)
    # select_citation_count = CSSSelector('div.gs_r > div.gs_ri > div.gs_fl > ' +
    #                                     'a:nth-of-type(1)')
    # # Set citation_count to 'None' if there are no search results
    # # or the structure of the results page differs from the one expected here.
    # if select_citation_count(tree):
    #     first_result = select_citation_count(tree)[0].text
    #     cited = re.match('^Cited by (\d+)$', first_result)
    #     if cited:
    #         citation_count = cited.group(1)
    #     elif first_result == 'Related articles':
    #         citation_count = 0
    #     else:
    #         citation_count = None
    #     print(first_result, citation_count)
    # else:
    #     citation_count = None
    time.sleep(1.337)
    return citation_count


def obtain_citation_count(article_file, output_file):
    df = pd.read_csv(article_file)
    df['mendeley_citation_count'] = df['doi'].apply(mendeley_citation_count)
    df.to_csv(output_file, index=None)

# AJPS
ajps_article_file = 'bld/ajps_article_coding_template.csv'
ajps_output_file = 'bld/ajps_mendeley_citation_count.csv'
obtain_citation_count(article_file=ajps_article_file,
                      output_file=ajps_output_file)

# APSR
apsr_article_file = 'bld/apsr_article_coding_template.csv'
apsr_output_file = 'bld/apsr_mendeley_citation_count.csv'
obtain_citation_count(article_file=apsr_article_file,
                      output_file=apsr_output_file)
