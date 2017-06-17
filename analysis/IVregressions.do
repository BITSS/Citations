set more off
clear all
cd "C:\Users\garret\Box Sync\CEGA-Programs-BITSS\3_Publications_Research\Citations\citations\analysis"

*The R script somehow loses many citations
*all with a foreign character in title
*so GSC redid it in Stata

*SAVE CITATIONS IN STATA FORMAT
insheet using ../external/apsr_2ndCheck.csv, clear names
keep doi citation
save ../external/apsr_2ndCheck.dta, replace
insheet using ../external/ajps_2ndCheck.csv, clear names
keep doi citation
save ../external/ajps_2ndCheck.dta, replace

*LOAD MAIN MERGED DATA
insheet using ../external/citations_clean_data.csv, clear names
rename abstractx abstract

*GET RID OF SOME NOT-REAL ARTICLES
count
drop if abstract=="NA" & strpos(title,"INDEX")>0
drop if abstract=="NA" & strpos(title,"Editor")>0
drop if abstract=="NA" & strpos(title,"Errat")>0

*APSR EXTERNAL REVIEWERS--NOT REAL ARTICLES
drop if doi=="10.1017/S0003055409990256"
drop if doi=="10.1017/S0003055410000547"
drop if doi=="10.1017/S0003055411000499"
drop if doi=="10.1017/S0003055412000470"
drop if doi=="10.1017/S0003055414000574"


replace citation_count="." if citation_count=="NA"
destring citation_count, replace
summ citation_count

*MERGE IN THE FULL CITATIONS DATA
*START WITH APSR
*MERGE, AND CHANGE NAME SO AJPS MERGE DOESN'T OVERWRITE 
merge 1:1 doi using ../external/apsr_2ndCheck.dta
drop if _merge==2 //these are a few Index not-real articles
replace citation="." if citation=="NA"
destring citation, replace
rename citation citation_apsr
summ citation*

*MERGE AJPS
rename _merge merge_apsr
merge 1:1 doi using ../external/ajps_2ndCheck.dta
replace citation="." if citation=="NA" 
destring citation, replace
summ citation*

*COMBINE AJPS AND APSR
replace citation=citation_apsr if citation==. & citation_apsr!=.
summ citation*

*NEW VERSION IS BETTER, DROP OLD
drop citation_apsr citation_count

*CORRECT A FEW MISSING DATES
replace publication_date_print = "2010-01-01" if doi=="10.1111/j.1540-5907.2009.00423.x"
replace publication_date_internet = "2009-12-28" if doi=="10.1111/j.1540-5907.2009.00423.x"
replace publication_date_print = "2010-10-01" if doi=="10.1111/j.1540-5907.2010.00466.x"
replace publication_date_internet = "2010-07-21" if doi=="10.1111/j.1540-5907.2010.00466.x"
replace publication_date_print = "2015-07-01" if doi=="10.1111/ajps.12158"
replace publication_date_internet = "2014-12-02" if doi=="10.1111/ajps.12158"
replace publication_date_print = "2015-07-01" if doi=="10.1111/ajps.12152"
replace publication_date_internet = "2014-12-16" if doi=="10.1111/ajps.12152"

*GENERATE DATES
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
label var ajpsXpost2010 "AJPS after 2010 Policy"
gen ajpsXpost2012=ajps*post2012
label var ajpsXpost2012 "AJPS after 2012 Policy"

gen year=substr(publication_date_print, 1, 4)
destring year, replace
drop if year>2014 //2006-2014 is what we said we'd cover


*LABEL DATA
label var year "Year"
label var citation "Citations"
label var print_months_ago "Months since Pub'd"
label var print_months_ago_sq "Months since Pub'd$^2$"
label var print_months_ago_cu "Months since Pub'd$^3$"
label var ajps "AJPS"
label var post2010 "After Oct 2010"
label define beforeafter 0 "Before" 1 "After"
label values post2010 beforeafter
label var post2012 "After July 2012"
label value post2012 beforeafter
label var avail_yn "Data and Code Available" 


*****************************************************
save ../external/cleaned/mergedforregs.dta, replace

********************************************************
*GRAPH SHARING OVER TIME
*******************************************************

bysort year ajps: egen avail_j_avg=mean(avail_yn)
label var avail_j_avg "Availability by Journal and Year"
gen ajps_y_avg=avail_j_avg if ajps==1
label var ajps_y_avg "AJPS"
gen apsr_y_avg=avail_j_avg if ajps==0
label var apsr_y_avg "APSR"
line ajps_y_avg apsr_y_avg year, title("Yearly Average Availability by Journal") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1)
graph export ../output/avail_time.png, replace

****************************
*GRAPH CITATIONS
****************************
histogram citation, bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/cite_histo.png, replace

bysort year ajps: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen ajps_y_citeavg=cite_j_avg if ajps==1
label var ajps_y_citeavg "AJPS"
gen apsr_y_citeavg=cite_j_avg if ajps==0
label var apsr_y_citeavg "APSR"
line ajps_y_citeavg apsr_y_citeavg year, title("Yearly Average Citations by Journal") ///
	bgcolor(white) graphregion(color(white))

graph export ../output/cite_time.png, replace
*********************************************************
*GRAPH TOPIC AND TYPE
*****************************************************
replace topic="" if topic=="skip"
tab topic, generate(topic_)
label var topic_1 "American"
label var topic_2 "Comparative"
label var topic_3 "Int'l Relations"
label var topic_4 "Methodology"
label var topic_5 "Theory"
label define journal 0 "APSR" 1 "AJPS"
label values ajps journal
graph bar topic_*, stack over(ajps) legend(lab(1 "American") ///
									lab(2 "Comparative") ///
									lab(3 "Int'l Relations") ///
									lab(4 "Methodology") ///
									lab(5 "Theory"))
graph export ../output/topicXjournal.png, replace

foreach X in 2010 2012{
graph bar topic_*, stack over(ajps) over(post`X') legend(lab(1 "American") ///
	lab(2 "Comparative") ///
	lab(3 "Int'l Relations") ///
	lab(4 "Methodology") ///
	lab(5 "Theory")) ///
	title("Article Topic by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/topicXjournalXpost`X'.png, replace
}

replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
foreach X in 2010 2012{
graph bar data_type_*, stack over(ajps) over(post`X') legend(lab(1 "Experimental") ///
	lab(2 "None") ///
	lab(3 "Observational") ///
	lab(4 "Simulations")) ///
	title("Data Type by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/typeXjournalXpost`X'.png, replace
}

***********************************************************
*REGRESSIONS
***********************************************************

*NAIVE
regress citation avail_yn
	outreg2 using ../output/naive.tex, tex label replace
regress citation avail_yn ajps 
	outreg2 using ../output/naive.tex, tex label append
regress citation avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naive.tex, tex label append title("Naive OLS Regression")

*NAIVE-LN
gen lncite=ln(citation+1)
label var lncite "Log(Citations+1)"
regress lncite avail_yn
	outreg2 using ../output/naiveLN.tex, tex label replace
regress lncite avail_yn ajps 
	outreg2 using ../output/naiveLN.tex, tex label append
regress lncite avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naiveLN.tex, tex label append title("Naive Log OLS Regression")

	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
ivregress 2sls citation ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012), first

	outreg2 using ../output/ivreg.tex, tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons

ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012), first

	outreg2 using ../output/ivreg.tex, tex label append ctitle("2SLS-Log") ///
		nocons
		
*MANUALLY DO THE IV
*FIRST STAGE
regress avail_yn ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu
test ajpsXpost2010=ajpsXpost2012=0
outreg2 using ../output/ivreg.tex, tex label append ctitle("First Stage") addstat(F Stat, r(F)) ///
	nocons

predict avail_hat
*SECOND STAGE--DON'T TRUST THE STANDARD ERRORS!
regress citation avail_hat ajps post2010 post2012 ///
	print_months_ago print_months_ago_sq print_months_ago_cu year
***********************************************	
