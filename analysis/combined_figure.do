*This makes a figure for the combined citations paper
*12/9/2018 Garret Christensen

*Figures for the top half are already made,
* in ps_citationregression and econ_citationregression 

/*
\begin{figure}[h!]
\includegraphics[scale=0.5]{./output/econ_availyn_time_data_nopp.eps}
\includegraphics[scale=0.5]{./output/ps_availyn_time_dataarticle.eps}

\includegraphics[scale=0.5]{./output/econ_availdata_time_data_nopp.eps}
\includegraphics[scale=0.5]{./output/ps_availdata_time_dataarticle.eps}
\caption{Data and Code Availability over Time}
\label{Flo:AvailoverTime}
\end{figure}
*/

set more off
clear all
label drop _all
cd "C:/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"
cap log close
log using ../logs/combined_figure.log, replace

use ../external_econ/cleaned/both_cleaned_mergedforregs.dta, clear

*normalize the difference in citations between AER and QJE
*calculate average cites by journal year
keep if mainsample==1
egen avg_jrn_yr_cites=mean(citation), by (year journal)
egen avg_aercites=mean(citation) if journal=="aer", by (year journal) 
egen avg_qjecites=mean(citation) if journal=="qje", by (year journal)
egen avg_apsrcites=mean(citation) if journal=="apsr", by (year journal) 
egen avg_ajpscites=mean(citation) if journal=="ajps", by (year journal)

*subtract that norm from actual cites
sort year journal
gen qje_bonus=320.5517-221.5938 //these are 2001 econ figures

*ajps outcited apsr, 121.9211 to 74.8125 in 2006, but all other years are the opposite.
*So maybe don't normalize?
gen ajps_bonus=121.9211-74.8125

*APPLY THE CITATION BONUS
gen norm0cite=citation
replace norm0cite=norm0cite+qje_bonus if journal=="aer"
replace norm0cite=norm0cite+ajps_bonus if journal=="apsr"

*************************************************
*ECONOMICS
***************************************************
*YEAR BY YEAR REGRESSION
*SAVE B's AND SE's AS LOCALS
forvalues X=2001/2009 {
	regress norm0cite aer if year==`X' & discipline=="econ"
	local b`X'=_b[aer]
	local se`X'=_se[aer]
}

*SPIT OUT LOCALS AS DATA, GRAPH THAT DATA
*ECON GRAPH
preserve
clear all
set obs 9
gen year=.
label var year "Year"
gen citations=.
label var citations "AER-QJE Citations"
gen upper=.
label var upper "95% CI"
gen lower=.
label var lower "95% CI"
forvalues X=2001/2009 {
	local Y=`X'-2000
	replace year=`X' in `Y'
	replace citations=`b`X'' in `Y'
	replace upper=`b`X''+`se`X''*1.96 in `Y'
	replace lower=`b`X''-`se`X''*1.96 in `Y'
}

twoway rcap upper lower year, lcolor(maroon) || connected citations year, ///
	xline(2005) bgcolor(white) graphregion(color(white)) lcolor(navy) mcolor(navy) ///
	title("AER Citation Advantage") 
graph save ../output/econ_cite_comparison.gph, replace
graph export ../output/econ_cite_comparison.eps, replace
graph export ../output/econ_cite_comparison.png, replace

restore
*************************************************
*PS
***************************************************
*YEAR BY YEAR REGRESSION
*SAVE B's AND SE's AS LOCALS
forvalues X=2006/2014 {
	regress norm0cite ajps if year==`X' & discipline=="ps"
	local b`X'=_b[ajps]
	local se`X'=_se[ajps]
}

*SPIT OUT LOCALS AS DATA, GRAPH THAT DATA
*ECON GRAPH
preserve
clear all
set obs 9
gen year=.
label var year "Year"
gen citations=.
label var citations "AJPS-APSR Citations"
gen upper=.
label var upper "95% CI"
gen lower=.
label var lower "95% CI"
forvalues X=2006/2014 {
	local Y=`X'-2005
	replace year=`X' in `Y'
	replace citations=`b`X'' in `Y'
	replace upper=`b`X''+`se`X''*1.96 in `Y'
	replace lower=`b`X''-`se`X''*1.96 in `Y'
}

twoway  rcap upper lower year, lcolor(maroon) || connected citations year, ///
	bgcolor(white) graphregion(color(white)) xline(2010 2012) ///
	title("AJPS Citation Advantage") lcolor(navy) mcolor(navy)
graph save ../output/ps_cite_comparison.gph, replace
graph export ../output/ps_cite_comparison.eps, replace
graph export ../output/ps_cite_comparison.png, replace

***********************************************
*COMBINE GRAPHS
**********************************************

 graph combine ../output/econ_availdata_time_data_nopp.gph ///
		../output/ps_availdata_time_dataarticle.gph ///
		../output/econ_cite_comparison.gph ///
		../output/ps_cite_comparison.gph
graph save ../output/combined_figure.gph, replace
graph export ../output/combined_figure.eps, replace
graph export ../output/combined_figure.png, replace 
		