*GARRET CHRISTENSEN, JUNE 6 2018*
*THIS FILE RUNS EVERYTHING*

cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"

do ps_citationregression.do //figures and regs with _just_ ps observations
do econ_citationregression.do //figures and regs with _just_ econ
do both_citationregression.do //combines data set, figures with both, but also requires run of previous files
//because certain output gets re-used

*Now, move a copy of every file necessary for the paper to a specific folder (./outputforsharelatex)
*Then, because ShareLaTeX Dropbox Sync SUCKS!, manually upload all of the files 
*to ShareLaTeX via their web interface. There are too many in the main ./output folder
*to keep track of.
*You can only upload 40 at a time!
*BE SURE TO ADD ANY OUTPUT USED IN THE PAPER TO THIS LIST!
cd ../output
#delimit;
foreach file in 
StataScalarList.tex
both_summstat.tex
econ_cite_histo.eps
ps_cite_histo.eps
econ_cite_histo_year.eps
ps_cite_histo_year.eps
both_histo_combined.eps
both_cite_time.eps
econ_availyn_time_data_nopp.eps
ps_availyn_time_dataarticle.eps
econ_availdata_time_data_nopp.eps
ps_availdata_time_dataarticle.eps
both_naive-simp_yn_FE.tex
both_naiveln-simp_yn_FE.tex
both_ivreg-simp_yn_FE.tex
both_ivregln-simp_yn_FE.tex
econ_topicXjournalXpost2005.eps
ps_topicXjournalXpost2012.eps
econ_typeXjournalXpost2005.eps
ps_typeXjournalXpost2012.eps
econ_rankXjournalXpost2005.eps
ps_rankXjournalXpost2012.eps
both_exclusion_yn_FE.tex
econ_exclusion_topic.tex
econ_exclusion.tex
exclusion_topic.tex
exclusion.tex
both_ivreg-simp_state_full_FE.tex
both_citationcomparison.eps
ProprietaryDataGraphYEAR.eps
both_naive-simp_data_FE.tex
both_naiveln-simp_data_FE.tex
both_ivreg-simp_data_FE.tex
both_ivregln-simp_data_FE.tex
both_first2-simp_yn_FE.tex
both_first2-simp_data_FE.tex
both_exclusion_data_FE.tex
both_ivregwok-simp_data_FE.tex
both_summstat_all.tex
both_histo_combined_all.eps
both_cite_time_all.eps
both_naive-simp_yn_FE_all.tex
both_ivreg-simp_yn_FE_all.tex
{;
#delimit cr
! cp `file' ../outputforsharelatex/`file'
}

