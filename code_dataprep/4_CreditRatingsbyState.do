********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Map of Credit Rating By State 
*** This Update: January 2023 
********************************************************************************
********************************************************************************
/// Load Bloomberg Data
use "${tem}\PrimaryMarketStates.dta", clear 
/// Identify Unique States
preserve 
gcollapse (mean) AmtIssued, by(StateCode)
drop AmtIssued
restore 
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

encode FitchInitRtg, gen(fitch1)
encode MdyInitRtg, gen(moody1)
encode SPInitRtg, gen(sp1)
copydesc FitchInitRtg fitch1
copydesc MdyInitRtg moody1 
copydesc SPInitRtg sp1 
drop FitchInitRtg MdyInitRtg SPInitRtg
rename fitch1 FitchInitRtg 
rename moody1 MdyInitRtg
rename sp1 SPInitRtg

gen rating_agg = 0 
replace rating_agg = 1 if rating == 1
replace rating_agg = 2 if rating == 2 | rating == 3 |rating == 4
replace rating_agg = 3 if rating == 5 | rating == 6 |rating == 7
replace rating_agg = 4 if rating == 8 | rating == 9 |rating == 10
label define rating_agg 0 "NR" 1 "AAA" 2 "AA" 3 "A" 4 "BBB"
label values rating_agg rating_agg

*******************************************************************************
gen year = year(IssueDate)
table StateCode, content(min year)
/// States that issued only in 2020: Arkansas, MT, MI, 
/// States that issued only in 2021: Alabama  
*keep if year == 2019
gen max_rating = rating 
gen min_rating = rating 
gen max_ratag = rating_agg
gen min_ratag = rating_agg
gcollapse (min) max_ratag (max) min_ratag, by(StateCode year)
sort StateCode year 
label values max_ratag rating_agg 
label values min_ratag rating_agg 

qui statastates, abbreviation(StateCode) nogen
drop if state_name == ""
drop StateCode
rename state_name state 
/// First Rating of the Sample: Rectangularize the Dataset 
xtset state_fips year
fillin state_fips year
xfill state 
/// First Year of Issuing 
bysort state_fips: egen minyear = min(year) if _fillin == 0 
qui tab state_fips, matrow(F)
local states = r(r)

matrix define S = J(`states',2, .)
matrix colnames S = "fips" "rating"

forvalues i=1(1)`states' {
	/// Save the Fips and Min Year 
	qui sum state_fips if state_fips == F[`i',1]
	qui sum minyear if state_fips == F[`i',1]
	local minyr = r(mean)
	/// Save the Rating 
	qui sum min_ratag if state_fips == F[`i',1] & year == `minyr'
	local rating = r(mean)
	/// Store the values 
	matrix S[`i',1] =  F[`i',1]
	matrix S[`i',2] = `rating'
}

clear 
svmat S 
rename (S1 S2) (state_fips rating_agg)
qui statastates, fips(state_fips) nogen
label define rating_agg 0 "NR" 1 "AAA" 2 "AA" 3 "A" 4 "BBB"
label values rating_agg rating_agg 
drop state_name
save "${tem}\state_ratings.dta",replace 

