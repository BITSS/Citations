set more off
clear all
cd "C:\Users\garret\Box Sync\CEGA-Programs-BITSS\3_Publications_Research\Citations\Citations-repo\analysis"

insheet using ../external/citations_clean_data.csv, clear names
rename abstractx abstract

drop if abstract=="NA" & strpos(title,"INDEX")>0
drop if abstract=="NA" & strpos(title,"Editor")>0
drop if abstract=="NA" & strpos(title,"Errat")>0

replace publication_date_print = "2010-01-01" in 238
replace publication_date_internet = "2009-12-28" in 238
replace publication_date_print = "2010-10-01" in 287
replace publication_date_internet = "2010-07-21" in 287
replace publication_date_print = "2015-07-01" in 583
replace publication_date_internet = "2014-12-02" in 583
replace publication_date_print = "2015-07-01" in 588
replace publication_date_internet = "2014-12-16" in 588


gen print_date=date(publication_date_print,"YMD")
gen online_date=date(publication_date_internet,"YMD")
local scrapedate=date("2017-05-15","YMD")
gen print_months_ago=(`scrapedate'-print_date)/30.42
gen online_months_ago=(`scrapedate'-online_date)/30.42
gen print_months_ago_sq=print_months_ago*print_months_ago
gen online_months_ago_sq=online_months_ago*online_months_ago
gen print_months_ago_cu=print_months_ago_sq*print_months_ago
gen online_months_ago_cu=online_months_ago_sq*online_months_ago

gen avail_yn=(availability=="files")
gen ajps=(journal=="ajps")

local Oct2010=date("2010-10-01","YMD")
gen post2010=(print_date>`Oct2010')

local July2012=date("2012-07-01","YMD")
gen post2012=(print_date>`July2012')

gen ajpsXpost2010=ajps*post2010
gen ajpsXpost2012=ajps*post2012

gen year=substr(publication_date_print, 1, 4)
destring year, replace
gen year_sq=year*year
gen year_cu=year_sq*year

drop if citation_count=="NA" //WHY!? They're in the 
destring citation_count, replace

ivregress 2sls citation_count ajps post2010 post2012 print_months_ago print_months_ago ///
	print_months_ago_sq print_months_ago_cu year year_sq year_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012)
	
