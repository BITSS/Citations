clear all
insheet using C:/Users/garret/Desktop/uni_ranking_new.csv, names
gen splitat=strpos(university,"   ")
gen unikeep=substr(university, 1, splitat)
replace unikeep=subinstr(unikeep,"—?",", ",.)
replace unikeep=subinstr(unikeep,"-?",", ",.)
gen location=ltrim(substr(university, splitat, .))
drop splitat
drop university
rename unikeep university
outsheet using C:/Users/garret/Desktop/uni_rankings.csv, delimiter(",") replace

*rankings are also here
*https://www.stat.tamu.edu/~jnewton/nrc_rankings/area39.html
