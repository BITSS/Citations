set more off
clear all
cd "\\Client\C$\Users\snake\Box\URAPshared\Data\Econ_data"

***************************************************
*LOAD DATA
***************************************************
*LOAD MAIN MERGED DATA
insheet using external/citations_clean_data.csv, clear names

*****************************************************
*DROP NON-REAL ARTICLES
******************************************************
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

*GENERATE DATES
gen date=date(publication_date,"YMD")
local scrapedate=date("2017-05-15","YMD")
gen months_ago=(`scrapedate'-date)/30.42
gen months_ago_sq=months_ago*months_ago
gen months_ago_cu=months_ago_sq*months_ago

gen avail_yn=(availability=="files")
gen aer=(journal=="aer")

local Mar2005=date("2005-03-01","YMD")
gen post2005=(print_date>`Oct2005')

gen aerXpost2005=aer*post2005
label var aerXpost2005 "aer post-2005 Policy"

gen year=substr(publication_date_print, 1, 4)
destring year, replace
drop if year>2009 //2001-2009 is what we said we'd cover

*LABEL DATA
label var year "Year"
label var citation "Citations"
label var print_months_ago "Months since Pub'd"
label var print_months_ago_sq "Months since Pub'd$^2$"
label var print_months_ago_cu "Months since Pub'd$^3$"
label var aer "aer"
label var post2005 "Post-Mar 2005"
label define beforeafter 0 "Before" 1 "After"
label values post2005 beforeafter
label var avail_yn "Data and Code Available" 

*****************************************************
save ../external/cleaned/mergedforregs.dta, replace

********************************************************
*GRAPH SHARING OVER TIME
*******************************************************

bysort year aer: egen avail_j_avg=mean(avail_yn)
label var avail_j_avg "Availability by Journal and Year"
gen aer_y_avg=avail_j_avg if aer==1
label var aer_y_avg "AER"
gen qje
_y_avg=avail_j_avg if aer==0
label var qje_y_avg "QJE"
line aer_y_avg qje_y_avg year, title("Yearly Average Availability by Journal") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1)
graph export ../output/avail_time.eps, replace

****************************
*GRAPH CITATIONS
****************************
histogram citation, bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/cite_histo.eps, replace

bysort year aer: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen aer_y_citeavg=cite_j_avg if aer==1
label var aer_y_citeavg "aer"
gen qje_y_citeavg=cite_j_avg if aer==0
label var qje_y_citeavg "qje"
line aer_y_citeavg qje_y_citeavg year, title("Yearly Average Citations by Journal") ///
	bgcolor(white) graphregion(color(white))

graph export ../output/cite_time.eps, replace

***COME BACK TO THIS***
*********************************************************
*GRAPH TOPIC AND TYPE
*****************************************************
/*replace topic="" if topic=="skip"
tab topic, generate(topic_)
label var topic_1 "American"
label var topic_2 "Comparative"
label var topic_3 "Int'l Relations"
label var topic_4 "Methodology"
label var topic_5 "Theory"
label define journal 0 "qje" 1 "aer"
label values aer journal
graph bar topic_*, stack over(aer) legend(lab(1 "American") ///
									lab(2 "Comparative") ///
									lab(3 "Int'l Relations") ///
									lab(4 "Methodology") ///
									lab(5 "Theory"))
graph export ../output/topicXjournal.eps, replace

* check range of dates?
foreach X in 2005 2009{
graph bar topic_*, stack over(post`X') over(aer)  legend(lab(1 "American") ///
	lab(2 "Comparative") ///
	lab(3 "Int'l Relations") ///
	lab(4 "Methodology") ///
	lab(5 "Theory")) ///
	title("Article Topic by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/topicXjournalXpost`X'.eps, replace
}

replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
label var data_type_1 "Experimental"
label var data_type_2 "No Data in Article" 
label var data_type_3 "Observational"
label var data_type_4 "Simulations"

* check range of dates?
foreach X in 2005 2009{
graph bar data_type_*, stack over(post`X') over(aer)  legend(lab(1 "Experimental") ///
	lab(2 "None") ///
	lab(3 "Observational") ///
	lab(4 "Simulations")) ///
	title("Data Type by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/typeXjournalXpost`X'.eps, replace
}
*/

*************************************
*GRAPH AUTHOR RANKING
*************************************
count
merge 1:1 doi using ../external/article_author_top_rank.dta
drop if _merge==2 //Contains a few 2015 articles, editorials, and erratum
*AS OF 6/21/2017 THE qje CENTENNIAL AND ~10 OTHERS AREN'T IN THIS DATASET
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
graph export ../output/histo_authrank.eps, replace
replace top_rank=.a if top_rank==125 //.a is NOT RANKED

gen top1=.
replace top1=1 if top_rank==1
replace top1=0 if top_rank>1 & top_rank<.b
gen top5=.
replace top5=1 if (top_rank>1 & top_rank<=5)
replace top5=0 if top1==1 | (top_rank>5 & top_rank<.b)
gen top20=.
replace top20=1 if (top_rank>5 & top_rank<=20)
replace top20=0 if top1==1|top5==1|(top_rank>20 & top_rank<.b)
gen top50=.
replace top50=1 if (top_rank>20 & top_rank<=50)
replace top50=0 if top1==1|top5==1|top20==1|(top_rank>50 & top_rank<.b)
gen top100=.
replace top100=1 if (top_rank>50 & top_rank <=100)
replace top100=0 if top1==1|top5==1|top20==1|top50==1|(top_rank>100 & top_rank<.b)
gen unranked=.
replace unranked=1 if top_rank==.a
replace unranked=0 if top_rank<.
label var top5 "Top 5"
label var top20 "Top 20"

* check range of dates
foreach X in 2005 2009{
graph bar top1 top5 top20 top50 top100 unranked, stack over(post`X') over(aer)  legend(lab(1 "Top 1") ///
	lab(2 "Top 5") ///
	lab(3 "Top 20") ///
	lab(4 "Top 50") ///
	lab(5 "Top 100") ///
	lab(6 "Unranked")) ///
	title("Institution Rankings by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/rankXjournalXpost`X'.eps, replace
}

***********************************************************
*REGRESSIONS
***********************************************************

*NAIVE
regress citation avail_yn
	outreg2 using ../output/naive.tex, dec(3) tex label replace addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label replace addtext(Sample, All) ///
	nocons drop(print_months_ago_cu print_months_ago_sq) addnote("Regressions include constant, squared and cubed months since publication.")
*regress citation avail_yn aer 
*	outreg2 using ../output/naive.tex, tex label append
regress citation avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/naive.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All)
	outreg2 using ../output/naive-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress citation avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu ///
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
*regress lncite avail_yn aer 
*	outreg2 using ../output/naiveLN.tex, tex label append
regress lncite avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
		outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu ///
	data_type_2
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append title("Naive Log OLS Regression") ///
		addtext(Sample, All)
	outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addtext(Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
regress lncite avail_yn aer print_months_ago	print_months_ago_sq print_months_ago_cu ///
	if data_type!="no_data"
	outreg2 using ../output/naiveLN.tex, dec(3) tex label append addtext(Sample, Data-Only)
	outreg2 using ../output/naiveLN-simp.tex, dec(3) tex label append addtext(Sample, Data-Only) ///
	nocons drop(print_months_ago_cu print_months_ago_sq)

	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
*LEVEL
ivregress 2sls citation aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ///
	aerX), first

	outreg2 using ../output/ivreg.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All)
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		nocons addtext(Sample, All) drop(print_months_ago_cu print_months_ago_sq)

*INCLUDE INTERACTIONS
gen aerXpost2005Xdata=aerXpost2005*(data_type_2==0)
label var aerXpost2005Xdata "aer Post-2005 with Data"
gen aerXXdata=aerX*(data_type_2==0)
label var aerXXdata "aer Post-2012 with Data"				
gen post2005Xdata=post2005*(data_type_2==0)
label var post2005Xdata "Post-2005 with Data"
gen Xdata=*(data_type_2==0)
label var Xdata "Post-2012 with Data"	
ivregress 2sls citation aer post2005  post2005Xdata Xdata ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = aerXpost2005Xdata ///
	aerXXdata), first

	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)

ivregress 2sls citation aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ///
	aerX) if data_type!="no_data", first

	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons
	outreg2 using ../output/ivreg-simp.tex, dec(3) tex label append ctitle("2SLS") ///
		addtext(Sample, Data-Only) nocons drop(print_months_ago_cu print_months_ago_sq)
		
		
*LOG		
ivregress 2sls lncite aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ///
	aerX), first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)")
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label replace ctitle("2SLS-Log") ///
		nocons addtext(Sample, All) title("2SLS Regression of ln(citations+1)") ///
		drop(print_months_ago_cu print_months_ago_sq)
		
		
ivregress 2sls lncite aer post2005  post2005Xdata Xdata print_months_ago ///
	print_months_ago_sq print_months_ago_cu data_type_2 (avail_yn = aerXpost2005Xdata ///
	aerXXdata), first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)
		
ivregress 2sls lncite aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu (avail_yn = aerXpost2005 ///
	aerX) if data_type!="no_data", first
	outreg2 using ../output/ivregLN.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only)		
	outreg2 using ../output/ivregLN-simp.tex, dec(3) tex label append ctitle("2SLS-Log") ///
		nocons addtext(Sample, Data-Only) drop(print_months_ago_cu print_months_ago_sq)
		
*MANUALLY DO THE IV
*FIRST STAGE
regress avail_yn aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu
	test aerXpost2005=aerX=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F' ) ///
	nocons addtext(Sample, All)
	outreg2 using ../output/first.tex, dec(3) keep(aerXpost2005 aerX) tex label replace ctitle("First Stage") ///
	addstat(F Stat, `F') nocons addtext(Sample, All) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress avail_yn aerXpost2005Xdata aerXXdata aer post2005  post2005Xdata Xdata ///
	print_months_ago print_months_ago_sq print_months_ago_cu data_type_2
	test aerXpost2005=aerX=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, IV=Data-Only)
	outreg2 using ../output/first.tex, dec(3) keep(aerXpost2005 aerX) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, IV=Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress avail_yn aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	test aerXpost2005=aerX=0
	local F=r(F)
	outreg2 using ../output/ivreg.tex, dec(3) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, Data-Only)
	outreg2 using ../output/first.tex, dec(3) keep(aerXpost2005 aerX) tex label append ctitle("First Stage") addstat(F Stat, `F') ///
	nocons addtext(Sample, Data-Only) /*drop(print_months_ago_cu print_months_ago_sq)*/


predict avail_hat
*SECOND STAGE--DON'T TRUST THE STANDARD ERRORS!
regress citation avail_hat aer post2005  ///
	print_months_ago print_months_ago_sq print_months_ago_cu year
**********************************************************
*TEST THE CHANGE IN TOPIC/TYPE/RANK USING THE MAIN SPECIFICATION
*********************************************************
regress topic_1 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
outreg2 using ../output/exclusion.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) ///
	/*drop(print_months_ago_cu print_months_ago_sq)*/ ///
	title("Exclusion Restriction")
	
regress topic_4 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress data_type_1 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress data_type_3 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) /*drop(print_months_ago_cu print_months_ago_sq)*/

regress top5 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) /*drop(print_months_ago_cu print_months_ago_sq)*/
	
regress top20 aerXpost2005 aerX aer post2005  print_months_ago ///
	print_months_ago_sq print_months_ago_cu if data_type_2==0
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005 aerX) /*drop(print_months_ago_cu print_months_ago_sq)*/

