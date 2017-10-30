# import csv
import aiohttp
import asyncio
import aiofiles
import json
import sys
import os
import re
import pandas as pd

from urllib.parse import quote


async def main_search(search_type):
    def chunks(l, n):
        """Yield successive n-sized chunks from l."""
        for i in range(0, len(l), n):
            yield l[i:i + n]

    async with aiohttp.ClientSession() as session:
        for small_chunk in list(chunks(df[df.citations.isnull()], 100)):
            if search_type == 'doi':
                tasks = [search_by_doi(session, row.doi) for row in small_chunk.itertuples()]
            elif search_type == 'title':
                tasks = [search_by_title(session, journal_name, row.title, row.year) for row in small_chunk.itertuples()]

            await asyncio.gather(*tasks)
            await asyncio.sleep(1)  # Just in case


async def search_by_doi(session, doi):
    async with session.get('http://api.elsevier.com/content/search/scopus',
                           params={
                               'apiKey': api_key,
                               'query': quote(f'DOI("{doi}")'),
                               'httpAccept': 'application/json'
                           }) as response:
        data = await response.text()

    async with aiofiles.open(f'jsons/doi/{doi.replace("/", ".")}.json', 'w', encoding='utf-8') as file:
        await file.write(data)


async def search_by_title(session, srctitle, title, pubyear):
    async with session.get('http://api.elsevier.com/content/search/scopus',
                           params={
                               'apiKey': api_key,
                               'query': quote(f'KEY(SRCTITLE("{srctitle}") AND TITLE({title}) AND PUBYEAR = {pubyear})'),
                               'httpAccept': 'application/json'
                           }) as response:
        data = await response.text()

    p = re.compile('[:"?]')

    async with aiofiles.open(f'jsons/title/{re.sub(p, "", title)}.json', 'w', encoding='utf-8') as file:
        await file.write(data)


def parse_jsons(search_type):
    if search_type == 'doi':
        p = re.compile('"([\w./]+)"')

        for filename in os.listdir('jsons/doi/'):
            with open(f'jsons/doi/{filename}', 'r', encoding='utf-8') as file:
                data = json.loads(file.read())

                doi = p.findall(data['search-results']['opensearch:Query']['@searchTerms'].replace('\ufeff', ''))[0]
                try:
                    df.loc[df.doi == doi]['citations'] = data['search-results']['entry'][0]['citedby-count']
                except KeyError:
                    # skip if article not found
                    pass

    elif search_type == 'title':
        for filename in os.listdir('jsons/title/'):
            with open(f'jsons/title/{filename}', 'r', encoding='utf-8') as file:
                data = json.loads(file.read())

                try:
                    # article found
                    if len(data['search-results']['entry']) != 1:
                        # skip if more than 2 found
                        continue
                    else:
                        df.loc[df.title.str.lower() == data['search-results']['entry'][0]['dc:title'].lower(), 'citations'] \
                            = data['search-results']['entry'][0]['citedby-count']
                except KeyError:
                    # skip if article not found
                    pass


if __name__ == '__main__':
    # Full journal names
    journal_names = {
        'aer': 'American Economic Review'
    }

    # Journal
    try:
        journal = sys.argv[1].lower()
        journal_name = journal_names[journal]
    except IndexError:
        print("Please provide a journal name")
        raise

    # api key
    try:
        with open('api_key.txt', 'r', encoding='utf-8') as file:
            api_key = file.readline()
    except IOError:
        print("No api_key.txt file")
        raise

    # list of articles
    dois = []
    try:
        df = pd.read_csv(f'inputs/{journal}_citations_scopus.csv')
    except IOError:
        print(f"No {journal}_citations_scopus.csv file")
        raise

    # run loop
    loop = asyncio.get_event_loop()

    # search by doi
    loop.run_until_complete(main_search('doi'))
    parse_jsons('doi')

    # search by title
    loop.run_until_complete(main_search('title'))
    parse_jsons('title')

    # write to file
    df.to_csv(f'outputs/{journal}_citations_scopus.csv')
