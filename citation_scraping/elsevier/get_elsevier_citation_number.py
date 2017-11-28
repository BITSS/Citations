#!/usr/bin/env python3

"""
Scrape citation counts from Scopus

$ python get_elsevier_citation_number.py [journal] [--save]

Args:
    journal: name of the journal you want to search
        aer: 'American Economic Review'
        qje: 'Quarterly Journal of Economics'
        apsr: 'American Political Science Review'
        apsr_centennial: 'American Political Science Review Centennial'
        ajps: 'American Journal of Political Science'
    --save (optional): save JSONs in citation_scraping/elsevier/jsons/

Example:
    $ python get_elsevier_citation_number.py qje
    $ python get_elsevier_citation_number.py aer --save

"""

import aiohttp
import asyncio
import aiofiles
import argparse
import json
import sys
import re
import pathlib
import numpy as np
import pandas as pd

from urllib.parse import quote


async def main_search(search_type):
    def chunks(l, n):
        """Yield successive n-sized chunks from l."""
        for i in range(0, len(l), n):
            yield l[i:i + n]

    async with aiohttp.ClientSession() as session:
        if search_type == 'doi':
            # Search by DOI
            for small_chunk in list(chunks(df[df.citation.isnull()], 100)):
                tasks = [search_by_doi(session, row.doi) for row in small_chunk.itertuples()]

                await asyncio.gather(*tasks)
                await asyncio.sleep(1)  # Just in case

        elif search_type == 'title':
            # Search by title
            for small_chunk in list(chunks(df[df.citation.isnull()], 100)):
                tasks = [search_by_title(session, journal_name, row.title, row.__getattribute__(date_varname).year) for row in small_chunk.itertuples()]

                await asyncio.gather(*tasks)
                await asyncio.sleep(1)  # Just in case


async def search_by_doi(session, doi):
    # query
    async with session.get('http://api.elsevier.com/content/search/scopus',
                           params={
                               'apiKey': api_key,
                               'query': quote(f'DOI("{doi}")'),
                               'httpAccept': 'application/json'
                           }) as response:
        data = await response.text()

    # save json
    if args.save:
        async with aiofiles.open(f'citation_scraping/elsevier/jsons/{args_journal}/doi/{doi.replace("/", ".")}.json', 'w', encoding='utf-8') as file:
            await file.write(data)

    data = json.loads(data)

    # write to df
    try:
        df.loc[df.doi == doi, 'citation'] = data['search-results']['entry'][0]['citedby-count']
        df.loc[df.doi == doi, 'result'] = 'doi'
    except KeyError:
        # skip if article not found
        pass
    except json.decoder.JSONDecodeError:
        df.loc[df.doi == doi, 'result'] = 'error'
        pass


async def search_by_title(session, srctitle, title, pubyear):
    query_title = title

    # apsr centennial review articles
    if args.journal == 'apsr_centennial':
        if re.match('^\d+\.', title) is not None:
            try:
                query_title = re.search('“(.*?)[.,]”', query_title).group(1)
            except AttributeError:
                pass

    # Remove "weird" characters
    query_title = re.sub(pattern_remove, "", query_title)
    query_title = re.sub(pattern_space, " ", query_title)

    # query
    async with session.get('http://api.elsevier.com/content/search/scopus',
                           params={
                               'apiKey': api_key,
                               'query': quote(f'KEY(SRCTITLE("{srctitle}") AND TITLE({query_title}) AND PUBYEAR = {pubyear})'),
                               'httpAccept': 'application/json'
                           }) as response:
        data = await response.text()

    # save json
    if args.save:
        filename = re.sub(pattern_filename, "", query_title)
        async with aiofiles.open(f'citation_scraping/elsevier/jsons/{args_journal}/title/{filename}.json', 'w', encoding='utf-8') as file:
            await file.write(data)

    data = json.loads(data)

    # Write to df
    try:
        # article found
        if len(data['search-results']['entry']) != 1:
            # skip if more than 2 found
            df.loc[df.title == title, 'result'] = 'title_multiple'
        else:
            df.loc[df.title == title, 'citation'] = data['search-results']['entry'][0]['citedby-count']
            df.loc[df.title == title, 'result'] = 'title'
    except KeyError:
        # skip if article not found
        pass
    except json.decoder.JSONDecodeError:
        df.loc[df.title == title, 'result'] = 'error'
        pass


if __name__ == '__main__':
    # region ARGUMENTS AND VARIABLES --------------------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument("journal", help="name of the journal you want to search")
    parser.add_argument("--save", help="save JSONs in citation_scraping/elsevier/jsons/", action='store_true')
    args = parser.parse_args()

    journal_names = {
        'aer': 'American Economic Review',
        'qje': 'Quarterly Journal of Economics',
        'apsr': 'American Political Science Review',
        'apsr_centennial': 'American Political Science Review',
        'ajps': 'American Journal of Political Science',
    }

    file_names = {
        'aer': 'indexed_aer',
        'qje': 'indexed_qje',
        'apsr': 'apsr_article_info_from_issue_toc',
        'apsr_centennial': 'apsr_centennial_article_coding_template',
        'ajps': 'ajps_article_info_from_issue_toc',
    }

    # journal name
    try:
        journal_name = journal_names[args.journal]

        # AER and QJE use publication_date, APSR and AJPS uses issue_date
        if args.journal in ['aer', 'qje']:
            date_varname = 'publication_date'
        elif args.journal in ['apsr', 'apsr_centennial', 'ajps']:
            date_varname = 'issue_date'
        else:
            raise KeyError
    except KeyError:
        print(f"{args.journal} is not in the journal list")
        raise

    # regex patterns for titles
    pattern_remove = re.compile('[?“”]')  # characters to remove
    pattern_space = re.compile('[—/]')  # characters to replace with a space
    pattern_filename = re.compile('[:"?/]')  # characters that are not accepted in a filename

    # If --save, create folders in the path
    if args.save:
        pathlib.Path(f'citation_scraping/elsevier/jsons/{args.journal}/doi').mkdir(parents=True, exist_ok=True)
        pathlib.Path(f'citation_scraping/elsevier/jsons/{args.journal}/title').mkdir(parents=True, exist_ok=True)
    # endregion

    # region API KEY
    try:
        with open('citation_scraping/elsevier/api_key.txt', 'r', encoding='utf-8') as file:
            api_key = file.readline()
    except IOError:
        print("No api_key.txt file")
        raise

    if api_key == "":
        sys.exit("No api key in api_key.txt")
    # endregion

    # region READ AND CLEAN ------------------------------------------------------------------
    # list of articles
    try:
        if args.journal in ['ajps', 'apsr', 'apsr_centennial']:
            df = pd.read_csv(f'bld/{file_names[args.journal]}.csv', encoding="utf-8")
        else:
            df = pd.read_csv(f'bld/{file_names[args.journal]}.csv', encoding="ISO-8859-1")
    except IOError:
        print(f"No bld/{file_names[args.journal]}.csv file")
        raise

    # publication_date / issue_date
    if args.journal == 'apsr_centennial':
        # APSR CENTENNIAL: needs issue_date column
        df['issue_date'] = pd.to_datetime('2006-11-01')
    else:
        df[date_varname] = pd.to_datetime(df[date_varname])

    df['citation'] = np.nan
    df['result'] = 'not found'

    # APSR and AJPS: filter by year
    if args.journal in ['apsr', 'ajps']:
        df = df[(df[date_varname] >= '2006-01-01') & (df[date_varname] < '2015-01-01')]

    # AJPS: remove (pages ...) from title
    if args.journal == 'ajps':
        pattern_title = re.compile(' \(pages .*\)$')
        df['title'] = df['title'].apply(lambda x: re.sub(pattern_title, '', x))

    # for testing
    # df = df.head(n=10)
    # endregion

    # region SEARCH -------------------------------------------------------------------------
    # run loop
    print(f"Searching {args.journal} articles on Scopus...")
    loop = asyncio.get_event_loop()

    # search by doi
    loop.run_until_complete(main_search('doi'))
    print(f"Search by DOI: DONE")

    # write to file: just in case an error occurs while searching by title
    df.to_csv(f'bld/{args.journal}_citations_scopus.csv', encoding='utf-8')

    # search by title
    loop.run_until_complete(main_search('title'))
    print("Search by title: DONE")

    # write to file
    df.to_csv(f'bld/{args.journal}_citations_scopus.csv', encoding='utf-8')
    # endregion
