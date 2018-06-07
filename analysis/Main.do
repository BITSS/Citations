*GARRET CHRISTENSEN, JUNE 6 2018*
*THIS FILE RUNS EVERYTHING*

cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"

do ps_citationregression.do //figures and regs with _just_ ps observations
do econ_citationregression.do //figures and regs with _just_ econ
do both_citationregression.do //combines data set, figures with both, but also requires run of previous files
//because certain output gets re-used
