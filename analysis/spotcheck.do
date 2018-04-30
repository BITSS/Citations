set more off
clear all
label drop _all
cd "/Users/garret/Box Sync/CEGA-Programs-BITSS/3_Publications_Research/Citations/citations/analysis"

use ../external/cleaned/combined_spotcheck.dta
count
drop if title=="" //Citations data has extra early AJPS article
count

set seed 1492
gen randomorder=runiform()
sort randomorder
gen assignedchecker="Neil" if _n<=20
replace assignedchecker="Jacqui" if _n>20 & _n<=40
replace assignedchecker="Don" if _n>40 & _n<=60
replace assignedchecker="Mu Yang" if _n>60 & _n<=80
replace assignedchecker="Simon" if _n>80 & _n<=100
replace assignedchecker="Kai" if _n>100 & _n<=120

export delimited ../external/cleaned/combined_spotcheck_assigned.csv, replace delimiter(",")

*Pretend you wanted to replicate your 20 assigned papers.
*First, is there any data or code, or is it just pure math/theory?
*If there's data/code, try and find it. (1)Visit the journal website and skim the article
*, google search for (1) the title and (2) the author, and (3) search dataverse
*If you find anything--OR NOT--compare what you find to the current answer in the dataset
*If there's anything that can be changed, edit it here:
*https://docs.google.com/document/d/1NQbD4w7j_HcUlGbMlFAyTt3x9AnfxxXUJTz8AKB9Mvs/edit?usp=sharing 
