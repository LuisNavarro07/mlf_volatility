********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Clean Bloomberg State Data and Merge with MSRB Secondary Market
*** This Update: September 2022 
********************************************************************************
********************************************************************************
/// Bloomberg Primary Market Bonds
/// All Bonds (Active and Matured) issued by State Governments between 2019 and 2021
clear 
forvalues i=1(1)2{
qui import excel "${raw}\state_bonds_bloomberg.xlsx", sheet("Sheet`i'") firstrow clear
tempfile statebonds`i'
qui save `statebonds`i'', replace 
}

qui use `statebonds1', clear
qui append using `statebonds2'
tempfile statebondscomplete
qui save `statebondscomplete' ,replace 
qui save "${tem}\PrimaryMarketStates.dta", replace 
*******************************************************************************
/// Keep Only CUSIPs
qui keep CUSIP 
qui duplicates drop CUSIP, force 
qui export delimited "${tem}\cusips_msrb.txt", replace 

//// Secondary Market Bonds 
/// Import data from the full market and then match on the cusips. 
qui use "${raw}\msrb_states1921.dta", clear 
merge m:1 CUSIP using `statebondscomplete', keep(match) nogen 
qui destring PAR_TRADED, replace 
qui statastates, abbreviation(StateCode) nogen
********************************************************************************
/// Aggregation for Robutstness Check: Fixed State Cohorts 
/// Merge with the Rating: this is the min rating observed by each state during the sample and it is fixed
merge m:1 state_fips using "${tem}\state_ratings.dta", keep(match master) nogen
/// Drop Unmatched == Puerto Rico and Guam bonds 
drop if rating_agg == . 
qui rename rating_agg rating_agg_stfix
/// This variable is the criterion for the collapse: rating_agg_stfix 
********************************************************************************
//// Aggregation for Main Results: Fixed Credit Categories 
/// Standardize Credit Ratings: This approach takes the average rating across the full sample period
/// Credit Rating 
qui gen rat_emp = 0 
qui replace rat_emp = 1 if SPInitRtg == "#N/A N/A" & MdyInitRtg == "#N/A N/A" & FitchInitRtg == "#N/A N/A" 
qui replace SPInitRtg = "" if SPInitRtg == "#N/A N/A"
qui replace MdyInitRtg = "" if MdyInitRtg == "#N/A N/A"
qui replace FitchInitRtg = "" if FitchInitRtg == "#N/A N/A"
*** Standard and Poors 
quietly generate StandardPoors = .
quietly replace StandardPoors = 1 if SPInitRtg == "AAA"
quietly replace StandardPoors = 2 if SPInitRtg == "AA+"
quietly replace StandardPoors = 3 if SPInitRtg == "AA"
quietly replace StandardPoors = 4 if SPInitRtg == "AA-"
quietly replace StandardPoors = 5 if SPInitRtg == "A+"
quietly replace StandardPoors = 6 if SPInitRtg == "A"
quietly replace StandardPoors = 7 if SPInitRtg == "A-"
quietly replace StandardPoors = 8 if SPInitRtg == "BBB+"
quietly replace StandardPoors = 9 if SPInitRtg == "BBB"
quietly replace StandardPoors = 10 if SPInitRtg == "BBB-"
**** Fitch
quietly generate Fitch = .
quietly replace Fitch = 1 if FitchInitRtg == "AAA"
quietly replace Fitch = 2 if FitchInitRtg == "AA+"
quietly replace Fitch = 3 if FitchInitRtg == "AA"
quietly replace Fitch = 4 if FitchInitRtg == "AA-"
quietly replace Fitch = 5 if FitchInitRtg == "A+"
quietly replace Fitch = 6 if FitchInitRtg == "A"
quietly replace Fitch = 7 if FitchInitRtg == "A-"
quietly replace Fitch = 8 if FitchInitRtg == "BBB+"
quietly replace Fitch = 9 if FitchInitRtg == "BBB"
quietly replace Fitch = 10 if FitchInitRtg == "BBB-"
**** Moodys
quietly generate Moodys = .
quietly replace Moodys = 1 if MdyInitRtg == "Aaa"
quietly replace Moodys = 2 if MdyInitRtg == "Aa1"
quietly replace Moodys = 3 if MdyInitRtg == "Aa2"
quietly replace Moodys = 4 if MdyInitRtg == "Aa3"
quietly replace Moodys = 5 if MdyInitRtg == "A1"
quietly replace Moodys = 6 if MdyInitRtg == "A2"
quietly replace Moodys = 7 if MdyInitRtg == "A3"
quietly replace Moodys = 8 if MdyInitRtg == "Baa1"
quietly replace Moodys = 9 if MdyInitRtg == "Baa2"
quietly replace Moodys = 10 if MdyInitRtg == "Baa3"
/// Rating Measure: the min credit rating assigned by any of the agencies. 
/// Note: I take the max operator because the rating is coded such that AAA is 1 and BBB is 10
generate rating = max(Moodys,Fitch,StandardPoors)
/// Aggregated Rating: Group same sign ratings in the same category 
gen rating_agg = 4 
replace rating_agg = 0 if rating == 1
replace rating_agg = 1 if rating == 2 | rating == 3 |rating == 4
replace rating_agg = 2 if rating == 5 | rating == 6 |rating == 7
replace rating_agg = 3 if rating == 8 | rating == 9 |rating == 10
cap label define rating_agg 0 "AAA" 1 "AA" 2 "A" 3 "BBB" 4 "NR"
label values rating_agg rating_agg
tab rating_agg
*******************************************************************************
/// Rename Variable For Consistency: Main Specification = rating_agg_var 
rename rating_agg rating_agg_var
*******************************************************************************
/// Get Spreads to Treasuries instead of Nominal Yields 
rename TRADE_DATE date 
merge m:1 date using "${raw}\FedYieldCurve.dta", keep(match master) nogen
/// Create a variable that allows to match with maturity 
gen mat_month = datediff(date,Maturity,"month")
gen mat_yr = datediff(date,Maturity,"year")
gen mat_index = 1
// 1 month 
replace mat_index = 1 if mat_month == 1
// 2 months
replace mat_index = 2 if mat_month == 2
// 3 months
replace mat_index = 3 if mat_month == 3
// 6 months 
replace mat_index = 4 if mat_month > 3 & mat_month <= 6 
// 12 months 
replace mat_index = 5 if mat_month > 6 & mat_month <= 12
// 2 yr 
replace mat_index = 6 if mat_month > 12 & mat_month <= (12*2) 
// 3 yr 
replace mat_index = 7 if mat_month > (12*2) & mat_month <= (12*5)
// 5 yr 
replace mat_index = 8 if mat_month > (12*5) & mat_month <= (12*7) 
// 7 yr 
replace mat_index = 9 if mat_month > (12*7) & mat_month <= (12*10)
// 10 yr 
replace mat_index = 10 if mat_month > (12*10) & mat_month <= (12*20)
// 20 yr 
replace mat_index = 11 if mat_month > (12*20) & mat_month <= (12*30) 
// 30 yr 
replace mat_index = 12 if mat_month > (12*30) 
/// Create outcome variable 
gen fedyield = 0 
local counter = 1 
local varlist one_month two_month three_month six_month one_yr two_yr three_yr five_yr seven_yr ten_yr twenty_yr thirty_yr
foreach var of local varlist {
	qui replace fedyield = `var' if mat_index == `counter'
	local counter = `counter' + 1
}

/// Generate Spread 
gen spread_yield = ((1 + (YIELD)) / (1 + (fedyield))) - 1 
/// Drop aux 
qui drop one_month two_month three_month six_month one_yr two_yr three_yr five_yr seven_yr ten_yr twenty_yr thirty_yr mat_index
rename date TRADE_DATE 
save "${tem}\statebondsfull_secondary.dta",replace 

exit 
