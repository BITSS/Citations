set more off
clear all
label drop _all
cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"

***************************************************
*LOAD DATA
***************************************************
*LOAD MAIN MERGED DATA
insheet using ../external_econ/citations_clean_data.csv, clear names

*****************************************************
*DROP NON-REAL ARTICLES
******************************************************
*NOTES FROM THE EDITOR
drop if strpos(title,"Notes from the Editor")>0

*ERRATA (LEFT OVER FROM AJPS/APSR)
drop if strpos(title,"Errata to")>0 //0
drop if strpos(title,"ERRATUM")>0 //0
drop if strpos(title,"Erratum")>0 //0
drop if strpos(title,"CORRIGENDUM")>0 //0 

*R MISSING TO STATA MISSING
replace citation_count="." if citation_count=="NA"
destring citation_count, replace
summ citation_count

*GENERATE DATES
/*Is this print or Internet publication date? 
SEEMS LIKE PRINT DATE--ALL FIRST OF MONTH*/
gen date=date(publication_date,"YMD")
*MU YANG SCRAPED ELSEVIER 11/21/17
*PRANAY SCRAPED WoK BASICALLY THE SAME TIME
local scrapedate=date("2017-11-21","YMD")
gen print_months_ago=(`scrapedate'-date)/30.42
gen print_months_ago_sq=print_months_ago*print_months_ago
gen print_months_ago_cu=print_months_ago_sq*print_months_ago

gen avail_yn=(availability=="files")

gen year=substr(publication_date, 1, 4)
destring year, replace
drop if year>2009 //2001-2009 is what we said we'd cover

*LABEL DATA
label var year "Year"
label var print_months_ago "Months since Pub'd"
label var print_months_ago_sq "Months since Pub'd$^2$"
label var print_months_ago_cu "Months since Pub'd$^3$"
label var avail_yn "Data and Code Available" 

*****************************************************
save ../external/cleaned/econ_mergedforregs.dta, replace
tab journal
count
append using ../external/cleaned/ps_mergedforregs.dta
count
drop lncite
*institution (name) only exists for Econ--PS only brought in rank
*date vars
*COUNT looks OK, but vars are half-half often. Fill in!
*For graphing, create a BEFORE var (v1: 2005 for econ, 2010 for PS,
*v2: 2005 for econ, 2012 for PS)

gen discipline="econ" if journal=="aer"|journal=="qje"
replace discipline="ps" if journal=="apsr"|journal=="ajps"
gen aer=(journal=="aer")
replace ajps=(journal=="ajps")
gen apsr=(journal=="apsr")
gen econ=(discipline=="econ")
label var aer "AER"
label var ajps "AJPS"
label var apsr "APSR"

*Make one combined cite count var
replace citation=citation_count if citation==. & discipline=="econ"
label var citation "Cites"
drop citation_count

*GENERATE VARS AFTER APPEND SO THEY'RE FILLED FOR ALL OBS
*DROP PRE-EXISTING ONES FROM PS DATA
*post2005 post2010 post2012 aerXpost2005 ajpsXpost2010 ajpsXpost2012
drop post2010 post2012 ajpsXpost2010 ajpsXpost2012 avail_hat data_type_* ///
	top1 top5 top20 top50 top100 unranked post2010Xdata post2012Xdata ///
	ajpsXpost2010Xdata ajpsXpost2012Xdata

local Mar2005=date("2005-03-01","YMD")
gen post2005=(date>`Mar2005')
label var post2005 "Post-Mar 2005"
label drop _all
label define beforeafter 0 "Before" 1 "After"
label values post2005 beforeafter

gen aerXpost2005=aer*post2005
label var aerXpost2005 "AER post-2005 Policy"

local Oct2010=date("2010-10-01","YMD")
gen post2010=(print_date>`Oct2010')
label var post2010 "Post-Oct 2010"

local July2012=date("2012-07-01","YMD")
gen post2012=(print_date>`July2012')
label var post2012 "Post-July 2012"

gen ajpsXpost2010=ajps*post2010
label var ajpsXpost2010 "AJPS post-2010 Policy"
gen ajpsXpost2012=ajps*post2012
label var ajpsXpost2012 "AJPS post-2012 Policy"

foreach X in 10 12{
 gen after`X'=.
 label var after`X' "AFTER policy. Econ=2005, PS=20`X'"
 replace after`X'=0 if post2005==0
 replace after`X'=1 if econ==1 & post2005==1
 replace after`X'=0 if post20`X'==0 & econ==0
 replace after`X'=1 if post20`X'==1 & econ==0
}

********************************************************
*GRAPH SHARING OVER TIME--COMBINED
*******************************************************
/*
bysort year aer: egen avail_j_avg=mean(avail_yn)
label var avail_j_avg "Availability by Journal and Year"
gen aer_y_avg=avail_j_avg if aer==1
label var aer_y_avg "AER"
gen qje_y_avg=avail_j_avg if aer==0
label var qje_y_avg "QJE"
line aer_y_avg qje_y_avg year, title("Yearly Average Availability by Journal") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1)
graph export ../output/both_avail_time.eps, replace


*GRAPH AVAIL FOR ONLY DATA-HAVING ARTICLES
gen avail_yn_dataarticle=avail_yn if data_type!="no_data"
bysort year aer: egen avail_j_avg_dataarticle=mean(avail_yn_dataarticle)
label var avail_j_avg_dataarticle "Availability by Journal and Year, Data Articles Only"
gen aer_y_avg_dataarticle=avail_j_avg_dataarticle if aer==1
label var aer_y_avg_dataarticle "AER"
gen qje_y_avg_dataarticle=avail_j_avg_dataarticle if aer==0
label var qje_y_avg_dataarticle "QJE"
line aer_y_avg_dataarticle qje_y_avg_dataarticle year, title("Yearly Average Availability by Journal, Data Articles") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1)
graph export ../output/both_avail_time_dataarticle.eps, replace

****************************
*GRAPH CITATIONS--COMBINED
****************************
histogram citation, bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/both_cite_histo.eps, replace

bysort year aer: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen aer_y_citeavg=cite_j_avg if aer==1
label var aer_y_citeavg "AER"
gen qje_y_citeavg=cite_j_avg if aer==0
label var qje_y_citeavg "QJE"
line aer_y_citeavg qje_y_citeavg year, title("Yearly Average Citations by Journal") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/both_cite_time.eps, replace
*/

*GRAPH DATA TYPE-COMBINED
replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
label var data_type_1 "Experimental"
label var data_type_2 "No Data in Article" 
label var data_type_3 "Observational"
label var data_type_4 "Simulations"

/*
foreach X in 2005{
graph bar data_type_*, stack over(post`X') over(aer)  legend(lab(1 "Experimental") ///
	lab(2 "None") ///
	lab(3 "Observational") ///
	lab(4 "Simulations")) ///
	title("Data Type by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/both_typeXjournalXpost`X'.eps, replace
}
*/

*************************************
*GRAPH AUTHOR RANKING--MAYBE?
*************************************

label var top_rank "Top US News Ranking of Author Institutions"
histogram top_rank, title("Top US News Ranking of Articles, Econ & PS") ///
	bgcolor(white) graphregion(color(white)) ///
	note("*Rank of 125 implies no author at top-100 ranked institution")
graph export ../output/histo_authrank.eps, replace
replace top_rank=.a if top_rank==125 //.a is NOT RANKED

gen top1=.
replace top1=1 if top_rank==1
replace top1=0 if top_rank>1 & top_rank<.b
*STUPID FOR ECON, SINCE THERE ARE >5 #1s
gen top5=.
replace top5=1 if (top_rank>1 & top_rank<=5)
replace top5=0 if top1==1 | (top_rank>5 & top_rank<.b)
gen top10=.
replace top10=1 if (top_rank>1 & top_rank<=10)
replace top10=0 if top1==1|top5==1|(top_rank>10 & top_rank<.b)
gen top20=.
replace top20=1 if (top_rank>10 & top_rank<=20)
replace top20=0 if top1==1|top5==1|top10==1|(top_rank>20 & top_rank<.b)
gen top50=.
replace top50=1 if (top_rank>20 & top_rank<=50)
replace top50=0 if top1==1|top5==1|top10==1|top20==1|(top_rank>50 & top_rank<.b)
gen top100=.
replace top100=1 if (top_rank>50 & top_rank <=100)
replace top100=0 if top1==1|top5==1|top10==1|top20==1|top50==1|(top_rank>100 & top_rank<.b)
gen unranked=.
replace unranked=1 if top_rank==.a
replace unranked=0 if top_rank<.
label var top5 "Top 5"
label var top10 "Top 10"
label var top20 "Top 20"
label var top50 "Top 50"

/*
foreach X in 2005{
graph bar top1 top5 top20 top50 top100 unranked, stack over(post`X') over(aer)  legend(lab(1 "Top 1") ///
	lab(2 "Top 5") ///
	lab(3 "Top 20") ///
	lab(4 "Top 50") ///
	lab(5 "Top 100") ///
	lab(6 "Unranked")) ///
	title("Institution Rankings by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/both_rankXjournalXpost`X'.eps, replace
}
*/
***********************************************************
*REGRESSIONS
***********************************************************

*NAIVE
regress citation avail_yn
	outreg2 using ../output/both_naive.tex, dec(3) tex label replace addtext(Sample, All)
	outreg2 using ../output/both_naive-simp.tex, dec(3) tex label replace addtext(Sample, All) ///
	nocons drop(print_months_ago_cu print_months_ago_sq) addnote("Regressions include constant, squared and cubed months since publication.")
*regress citation avail_yn aer 
*	outreg2 using ../output/both_naive.tex, tex label append
regress citation avail_yn aer ajps apsr print_months_ago print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/both_naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/both_naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn aer ajps apsr print_months_ago print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/both_naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/both_naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn aer ajps apsr print_months_ago print_months_ago_sq print_months_ago_cu ///
	if data_type!="no_data"
	outreg2 using ../output/both_naive.tex, dec(3) tex label append addtext(Sample, Data-Only)
	outreg2 using ../output/both_naive-simp.tex, dec(3) tex label append addtext(Sample, Data-Only) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)

*NAIVE-LN
gen lncite=ln(citation+1)
label var lncite "Ln(Cites+1)"
regress lncite avail_yn
	outreg2 using ../output/both_naiveLN.tex, dec(3) tex label replace addtext(Sample, All)
	outreg2 using ../output/both_naiveLN-simp.tex, dec(3) tex label replace addtext(Sample, All) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)
*regress lncite avail_yn aer 
*	outreg2 using ../output/both_naiveLN.tex, tex label append
regress lncite avail_yn aer ajps apsr print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/both_naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
		outreg2 using ../output/both_naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn aer ajps apsr print_months_ago	print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/both_naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
	outreg2 using ../output/both_naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn aer ajps apsr print_months_ago	print_months_ago_sq print_months_ago_cu ///
	if data_type!="no_data"
	outreg2 using ../output/both_naiveLN.tex, dec(3) tex label append addtext(Sample, Data-Only)
	outreg2 using ../output/both_naiveLN-simp.tex, dec(3) tex label append addtext(Sample, Data-Only) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)

	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
*LEVEL
ivregress 2sls citation aer ajps apsr post2005 post2010 post2012  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ajpsXpost2010 ajpsXpost2012), first

	outreg2 using ../output/both_ivreg.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All) drop(print_months_ago_cu print_months_ago_sq)
	outreg2 using ../output/both_ivreg-simp.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All) drop(print_months_ago_cu print_months_ago_sq post2005 post2010 post2012)

*INCLUDE INTERACTIONS
gen aerXpost2005Xdata=aerXpost2005*(data_type_2==0)
label var aerXpost2005Xdata "AER Post-2005 with Data"				
gen post2005Xdata=post2005*(data_type_2==0)
label var post2005Xdata "Post-2005 with Data"
gen ajpsXpost2010Xdata=ajpsXpost2010*(data_type_2==0)
label var ajpsXpost2010Xdata "AJPS Post-2010 with Data"				
gen post2010Xdata=post2010*(data_type_2==0)
label var post2010Xdata "Post-2010 with Data"
gen ajpsXpost2012Xdata=ajpsXpost2012*(data_type_2==0)
label var ajpsXpost2012Xdata "AJPS Post-2012 with Data"				
gen post2012Xdata=post2012*(data_type_2==0)
label var post2012Xdata "Post-2012 with Data"
	
ivregress 2sls citation aer ajps apsr post2005 post2005Xdata ///
	post2010 post2010Xdata post2012 post2012Xdata ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata), ///
	first

	outreg2 using ../output/both_ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)
	outreg2 using ../output/both_ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq post2005 post2005Xdata post2010 post2010Xdata post2012 post2012Xdata)

ivregress 2sls citation aer ajps apsr post2005 post2010 post2012  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ajpsXpost2010 ajpsXpost2012) ///
    if data_type!="no_data", first

	outreg2 using ../output/both_ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons drop(print_months_ago_cu print_months_ago_sq)
	outreg2 using ../output/both_ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons drop(print_months_ago_cu print_months_ago_sq post2005 post2005Xdata post2010 post2010Xdata post2012 post2012Xdata)

		
*LOG		
ivregress 2sls lncite aer ajps apsr post2005 post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ajpsXpost2010 ajpsXpost2012), first
	outreg2 using ../output/both_ivregLN.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)") ///
		drop(print_months_ago_cu print_months_ago_sq)
	outreg2 using ../output/both_ivregLN-simp.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)") ///
		drop(print_months_ago_cu print_months_ago_sq post2005 post2010 post2012)
		
		
ivregress 2sls lncite aer ajps apsr post2005 post2010 post2012  post2005Xdata post2010Xdata post2012Xdata print_months_ago ///
	print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata), first
	outreg2 using ../output/both_ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)
	outreg2 using ../output/both_ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq post2005 post2010 post2012  post2005Xdata post2010Xdata post2012Xdata)
		
ivregress 2sls lncite aer ajps apsr post2005 post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ajpsXpost2010 ajpsXpost2012) if data_type!="no_data", first
	outreg2 using ../output/both_ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only) drop(print_months_ago_cu print_months_ago_sq)	
	outreg2 using ../output/both_ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only) drop(print_months_ago_cu print_months_ago_sq post2005 post2010 post2012)
		
*MANUALLY DO THE IV
*FIRST STAGE
regress avail_yn aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu
	test aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	*outreg2 using ../output/both_ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first.tex, dec(3) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label replace ctitle("First Stage") ///
	addstat(F Stat, `F') nocons addtext(Sample, All) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress avail_yn aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata aer ajps apsr post2005 post2010 post2012 post2005Xdata post2010Xdata post2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012 ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2
	test aerXpost2005Xdata=ajpsXpost2010Xdata=ajpsXpost2012Xdata=0
	local F=r(F)
	*outreg2 using ../output/both_ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	*nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/both_first.tex, dec(3) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, IV=Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress avail_yn aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	test aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	*outreg2 using ../output/both_ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	*nocons addtext(Sample, Data-Only)
	outreg2 using ../output/both_first.tex, dec(3) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/


predict avail_hat
*SECOND STAGE--DON'T TRUST THE STANDARD ERRORS!
regress citation avail_hat aer ajps apsr post2005 post2010 post2012 ///
	print_months_ago print_months_ago_sq print_months_ago_cu year
**********************************************************
*TEST THE CHANGE IN TOPIC/TYPE/RANK USING THE MAIN SPECIFICATION
*********************************************************
/*TOPICS DON'T COMBINE ACROSS DISCIPLINE
regress topic_1 aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
outreg2 using ../output/both_exclusion.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005) ///
	/*drop(print_months_ago_cu print_months_ago_sq)*/ ///
	title("Exclusion Restriction")
	
regress topic_4 aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005) /*drop(print_months_ago_cu print_months_ago_sq)*/
IF YOU FIX THIS FIX APPEND REPLACE*/
regress data_type_1 aerXpost2005 post2005 aer ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress data_type_3 aerXpost2005 post2005 aer ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress top10 aerXpost2005 post2005 aer ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress top20 aerXpost2005  post2005 aer ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress top50 aerXpost2005  post2005 aer ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/both_exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(print_months_ago_cu print_months_ago_sq)*/

