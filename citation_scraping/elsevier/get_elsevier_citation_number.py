import aiohttp
import asyncio
import aiofiles
import json
import sys
import re
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
                tasks = [search_by_title(session, journal_name, row.title, row.publication_date.year) for row in small_chunk.itertuples()]

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
    journal_names = {
        'aer': 'American Economic Review',
        'qje': 'Quarterly Journal of Economics',
        'apsr': 'American Political Science Review',
        'ajps': 'American Journal of Political Science',
    }

    file_names = {
        'aer': 'indexed_aer',
        'qje': 'indexed_qje',
        'aspr': '',
        'ajps': '',
    }

    # journal name
    try:
        journal = sys.argv[1].lower()
        journal_name = journal_names[journal]
    except IndexError:
        print("Please provide a journal name")
        raise

    # api key
    try:
        with open('citation_scraping/elsevier/api_key.txt', 'r', encoding='utf-8') as file:
            api_key = file.readline()
    except IOError:
        print("No api_key.txt file")
        raise

    if api_key == "":
        sys.exit("No api key in api_key.txt")

    # list of articles
    dois = []
    try:
        df = pd.read_csv(f'bld/{file_names[journal]}.csv', encoding="ISO-8859-1")
        df = df.head(n=10)  # for testing
    except IOError:
        print(f"No bld/{file_names[journal]}.csv file")
        raise

    # create wanted columns
    df['publication_date'] = pd.to_datetime(df['publication_date'])
    df['citation'] = np.nan
    df['result'] = 'not found'

    # run loop
    print(f"Searching {journal_name} articles on Scopus...")
    loop = asyncio.get_event_loop()

    # search by doi
    loop.run_until_complete(main_search('doi'))
    print(f"Searching by DOI: DONE")

    # write to file: just to be safe
    df.to_csv(f'bld/{journal}_citations_scopus.csv')

    # search by title
    pattern_remove = re.compile('[?“”]')  # characters to remove
    pattern_space = re.compile('[—/]')  # characters to replace with a space
    pattern_filename = re.compile('[:"?/]')  # characters that are not accepted in a filename

    loop.run_until_complete(main_search('title'))
    print("Searching by title: DONE")

    # write to file
    df.to_csv(f'bld/{journal}_citations_scopus.csv')
