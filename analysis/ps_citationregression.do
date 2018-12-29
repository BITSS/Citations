set more off
clear all
cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"
cap log close
log using ../logs/ps_citationregression.log, replace

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

***************************************************************
*CREATE MAIN SAMPLE VARIABLE BEFORE ANY ANALYSIS.
*USE THIS AS AN IF BEFORE nearly ALL analysis!
gen mainsample=1 if data_type!="no_data" & apsr_centennial_issue!="TRUE"
label var mainsample "Regular Data Articles"
***************************************************************

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

gen ajps=(journal=="ajps")

local Oct2010=date("2010-10-01","YMD")
gen post2010=(print_date>`Oct2010')

local July2012=date("2012-07-01","YMD")
gen post2012=(print_date>`July2012')

replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
label var data_type_1 "Experimental"
label var data_type_2 "No Data in Article" 
label var data_type_3 "Observational"
label var data_type_4 "Simulations"

*GENERATE INTERACTIONS
gen ajpsXdata=ajps*(data_type_2==0)
label var ajpsXdata "AJPS with Data"
gen ajpsXpost2010=ajps*post2010
label var ajpsXpost2010 "AJPS post-2010 Policy"
gen ajpsXpost2012=ajps*post2012
label var ajpsXpost2012 "AJPS post-2012 Policy"

gen ajpsXpost2010Xdata=ajpsXpost2010*(data_type_2==0)
label var ajpsXpost2010Xdata "AJPS Post-2010 with Data"
gen ajpsXpost2012Xdata=ajpsXpost2012*(data_type_2==0)
label var ajpsXpost2012Xdata "AJPS Post-2012 with Data"				
gen post2010Xdata=post2010*(data_type_2==0)
label var post2010Xdata "Post-2010 with Data"
gen post2012Xdata=post2012*(data_type_2==0)
label var post2012Xdata "Post-2012 with Data"	

gen year=substr(publication_date_print, 1, 4)
destring year, replace
drop if year>2014 //2006-2014 is what we said we'd cover

************************
*CORRECTIONS FROM THE RANDOM SPOTCHECK
*Jacqui
*said files but actually 0
replace availability_website="0" if title=="Mutual Optimism as a Rationalist Explanation of War" &  doi=="10.1111/j.1540-5907.2010.00475.x"
replace availability="0" if title=="Mutual Optimism as a Rationalist Explanation of War" &  doi=="10.1111/j.1540-5907.2010.00475.x"

*Mu Yang
* there are data files on the author website
replace availability = "data" if title == "Can Institutions Build Unity in Multiethnic States?" & doi == "10.1017/S0003055407070505"
replace availability_website = "data" if title == "Can Institutions Build Unity in Multiethnic States?" & doi == "10.1017/S0003055407070505"

* the link on the author website is dead, but I could google and locate the file
replace availability = "files" if title == "How Large and Long-lasting Are the Persuasive Effects of Televised Campaign Ads? Results from a Randomized Field Experiment" & doi == "10.1017/S000305541000047X"
replace availability_website="files" if title == "How Large and Long-lasting Are the Persuasive Effects of Televised Campaign Ads? Results from a Randomized Field Experiment" & doi == "10.1017/S000305541000047X"

* not observational
replace data_type = "experimental" if title == "The Impact of Ballot Type on Voter Errors" & doi == "10.1111/j.1540-5907.2011.00579.x"

* uses observational data
replace data_type = "observational" if title == "Transformations of the Concept of Ideology in the Twentieth Century" & doi == "10.1017/S0003055406062502"

*Don
* dataverse only has data, not code
replace availability_dataverse="data" if title=="Mapping the Ideological Marketplace" &  doi=="10.1111/ajps.12062"
replace availability="data" if title=="Mapping the Ideological Marketplace" &  doi=="10.1111/ajps.12062"

*Kai
* found data and codes on author’s website
replace availability = "files" if title == "Electoral Institutions and the Politics of Coalitions: Why Some Democracies Redistribute More Than Others" & doi == "10.1017/S0003055406062083"
replace availability_website = "files" if title == "Electoral Institutions and the Politics of Coalitions: Why Some Democracies Redistribute More Than Others" & doi == "10.1017/S0003055406062083"
***********************
gen avail_yn=(availability=="files")
gen avail_data=(availability=="files"|availability=="data")


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

*CREATE STATED/PARTIAL AVAILABILITY
foreach var in reference_code_partial_strict reference_code_partial_easy reference_data_partial_strict reference_data_partial_easy reference_files_partial_strict reference_files_partial_easy reference_code_full_strict reference_code_full_easy reference_data_full_strict reference_data_full_easy reference_files_full_strict reference_files_full_easy{
	replace `var'="." if `var'=="NA"
	destring `var', replace
}
gen avail_state_full=(reference_data_full_strict==1| reference_data_full_easy==1| reference_files_full_strict==1| reference_files_full_easy==1)
gen avail_state_part=(avail_state_full==1)|(reference_code_partial_strict==1| reference_code_partial_easy==1| reference_data_partial_strict==1| reference_data_partial_easy==1| reference_files_partial_strict==1| reference_files_partial_easy==1)
label var avail_state_full "Stated Availability" 
label var avail_state_part "Stated Availability:Part"

********************************************************
*GRAPH SHARING OVER TIME
*******************************************************
foreach data in yn data /*state_full state_part*/{
if "`data'"=="yn" local t="Data & Code"
if "`data'"=="data" local t="Data"

bysort year ajps: egen avail_j_avg`data'=mean(avail_`data')
label var avail_j_avg`data' "Availability by Journal and Year"
gen ajps_y_avg`data'=avail_j_avg`data' if ajps==1
label var ajps_y_avg`data' "AJPS"
gen apsr_y_avg`data'=avail_j_avg`data' if ajps==0
label var apsr_y_avg`data' "APSR"
line ajps_y_avg`data' apsr_y_avg`data' year, title("`t' Availability by Journal") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1) xline(2010 2012) lpattern(solid dash)
graph save ../output/ps_avail`data'_time_all.gph, replace
graph export ../output/ps_avail`data'_time_all.eps, replace
graph export ../output/ps_avail`data'_time_all.png, replace

*GRAPH AVAIL FOR ONLY DATA-HAVING ARTICLES
gen avail_`data'_dataarticle=avail_`data' if data_type!="no_data"
bysort year ajps: egen avail_j_avg_dataarticle`data'=mean(avail_`data'_dataarticle)
label var avail_j_avg_dataarticle`data' "Availability by Journal and Year, Data Articles Only"
gen ajps_y_avg_dataarticle`data'=avail_j_avg_dataarticle`data' if ajps==1
label var ajps_y_avg_dataarticle`data' "AJPS"
gen apsr_y_avg_dataarticle`data'=avail_j_avg_dataarticle`data' if ajps==0
label var apsr_y_avg_dataarticle`data' "APSR"
line ajps_y_avg_dataarticle`data' apsr_y_avg_dataarticle`data' year, title("(B) `t' Availability by Journal, Data Articles") ///
	bgcolor(white) graphregion(color(white)) ///
	ylabel(0 0.2 0.4 0.6 0.8 1) xline(2010 2012) lpattern(solid dash)
graph save ../output/ps_avail`data'_time_dataarticle.gph, replace
graph export ../output/ps_avail`data'_time_dataarticle.eps, replace
graph export ../output/ps_avail`data'_time_dataarticle.png, replace

} // end loop of data and code vs. just data



*COULD DO FIGURE WITH ONLY DATA ARTICLES--CLOSE TO 100%?
*MAKE ONE LINE DASHED FOR B&W READERS?
****************************
*GRAPH CITATIONS
****************************
*FIRST, BRING IN MU YANG'S ELSEVIER API DATA
save ../external/temp.dta, replace
import delimited using ../external/ajps_citations_scopus.csv, delimiter(",") clear
save ../external/ajps_citations_scopus.dta, replace
import delimited using ../external/apsr_citations_scopus.csv, delimiter(",") clear
save ../external/apsr_citations_scopus.dta, replace
append using ../external/ajps_citations_scopus.dta
*APSR Centennial is duplicated, so don't need to include separately.
keep doi citation
rename citation citationE
merge 1:1 doi using ../external/temp
*Elsevier Scraping has cites for articles we don't have. 126 of them. Drop those.
count if _merge==1
if r(N)!=126 flip the heck out!
drop if _merge==1 
rename _merge merge_Scopus


	
label var citationE "Scopus Citations"
label var citation "Web of Knowledge Citations"
rename citation WoK
rename citationE Scopus
*scatter citation citationE || lfit citation citationE, title("Comparison of Citation Data") ///
*	bgcolor(white) graphregion(color(white)) legend(off) ytitle("Web of Knowledge Citations")
*aaplot WoK Scopus, aformat(%3.2f) bformat(%3.2f) bgcolor(white) graphregion(color(white))
*graph export ../output/ps_citationcomparison.eps, replace
*graph export ../output/ps_citationcomparison.png, replace

*APRIL 18, 2018
*CHANGE MAIN CITATION VARIABLE TO SCOPUS
*CHANGE SCRAPE DATE TO MU YANG'S ACTUAL DATE: 11/21/17
rename Scopus citation
label var citation "Citations"
gen lncitation=ln(citation+1)

*BRING IN THIRD CITATION MEASURE--PRANAY. PRANAY did WoK API, better than Evey's code. Mu Yang did Elsevier Scopus API.
*PRANAY ALSO HAS THE YEAR BY YEAR CITATION NUMBERS
*TRY PRANAY'S DATA
save ../external/temp.dta, replace
import delimited using ../external/citation_counts.csv, delimiter(",") clear
keep if journalname=="American Journal of Political Science"|journalname=="American Political Science Review"
drop if doi=="No DOI"
merge 1:1 doi using ../external/temp.dta
keep if _merge!=1
rename _merge merge_WoK_Pranay
rename totalcitations wokcitation
label var wokcitation "Citations Web of Knowledge"
gen lnwokcitation=ln(wokcitation+1)
label var lnwokcitation "Log Citations Web of Knowledge"
rename citations _2001citation
label var _2001citation "2001 WoK Citations"
forvalues X=10/26 {
 local Y=`X'+1992
 rename v`X' _`Y'citation
 label var _`Y'citation "`Y' WoK Citations"
}

*GENERATE CITATION FLOW VARIABLES
forvalues Y=0/5 {
	gen year`Y'citation=.
	label var year`Y'citation "Citations `Y' years after publication"
	forvalues X=2006/`=2017-`Y'' {
		replace year`Y'citation=_`=`X'+`Y''citation if year==`X'
	}
}
gen cum3citation=year0citation+year1citation+year2citation+year3citation
label var cum3citation "Cumulative Citations after 3 years"
gen cum5citation=year0citation+year1citation+year2citation+year3citation+year4citation+year5citation
label var cum5citation "Cumulative Citations after 5 years"

*CITATION HISTOGRAMS
*ALL
histogram citation if citation<500, bgcolor(white) graphregion(color(white)) title("Density of Citations, Political Science") ///
	subtitle("All Articles")
graph export ../output/ps_cite_histo_all.eps, replace
graph export ../output/ps_cite_histo_all.png, replace
graph save ../output/ps_cite_histo_all.gph, replace

gen citation_year=citation/(print_months_ago/12)
label var citation_year "Citations per Year"
histogram citation_year if citation<500, bgcolor(white) graphregion(color(white)) title("Density of Citations per Year, Political Science") ///
		subtitle("All Articles")
graph export ../output/ps_cite_histo_year_all.eps, replace
graph export ../output/ps_cite_histo_year_all.png, replace
graph save ../output/ps_cite_histo_year_all.gph, replace

*MAINSAMPLE
histogram citation if citation<500 &mainsample==1, bgcolor(white) graphregion(color(white)) title("Density of Citations, Political Science")
graph export ../output/ps_cite_histo.eps, replace
graph export ../output/ps_cite_histo.png, replace
graph save ../output/ps_cite_histo.gph, replace

label var citation_year "Citations per Year"
histogram citation_year if citation<500 & mainsample==1, bgcolor(white) graphregion(color(white)) title("Density of Citations per Year, Political Science")
graph export ../output/ps_cite_histo_year.eps, replace
graph export ../output/ps_cite_histo_year.png, replace
graph save ../output/ps_cite_histo_year.gph, replace


bysort year ajps: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen ajps_y_citeavg=cite_j_avg if ajps==1
label var ajps_y_citeavg "AJPS"
gen apsr_y_citeavg=cite_j_avg if ajps==0
label var apsr_y_citeavg "APSR"
line ajps_y_citeavg apsr_y_citeavg year, title("Total Citations by Journal") ///
	bgcolor(white) graphregion(color(white)) lpattern(solid dash)
graph export ../output/ps_cite_time.png, replace
graph export ../output/ps_cite_time.eps, replace


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
*May 2018? What did I mean here? Why would I want to do this?

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
replace top1=1 if top_rank<=6
replace top1=0 if top_rank>6 & top_rank<.b
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
label var top1 "Top 6"
label var top10 "Top 10"
label var top20 "Top 20"
label var top50 "Top 50"

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
foreach data in yn data state_full state_part{
foreach time in "print_months_ago print_months_ago_sq print_months_ago_cu" "i.year" {
if "`time'"=="print_months_ago print_months_ago_sq print_months_ago_cu" local t="months"
if "`time'"=="i.year#ps" local t="FE"

*NAIVE
foreach ln in "" ln wok lnwok {
regress `ln'citation avail_`data'
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label replace addtext(Months since Publication, None, Sample, All) addstat(Mean Dep. Var., `depvarmean')
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label replace addtext(Months since Publication, None, Sample, All) addstat(Mean Dep. Var., `depvarmean') ///
	nocons drop(print_months_ago_cu print_months_ago_sq) addnote("Regressions include constant, squared and cubed months since publication.") 
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label replace addtext(Year-Discipline FE, No, Sample, All) addstat(Mean Dep. Var., `depvarmean')
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label replace addtext(Year-Discipline FE, No, Sample, All) addstat(Mean Dep. Var., `depvarmean') ///
	nocons addnote("Regressions include constant, squared and cubed months since publication.")
	}
*regress citation avail_yn ajps 
*	outreg2 using ../output/ps_naive.tex, tex label append
regress `ln'citation avail_`data' ajps `time'
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All) nocons drop(print_months_ago_cu print_months_ago_sq)
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All) nocons
	}
regress `ln'citation avail_`data' ajps `time' data_type_2
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All) nocons keep(avail_`data' ajps data_type_2)
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append title("Naive OLS Regression") ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All) nocons keep(avail_`data' ajps data_type_2)
	}
regress `ln'citation avail_`data' ajps `time' if data_type!="no_data"
	summ `ln'citation avail_`data'
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append addtext(Months since Publication, Cubic, Sample, Data-Only) addstat(Mean Dep. Var., `depvarmean')
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append addtext(Months since Publication, Cubic, Sample, Data-Only) addstat(Mean Dep. Var., `depvarmean') ///
	nocons keep(avail_`data' ajps data_type_2)
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_naive`ln'_`data'_`t'.tex, dec(3) tex label append addtext(Year-Discipline FE, Yes, Sample, Data-Only) addstat(Mean Dep. Var., `depvarmean')
	outreg2 using ../output/ps_naive`ln'-simp_`data'_`t'.tex, dec(3) tex label append addtext(Year-Discipline FE, Yes, Sample, Data-Only) addstat(Mean Dep. Var., `depvarmean') ///
	nocons keep(avail_`data' ajps data_type_2)
	}
	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
*LEVEL
ivreg2 `ln'citation ajps post2010 post2012 `time' (avail_`data' = ajpsXpost2010 ajpsXpost2012), first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	local F=e(widstat)
	if "`t'"=="months" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label replace ctitle("2SLS `ln'") title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label replace ctitle("2SLS `ln'") title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, All) drop(print_months_ago_cu print_months_ago_sq)
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/ps_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, All) nocons keep(avail_`data' ajpsXpost2010)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label replace ctitle("2SLS") title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, All)
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/ps_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, All) nocons keep(avail_`data' ajpsXpost2010) 	
	}
*INCLUDE INTERACTIONS
ivreg2 `ln'citation ajps post2010 post2012 ajpsXdata post2010Xdata post2012Xdata `time' data_type_2 (avail_`data' = ajpsXpost2010 ajpsXpost2012 ajpsXpost2010Xdata ajpsXpost2012Xdata), ///
	first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	local F=e(widstat)
	if "`t'"=="months" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, IV=Data-Only)
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, IV=Data-Only) drop(print_months_ago_cu print_months_ago_sq)
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/ps_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-Only) nocons keep(avail_`data' ajpsXpost2010 ajpsXpost2010Xdata ajpsXpost2012 ajpsXpost2012Xdata)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only)
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only)
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/e_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only) nocons keep(avail_`data' ajpsXpost2010 ajpsXpost2010Xdata ajpsXpost2012 ajpsXpost2012Xdata) 	
	}
ivreg2 `ln'citation ajps post2010 post2012 `time' (avail_`data' = ajpsXpost2010 ajpsXpost2012) ///
    if data_type!="no_data", first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	local F=e(widstat)
	if "`t'"=="months" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-Only) nocons
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-Only) nocons drop(print_months_ago_cu print_months_ago_sq)
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/ps_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-Only) nocons keep(avail_`data' ajpsXpost2010 ajpsXpost2012)
	}
	if "`t'"=="FE" {
	outreg2 using ../output/ps_ivreg`ln'_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-Only) nocons
	outreg2 using ../output/ps_ivreg`ln'-simp_`data'.tex, dec(3) tex label append ctitle("2SLS `ln'") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-Only) nocons
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/ps_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only) nocons keep(avail_`data' ajpsXpost2010 ajpsXpost2012) 		
	}
} // end level log loop
} // end time loop
} // end data loop

*RUN NEGATIVE BINOMIAL HERE?
		
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
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ topic_1 if e(sample)==1
local depvarmean=r(mean)
outreg2 using ../output/exclusion_topic.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	/*drop(print_months_ago_cu print_months_ago_sq)*/ ///
	title("Exclusion Restriction: Political Science Topics") ///
	addstat(Mean Dep. Var., `depvarmean')

regress topic_2 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ topic_2 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion_topic.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')

regress topic_3 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ topic_3 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion_topic.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')
	
regress topic_4 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ topic_4 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion_topic.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')

regress topic_5 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ topic_5 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion_topic.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')

********************************************************************
regress data_type_1 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ data_type_1 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label replace  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	title("Exclusion Restriction: Political Science Data Type \& Institution Ranking") ///
	addstat(Mean Dep. Var., `depvarmean')
	
regress data_type_3 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ data_type_3 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')
regress data_type_4 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ data_type_4 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')
	
regress top1 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ top1 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')
	
regress top10 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ top10 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')
	
regress top20 ajpsXpost2010 ajpsXpost2012 ajps post2010 post2012 print_months_ago ///
	print_months_ago_sq print_months_ago_cu if mainsample==1
summ top20 if e(sample)==1
local depvarmean=r(mean)
	outreg2 using ../output/exclusion.tex, dec(3) tex label append  ///
	nocons addtext(Sample, Data-NoPP) keep(ajpsXpost2010 ajpsXpost2012) ///
	addstat(Mean Dep. Var., `depvarmean')

*SAVE DATA AFTER ALL MERGES/NEW VARS
save ../external/cleaned/ps_mergedforregs.dta, replace

	

	
exit
*HEY! Want the latest results copied to the ShareLaTeX folder of the paper? 
*Run this line!
! cp -r /Users/garret/Box\ Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/output /Users/garret/Box\ Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/paper_backup/data_sharing_and_citations/
