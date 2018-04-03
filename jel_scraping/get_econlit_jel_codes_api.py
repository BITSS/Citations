#!/usr/bin/env python3

"""
Scrape JEL codes from EconLit

$ python get_econlit_jel_codes_api.py [journal]

Args:
    journal: name of the journal you want to search
        aer: 'American Economic Review'
        qje: 'Quarterly Journal of Economics'

Example:
    $ python get_elsevier_citation_number.py qje

"""

import aiohttp
import asyncio
import argparse
import re
import numpy as np

from urllib.parse import quote
from data_preparation.tools import read_data_entry
from bs4 import BeautifulSoup


async def main_search(search_type):
    def chunks(l, n):
        """Yield successive n-sized chunks from l."""
        for i in range(0, len(l), n):
            yield l[i:i + n]

    async with aiohttp.ClientSession() as session:
        if search_type == 'doi':
            # Search by DOI
            for small_chunk in list(chunks(df[df.JEL_econlit.isnull()], 100)):
                tasks = [search_by_doi(session, row.doi) for row in small_chunk.itertuples()]

                print("100 done")
                df.to_csv(f'bld/{file_names[args.journal]}_econlit.csv', encoding='utf-8')

                await asyncio.gather(*tasks)
                await asyncio.sleep(1)  # Just in case

        elif search_type == 'title':
            # Search by title
            for small_chunk in list(chunks(df[df.JEL_econlit.isnull()], 100)):
                tasks = [search_by_title(session, journal_name, row.title, row.publication_date[:4]) for row in small_chunk.itertuples()]

                print("100 done")
                df.to_csv(f'bld/{file_names[args.journal]}_econlit.csv', encoding='utf-8')

                await asyncio.gather(*tasks)
                await asyncio.sleep(1)  # Just in case


async def search_by_doi(session, doi):
    # query
    async with session.get('http://fedsearch.proquest.com/search/sru/econlit',
                           params={
                               'version': '1.2',
                               'operation': 'searchRetrieve',
                               'query': quote(f'"{doi}"'),
                           }) as response:
        data = await response.text()

    jel_codes = []
    soup = BeautifulSoup(data, 'xml')

    try:
        number_of_results = soup.find('zs:numberOfRecords').text

        if number_of_results == '1':
            for datafield in soup.find_all(tag="653"):
                subfield = datafield.find('subfield')
                result = re.match(pattern, subfield.text)

                try:
                    jel_codes.append(result.group(2))
                except AttributeError:
                    pass

            df.loc[df.doi == doi, 'JEL_econlit'] = ' '.join(jel_codes)
            search_result = 'SUCCESS'
        elif number_of_results == '0':
            search_result = 'NOT_FOUND'
        else:
            search_result = 'MULTIPLE'
    except AttributeError:
        search_result = 'ERROR'

    df.loc[df.doi == doi, 'JEL_econlit_search_result'] = search_result


async def search_by_title(session, journal_name, title, pubyear):
    query_title = title

    # Remove "weird" characters
    query_title = re.sub(pattern_remove, "", query_title)
    query_title = re.sub(pattern_space, " ", query_title)

    # query
    async with session.get('http://fedsearch.proquest.com/search/sru/econlit',
                           params={
                               'version': '1.2',
                               'operation': 'searchRetrieve',
                               'query': quote(f'title="{query_title}" and publication="{journal_name}" and date={pubyear}'),
                           }) as response:
        data = await response.text()

    jel_codes = []
    soup = BeautifulSoup(data, 'xml')

    try:
        number_of_results = soup.find('zs:numberOfRecords').text

        if number_of_results == '1':
            for datafield in soup.find_all(tag="653"):
                subfield = datafield.find('subfield')
                result = re.match(pattern, subfield.text)

                try:
                    jel_codes.append(result.group(2))
                except AttributeError:
                    pass

            df.loc[df.title == title, 'JEL_econlit'] = ' '.join(jel_codes)
            search_result = 'SUCCESS'
        elif number_of_results == '0':
            search_result = 'NOT_FOUND'
        else:
            search_result = 'MULTIPLE'
    except AttributeError:
        search_result = 'ERROR'

    df.loc[df.title == title, 'JEL_econlit_search_result'] = search_result

if __name__ == '__main__':
    # region ARGUMENTS AND VARIABLES --------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("journal", help="name of the journal you want to search")
    args = parser.parse_args()

    journal_names = {
        'aer': 'American Economic Review',
        'qje': 'Quarterly Journal of Economics',
    }

    file_names = {
        'aer': 'indexed_aer_with_jel_template',
        'qje': 'indexed_qje_with_jel_template',
    }

    # journal name
    try:
        journal_name = journal_names[args.journal]
    except KeyError:
        print(f"{args.journal} is not in the journal list")
        raise

    # regex patterns for titles
    pattern_remove = re.compile('[?“”]')  # characters to remove
    pattern_space = re.compile('[—/]')  # characters to replace with a space
    # endregion

    # region READ AND CLEAN ------------------------------------------------------------------
    # list of articles
    try:
        df = read_data_entry(f'bld/{file_names[args.journal]}.ods')
    except IOError:
        print(f"No bld/{file_names[args.journal]} file")
        raise

    df['JEL_econlit'] = np.nan
    df['JEL_econlit_search_result'] = np.nan

    # for testing
    # df = df.head(n=10)
    # endregion

    # region SEARCH -------------------------------------------------------------------------
    pattern = re.compile('(.*)\((.*)\)')

    # run loop
    print(f"Searching {args.journal} articles on EconLit...")
    loop = asyncio.get_event_loop()

    # # search by doi
    loop.run_until_complete(main_search('doi'))
    print(f"Search by DOI: DONE")

    # write to file: just in case an error occurs while searching by title
    df.to_csv(f'bld/{file_names[args.journal]}_econlit.csv', encoding='utf-8')

    # search by title
    loop.run_until_complete(main_search('title'))
    print("Search by title: DONE")

    # write to file
    df.to_csv(f'bld/{file_names[args.journal]}_econlit.csv', encoding='utf-8')
    # endregion
