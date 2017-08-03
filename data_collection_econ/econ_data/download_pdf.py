import pandas as pd
from urllib.request import urlretrieve

def select_years(file_name): 
    df = pd.read_csv(file_name)
    df['year'] = df.publication_date.apply(lambda x: x[0:4])
    df['year'] = pd.to_numeric(df['year'], errors = 'coerce')
    df = df.loc[(df['year'] >= 2001) & (df['year'] <= 2009)]
    nrow = df.doi.count()
    df['index'] = list(range(0, nrow))
    df.to_csv('indexed1_' + file_name, encoding = 'utf-8')

def download_pdf(file_name, journal):
    df = pd.read_csv(file_name, nrows = 5)
    nrow = df.doi.count()
    k = 0
    while k <= nrow:
        urlretrieve(df.pdf_url[k], str(df.index[k]) + journal + '.pdf')
        k += 1

select_years('aer.csv')
#download_pdf('indexed1_aer.csv', 'aer')
# select_years('qje.csv')
# download_pdf('indexed_qje.csv', 'qje')












