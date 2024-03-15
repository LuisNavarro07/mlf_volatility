********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Clean Bloomberg State Data and Merge with MSRB Secondary Market
*** This Update: February 2024
********************************************************************************
********************************************************************************
/// Bloomberg Primary Market Bonds
/// All Bonds (Active and Matured) issued by State Governments between 2019 and 2021

forvalues i=1(1)2{
import excel "${raw}/state_bonds_bloomberg.xlsx", sheet("Sheet`i'") firstrow clear
tempfile statebonds`i'
save `statebonds`i'', replace 
}

use `statebonds1', clear
append using `statebonds2'
********************************************************************************
/// Do the credit rating analysis here 
// https://financestu.com/sp-vs-moodys-vs-fitch/
// https://www.moneyland.ch/en/rating-agencies
// https://www.moodys.com/sites/products/productattachments/ap075378_1_1408_ki.pdf

/// Standardize Credit Ratings 
/// replaces NAs with empty cells 
replace SPInitRtg = "" if SPInitRtg == "#N/A N/A"
replace MdyInitRtg = "" if MdyInitRtg == "#N/A N/A"
replace FitchInitRtg = "" if FitchInitRtg == "#N/A N/A"

/*

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

*/

/// Create Rating Variables 
generate StandardPoors = .
replace  StandardPoors = 1  if SPInitRtg == "AAA" | SPInitRtg == "SP-1+" | SPInitRtg == "AAA/A-1+"
replace  StandardPoors = 2  if SPInitRtg == "AA+" | SPInitRtg == "AA+/A-1" | SPInitRtg == "AA+/A-1+"
replace  StandardPoors = 3  if SPInitRtg == "AA" | SPInitRtg == "SP-1" | SPInitRtg == "AA/A-1" | SPInitRtg == "AA/A-1+"
replace  StandardPoors = 4  if SPInitRtg == "AA-"
replace  StandardPoors = 5  if SPInitRtg == "A+"
replace  StandardPoors = 6  if SPInitRtg == "A" | SPInitRtg == "SP-2" | SPInitRtg == "A/A-1" 
replace  StandardPoors = 7  if SPInitRtg == "A-"
replace  StandardPoors = 8  if SPInitRtg == "BBB+"
replace  StandardPoors = 9  if SPInitRtg == "BBB" | SPInitRtg == "SP-3"
replace  StandardPoors = 10 if SPInitRtg == "BBB-" | SPInitRtg == "BB+" | SPInitRtg == "BB" | SPInitRtg == "BB-" | SPInitRtg == "B"
replace  StandardPoors = 11 if StandardPoors == . 

// https://www.bonddesk.com/moodys.html#:~:text=There%20are%20four%20rating%20categories,speculative%20quality%20are%20designated%20SG.
** Moody's 
generate Moodys = .
replace  Moodys = 1  if MdyInitRtg == "Aaa" | MdyInitRtg == "MIG1" | MdyInitRtg == "VMIG1" | MdyInitRtg == "Aaa/VMIG1"
replace  Moodys = 2  if MdyInitRtg == "Aa3"
replace  Moodys = 3  if MdyInitRtg == "Aa2" | MdyInitRtg == "MIG2" | MdyInitRtg == "Aa2/VMIG1" 
replace  Moodys = 4  if MdyInitRtg == "Aa1" | MdyInitRtg == "Aa1/VMIG1"
replace  Moodys = 5  if MdyInitRtg == "A3"
replace  Moodys = 6  if MdyInitRtg == "A2" | MdyInitRtg == "MIG3" | MdyInitRtg == "VMIG3"
replace  Moodys = 7  if MdyInitRtg == "A1" 
replace  Moodys = 8  if MdyInitRtg == "Baa3"
replace  Moodys = 9  if MdyInitRtg == "Baa2" | MdyInitRtg == "SG"
replace  Moodys = 10 if MdyInitRtg == "Baa1" | MdyInitRtg == "MIG4" | MdyInitRtg == "VMIG4"
replace  Moodys = 11 if Moodys == . 

**** Fitch
/// https://www.fitchratings.com/products/rating-definitions#about-rating-definitions
generate Fitch = .
replace  Fitch = 1  if FitchInitRtg == "AAA" | FitchInitRtg == "F1+" 
replace  Fitch = 2  if FitchInitRtg == "AA+" | FitchInitRtg == "AA+/F1+"
replace  Fitch = 3  if FitchInitRtg == "AA" | FitchInitRtg == "AA/F1+" | FitchInitRtg == "F1"
replace  Fitch = 4  if FitchInitRtg == "AA-" 
replace  Fitch = 5  if FitchInitRtg == "A+"
replace  Fitch = 6  if FitchInitRtg == "A" | FitchInitRtg == "F2" | FitchInitRtg == "A(EXP)"
replace  Fitch = 7  if FitchInitRtg == "A-"
replace  Fitch = 8  if FitchInitRtg == "BBB+"
replace  Fitch = 9  if FitchInitRtg == "BBB" | FitchInitRtg == "F3"
replace  Fitch = 10 if FitchInitRtg == "BBB-"
replace  Fitch = 11 if Fitch == . 


/// Create rating variable: max of the three ratings. since the rating are coded such 
/// that a largest number is a lowest rating, taking the max means we are considering the lowest 
/// rating assigned by any of these agencies 
gsort -StandardPoors -Moodys -Fitch
generate rating = .
/// when two are missing, assign the one we know 
replace rating = StandardPoors if Moodys == 11 & Fitch == 11
replace rating = Moodys if StandardPoors == 11 & Fitch == 11
replace rating = Fitch if StandardPoors == 11 & Moodys == 11
//// when one is missing, take the average of the ones we have 
replace rating = max(StandardPoors, Moodys) if Fitch == 11 & !(StandardPoors == 11 | Moodys == 11)
replace rating = max(StandardPoors, Fitch) if Moodys == 11 & !(StandardPoors == 11 | Fitch == 11)
replace rating = max(Moodys, Fitch) if StandardPoors == 11 & !(Moodys == 11 | Fitch == 11)

replace rating = max(StandardPoors, Moodys, Fitch) if !(StandardPoors == 11 | Moodys == 11 | Fitch == 11)



/// Aggregated Rating Measure 
gen rating_agg = 5 
/// AAA = 1
replace rating_agg = 1 if rating == 1
/// AA = 2, 3, 4
replace rating_agg = 2 if rating == 2 | rating == 3 |rating == 4
/// A = 5, 6, 7
replace rating_agg = 3 if rating == 5 | rating == 6 |rating == 7
/// BBB = 8, 9, 10 
replace rating_agg = 4 if rating == 8 | rating == 9 |rating == 10
label define rating_agg  1 "AAA" 2 "AA" 3 "A" 4 "BBB" 5 "NR"
label values rating_agg rating_agg
/// Express in strings 
gen rating_agg_str = ""
replace rating_agg_str = "AAA" if rating_agg == 1
replace rating_agg_str = "AA" if rating_agg == 2
replace rating_agg_str = "A" if rating_agg == 3
replace rating_agg_str = "BBB" if rating_agg == 4
replace rating_agg_str = "NR" if rating_agg == 5
********************************************************************************
/// Filtering Assumptions 
/// Exclude Puerto Rico and Guam 
drop if StateCode == "PR" | StateCode == "GU" 
/// Exclude Not Rated Bonds 
drop if rating_agg_str == "NR"
********************************************************************************
/// Save the bonds here 
tempfile statebondscomplete
save `statebondscomplete' ,replace 
********************************************************************************
********************************************************************************
/// Data for the Ratings Map 
use `statebondscomplete',clear 
keep rating_agg StateCode IssueDate
gen year = year(IssueDate)
keep if year == 2019
gcollapse (mean) rating_agg, by(StateCode)
replace rating_agg = round(rating_agg)
sort rating_agg StateCode
duplicates drop StateCode, force 
statastates, abbreviation(StateCode)
replace rating_agg = 5 if rating_agg == .
drop _merge
save "${tem}/state_ratings_data.dta", replace 

*******************************************************************************
//// Secondary Market Bonds 
/// Import data from the full market and then match on the cusips. 
use "${raw}/msrb_states1921.dta", clear 
merge m:1 CUSIP using `statebondscomplete', keep(match) nogen 
destring PAR_TRADED, replace 
/// Export data for the analysis 
save "${tem}/statebondsfull_secondary.dta",replace 
********************************************************************************
/// Keep Only CUSIPs
keep CUSIP 
duplicates drop CUSIP, force 
export delimited "${tem}/cusips_msrb.txt", replace 

********************************************************************************
/// Data with Fixed Credit Rating Cohort 
use "${tem}/statebondsfull_secondary.dta",clear 
drop rating rating_agg rating_agg_str
/// Assign Credit Rating 
merge m:1 StateCode using "${tem}/state_ratings_data.dta", keep(match master) nogen 
gen rating_agg_str = ""
replace rating_agg_str = "AAA" if rating_agg == 1
replace rating_agg_str = "AA" if rating_agg == 2
replace rating_agg_str = "A" if rating_agg == 3
replace rating_agg_str = "BBB" if rating_agg == 4
replace rating_agg_str = "NR" if rating_agg == 5
/// Assumption: Drop Not Rated States 
drop if rating_agg_str == "NR"
/// Display Groups
table state_name rating_agg_str

gcollapse (mean) YIELD, by(rating_agg TRADE_DATE) 
xtset rating_agg TRADE_DATE
rename (YIELD TRADE_DATE) (yield date)
reshape wide yield, i(date) j(rating_agg)

*global lab0 "nr" 
global lab1 "3a" 
global lab2 "2a" 
global lab3 "a" 
global lab4 "3b"

forvalues i=1(1)4{
    label variable yield`i' "Yield - ${lab`i'}"
	rename yield`i' yield${lab`i'}
}
save "${tem}/secondary_rating_fixedcr.dta",replace 


********************************************************************************
/// Robustness Check: Groups by Credit Rating, allowing states to change 
use "${tem}/statebondsfull_secondary.dta",clear 
/// Collapse Data to Have Credit Rating by Day Observations 
/// Collapse the data by credit rating and day. So we are taking the average across states, fixing the credit rating. 
gcollapse (mean) YIELD, by(rating_agg TRADE_DATE) 
xtset rating_agg TRADE_DATE
rename (YIELD TRADE_DATE) (yield date)
reshape wide yield, i(date) j(rating_agg)

*global lab0 "nr" 
global lab1 "3a" 
global lab2 "2a" 
global lab3 "a" 
global lab4 "3b"

forvalues i=1(1)4{
    label variable yield`i' "Yield - ${lab`i'}"
	rename yield`i' yield${lab`i'}
}
save "${tem}/secondary_rating.dta", replace  

 
*********************************************************************************
/// Data for Robustness Checks on Heterogeneity of Federal Support 
use "${tem}/statebondsfull_secondary.dta",clear 
drop rating rating_agg rating_agg_str
/// Assign Credit Rating 
merge m:1 StateCode using "${tem}/state_ratings_data.dta", keep(match master) nogen 
gen rating_agg_str = ""
replace rating_agg_str = "AAA" if rating_agg == 1
replace rating_agg_str = "AA" if rating_agg == 2
replace rating_agg_str = "A" if rating_agg == 3
replace rating_agg_str = "BBB" if rating_agg == 4
replace rating_agg_str = "NR" if rating_agg == 5
/// Assumption: Drop Not Rated States 
drop if rating_agg_str == "NR"
merge m:1 StateCode using "${tem}/cares_rankings.dta", keep(match master) nogen
drop if fedsupport_categories == ""
/// Collapse the data by credit rating - percentiles and day. So we are taking the average across states, fixing the credit rating - percentiles of CRF.
gen group = rating_agg_str + "-" + fedsupport_categories

gcollapse (mean) YIELD, by(group TRADE_DATE) 
encode group, gen(group1) 
xtset group1 TRADE_DATE
rename (YIELD TRADE_DATE) (yield date)
cap drop group
reshape wide yield, i(date) j(group1)

*global lab1 "A-Fixed Allocation"
*global lab2 "A-Variable Allocation"
*global lab3 "AA-Fixed Allocation"
*global lab4 "AA-Variable Allocation"
*global lab5 "AAA-Fixed Allocation"
*global lab6 "AAA-Variable Allocation"
*global lab7 "BBB-Fixed Allocation"
*global lab8 "BBB-Variable Allocation"

*global lab1 "A-p0-p33"	
*global lab2 "A-p34-p66"
*global lab3 "A-p67-p100"	
*global lab4 "AA-p0-p33"	
*global lab5 "AA-p34-p66"	
*global lab6 "AA-p67-p100"	
*global lab7 "AAA-p0-p33"	
*global lab8 "AAA-p34-p66"	
*global lab9 "AAA-p67-p100"
*global lab10 "BBB-p0-p33"	
*global lab11 "BBB-p34-p66"	   
*global lab12 "BBB-p67-p100"

global lab1 "A-p0-p50"		
global lab2 "A-p51-p100"		
global lab3 "AA-p0-p50"		
global lab4 "AA-p51-p100"		
global lab5 "AAA-p0-p50"		
global lab6 "AAA-p51-p100"	
global lab7 "BBB-p0-p50"		
global lab8 "BBB-p51-p100"	


forvalues i=1(1)8{
    label variable yield`i' "Yield - ${lab`i'}"
	*label variable par`i' "Par Traded - ${lab`i'}"
}
save "${tem}/secondary_rating_crf.dta",replace 
*********************************************************************************

exit 
