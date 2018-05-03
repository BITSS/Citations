set more off
clear all
cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"

*The R script somehow loses many citations
*all with a foreign character in title
*so GSC redid it in Stata
***************************************************
*LOAD DATA
***************************************************
*SAVE CITATIONS IN STATA FORMAT
insheet using ../external/apsr_2ndCheck.csv, clear names
keep doi citation
save ../external/apsr_2ndCheck.dta, replace
insheet using ../external/ajps_2ndCheck.csv, clear names
keep doi citation
save ../external/ajps_2ndCheck.dta, replace
insheet using ../external/apsr_centennial.csv, clear names
keep doi citation
save ../external/apsr_centennial.dta, replace

*SAVE AUTHOR RANK IN STATA FORMAT
insheet using ../external/article_author_top_rank.csv, clear names
keep doi top_rank
save ../external/article_author_top_rank.dta, replace

*LOAD MAIN MERGED DATA
insheet using ../external/citations_clean_data.csv, clear names
count
rename abstractx abstract

*****************************************************
*DROP NON-REAL ARTICLES
******************************************************

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

*NOTES FROM THE EDITOR
drop if strpos(title,"Notes from the Editor")>0

*ERRATA
drop if strpos(title,"Errata to")>0 //1
drop if strpos(title,"ERRATUM")>0 //3
drop if strpos(title,"Erratum")>0 //1
drop if strpos(title,"CORRIGENDUM")>0 //2 

replace citation_count="." if citation_count=="NA"
destring citation_count, replace
summ citation_count

*MERGE IN THE FULL CITATIONS DATA
*START WITH APSR
*MERGE, AND CHANGE NAME SO AJPS MERGE DOESN'T OVERWRITE 
merge 1:1 doi using ../external/apsr_2ndCheck.dta
drop if _merge==2 //these are a few Index not-real articles
rename _merge merge_apsr
replace citation="." if citation=="NA"
destring citation, replace
rename citation citation_apsr
summ citation*

*MERGE AJPS
merge 1:1 doi using ../external/ajps_2ndCheck.dta
drop if _merge==2 //Editor notes, etc.
rename _merge merge_ajps
replace citation="." if citation=="NA" 
destring citation, replace
summ citation*

*COMBINE AJPS AND APSR
*MERGING MUST BE DONE THIS WAY SINCE IT WRITES OVER VARS WITH THE SAME NAME
*MAYBE THERE'S A WAY AROUND THAT?
replace citation=citation_apsr if citation==. & citation_apsr!=.
summ citation*
rename citation citation_hold

*MERGE APSR CENTENNIAL
merge 1:1 doi using ../external/apsr_centennial.dta
drop if _merge==2 //There aren't any as of 6/27/17
replace citation_hold=citation if citation_hold==. & citation!=.
drop citation
rename citation_hold citation
rename _merge merge_apsr_centennial

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
local scrapedate=date("2017-11-21","YMD")
gen print_months_ago=(`scrapedate'-print_date)/30.42
gen online_months_ago=(`scrapedate'-online_date)/30.42
gen print_months_ago_sq=print_months_ago*print_months_ago
gen online_months_ago_sq=online_months_ago*online_months_ago
gen print_months_ago_cu=print_months_ago_sq*print_months_ago
gen online_months_ago_cu=online_months_ago_sq*online_months_ago

gen avail_yn=(availability=="files")
gen avail_data=(availability=="files"|availability=="data")
gen ajps=(journal=="ajps")

local Oct2010=date("2010-10-01","YMD")
gen post2010=(print_date>`Oct2010')

local July2012=date("2012-07-01","YMD")
gen post2012=(print_date>`July2012')

gen ajpsXpost2010=ajps*post2010
label var ajpsXpost2010 "AJPS post-2010 Policy"
gen ajpsXpost2012=ajps*post2012
label var ajpsXpost2012 "AJPS post-2012 Policy"

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
label var post2010 "Post-Oct 2010"
label define beforeafter 0 "Before" 1 "After"
label values post2010 beforeafter
label var post2012 "Post-July 2012"
label value post2012 beforeafter
label var avail_yn "Data and Code Available" 


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
graph export ../output/ps_avail_time.eps, replace
graph export ../output/ps_avail_time.png, replace

*COULD DO FIGURE WITH ONLY DATA ARTICLES--CLOSE TO 100%?
*MAKE ONE LINE DASHED FOR B&W READERS?
****************************
*GRAPH CITATIONS
****************************
histogram citation, bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/ps_cite_histo.eps, replace
graph export ../output/ps_cite_histo.png, replace

bysort year ajps: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen ajps_y_citeavg=cite_j_avg if ajps==1
label var ajps_y_citeavg "AJPS"
gen apsr_y_citeavg=cite_j_avg if ajps==0
label var apsr_y_citeavg "APSR"
line ajps_y_citeavg apsr_y_citeavg year, title("Yearly Average Citations by Journal") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/ps_cite_time.png, replace
graph export ../output/ps_cite_time.eps, replace
save ../external/temp.dta, replace

*TRY MU YANG'S ELSEVIER API DATA
import delimited using ../external/ajps_citations_scopus.csv, delimiter(",") clear
save ../external/ajps_citations_scopus.dta, replace
import delimited using ../external/apsr_citations_scopus.csv, delimiter(",") clear
save ../external/apsr_citations_scopus.dta, replace
append using ../external/ajps_citations_scopus.dta
*APSR Centennial is duplicated, so don't need to include separately.
keep doi citation
rename citation citationE
merge 1:1 doi using ../external/temp
rename _merge merge_Scopus

gen lnciteE=ln(citationE)
ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
ivregress 2sls lnciteE ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
	
label var citationE "Scopus Citations"
label var citation "Web of Knowledge Citations"
rename citation WoK
rename citationE Scopus
*scatter citation citationE || lfit citation citationE, title("Comparison of Citation Data") ///
*	bgcolor(white) graphregion(color(white)) legend(off) ytitle("Web of Knowledge Citations")
aaplot WoK Scopus, aformat(%3.2f) bformat(%3.2f) bgcolor(white) graphregion(color(white))
graph export ../output/ps_citationcomparison.eps, replace
graph export ../output/ps_citationcomparison.png, replace

*APRIL 18, 2018
*CHANGE MAIN CITATION VARIABLE TO SCOPUS
*CHANGE SCRAPE DATE TO MU YANG'S ACTUAL DATE: 11/21/17
rename Scopus citation

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
graph export ../output/topicXjournal.eps, replace

foreach X in 2010 2012{
graph bar topic_*, stack over(post`X') over(ajps)  legend(lab(1 "American") ///
	lab(2 "Comparative") ///
	lab(3 "Int'l Relations") ///
	lab(4 "Methodology") ///
	lab(5 "Theory")) ///
	title("Article Topic by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/ps_topicXjournalXpost`X'.eps, replace
graph export ../output/ps_topicXjournalXpost`X'.png, replace
}
*AGAIN, DO THESE FOR ONLY DATA ARTICLES

replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
label var data_type_1 "Experimental"
label var data_type_2 "No Data in Article" 
label var data_type_3 "Observational"
label var data_type_4 "Simulations"
foreach X in 2010 2012{
graph bar data_type_*, stack over(post`X') over(ajps)  legend(lab(1 "Experimental") ///
	lab(2 "None") ///
	lab(3 "Observational") ///
	lab(4 "Simulations")) ///
	title("Data Type by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/ps_typeXjournalXpost`X'.eps, replace
graph export ../output/ps_typeXjournalXpost`X'.png, replace
}

*************************************
*GRAPH AUTHOR RANKING
*************************************
count
merge 1:1 doi using ../external/article_author_top_rank.dta
drop if _merge==2 //Contains a few 2015 articles, editorials, and erratum
*AS OF 6/21/2017 THE APSR CENTENNIAL AND ~10 OTHERS AREN'T IN THIS DATASET
count
rename _merge merge_auth_rank
replace top_rank=".a" if top_rank=="NA"
destring top_rank, replace
replace top_rank=.b if top_rank==. //.b is TRULY MISSING
replace top_rank=125 if top_rank==.a //temp! 
label var top_rank "Top US News Ranking of Author Institutions"
histogram top_rank, title("Top US News Ranking of Articles") ///
	bgcolor(white) graphregion(color(white)) ///
	note("*Rank of 125 implies no author at top-100 ranked institution")
graph export ../output/ps_histo_authrank.eps, replace
graph export ../output/ps_histo_authrank.png, replace
replace top_rank=.a if top_rank==125 //.a is NOT RANKED

gen top1=.
replace top1=1 if top_rank==1
replace top1=0 if top_rank>1 & top_rank<.b
gen top10=.
replace top10=1 if (top_rank>1 & top_rank<=10)
replace top10=0 if top1==1 | (top_rank>10 & top_rank<.b)
gen top20=.
replace top20=1 if (top_rank>10 & top_rank<=20)
replace top20=0 if top1==1|top10==1|(top_rank>20 & top_rank<.b)
gen top50=.
replace top50=1 if (top_rank>20 & top_rank<=50)
replace top50=0 if top1==1|top10==1|top20==1|(top_rank>50 & top_rank<.b)
gen top100=.
replace top100=1 if (top_rank>50 & top_rank <=100)
replace top100=0 if top1==1|top10==1|top20==1|top50==1|(top_rank>100 & top_rank<.b)
gen unranked=.
replace unranked=1 if top_rank==.a
replace unranked=0 if top_rank<.
label var top10 "Top 10"
label var top20 "Top 20"

foreach X in 2010 2012{
graph bar top1 top10 top20 top50 top100 unranked, stack over(post`X') over(ajps)  legend(lab(1 "Top 1*") ///
	lab(2 "Top 10") ///
	lab(3 "Top 20") ///
	lab(4 "Top 50") ///
	lab(5 "Top 100") ///
	lab(6 "Unranked")) ///
	title("Institution Rankings by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/ps_rankXjournalXpost`X'.eps, replace
graph export ../output/ps_rankXjournalXpost`X'.png, replace
}

*****************************************************

***********************************************************
*REGRESSIONS
***********************************************************

*NAIVE
regress citation avail_yn
	outreg2 using ../output/naive.tex, dec(3) tex label replace addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label replace addtext(Sample, All) ///
	nocons drop(print_months_ago_cu print_months_ago_sq) addnote("Regressions include constant, squared and cubed months since publication.")
*regress citation avail_yn ajps 
*	outreg2 using ../output/naive.tex, tex label append
regress citation avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu ///
	if data_type!="no_data"
	outreg2 using ../output/naive.tex, dec(3) tex label append addtext(Sample, Data-Only)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label append addtext(Sample, Data-Only) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)

*NAIVE-LN
gen lncite=ln(citation+1)
label var lncite "Ln(Cites+1)"
regress lncite avail_yn
	outreg2 using ../output/naiveLN.tex, dec(3) tex label replace addtext(Sample, All)
	outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label replace addtext(Sample, All) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)
*regress lncite avail_yn ajps 
*	outreg2 using ../output/naiveLN.tex, tex label append
regress lncite avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
		outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
	outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn ajps print_months_ago	print_months_ago_sq print_months_ago_cu ///
	if data_type!="no_data"
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append addtext(Sample, Data-Only)
	outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append addtext(Sample, Data-Only) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)

*RUN NEGATIVE BINOMIAL HERE?
	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
*LEVEL
ivregress 2sls citation ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012), first

	outreg2 using ../output/ivreg.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All)
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All) drop(print_months_ago_cu print_months_ago_sq)

*INCLUDE INTERACTIONS
gen ajpsXpost2010Xdata=ajpsXpost2010*(data_type_2==0)
label var ajpsXpost2010Xdata "AJPS Post-2010 with Data"
gen ajpsXpost2012Xdata=ajpsXpost2012*(data_type_2==0)
label var ajpsXpost2012Xdata "AJPS Post-2012 with Data"				
gen post2010Xdata=post2010*(data_type_2==0)
label var post2010Xdata "Post-2010 with Data"
gen post2012Xdata=post2012*(data_type_2==0)
label var post2012Xdata "Post-2012 with Data"	
ivregress 2sls citation ajps post2010 post2012 post2010Xdata post2012Xdata ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = ajpsXpost2010Xdata ///
	ajpsXpost2012Xdata), first

	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)

ivregress 2sls citation ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first

	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons drop(print_months_ago_cu print_months_ago_sq)
		
		
*LOG		
ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012), first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)")
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)") ///
		drop(print_months_ago_cu print_months_ago_sq)
		
		
ivregress 2sls lncite ajps post2010 post2012 post2010Xdata post2012Xdata print_months_ago ///
	print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = ajpsXpost2010Xdata ///
	ajpsXpost2012Xdata), first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)
		
ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only)		
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only) drop(print_months_ago_cu print_months_ago_sq)
		
*MANUALLY DO THE IV
*FIRST STAGE
regress avail_yn ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu
	test ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F' ) ///
	nocons addtext(Sample, All)
	outreg2 using ../output/first.tex, dec(3) keep(ajpsXpost2010 ajpsXpost2012) tex label replace ctitle("First Stage") ///
	addstat(F Stat, `F') nocons addtext(Sample, All) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress avail_yn ajpsXpost2010Xdata ajpsXpost2012Xdata ajps post2010 post2012 post2010Xdata post2012Xdata ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2
	test ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/first.tex, dec(3) keep(ajpsXpost2010 ajpsXpost2012) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, IV=Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress avail_yn ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	test ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, Data-Only)
	outreg2 using ../output/first.tex, dec(3) keep(ajpsXpost2010 ajpsXpost2012) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/

	

predict avail_hat
*SECOND STAGE--DON'T TRUST THE STANDARD ERRORS!
regress citation avail_hat ajps post2010 post2012 ///
	print_months_ago print_months_ago_sq print_months_ago_cu year
**********************************************************
*TEST THE CHANGE IN TOPIC/TYPE/RANK USING THE MAIN SPECIFICATION
*********************************************************
regress topic_1 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
outreg2 using ../output/exclusion.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) ///
	/*drop(print_months_ago_cu print_months_ago_sq)*/ ///
	title("Exclusion Restriction")
	
regress topic_4 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress data_type_1 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress data_type_3 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress top10 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress top20 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/

*SAVE DATA AFTER ALL MERGES/NEW VARS
save ../external/cleaned/ps_mergedforregs.dta, replace

	
*TRY PRANAY'S DATA
*WAIT. IS IT WEB OF KNOWLEDGE? I THOUGHT IT WAS ELSEVEIR BUT CORRELATION IS 0.996!
save ../external/temp.dta, replace
/*
import delimited using ../external/citation_counts.csv, delimiter(",") clear
keep if journalname=="American Journal of Political Science"|journalname=="American Political Science Review"
drop if doi=="No DOI"
merge 1:1 doi using ../external/temp.dta
keep if _merge==3
gen lnciteE=ln(totalcitations)

ivregress 2sls lncite ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
ivregress 2sls lnciteE ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = ajpsXpost2010 ///
	ajpsXpost2012) if data_type!="no_data", first
*/
	
