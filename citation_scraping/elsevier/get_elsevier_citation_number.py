import csv
import aiohttp
import asyncio
import aiofiles
import json
import sys
import os
import re

from urllib.parse import quote


async def main_search():
    def chunks(l, n):
        """Yield successive n-sized chunks from l."""
        for i in range(0, len(l), n):
            yield l[i:i + n]

    async with aiohttp.ClientSession() as session:
        for small_chunk in list(chunks(dois, 100)):
            tasks = [fetch_search_result(session, doi) for doi in small_chunk]

            await asyncio.gather(*tasks)
            await asyncio.sleep(1)  # Just in case


async def fetch_search_result(session, doi):
    async with session.get('http://api.elsevier.com/content/search/scopus',
                           params={
                               'apiKey': api_key,
                               'query': quote(f'DOI("{doi}")'),
                               'httpAccept': 'application/json'
                           }) as response:
        data = await response.text()

    async with aiofiles.open(f'jsons/{doi.replace("/", ".")}.json', 'w', encoding='utf-8') as file:
        await file.write(data)


def parse_jsons():
    p = re.compile('"([\w./]+)"')

    # Construct rows from JSONs
    rows = []
    for filename in os.listdir('jsons/'):
        with open(f'jsons/{filename}', 'r', encoding='utf-8') as file:
            data = json.loads(file.read())

            doi = p.findall(data['search-results']['opensearch:Query']['@searchTerms'].replace('\ufeff', ''))[0]
            try:
                # has data
                rows.append([doi, data['search-results']['entry'][0]['citedby-count']])
            except KeyError:
                # article not found
                rows.append([doi, "NA"])

    # Write to file
    with open(f'outputs/{journal}.csv', 'w', newline='', encoding='utf-8') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(['DOI', 'citations'])
        for row in rows:
            writer.writerow(row)


if __name__ == '__main__':
    # Journal
    try:
        journal = sys.argv[1].lower()
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

    # dois file
    dois = []
    try:
        with open(f'inputs/{journal}.csv', 'r', encoding='utf-8') as csv_file:
            reader = csv.reader(csv_file, delimiter=',')
            for row in reader:
                dois.append(row[0])
    except IOError:
        print(f"No {journal}.csv file")
        raise

    # run loop
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main_search())

    # parse
    parse_jsons()
