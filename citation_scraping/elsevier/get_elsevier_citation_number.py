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
        if search_type == 'doi':
            for small_chunk in list(chunks(df[df.citations.isnull()], 100)):
                tasks = [search_by_doi(session, row.doi) for row in small_chunk.itertuples()]

                await asyncio.gather(*tasks)
                await asyncio.sleep(1)  # Just in case

        elif search_type == 'title':
            for row in df[df.citations.isnull()].itertuples():
                await search_by_title(session, journal_name, row.title, row.year)


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
    filename = re.sub(p, "", title)

    async with aiofiles.open(f'jsons/title/{filename}.json', 'w', encoding='utf-8') as file:
        await file.write(data)

    # parse
    try:
        with open(f'jsons/title/{filename}.json', 'r', encoding='utf-8') as file:
            data = json.loads(file.read())

            try:
                # article found
                if len(data['search-results']['entry']) != 1:
                    # skip if more than 2 found
                    df.loc[df.title == title, 'result'] = 'title_multiple'
                else:
                    df.loc[df.title == title, 'citations'] = data['search-results']['entry'][0]['citedby-count']
                    df.loc[df.title == title, 'result'] = 'title'
            except KeyError:
                # skip if article not found
                pass
    except json.decoder.JSONDecodeError:
        df.loc[df.title == title, 'result'] = 'error'
        pass


def parse_jsons():
    p = re.compile('"([\w./]+)"')

    for filename in os.listdir('jsons/doi/'):
        with open(f'jsons/doi/{filename}', 'r', encoding='utf-8') as file:
            data = json.loads(file.read())

            doi = p.findall(data['search-results']['opensearch:Query']['@searchTerms'].replace('\ufeff', ''))[0]
            try:
                df.loc[df.doi == doi]['citations'] = data['search-results']['entry'][0]['citedby-count']
                df.loc[df.doi == doi]['result'] = 'doi'
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

    if api_key == "":
        sys.exit("No api key in api_key.txt")

    # list of articles
    dois = []
    try:
        df = pd.read_csv(f'inputs/{journal}_citations_scopus.csv')
    except IOError:
        print(f"No {journal}_citations_scopus.csv file")
        raise

    df['result'] = 'not found'
    df.loc[df.citations.notnull(), 'result'] = 'existing'

    # run loop
    print(f"Searching articles on {journal_name}...")
    loop = asyncio.get_event_loop()

    # search by doi
    # loop.run_until_complete(main_search('doi'))
    # parse_jsons()
    print("Searching by DOI: DONE")

    # search by title
    loop.run_until_complete(main_search('title'))
    print("Searching by title: DONE")

    # write to file
    df.to_csv(f'outputs/{journal}_citations_scopus.csv')
