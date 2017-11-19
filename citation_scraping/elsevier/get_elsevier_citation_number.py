import aiohttp
import asyncio
import aiofiles
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
    async with aiofiles.open(f'citation_scraping/elsevier/jsons/{journal}/doi/{doi.replace("/", ".")}.json', 'w', encoding='utf-8') as file:
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
    # Remove "weird" characters
    query_title = re.sub(pattern_remove, "", title)
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
    filename = re.sub(pattern_filename, "", title)
    async with aiofiles.open(f'citation_scraping/elsevier/jsons/{journal}/title/{filename}.json', 'w', encoding='utf-8') as file:
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
    # region ARGUMENT --------------------------------------------------
    journal_names = {
        'aer': 'American Economic Review',
        'qje': 'Quarterly Journal of Economics',
        'apsr': 'American Political Science Review',
        # 'apsr_centennial': 'American Political Science Review',
        'ajps': 'American Journal of Political Science',
    }

    file_names = {
        'aer': 'indexed_aer',
        'qje': 'indexed_qje',
        'apsr': 'apsr_article_info_from_issue_toc',
        # 'apsr_centennial': 'apsr_centennial_article_coding_template',
        'ajps': 'ajps_article_info_from_issue_toc',
    }

    # journal name
    try:
        journal = sys.argv[1].lower()
        journal_name = journal_names[journal]

        # AER and QJE use publication_date, APSR and AJPS uses issue_date
        if journal in ['aer', 'qje']:
            date_varname = 'publication_date'
        elif journal in ['apsr', 'apsr_centennial', 'ajps']:
            date_varname = 'issue_date'
        else:
            raise KeyError
    except IndexError:
        print("Please provide a journal name")
        raise
    except KeyError:
        print(f"{journal} is not in the list")
        raise

    pathlib.Path(f'citation_scraping/elsevier/jsons/{journal}/doi').mkdir(parents=True, exist_ok=True)
    pathlib.Path(f'citation_scraping/elsevier/jsons/{journal}/title').mkdir(parents=True, exist_ok=True)
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
    dois = []
    try:
        df = pd.read_csv(f'bld/{file_names[journal]}.csv', encoding="ISO-8859-1")
    except IOError:
        print(f"No bld/{file_names[journal]}.csv file")
        raise

    # publication_date / issue_date
    if journal == 'apsr_centennial':
        # APSR CENTENNIAL: needs issue_date column
        df['issue_date'] = pd.to_datetime('2006-11-01')
    else:
        df[date_varname] = pd.to_datetime(df[date_varname])

    df['citation'] = np.nan
    df['result'] = 'not found'

    # APSR and AJPS: filter by year
    if journal in ['apsr', 'ajps']:
        df = df[(df[date_varname] >= '2006-01-01') & (df[date_varname] < '2015-01-01')]

    # AJPS: remove (pages ...)
    if journal == 'ajps':
        pattern_title = re.compile(' \(pages .*\)$')
        df['title'] = df['title'].apply(lambda x: re.sub(pattern_title, '', x))

    # for testing
    # df = df.head(n=10)
    # endregion

    # region SEARCH -------------------------------------------------------------------------
    # run loop
    print(f"Searching {journal_name} articles on Scopus...")
    loop = asyncio.get_event_loop()

    # search by doi
    loop.run_until_complete(main_search('doi'))
    print(f"Searching by DOI: DONE")

    # write to file: just to be safe
    df.to_csv(f'bld/{journal}_citations_scopus.csv', encoding='utf-8')

    # search by title
    pattern_remove = re.compile('[?“”]')  # characters to remove
    pattern_space = re.compile('[—/]')  # characters to replace with a space
    pattern_filename = re.compile('[:"?/]')  # characters that are not accepted in a filename

    loop.run_until_complete(main_search('title'))
    print("Searching by title: DONE")

    # write to file
    df.to_csv(f'bld/{journal}_citations_scopus.csv', encoding='utf-8')
    # endregion
