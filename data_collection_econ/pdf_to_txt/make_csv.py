import os
import pdfminer 
import pdf2txt
import glob 
import re 
import pandas as import pd


aer_txt_files = os.listdir('../econ_data/aertxt') #list of aer_txt_files
qje_txt_files = os.listdir('../econ_data/qjetxt') #list of qje txt files
def convert(pdf_files, journal):
	path = journal + 'txt'
	os.makedirs(path)
	for pdf_file in pdf_files:
		pdf_path = '../econ_data/' + journal + '/' + pdf_file
		txt_file = re.sub('.pdf', '.txt', pdf_file) #'11qje.txt'
		#glue into command line 
		command = ' '.join(['pdf2txt.py -V -o', txt_file, pdf_path])
		os.system(command)
		os.rename(txt_file, './' + path + '/' + txt_file)


columns = ['index', 'content']

def txt_to_csv(files, journal):
    df = pd.DataFrame(columns = columns)
    csv_file_name = journal + '.csv'
    for file in files:
        file_path = '../econ_data/' + journal + 'txt/' + file
        file_index = re.findall(r'\d+', file)
        file_content = open(file_path, 'r')
        df = df.append({'index': file_index, 'content': file_content}, ignore_index=True)
    df.to_csv(csv_file_name, columns = columns, encoding='utf-8')
