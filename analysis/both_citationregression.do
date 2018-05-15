set more off
clear all
label drop _all
cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"
cap log close
log using ../logs/both_citationregression.log, replace
/*TO DO:
apply PP-IV to econ, check that PS is right
Make summary stats table
Figure the XX stats in intro: data vs. data & code sharing
*/


***************************************************
*LOAD DATA
***************************************************
*****************************************************
use ../external_econ/cleaned/econ_mergedforregs.dta, replace
tab journal
count
append using ../external/cleaned/ps_mergedforregs.dta
count

*institution (name) only exists for Econ--PS only brought in rank
*date vars
*COUNT looks OK, but vars are half-half often. Fill in!
*For graphing, create a BEFORE var (v1: 2005 for econ, 2010 for PS,
*v2: 2005 for econ, 2012 for PS)

*PS data comes with avail_yn, but create _data for both disc after append
replace avail_data=(availability=="files"|availability=="data")
label var avail_data "Data Available"
*CREATE STATED/PARTIAL AVAILABILITY
foreach var in reference_code_partial_strict reference_code_partial_easy reference_data_partial_strict reference_data_partial_easy reference_files_partial_strict reference_files_partial_easy reference_code_full_strict reference_code_full_easy reference_data_full_strict reference_data_full_easy reference_files_full_strict reference_files_full_easy{
	replace `var'="." if `var'=="NA"
	destring `var', replace
}
gen avail_state_full=(reference_data_full_strict==1| reference_data_full_easy==1| reference_files_full_strict==1| reference_files_full_easy==1)
gen avail_state_part=(avail_state_full==1)|(reference_code_partial_strict==1| reference_code_partial_easy==1| reference_data_partial_strict==1| reference_data_partial_easy==1| reference_files_partial_strict==1| reference_files_partial_easy==1)
label var avail_state_full "Stated Availability" 
label var avail_state_part "Stated Availability:Part"

*EXPORT SUMM STATS DIRECTLY TO LATEX!
cap program drop latexnc
program define latexnc
*Spot is the string with the name
local spot1="`1'"
*Spot2 is the actual value stored in the scalar
local spot2=`1'
local latexnc1 "\\newcommand{\\\`spot1'}{`spot2'}"
! echo `latexnc1' >> `2' 
end 

*Create empty tex file to store new commands
cap rm ../output/StataScalarList.tex
! touch ../output/StataScalarList.tex

*TOTAL STATED AVAIL
count if avail_state_full==1
scalar Navailstatefull=r(N)
local Navailstatefull=r(N)
latexnc Navailstatefull "../output/StataScalarList.tex"

*TOTAL AVAIL
count if avail_yn==1
scalar Navailyn=r(N)
latexnc Navailyn "../output/StataScalarList.tex"

*TOTAL STATED AND AVAIL
count if avail_yn==1 & avail_state_full==1
scalar Navailstateandfound=r(N)
local Navailstateandfound=r(N)
latexnc Navailstateandfound "../output/StataScalarList.tex"

*FRACTION
scalar percentstatefound=round(`Navailstateandfound'/`Navailstatefull'*100,1)
latexnc percentstatefound "../output/StataScalarList.tex"


gen discipline="econ" if journal=="aer"|journal=="qje"
replace discipline="ps" if journal=="apsr"|journal=="ajps"
replace aer=(journal=="aer")
replace ajps=(journal=="ajps")
gen apsr=(journal=="apsr")
gen econ=(discipline=="econ")
label var aer "AER"
label var ajps "AJPS"
label var apsr "APSR"
replace pp=0 if discipline=="ps"


*GENERATE VARS AFTER APPEND SO THEY'RE FILLED FOR ALL OBS
*DROP PRE-EXISTING ONES FROM PS DATA
*post2005 post2010 post2012 aerXpost2005 ajpsXpost2010 ajpsXpost2012
drop post2010 post2012 ajpsXpost2010 ajpsXpost2012 avail_hat data_type_* ///
	top1 top10 top20 top50 top100 unranked post2010Xdata post2012Xdata ///
	ajpsXpost2010Xdata ajpsXpost2012Xdata ///
	cite_j_avg ajps_y_citeavg apsr_y_citeavg citation_year

local Mar2005=date("2005-03-01","YMD")
replace post2005=(date>`Mar2005')
label var post2005 "Post-Mar 2005"
label drop _all
label define beforeafter 0 "Before" 1 "After"
label values post2005 beforeafter

replace aerXpost2005=aer*post2005
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
*/
****************************
*GRAPH CITATIONS--COMBINED
****************************
histogram citation, bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/both_cite_histo.eps, replace
graph export ../output/both_cite_histo.png, replace

gen citation_year=citation/(print_months_ago/12)
label var citation_year "Total Citations per Year"
histogram citation_year, bgcolor(white) graphregion(color(white)) title("Density of Citations per Year")
graph export ../output/both_cite_histo_year.eps, replace
graph export ../output/both_cite_histo_year.png, replace


*TRICKY TO GET IT TO LOOK NICE OVERLAYED, BUT YOU CAN DO IT.
twoway (histogram citation if econ, color(red%30)) ///
       (histogram citation if !econ, color(green%30)), ///
       legend(order(1 "Economics" 2 "Political Science")) ///
	   bgcolor(white) graphregion(color(white)) title("Density of Citations")
graph export ../output/both_cite_histo_combo.eps, replace
graph export ../output/both_cite_histo_combo.png, replace


*COMBINE THE DISCIPLINES ON THE SAME SCALE
graph combine ../output/econ_cite_histo.gph ../output/ps_cite_histo.gph, ///
	xcommon saving(../output/temp_histo.gph, replace)
graph combine ../output/econ_cite_histo_year.gph ../output/ps_cite_histo_year.gph, ///
	xcommon saving(../output/temp_histo_year.gph, replace)

graph combine ../output/temp_histo.gph ../output/temp_histo_year.gph, col(1) 
graph export ../output/both_histo_combined.eps, replace
graph export ../output/both_histo_combined.png, replace

*SEND STATISTICS DIRECTLY TO THE PAPER!
* We want to mention the median in our paper 
summ citation, detail
scalar mediancitesboth=round(r(p50),1)
latexnc mediancitesboth "../output/StataScalarList.tex"

summ citation if econ==1, detail
scalar mediancitesecon=round(r(p50),1)
latexnc mediancitesecon "../output/StataScalarList.tex"

summ citation if econ==0, detail
scalar mediancitesps=round(r(p50),1)
latexnc mediancitesps "../output/StataScalarList.tex"

*CITATIONS PER YEAR
summ citation_year, detail
scalar mediancitesyearboth=round(r(p50),1)
latexnc mediancitesyearboth "../output/StataScalarList.tex"

summ citation_year if econ==1, detail
scalar mediancitesyearecon=round(r(p50),1)
latexnc mediancitesyearecon "../output/StataScalarList.tex"

summ citation_year if aer==1, detail
scalar mediancitesyearaer=round(r(p50),1)
latexnc mediancitesyearaer "../output/StataScalarList.tex"

summ citation_year if journal=="qje", detail
scalar mediancitesyearqje=round(r(p50),1)
latexnc mediancitesyearqje "../output/StataScalarList.tex"

summ citation_year if econ==0, detail
scalar mediancitesyearps=round(r(p50),1)
latexnc mediancitesyearps "../output/StataScalarList.tex"


bysort year journal: egen cite_j_avg=mean(citation)
label var cite_j_avg "Cites by Journal and Year"
gen aer_y_citeavg=cite_j_avg if aer==1
label var aer_y_citeavg "AER"
gen qje_y_citeavg=cite_j_avg if journal=="qje"
label var qje_y_citeavg "QJE"
gen ajps_y_citeavg=cite_j_avg if ajps==1
label var ajps_y_citeavg "AJPS"
gen apsr_y_citeavg=cite_j_avg if journal=="apsr"
label var apsr_y_citeavg "APSR"
line aer_y_citeavg qje_y_citeavg ajps_y_citeavg apsr_y_citeavg year, title("Total Citations by Journal") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/both_cite_time.eps, replace
graph export ../output/both_cite_time.png, replace

*GRAPH DATA TYPE-COMBINED
replace data_type="" if data_type=="skip"
tab data_type, generate(data_type_)
label var data_type_1 "Experimental"
label var data_type_2 "No Data in Article"
label var data_type_3 "Observational"
label var data_type_4 "Simulations"

*GENERATE INTERACTIONS
gen aerXdata=aer*(data_type_2==0)
label var aerXdata "AER data articles"
gen ajpsXdata=ajps*(data_type_2==0)
label var ajpsXdata "AJPS data articles"
gen apsrXdata=apsr*(data_type_2==0)
label var apsrXdata "APSR data articles"

replace aerXpost2005Xdata=aerXpost2005*(data_type_2==0)
label var aerXpost2005Xdata "AER Post-2005 with Data"
replace post2005Xdata=post2005*(data_type_2==0)
label var post2005Xdata "Post-2005 with Data"
gen post2005Xnotpp=post2005*(pp!=1)
label var post2005Xnotpp "Post-2005 not P\&P"
gen dataXnotpp=(data_type_2==0)*(pp!=1)
label var dataXnotpp "Non P\&P data article"
gen post2005XdataXnotpp=post2005Xdata*(pp!=1)
label var post2005XdataXnotpp "Data non-PP article post-2005"
gen aerXpost2005XdataXnotpp=aerXpost2005Xdata*(pp!=1)
label var aerXpost2005XdataXnotpp "AER Data non-PP article post-2005"
gen aerXpost2005Xnotpp=aerXpost2005*(pp!=1)
label var aerXpost2005Xnotpp "AER After 2005 Not P\&P"
gen aerXdataXnotpp=aerXdata*(pp!=1)
label var aerXdataXnotpp "AER data article not P\&P"
gen aerXnotpp=aer*(pp!=1)
label var aerXnotpp "AER non P\&P article"


gen ajpsXpost2010Xdata=ajpsXpost2010*(data_type_2==0)
label var ajpsXpost2010Xdata "AJPS Post-2010 with Data"
gen post2010Xdata=post2010*(data_type_2==0)
label var post2010Xdata "Post-2010 with Data"
gen ajpsXpost2012Xdata=ajpsXpost2012*(data_type_2==0)
label var ajpsXpost2012Xdata "AJPS Post-2012 with Data"
gen post2012Xdata=post2012*(data_type_2==0)
label var post2012Xdata "Post-2012 with Data"



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
gen top10=.
replace top10=1 if (top_rank>1 & top_rank<=10)
replace top10=0 if top1==1|(top_rank>10 & top_rank<.b)
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
label var top1 "Top 1"
label var top5 "Top 5"
label var top10 "Top 10"
label var top20 "Top 20"
label var top50 "Top 50"
label var top100 "Top 100"

/*
foreach X in 2005{
graph bar top1 top10 top20 top50 top100 unranked, stack over(post`X') over(aer)  legend(lab(1 "Top 1*") ///
	lab(2 "Top 10") ///
	lab(3 "Top 20") ///
	lab(4 "Top 50") ///
	lab(5 "Top 100") ///
	lab(6 "Unranked")) ///
	title("Institution Rankings by Journal Before and After `X' Policy") ///
	bgcolor(white) graphregion(color(white))
graph export ../output/both_rankXjournalXpost`X'.eps, replace
}
*/

*SAVE FINAL DATA
save ../external_econ/cleaned/both_cleaned_mergedforregs.dta, replace

***********************************************************
*REGRESSIONS
***********************************************************
foreach data in yn data state_full state_part{
foreach time in "print_months_ago print_months_ago_sq print_months_ago_cu" "i.year#econ" {
if "`time'"=="print_months_ago print_months_ago_sq print_months_ago_cu" local t="months"
if "`time'"=="i.year#econ" local t="FE"

*NAIVE (LOOP OVER LEVEL AND LOGS}
foreach ln in "" ln{
regress `ln'citation avail_`data'
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label replace ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, None, Sample, All) keep(avail_`data') 
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label replace ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, None, Sample, All) keep(avail_`data') nocons  ///
		// addnote("Regressions include a constant, linear, squared, and cubed months since publication.")
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label replace ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, No, Sample, All) keep(avail_`data') 
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label replace ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, No, Sample, All) keep(avail_`data') nocons
	}

regress `ln'citation avail_`data' aer ajps apsr `time'
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append title("Naive OLS Regression") ///
		 addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append title("Naive OLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All) nocons keep(avail_`data' aer ajps apsr)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append title("Naive OLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append title("Naive OLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All) nocons keep(avail_`data' aer ajps apsr) 	
	}
regress `ln'citation avail_`data' aer ajps apsr data_type_2 pp `time'	
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, All) nocons ///
	keep(avail_`data' aer ajps apsr data_type_2 pp) 
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append ///
	addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, All) nocons ///
	keep(avail_`data' aer ajps apsr data_type_2 pp)
	}
regress `ln'citation avail_`data' aer ajps apsr `time' if data_type!="no_data" & pp!=1
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	if "`t'"=="months" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append addstat(Mean Dep. Var., `depvarmean') ///
		addtext(Months since Publication, Cubic, Sample, Data-NoPP)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append addstat(Mean Dep. Var., `depvarmean') ///
		addtext(Months since Publication, Cubic, Sample, Data-NoPP) nocons keep(avail_`data' aer ajps apsr) 
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_naive`ln'_`data'_`t'.tex, dec(2) tex label append addstat(Mean Dep. Var., `depvarmean')  ///
		addtext(Year-Discipline FE, Yes,Sample, Data-NoPP)
	outreg2 using ../output/both_naive`ln'-simp_`data'_`t'.tex, dec(2) tex label append addstat(Mean Dep. Var., `depvarmean') ///
		addtext(Year-Discipline FE, Yes,Sample, Data-NoPP) nocons keep(avail_`data' aer ajps apsr)
	}	
*********************************
*INSTRUMENTAL VARIABLE REGRESSION
*LEVEL
ivreg2 `ln'citation aer ajps apsr post2005 post2010 post2012  `time' ///
	(avail_`data' = aerXpost2005 ajpsXpost2010 ajpsXpost2012), first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	
	local F=e(widstat)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		 addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, All)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, All) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012)	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, All) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, All)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, All) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012) 	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label replace title("2SLS Regression") ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, All) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012) 	
		}
*INCLUDE INTERACTIONS
*INCLUDE ALL DOUBLES FOR TRIPLE

ivreg2 `ln'citation aer ajps apsr post2005 post2005Xdata ///
	post2010 post2010Xdata post2012 post2012Xdata aerXdata ajpsXdata ///
	`time' data_type_2 (avail_`data' = aerXpost2005 ajpsXpost2010 ajpsXpost2012 ///
	aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata), ///
	first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	
	local F=e(widstat)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		 addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-Only)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-Only) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012)	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-Only) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012 aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata)	

	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012) 	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012 aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata) 	
	}
	
*COMPLICATED INTERACTION WITH PP
*BECAUSE P&P IS ONLY ECONOMICS, IF YOU INCLUDE THE 4-WAY INTERACTION (aerXpost2005XdataXnotpp)
*SOME OF THE TRIPLE/DOUBLE INTERACTIONS BECOME COLINEAR
*THIS IS WHY I DROP TO OF THE AER DOUBLE INTERACTIONS
ivreg2 `ln'citation aer ajps apsr post2005 post2005Xdata   ///
	post2010 post2010Xdata post2012 post2012Xdata /*aerXdata*/ ajpsXdata ///
	pp /*aerXnotpp*/ post2005Xnotpp dataXnotpp aerXdataXnotpp post2005XdataXnotpp /// 
	`time' data_type_2 (avail_`data' = aerXpost2005 ajpsXpost2010 ajpsXpost2012 ///
	aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata ///
	aerXpost2005Xnotpp aerXpost2005XdataXnotpp ), ///
	first savefirst robust

	*FULL SET OF 4 INTERACTIONS
	
	*aer
	*post2005
	*data
	*notpp
	
	*aerXpost2005
	*aerXdata
	*aerXnotpp
	
	*post2005Xdata
	*post2005Xnotpp
	*dataXnotpp
	
	*aerXdataXnotpp
	*aerXpost2005Xnotpp
	*aerXpost2005Xdata
	*post2005XdataXnotpp
	
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	
	local F=e(widstat)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		 addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-NoPP)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-NoPP) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012)	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, IV=Data-NoPP) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012 aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-NoPP)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-NoPP) nocons keep(avail_`data' aer ajps apsr post2005 post2010 post2012) 	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, IV=Data-NoPP) nocons keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012 aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata) 	
	}	
	
ivreg2 `ln'citation aer ajps apsr post2005 post2010 post2012  `time' (avail_`data' = aerXpost2005 ajpsXpost2010 ajpsXpost2012) ///
    if data_type!="no_data", first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)	
	
	local F=e(widstat)

	if "`t'"=="months" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		 addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-Only)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-Only) nocons ///
		keep(avail_`data' aer ajps apsr post2005 post2010 post2012)	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-Only) nocons ///
		keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-Only)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-Only) nocons ///
		keep(avail_`data' aer ajps apsr post2005 post2010 post2012) 	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-Only) nocons ///
		keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012) 	
	}
	
ivreg2 `ln'citation aer ajps apsr post2005 post2010 post2012  `time' ///
	(avail_`data' = aerXpost2005 ajpsXpost2010 ajpsXpost2012) ///
    if data_type!="no_data" & pp!=1, first savefirst robust
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	
	local F=e(widstat)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		 addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-NoPP)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-NoPP) nocons ///
		keep(avail_`data' aer ajps apsr post2005 post2010 post2012)	
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Months since Publication, Cubic, Sample, Data-NoPP) nocons ///
		keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012)	
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_ivreg`ln'_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP)
	outreg2 using ../output/both_ivreg`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) nocons ///
		keep(avail_`data' aer ajps apsr post2005 post2010 post2012) 
	est restore _ivreg2_avail_`data'
	outreg2 using ../output/both_first2`ln'-simp_`data'_`t'.tex, dec(2) tex label append  ///
		addstat(Mean Dep. Var., `depvarmean', F Stat, `F') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) nocons ///
		keep(avail_`data' aerXpost2005 ajpsXpost2010 ajpsXpost2012) 	

	}
} //end ln-normal citations
***********************************************************************
*MANUALLY DO THE IV
*FIRST STAGE
regress avail_`data'  aer  ajps apsr aerXpost2005 ajpsXpost2010 ajpsXpost2012 post2005 post2010 post2012 `time'
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	test aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	if "`t'"=="months" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label replace /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, All) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label replace /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, All) /*drop(`time')*/
	}
	
*INTERACTIONS
regress avail_`data' aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata ///
	aer ajps apsr aerXdata ajpsXdata ///
	post2005 post2010 post2012 ///
	post2005Xdata post2010Xdata post2012Xdata ///
	aerXpost2005 ajpsXpost2010 ajpsXpost2012 `time' data_type_2
	
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	test aerXpost2005Xdata=ajpsXpost2010Xdata=ajpsXpost2012Xdata=aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	if "`t'"=="months" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, IV=Data-Only) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, IV=Data-Only) /*drop(`time')*/
	}
	
*EXTRA PP INTERACTION
regress avail_`data' aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata ///
	aer ajps apsr /*aerXdata*/ ajpsXdata ///
	post2005 post2010 post2012 ///	
	pp /*aerXnotpp post2005Xnotpp*/ dataXnotpp aerXdataXnotpp post2005XdataXnotpp /// 
	aerXpost2005Xnotpp aerXpost2005XdataXnotpp ///
	post2005Xdata post2010Xdata post2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012 `time' data_type_2
	
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	test aerXpost2005Xdata=ajpsXpost2010Xdata=ajpsXpost2012Xdata=aerXpost2005=ajpsXpost2010=ajpsXpost2012=aerXpost2005Xnotpp=aerXpost2005XdataXnotpp=0
	local F=r(F)
	if "`t'"=="months" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, IV=Data-NoPP) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005Xdata ajpsXpost2010Xdata ajpsXpost2012Xdata aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, IV=Data-NoPP) /*drop(`time')*/
	}

regress avail_`data'  aer ajps apsr aerXpost2005 ajpsXpost2010 ajpsXpost2012 post2005 post2010 post2012 `time' ///
	if data_type_2==0 
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	test aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	if "`t'"=="months" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, Data-Only) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, Data-Only) /*drop(`time')*/
	}
	
	
	
regress avail_`data' aer ajps apsr aerXpost2005 ajpsXpost2010 ajpsXpost2012 post2005 post2010 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ `ln'citation if e(sample)==1
	local depvarmean=r(mean)
	test aerXpost2005=ajpsXpost2010=ajpsXpost2012=0
	local F=r(F)
	if "`t'"=="months" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Months since Publication, Cubic, Sample, Data-NoPP) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	*outreg2 using ../output/both_ivreg_`data'_`t'.tex, dec(2) tex label append /*ctitle("First Stage")*/ addstat(F Stat, `F' ) ///
	*nocons addtext(Sample, All)
	outreg2 using ../output/both_first_`data'_`t'.tex, dec(2) keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) tex label append /*ctitle("First Stage")*/ ///
	addstat(Mean Dep. Var., `depvarmean', F Stat, `F') nocons addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) /*drop(`time')*/
	}
cap drop avail_hat
predict avail_hat
*SECOND STAGE--DON'T TRUST THE STANDARD ERRORS!
regress citation avail_hat aer ajps apsr post2005 post2010 post2012 ///
	`time' year
**********************************************************
*TEST THE CHANGE IN TOPIC/TYPE/RANK USING THE MAIN SPECIFICATION
*********************************************************
/*TOPICS DON'T COMBINE ACROSS DISCIPLINE
regress topic_1 aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012  `time' if data_type_2==0
outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label replace  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005) ///
	/*drop(`time')*/ ///
	title("Exclusion Restriction")

regress topic_4 aerXpost2005 aer post2005 ajps apsr ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' if data_type_2==0
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
	nocons addtext(Sample, Data-Only) keep(aerXpost2005) /*drop(`time')*/
IF YOU FIX THIS FIX APPEND REPLACE*/
regress data_type_1  post2005 aer ajps apsr aerXpost2005 ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ data_type_1 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label replace  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label replace  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
regress data_type_3  post2005 aer ajps apsr aerXpost2005 ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ data_type_3 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
regress top1  post2005 aer ajps apsr aerXpost2005 ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ top1 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
	nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
regress top10  post2005 aer ajps apsr aerXpost2005 ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ top10 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
	nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
regress top20  post2005 aer ajps apsr aerXpost2005 ajpsXpost2010 post2010 ajpsXpost2012 post2012 `time' ///
	if data_type_2==0 & pp!=1
	summ top20 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
regress top50 aer ajps apsr aerXpost2005 ajpsXpost2010 post2005 post2010 post2012 ajpsXpost2012  `time' ///
	if data_type_2==0 & pp!=1
	summ top50 if e(sample)==1
	local depvarmean=r(mean)
	
	if "`t'"=="months" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Months since Publication, Cubic, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	if "`t'"=="FE" {
	outreg2 using ../output/both_exclusion_`data'_`t'.tex, dec(2) tex label append  ///
		nocons addstat(Mean Dep. Var., `depvarmean') addtext(Year-Discipline FE, Yes, Sample, Data-NoPP) ///
		keep(aerXpost2005 ajpsXpost2010 ajpsXpost2012) /*drop(`time')*/
	}
	
} //end time as FE or months
} //end data availability




exit
*HEY! Want the latest results copied to the ShareLaTeX folder of the paper? 
*Run this line!
! cp -r /Users/garret/Box\ Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/output /Users/garret/Dropbox/Apps/ShareLaTeX/citations

