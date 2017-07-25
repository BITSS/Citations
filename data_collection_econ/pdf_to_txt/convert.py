import os
# import pdfminer 
# import pdf2txt
import glob 
import re 
import pandas as pd

# #turn pdf into txt 
# aer_pdf_files = os.listdir('../econ_data/aer')
# qje_pdf_files = os.listdir('../econ_data/qje')
# def convert(pdf_files, journal):
# 	path = journal + 'txt'
# 	os.makedirs(path)
# 	for pdf_file in pdf_files:
# 		pdf_path = '../econ_data/' + journal + '/' + pdf_file
# 		txt_file = re.sub('.pdf', '.txt', pdf_file) #'11qje.txt'
# 		#glue into command line 
# 		command = ' '.join(['pdf2txt.py -V -o', txt_file, pdf_path])
# 		os.system(command)
# 		os.rename(txt_file, './' + path + '/' + txt_file)

# #turn txt into csv 
# def txt_to_csv(journal):
# 	 columns = ['index', 'content']
# 	 files = os.listdir('./' + journal + 'txt/')
# 	 df = pd.DataFrame(columns = columns)
# 	 for file in files:
# 		 file_path = './' + journal + 'txt/' + file
# 		 file_index = re.findall(r'\d+', file)[0]
# 		 file_content = open(file_path, 'r')
# 		 f = open(file_path)
# 		 content = " ".join(line.strip() for line in f)
# 		 df = df.append({'index': file_index, 'content': content}, ignore_index=True)
# 	 csv_file_name = journal +'_content.csv'
# 	 df.to_csv(csv_file_name, columns = columns, encoding='utf-8', index = False)

# txt_to_csv('aer')
# txt_to_csv('qje')

#Merge csv with indexed dataframe 
aer_columns = ['JEL','abstract','author', 'doi','journal', 'pdf_url', 'publication_date', 'title', 'url', 'year', 'article_ix', 'content']
qje_columns = ['JEL','institution','abstract','author', 'doi','journal', 'pdf_url', 'publication_date', 'title', 'url', 'year', 'article_ix', 'content']

def merge_indexed(journal, columns):
	indexed_csv_path = '../econ_data/indexed_'+ journal + '.csv'
	txt_csv_path = journal +'_content.csv'
	indexed = pd.read_csv(indexed_csv_path, index_col= False)
	txt = pd.read_csv(txt_csv_path, index_col=False)
	txt['index'] = pd.to_numeric(txt['index'])
	complete = indexed.merge(txt,'left', 'index')
	complete_csv_path = 'complete' + '_' + journal +'.csv'
	complete.rename(columns={'index': 'article_ix'}, inplace=True)
	complete.to_csv(complete_csv_path, columns = columns, encoding = 'utf-8', index = False)

merge_indexed('qje', qje_columns)
merge_indexed('aer', aer_columns)

# in aer Index 122, 123, 959, 960, 1367, 1368, 1561, 1562, 1750, 1751, 
# 1969, 1970, 2377,2378, 2571, 2572, 2665, 2666, 3404, 3405, 3586, 3589
# have dead pdf links, unable to access content.
# For QJE, complete_qje.csv contains all articles contents, including those of missing authors
# For AER, complete_aer.csv does not contain content of those with missing authors, because
# of frequent deadlink disrupts code very frequently.  










