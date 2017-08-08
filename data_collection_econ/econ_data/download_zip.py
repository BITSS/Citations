import pandas as pd
from urllib.request import urlretrieve
import os
import glob 

def select_years(file_name):
    df = pd.read_csv(file_name, index_col=None)
    df['year'] = df.publication_date.apply(lambda x: x[0:4])
    df['year'] = pd.to_numeric(df['year'], errors = 'coerce')
    df = df.loc[(df['year'] >= 2001) & (df['year'] <= 2009)]
    df = df.dropna(subset = ['data_url', 'ds_url', 'app_url', 'corr_url'], how='all')
    df.fillna(0, inplace=True)
    df['data_file_name'] = df['data_url'].apply(split_url)
    df['ds_file_name'] = df['ds_url'].apply(split_url)
    df['app_file_name'] = df['app_url'].apply(split_url)
    df['corr_file_name'] = df['corr_url'].apply(split_url)
    df.to_csv('2001-2009_' + file_name, encoding = 'utf-8', index = False)

def split_url(url):
    if url == 0:
        return 0
    else: 
        return url.split("?")[0].split("/")[-1]

def download_helper(csv_file_name, url_list, url_file_name):
    df = pd.read_csv(csv_file_name)
    nrow = df['doi'].count()
    k = 0
    while k <= nrow:
        if df[url_list][k] == '0':
            k += 1
        else:
            try:
                urlretrieve(df[url_list][k], df[url_file_name][k])
                k += 1
            except Exception:
                k += 1
                pass
   

def download_files(csv_file_name):
    download_helper(csv_file_name, 'data_url', 'data_file_name')
    download_helper(csv_file_name, 'app_url', 'app_file_name')
    download_helper(csv_file_name, 'ds_url', 'ds_file_name')
    download_helper(csv_file_name, 'corr_url', 'corr_file_name')


select_years('aer_additional_material.csv')
download_files('2001-2009_aer_additional_material.csv')







