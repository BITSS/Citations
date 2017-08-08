
################################
#     directory structue       #
################################
data_collection_econ 
│   README.txt
│   select_sample_aer.R    
│
└───aer 
│   	│   
│   	└───aer
│   
│		└───spiders
│		│	│
│		│	│   
│		│	└───aer_spider.py 
│		│  	│ 
│		│	└───... 
│		│   
│		└───items.py
│   		│
│		└─── ... 
└───aer_zip 
│   	│   
│   	└───aer_zip
│   
│		└───spiders
│		│	│
│		│	│   
│		│	└───aer_zip_spider.py 
│		│  	│ 
│		│	└───... 
│		│   
│		└───items.py
│   		│
│		└─── ... 
│
│   
└───econ_data
│	│   
│	└───aer_download.R
│	│   
│	└───download_pdf.py 
│   	│
│	└───download_zip.py 
│   
└───pdf_to_txt
│   	│
│	└───pdfminer
│	│   
│	└───convert.py
│   	│
│	└───make_csv.py 
│	│
│	└───pdf2txt.py
│	│
│	└───get_institution.R 
│   
└───qje 
│   
│   	└───qje
│   
│		└───spiders
│		│	│
│		│	│   
│		│	└───qje_spider.py 
│		│  	│ 
│		│	└───... 
│		│   
│		└───items.py
│   		│
│		└─── ... 
│   
└───zip_to_info
	│   
	└───zip_info.R 



################################
#         explanation          #
################################

1. aer and qje 
	are the article scrapy files. You can change aer_spider.py and items.py to
	add information or remove information you would like to scrape. same thing for qje. 
	key information scraped: 
	title, doi, author, date, pdf download link, article url, 
	author institution(only for qje),JEL(empty for all qje 2001-2009), abstract 

2. aer_zip scrapes all the attachment download links for all articles. 
	key information scraped: 
	doi, title, publication_date, url, data_url, corr_url, app_url, ds_url, journal
	(corr = corrigium, app = appendix, ds = disclosure) 

3. econ_data
	1. download_pdf.py 
	is used to select needed article entries from 2001 to 2009, 
	index each entry and save to indexed_aer.csv and indexed_qje.csv. Then it would
	download the pdf files using the scraped pdf urls, each file will be saved to the 
	corresponding *index*_aer.pdf or *index*_qje.pdf (indexes are used because naming
	files by doi name contains characters not allowed for file names, and there are 
	potential duplicated names, hence using index is easier). However, the download
	function for aer is not working because of website restrictions.
	
	***Note: for indexed_*journal*.csv, we do not include articles that have author names 
	missing, this standard was applied in the political science journal as well.  

	2. aer_download.R 
	is used to download from pdf urls in indexed_aer.csv in batches.
	before detected by the aer website, we can download around 90 but less than 90 
	articles under one IP address per day. this code was executed on several different
	computers with different IP addresses to complete the download. 

	3. download_zip.py 
	is used to download all the attachment files for aer articles from 2001 to 2009, 		
	saved by using assigned file names in their corresponding urls. The file first 
	selects by year, then creates file name columns for each link, gives output file 
	'2001-2009_aer_additional_material.csv'. Then the script will download all zip
	files from '2001-2009_aer_additional_material.csv'

4. pdf_to_txt
	1. pdfminer 
	this is the base scripts for pdfminer, downloaded straight from the website
	https://euske.github.io/pdfminer/
	read how to use this package on this website. note: pdfminer only works in 
	python 2.X environment
	
	2. convert.py 
	reads all the pdf files then convert them into txt files, named with their 	
	corresponding indexes. eg. 112_aer.pdf --> 112_aer.txt. 
	Then it taks in indexed_*journal*.csv and merges on the output file from 
	make_csv.py based on the article index number. giving output complete_*journal*.csv

	3. make_csv.py 
	reads all the txt files, and create a dataframe with a index number column and a 
	content column for each article. 

	4. pdf2txt.py 
	the only tool script we need from pdfminer package. convert.py works on envoking 
	a command call using pdf2txt, which allows us to read the pdf, turning horrizontal
	pages into verticle pages (which is common for representing regression charts or 
	raw data charts in econ articles), then to save as txt output. 

	5. get_institution.R 
	this is a R script that reads all aer txt files, extracts the lines between the 		
	first line that start with an asterisk and line 51 (end of page, the usual 		
	location for aer footnotes). then for each footnote we only save everything from 
	begining to any mention of 'thank, grateful, support, seminar'. we then match the
	txt against a list of 900 institutions world wide. 
	we also inspect the unmatched articles, then add alternative names for schools,
	rematch, then save a unique list of institutions for each article.  
	
	***Note: only applicable to AER, since QJE institutions can be scraped from website 
	directly, no need for further txt matching. 

5. zip_to_info
	1.zip_to_info.R
	this is a R script that reads all downloaded aer data files (not including appendix 		
	corrigium, and disclosure files), unzip each zipfiles, including the nested zip 		
	files, then save a column of all file names (without their directory location info) 
	and a column of unique file extensions lists. By doing simple extension matching, we 
	generate True or False information for code and data avalibility. the final output 		
	of the script is 'aer_data_attachment_info.csv'

	***Note: since a lot of attachments are from back in the days, and people back then
	like to use txt files to save data or use .exe files to run code, we need to 
	further hand check adding on the current output. Also some of the compressed files 
	are in gz/tar/rar format, my code is only applicable to zip files. also make sure 
	you can run zip commands in your terminal. the code evokes commands lines to 
	recursively unzip files in the terminal.       





















