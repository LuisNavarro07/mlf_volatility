*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Clean Bloomberg Data to Get Credit Ratings 
*************************************************************************
*************************************************************************
/// Load Bloomberg Data
forvalues i=1(1)2{
import excel "${raw}\state_bonds_bloomberg.xlsx", sheet("Sheet`i'") firstrow clear
save "${tem}\statebonds`i'.dta",replace 
}

use "${tem}\statebonds1.dta", clear
append using "${tem}\statebonds2.dta"

/// Standardize Credit Ratings 
/// Credit Rating 
gen rat_emp = 0 
replace rat_emp = 1 if SPInitRtg == "#N/A N/A" & MdyInitRtg == "#N/A N/A" & FitchInitRtg == "#N/A N/A" 
replace SPInitRtg = "" if SPInitRtg == "#N/A N/A"
replace MdyInitRtg = "" if MdyInitRtg == "#N/A N/A"
replace FitchInitRtg = "" if FitchInitRtg == "#N/A N/A"

*** Standard and Poors 
generate StandardPoors = .
replace StandardPoors = 1 if SPInitRtg == "AAA"
replace StandardPoors = 2 if SPInitRtg == "AA+"
replace StandardPoors = 3 if SPInitRtg == "AA"
replace StandardPoors = 4 if SPInitRtg == "AA-"
replace StandardPoors = 5 if SPInitRtg == "A+"
replace StandardPoors = 6 if SPInitRtg == "A"
replace StandardPoors = 7 if SPInitRtg == "A-"
replace StandardPoors = 8 if SPInitRtg == "BBB+"
replace StandardPoors = 9 if SPInitRtg == "BBB"
replace StandardPoors = 10 if SPInitRtg == "BBB-"

**** Fitch
generate Fitch = .
replace Fitch = 1 if FitchInitRtg == "AAA"
replace Fitch = 2 if FitchInitRtg == "AA+"
replace Fitch = 3 if FitchInitRtg == "AA"
replace Fitch = 4 if FitchInitRtg == "AA-"
replace Fitch = 5 if FitchInitRtg == "A+"
replace Fitch = 6 if FitchInitRtg == "A"
replace Fitch = 7 if FitchInitRtg == "A-"
replace Fitch = 8 if FitchInitRtg == "BBB+"
replace Fitch = 9 if FitchInitRtg == "BBB"
replace Fitch = 10 if FitchInitRtg == "BBB-"


**** Moodys
generate Moodys = .
replace Moodys = 1 if MdyInitRtg == "Aaa"
replace Moodys = 2 if MdyInitRtg == "Aa1"
replace Moodys = 3 if MdyInitRtg == "Aa2"
replace Moodys = 4 if MdyInitRtg == "Aa3"
replace Moodys = 5 if MdyInitRtg == "A1"
replace Moodys = 6 if MdyInitRtg == "A2"
replace Moodys = 7 if MdyInitRtg == "A3"
replace Moodys = 8 if MdyInitRtg == "Baa1"
replace Moodys = 9 if MdyInitRtg == "Baa2"
replace Moodys = 10 if MdyInitRtg == "Baa3"

global creditrat SPInitRtg MdyInitRtg FitchInitRtg Fitch StandardPoors Moodys rating
generate rating = max(Moodys,Fitch,StandardPoors)

gen rating_agg = 0 
replace rating_agg = 1 if rating == 1
replace rating_agg = 2 if rating == 2 | rating == 3 |rating == 4
replace rating_agg = 3 if rating == 5 | rating == 6 |rating == 7
replace rating_agg = 4 if rating == 8 | rating == 9 |rating == 10


*******************************************************************************
gen year = year(IssueDate)
keep if year == 2019
gen max_rating = rating 
gen min_rating = rating 
gen max_ratag = rating_agg
gen min_ratag = rating_agg
gcollapse (max) max_rating max_ratag (min) min_rating min_ratag, by(StateCode)

label define rating 1 "AAA" 2 "AA+" 3 "AA" 4 "AA-" 5 "A+" 6 "A" 7 "A-" 8 "BBB+" 9 "BBB" 10 "BBB-"
label values max_rating rating  
label values min_rating rating  
label define rating_agg 0 "NR" 1 "AAA" 2 "AA" 3 "A" 4 "BBB"
label values max_ratag rating_agg 
label values min_ratag rating_agg 

statastates, abbreviation(StateCode) nogen
drop if state_name == ""
drop state_fips StateCode
rename state_name state 
save "${tem}\state_ratings.dta",replace 

