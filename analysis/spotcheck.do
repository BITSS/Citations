
*RAN THIS ONCE TO CREATE SPOTCHECK SAMPLE
/*
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
*/

*Pretend you wanted to replicate your 20 assigned papers.
*First, is there any data or code, or is it just pure math/theory?
*If there's data/code, try and find it. (1)Visit the journal website and skim the article
*, google search for (1) the title and (2) the author, and (3) search dataverse
*If you find anything--OR NOT--compare what you find to the current answer in the dataset
*If there's anything that can be changed, edit it here:
*https://docs.google.com/document/d/1NQbD4w7j_HcUlGbMlFAyTt3x9AnfxxXUJTz8AKB9Mvs/edit?usp=sharing 

*pretend this is Stata code to modify specific observations
/*For example, say you actually found the data and code for one on dataverse, title "Prognosis Negative" doi:1776/1861.x */
*Garret
*Found the data on dataverse
*replace availability="files" if title=="Prognosis Negative" & doi=="1776/1861.x"
*replace availability_dataverse="files" if title=="Prognosis Negative" & doi=="1776/1861.x"

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

* found data and codes from AER extension
replace availability = "files" if title == "A Model of Housing in the Presence of Adjustment Costs: A Structural Interpretation of Habit Persistence" & doi == "10.1257/aer.98.1.474"
replace availability_fileext = "files" if title == "A Model of Housing in the Presence of Adjustment Costs: A Structural Interpretation of Habit Persistence" & doi == "10.1257/aer.98.1.474"


*Simon
* No issues
