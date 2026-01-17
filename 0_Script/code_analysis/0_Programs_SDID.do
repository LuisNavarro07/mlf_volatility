********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: SDID Programs  
*** This Update: January 2026 
********************************************************************************


********************************************************************************
* Define Programs for cleaning data 
********************************************************************************


********************************************************************************
********************************************************************************
* Program 1: Clean Bloomberg Bonds
********************************************************************************
********************************************************************************
cap program drop clean_bonds 
program define clean_bonds, rclass 
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
*save "${tem}/statebondsfull_secondary.dta",replace 
********************************************************************************


end 


********************************************************************************
********************************************************************************
* Program 2: Create Depvar: Baseline
********************************************************************************
********************************************************************************
cap program drop create_yields_depvar
program define create_yields_depvar, rclass 

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
table StateCode rating_agg_str

/// Build a measure of the average yield for each trade date (daily)
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
end

********************************************************************************
********************************************************************************
* Program 3: Create Depvar: Yield Weight
********************************************************************************
********************************************************************************
cap program drop create_yields_depvar_weight
program define create_yields_depvar_weight, rclass 

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
table StateCode rating_agg_str

/// Build a measure of the average yield for each trade date (daily [Weighted by Par]
gcollapse (mean) YIELD [aweight=PAR_TRADED], by(rating_agg TRADE_DATE) 
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
end

********************************************************************************
********************************************************************************
* Program 4: Create Depvar: Fixed Credit Rating Profile 
********************************************************************************
********************************************************************************
cap program drop create_yields_depvar_rating
program define create_yields_depvar_rating, rclass 


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

end 

********************************************************************************
********************************************************************************
* Program 5: Create Depvar: CRF Analysis
********************************************************************************
********************************************************************************

cap program drop create_yields_depvar_crf 
program define create_yields_depvar_crf, rclass

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

/*
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
*/
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


end 

********************************************************************************
********************************************************************************
* Program 6: Create Depvar: Compute Bond Spreads 
********************************************************************************
********************************************************************************


cap program drop compute_bond_spread 
program define compute_bond_spread, rclass 

preserve
use  "${raw}/FedYieldCurve.dta", clear
rename date TRADE_DATE
tempfile fedyield
save `fedyield', replace
restore 

merge m:1 TRADE_DATE using `fedyield', keep(match master) nogen
gen mat_month = datediff(TRADE_DATE,Maturity,"month")
gen mat_yr = datediff(TRADE_DATE,Maturity,"year")
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
gen spread = 0 
local counter = 1 
local varlist one_month two_month three_month six_month one_yr two_yr three_yr five_yr seven_yr ten_yr twenty_yr thirty_yr
foreach var of local varlist {
    replace spread = YIELD - `var' if mat_index == `counter'
	local counter = `counter' + 1
}

drop one_month two_month three_month six_month one_yr two_yr three_yr five_yr seven_yr ten_yr twenty_yr thirty_yr
gen yield_back = YIELD

replace YIELD = spread
end 

********************************************************************************
********************************************************************************
* Program 7: Create Depvar: Residualized Yield
********************************************************************************
********************************************************************************

cap program drop create_residualized_yield
program define create_residualized_yield, rclass 

gen state_abb = StateCode
gen date = dofm(mofd(TRADE_DATE))
format date %td
merge m:1 date state_abb using "${cln}/state_unemployment_data.dta", keep(match master) nogen

drop if YIELD == . 
drop if un_rate == .

/// Estimate regression model to create residualized outcome 
/// Regression: Yield on Unemployment Rate and Coincident Index of Economic Activity + state FE
qui reghdfe YIELD un_rate econ_index, absorb(state_abb) cluster(state)
qui predict yield_hat, xb
/// Create Residualized yield
gen yield_res = YIELD - yield_hat 

drop YIELD 
rename yield_res YIELD
end 

********************************************************************************
********************************************************************************
* Program 8: Create Depvar: Residualized Spread
********************************************************************************
********************************************************************************
cap program drop create_residualized_spread 
program define create_residualized_spread, rclass 


gen state_abb = StateCode
gen date = dofm(mofd(TRADE_DATE))
format date %td
merge m:1 date state_abb using "${cln}/state_unemployment_data.dta", keep(match master) nogen

drop if YIELD == . 
drop if un_rate == .

/// Estimate regression model to create residualized outcome 
/// Regression: Yield on Unemployment Rate and Coincident Index of Economic Activity + state FE
reghdfe spread un_rate econ_index, absorb(state_abb) cluster(state)
predict spread_hat, xb
/// Create Residualized yield
gen spread_res = spread - spread_hat 
drop YIELD 
rename spread YIELD 


end 


********************************************************************************
********************************************************************************
* Program 9: Clean Data for Baseline 
********************************************************************************
********************************************************************************
cap program drop clean_baseline
program define clean_baseline, rclass 

keep date yield*
/// Rename variables to do the reshape 
local varlist yield3a yield2a yielda yield3b
local i = 1
foreach var of local varlist {
	global name`i' =  "`var'"
	rename `var' var`i'
	local i = `i' + 1
}
/// Reshape Long 
reshape long var, i(date) j(sec_id)
rename var volatility 
tsset sec_id date
sort sec_id date

********************************************************************************
/// Add Yield as an outcome. This is to do the graphs 
clonevar yield = volatility
********************************************************************************
/// Names and Varlabs
gen name = ""
replace name = "AAA" if sec_id == 1
replace name = "AA" if sec_id == 2
replace name = "A" if sec_id == 3
replace name = "BBB" if sec_id == 4 

gen varlab = "State Bonds - " + name 
gen data = "Outcome"

end


********************************************************************************
********************************************************************************
* Program 10: Clean Data for CRF Analaysis 
********************************************************************************
********************************************************************************

cap program drop clean_robust 
program define clean_robust, rclass 

keep date yield*
/// Reshape Long 
reshape long yield, i(date) j(sec_id)
rename yield volatility 
tsset sec_id date
sort sec_id date
********************************************************************************
/// Add Yield as an outcome. This is to do the graphs 
clonevar yield = volatility
********************************************************************************
/// Names and Varlabs
gen name = ""
replace name = "A-p0-p50"		if sec_id == 1
replace name = "A-p51-p100"		if sec_id == 2
replace name = "AA-p0-p50"		if sec_id == 3
replace name = "AA-p51-p100"	if sec_id == 4
replace name = "AAA-p0-p50"		if sec_id == 5
replace name = "AAA-p51-p100"	if sec_id == 6
replace name = "BBB-p0-p50"		if sec_id == 7
replace name = "BBB-p51-p100"	if sec_id == 8

/*
*replace name = "A-p0-p33"		if sec_id == 1
*replace name = "A-p34-p66"		if sec_id == 2
*replace name = "A-p67-p100"		if sec_id == 3
*replace name = "AA-p0-p33"		if sec_id == 4
*replace name = "AA-p34-p66"		if sec_id == 5
*replace name = "AA-p67-p100"	if sec_id == 6	
*replace name = "AAA-p0-p33"		if sec_id == 7
*replace name = "AAA-p34-p66"	if sec_id == 8
*replace name = "AAA-p67-p100"	if sec_id == 9
*replace name =  "BBB-p0-p33"	if sec_id == 10
*replace name =  "BBB-p34-p66"	if sec_id == 11 
*replace name =  "BBB-p67-p100"	if sec_id == 12

*replace name = "A-Fixed Allocation" if sec_id == 1
*replace name = "A-Variable Allocation" if sec_id == 2
*replace name = "AA-Fixed Allocation" if sec_id == 3
*replace name = "AA-Variable Allocation" if sec_id == 4
*replace name = "AAA-Fixed Allocation" if sec_id == 5
*replace name = "AAA-Variable Allocation" if sec_id == 6
*replace name = "BBB-Fixed Allocation" if sec_id == 7
*replace name = "BBB-Variable Allocation" if sec_id == 8
*/

gen varlab = "State Bonds - " + name 
gen data = "Outcome"
end


********************************************************************************
********************************************************************************
* Program 11: Prepare Data in format for synth (sdid) [strongly balanced panel]
********************************************************************************
********************************************************************************
cap program drop synth_prep
program define synth_prep, rclass 
/// Append the Donors 
append using "${tem}/bloombergprices_clean.dta"
** add currencies 
append using "${tem}/fred_currencies_clean.dta"
***
replace data = "Donor Prices" if data == ""
append using  "${tem}/spgoindex.dta"
replace data = "SP Munis" if data == ""

********************************************************************************
/// Compute the Standard Deviation of Weekly Prices 
gen wofd= wofd(date + 1)
/// Collapse at the weekly levels - This gets the weekly volatility measure  
gcollapse (mean) date yield (sd) volatility, by(wofd name varlab data)
//// Collapse by Month: Average of the 4 weeks at each month 
gen mofd = mofd(date)
gcollapse (mean) volatility yield date, by(mofd varlab name data) 
format mofd %tmMon_CCYY
gen year = year(date)
gen treat = 0 
replace treat = 1 if data == "Outcome"
tempfile data
save `data', replace 
********************************************************************************
/// Exclude Data From SP Muni Index on the Treatment Period 
drop if data == "SP Munis" & year >= 2019 
gsort -treat -data name mofd 
********************************************************************************
/// Manual Replacement of the first unit of volatility for BBB January 2019 
*sum volatility if name == "BBB" & mofd == tm(2019m2)
*replace volatility = r(mean) if name == "BBB" & mofd == tm(2019m1) 
*mdesc volatility
********************************************************************************
/// Now I need to express everything in Experiment Time 
/// This variable refers to the experiment cohort 
gen year_exp = . 
/// Variables to determine experiment-months. 36 periods. Treatment Happens in April of t+1, so it is the 16th period 
gen month = month(dofm(mofd))
gen month_exp = month 
/// Two Steps: First Save the Treated Cohort 
replace year_exp = 1 if mofd >= tm(2019m1) & mofd <= tm(2021m12)
/// Store only the treated cohort (including donors from it)
preserve 
drop if data == "SP Munis"
replace month_exp = month + 12 if year == 2020 
replace month_exp = month + 24 if year == 2021 
tempfile treated 
save `treated' , replace 
restore 

/// Second: Now I need to reshape the dataset so each cohort
keep if data == "SP Munis"

/// List of Cohorts: 
local cohort5 mofd >= tm(2013m1) & mofd <= tm(2015m12)
local cohort4 mofd >= tm(2014m1) & mofd <= tm(2016m12)
local cohort3 mofd >= tm(2015m1) & mofd <= tm(2017m12)
local cohort2 mofd >= tm(2016m1) & mofd <= tm(2018m12)


/// Keep observations at each cohort 
forvalues i=2(1)5{
preserve 
keep if `cohort`i''
sum year 
local initial = r(min)
replace month_exp = month + 12 if year == (`initial' + 1)
replace month_exp = month + 24 if year == (`initial' + 2)
replace year_exp = `i'
tempfile cohort`i'
save `cohort`i'', replace 
restore 
}

/// Append them 
use `cohort2', clear 
forvalues i=3(1)5{
	append using `cohort`i''
}

/// Save them 
tempfile munis
save `munis', replace 


/// Finally, append them together with the treated untis 
use `treated', clear 
append using `munis'

********************************************************************************
/// Create IDs 
/// First with Treated Units 
egen id = group(name) if data == "Outcome"
/// Second Identify Donors from the SP Data 
egen id_sp = group(name year_exp) if data == "SP Munis"
replace id = id_sp + 2000  if data == "SP Munis"
/// Third Identify Donors from the Bloomberg data 
egen id_bloom = group(name) if data == "Donor Prices"
replace id = id_bloom + 3000 if data == "Donor Prices"
drop id_bloom id_sp
********************************************************************************
/// Homogeneous IDs 
egen id1 = group(id)
drop id 
rename id1 id 
tsset id month_exp
rename volatility v 

end 
********************************************************************************
********************************************************************************



********************************************************************************
********************************************************************************
* Define Programs for analysis 
********************************************************************************
********************************************************************************


* Options for Graphs 
global graphopts ylabel(#10, nogrid labsize(small) angle(0)) /// 
					title(, size(small) pos(11) color(black)) /// 
					plotregion(lcolor(black)) /// 
					graphregion(margin(4 4 4 4)) /// 
					plotregion(lcolor(black)) /// 
					xtitle("", size(small)) /// 
					xlabel(#33, nogrid labsize(small) angle(90)) /// 
					yscale(titlegap(0))

global smoke_options ylabel(#10, nogrid labsize(vsmall) angle(0)) /// 
					 xtitle("", size(vsmall)) /// 
					 xlabel(#33, labsize(vsmall) angle(90) nogrid) /// 
					 ytitle("Treatment Effect (Difference in Volatility, p.p.)", size(vsmall)) ////
					 title(, size(small) pos(11) color(black)) /// 
					 xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) /// 
					 legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) /// 
					 plotregion(color() lcolor(black)) graphregion(color() margin(4 4 4 4))

********************************************************************************
********************************************************************************
* Program 12: SDID Prep 
********************************************************************************
********************************************************************************
cap program drop sdid_prep
program define sdid_prep, rclass 

* Analysis Window 
qui keep if month_exp > 3 
qui keep if month_exp <= $keep_post

sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd
/// Organize Dataset
/// Table of Treated States 
qui tab id if treat==1, matrow(T)
global tr_units = r(r)
/// Create Variables for Sdid 
xtset id month_exp
qui gen post = 0 
qui replace post = 1 if month_exp >= ${treat_period}
cap drop did 
qui gen did = treat*post
gsort -treat id month_exp
order id treat month month_exp post year month year_exp v v_pre_mn v_pre_sd v_norm 

end 
********************************************************************************
********************************************************************************
* Program 13: SDID Estimation: Estimates the sdid for an individual dependent variable 
********************************************************************************
********************************************************************************
cap program drop sdid_est 
program define sdid_est, rclass 

* Analysis Window 
qui keep if month_exp > 3 
*qui keep if month_exp <= $keep_post

preserve 
collapse (first) asset_class varlab name, by(id)
rename id donor_id
tempfile donors_name
save `donors_name', replace 
restore 

preserve 
keep if treat == 1
collapse (mean) mofd, by(month_exp)
tempfile dates 
save `dates', replace 
restore 

/// Pre-treat mean and sd 
qui sum v if treat==1 & post == 0 // Considering the entire pre for rescaling
loc mn_pre = r(mean)
loc sd_pre = r(sd)

/// Create Dependent Variable: Each observation is adjusted using the mean and sd of the treated unit during the pre-intervention 
gen v_lev = `sd_pre'*v_norm + `mn_pre' 

* v_lev expresses the normalized volatility of each instrument, in terms of the mean and sd of the treated unit during the pre-treatement period. ATT is expressed in this units. 

* depvar = v_lev
global depvar v_lev 

*tempfile sdid_data
*save `sdid_data', replace 

*------------------------------------------------------------------------------
// Compute SDID - Standard 
*use `sdid_data', clear 
qui sdid $depvar id month_exp did, vce(noinference) method(sdid) mattitles

/// Get Output: weights and treated series 
mat W = e(omega)	
matrix lambda = e(lambda)[1..12,1]
mat SDID = e(series)
mat tau = e(tau)
* Pre-Treatment Period
mat Yc=SDID[1..12,2]	
mat Yt=SDID[1..12,3]	
/// ATT 
scalar att = e(ATT)
** Results for Event Study Plot 
matlist lambda' * (Yt - Yc)
matrix aux = lambda' * (Yt - Yc)
scalar meanpre_o = aux[1,1]

* 1. Create the difference vector 
matrix diff = Yt - Yc

* 2. Calculate Sum of Squared Errors (SSE)
* We multiply Gap transposed by Gap to sum the squared elements
matrix SSE_mat = diff' * diff 
scalar sse = SSE_mat[1,1]

* 3. Compute RMSPE
* We divide by the number of pre-treatment periods (rows in your Yt matrix)
scalar T_pre = rowsof(Yt)
scalar rmspe = sqrt(sse / T_pre)

* Format Results 
clear
svmat SDID
qui rename (SDID1 SDID2 SDID3) (month_exp Y_sdid Y_treated)
*svmat difference 

svmat Yt 
svmat Yc

qui sum Yt1
loc Yt_mn=r(mean) 
loc Yt_sd=r(sd) 
qui sum Yc1
loc Yc_mn=r(mean) 
loc Yc_sd=r(sd) 

qui gen CohenD_sdid = abs(`Yt_mn' - `Yc_mn') / (0.5*`Yt_sd'^2 + 0.5*`Yc_sd'^2)^(1/2)

qui drop Yt1 Yc1

* Y_treat_lev and Y_sdid_lev are in units of the dependent variable 
*qui gen Y_treat_lev = `sd_pre'*Y_treated + `mn_pre' 
*qui gen Y_sdid_lev = `sd_pre'*Y_sdid + `mn_pre' 	
*qui gen tr_eff = Y_treat_lev - Y_sdid_lev

* Treatment Effect is in units of the dependent variable 
qui gen tr_eff = Y_treated - Y_sdid
/// see page 29 of sdid stata paper 
qui gen tr_eff_ev = tr_eff - meanpre_o
*drop Y_treated Y_treat_lev
qui gen event_time = month_exp - $treat_period
qui gen att = att
qui gen rmspe = rmspe
qui gen mn_pre = `mn_pre'
/// add dates
qui merge m:1 month_exp using `dates', keep(match master) nogen

/// Add weights 
svmat W 
qui rename (W1 W2) (weight donor_id)
qui merge m:1 donor_id using `donors_name', keep(match master) nogen
	
qui tempfile sdid_res
qui save 	`sdid_res', replace 

*-------------------------------------------------------------------------------
* Sdid event - not needed because smoke plot gets at this. 
/*
use `sdid_data', clear 
qui sdid_event $depvar id month_exp did, vce(off) method(sdid) placebo(all)

/// Get Output: weights and treated series 
mat SDID = e(H)

clear 
svmat SDID
keep SDID1
rename SDID1 att
drop if _n == 1
drop if att == .

gen time = _n 
gen event_time = time
replace event_time = -(time - 21) if _n > 21
sort event_time
keep event_time att 
*/
 
end 
********************************************************************************
********************************************************************************
* Program 14: SDID Full [Estimates Models for All Depvars]
********************************************************************************
********************************************************************************
cap program drop sdid_est_full
program define sdid_est_full, rclass 

tab id if data == "Outcome"
global tot = r(r)

/// Estimate for each outcome 
forvalues i = 1(1)$tot{
	preserve 
	qui sdid_prep
	/// Each treated unit and rest of donors
	qui keep if id == `i' | data != "Outcome"
	/// Compute sdid 
	qui sdid_est
	/// Use results 
	qui gen id = `i'
	tempfile sdid_res_out`i'
	qui save `sdid_res_out`i'', replace 
	restore 
	
}
 
use `sdid_res_out1', clear 
forvalues j = 2(1)$tot{
	append using `sdid_res_out`j''
}

save "${oup}/sdid_results.dta", replace

end 


********************************************************************************
********************************************************************************
* Program 15: SDID Placebos Loop [Runs Placebos for Inference]
********************************************************************************
******************************************************************************** 
cap program drop run_placebo_loops
program define run_placebo_loops

*Prepare data for analysis 
qui sdid_prep

qui tab id if data == "Outcome"
global tot = r(r)

* 1. Create Outcomes
forvalues i = 1(1)$tot{
qui sum v if id == `i' & post == 0
local pre_mean = r(mean)
local pre_sd = r(sd)

* We rescale everyone (including the placebo treated) to look like Real Unit `i`
qui gen v_lev`i' = `pre_sd' * v_norm + `pre_mean'


}

* 1. DEFINE DONOR POOL
* Identify the donors (exclude real treated units to avoid contamination)

* Extra code --------------
drop if asset_class == "Municipal Bonds"
*---------------------------

qui keep if data != "Outcome" 
qui tab id, matrow(Donors)
global num_donors = r(r)
* Save this "clean" donor dataset to memory/disk to speed up the loop
qui tempfile donor_data
qui save `donor_data'


forvalues j = 1(1)$num_donors {
    qui clear 
    qui use `donor_data', clear 
    * Get the actual ID of the donor from the matrix stored earlier
    local donor_id = Donors[`j',1]
    * Analysis Window 
	qui keep if month_exp > 3 
	*qui keep if month_exp <= $keep_post
    * A. Set up Placebo Treatment
    * This donor becomes the "treated" unit
	qui replace treat = 0 
    qui replace treat = 1 if id == `donor_id'
	qui replace did = 0 
    qui replace did = 1 if treat == 1 & post == 1
    
    * D. Store Results
    * We need to save the ATT, the Target Unit (i), and the Placebo Unit (j)
	forvalues i = 1(1)$tot{
	* C. Run SDID
    * Note: vce(noinference) makes this fast
	qui sdid v_lev`i' id month_exp did, vce(noinference) method(sdid)
	
	qui local att = e(ATT)
	/// Get Output: weights and treated series 
	matrix lambda = e(lambda)[1..12,1]
	mat SDID = e(series)
	* Pre-Treatment Period
	mat Yc =SDID[1..12,2]	
	mat Yt =SDID[1..12,3]	
	** Results for Event Study Plot 
	matrix aux = lambda' * (Yt - Yc)
	scalar meanpre_o = aux[1,1]
	
	* 1. Create the difference vector 
	matrix diff = Yt - Yc

	* 2. Calculate Sum of Squared Errors (SSE)
	* We multiply Gap transposed by Gap to sum the squared elements
	matrix SSE_mat = diff' * diff 
	scalar sse = SSE_mat[1,1]

	* 3. Compute RMSPE
	* We divide by the number of pre-treatment periods (rows in your Yt matrix)
	scalar T_pre = rowsof(Yt)
	scalar rmspe = sqrt(sse / T_pre)
		
	preserve 
    qui clear 
    qui svmat SDID
	qui rename (SDID1 SDID2 SDID3) (month_exp Y_sdid Y_treated)
	qui svmat Yt 
	qui svmat Yc
	qui sum Yt1
	loc Yt_mn=r(mean) 
	loc Yt_sd=r(sd) 
	qui sum Yc1
	loc Yc_mn=r(mean) 
	loc Yc_sd=r(sd) 
	qui gen CohenD_sdid = abs(`Yt_mn' - `Yc_mn') / (0.5*`Yt_sd'^2 + 0.5*`Yc_sd'^2)^(1/2)
	qui drop Yt1 Yc1
	* Treatment Effect is in units of the dependent variable 
	qui gen tr_eff = Y_treated - Y_sdid
	/// see page 29 of sdid stata paper 
	qui gen tr_eff_ev = tr_eff - meanpre_o
	qui gen event_time = month_exp - $treat_period
	qui gen rmspe = rmspe

	
	qui gen id = `i'
    qui gen att = `att'
    qui tempfile placebo_att`i'
	qui save `placebo_att`i'', replace 
	restore 
	dis "Placebo: Treated Unit `i': Donor `j'"
	}
	
	qui use `placebo_att1', clear 
	forvalues k = 2(1)$tot{
	append using `placebo_att`k''
	}
	qui gen placebo_id = `donor_id' 
	qui tempfile placebo_donor`j'
	qui save `placebo_donor`j'', replace      
	dis "Placebos of Donor `j' out of $num_donors - Completed"
} 

/// Append all placebos 
qui use `placebo_donor1', replace 
forvalues j = 2(1)$num_donors {
	qui append using `placebo_donor`j''
}

qui save "${oup}/sdid_placebo_distributions.dta", replace

end 

********************************************************************************
********************************************************************************
/// Program 16: Create Table for Main Results 
********************************************************************************
********************************************************************************
cap program drop att_table
program define att_table, rclass
/// Results as a transpose 
matrix define M = R'
/// Clear the environment 
clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
replace M6 = 0 if M6 == . 
/// Drop ate excess volatility if the effect is not interpretab;e 
replace M10 = . if M10 < -300 | M10 > 300
/// Statistical Significance: Left-sided test  
qui gen stars = "" 
qui replace stars = "*" if M5 < 0.1
qui replace stars = "**" if M5 < 0.05 
qui replace stars = "***" if M5 < 0.01
/// Format Variables 
qui tostring M1, gen(ate) force format(%12.4fc)
qui tostring M2, gen(se) force format(%12.4fc)
qui tostring M3, gen(ci_min) force format(%12.4fc)
qui tostring M4, gen(ci_max) force format(%12.4fc)
qui tostring M5, gen(pval1) force format(%12.4fc)
qui tostring M6, gen(pval2) force format(%12.4fc)
qui tostring M7, gen(vol_pre) force format(%12.4fc)
qui tostring M8, gen(vol_treat) force format(%12.4fc)
qui tostring M9, gen(excess_vol) force format(%12.4fc)
qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
qui tostring M11, gen(rmspe) force format(%12.4fc)
qui replace ate_excess_vol = ate_excess_vol + "\%"
qui replace ate_excess_vol = "NA" if ate_excess_vol == ".\%"
qui replace se = "(" + se + ")"
qui replace ate = ate + stars
qui gen cint = "(" + ci_min + "," + ci_max + ")"

qui gen id = _n
qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval1 pval2 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
qui keep id b*
qui reshape long b, i(id) j(vars) string
qui destring vars, gen(id1)
qui drop vars 
qui reshape wide b, i(id1) j(id)  
qui gen names = ""
qui replace names = "ATT (a)" if _n == 1
qui replace names = "SE" if _n == 2
qui replace names = "Conf Interval" if _n == 3
qui replace names = "Historic Volatility (b)" if _n == 4
qui replace names = "Volatility March 2020 (c)" if _n == 5
qui replace names = "Excess Volatility (d = c - b)" if _n == 6
qui replace names = "ATT, % Excess Volatility (e = d/a)" if _n == 7
qui replace names = "P-Value (Left Tail)" if _n == 8
qui replace names = "P-Value (Two Tails)" if _n == 9
qui replace names = "RMSPE" if _n == 10
qui drop id1
qui rename (names b1 b2 b3 b4) (Results A AA AAA BBB)
qui order Results AAA AA A BB
end 

********************************************************************************
********************************************************************************
* Program 17: Construct ATT Table and Other Model Outputs 
********************************************************************************
********************************************************************************
cap program drop construct_att_table 
program define construct_att_table, rclass 

* 1. Load Real Results
use "${oup}/sdid_results.dta", clear 
collapse (mean) att, by(id)
gen placebo_id = 0 // Marker for the "Real" treated unit
reshape wide att, i(placebo_id) j(id)
tempfile sdid_att 
save `sdid_att'

* 2. Append Placebo Results
use "${oup}/sdid_placebo_distributions.dta", clear 
cap drop survival

preserve 
gcollapse (mean) rmspe, by(placebo_id id)
qui gen survival = 0 
qui replace survival = 1 if rmspe <= $rmspe_cutoff
keep placebo_id id survival 
tempfile placebo_survival 
save `placebo_survival', replace 
restore 

merge m:1 id placebo_id using `placebo_survival', keep(match master) nogen
* keep only good placebos 
tabstat rmspe, by(survival) stat(mean n)
tab survival
keep if survival == 1

*save "${oup}/sdid_placebo_distributions_clean.dta", replace 
***** save data for further analysis 

*use "${oup}/sdid_placebo_distributions_clean.dta", clear 
gcollapse (mean) att, by(placebo_id id)
reshape wide att, j(id) i(placebo_id)
*rename attp* att* 
append using `sdid_att'
sort placebo_id
/// Matrix to Store Results 
local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB" 
matrix define R=J(12,4,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "att" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"


* 3. Calculate Inference Metrics
* We loop over the 4 outcomes (AAA, AA, A, BBB)
forvalues i = 1(1)$tot {
	
    * A. Get the Real ATT value (stored where placebo_id == 0)
    qui sum att`i' if placebo_id == 0
    local real_att = r(mean)
    mat R[1,`i'] = `real_att'
	
    * B. Calculate Standard Error 
    * (SD of the placebo distribution, usually excluding the real unit)
    qui sum att`i' if placebo_id != 0
    gen se`i' = r(sd)
    mat R[2,`i'] = r(sd)
	
	_pctile att`i' if placebo_id != 0, percentiles(2.5 97.5)
	mat R[3,`i'] = r(r1)
	mat R[4,`i'] = r(r2)
	
    * C. Two-Sided P-Value (Recommended)
    * Checks if abs(placebo) > abs(real)
    * Formula: (Count + 1) / (N_donors + 1)
    gen abs_diff`i' = abs(att`i') >= abs(`real_att')
    qui count if abs_diff`i' == 1 & placebo_id != 0
    local count_extreme = r(N)
    qui count if placebo_id != 0
    local N_placebos = r(N)
    
    gen pval_2sided`i' = (`count_extreme' + 1) / (`N_placebos' + 1)
	qui sum pval_2sided`i'
    mat R[6,`i'] = r(mean)
	
    * D. One-Sided P-Value (Left Tail, if you expect negative effects)
    * Checks if placebo < real
    gen left_diff`i' = att`i' <= `real_att'
    qui count if left_diff`i' == 1 & placebo_id != 0
    local count_lower = r(N)
    
    gen pval_1sided`i' = (`count_lower' + 1) / (`N_placebos' + 1)
	qui sum pval_1sided`i'
	mat R[5,`i'] = r(mean)
	qui local pval1 = round(r(mean),0.0001)
	
	
		/// Percentiles for lines in density plot
	qui cumul att`i' , gen(att`i'_cdf)
	/// Percentile 2.5% 
	qui sum att`i'  if att`i'_cdf <= 0.025
	local p025 = r(max)
	/// Percentile 5.0% 
	qui sum att`i'  if att`i'_cdf <= 0.05
	local p050 = r(max)	
	/// Percentile 95.0% 
	qui sum att`i'  if att`i'_cdf <= 0.95
	local p950 = r(max)
	/// Percentile 97.5% 
	qui sum att`i'  if att`i'_cdf <= 0.975
	local p975 = r(max)
	
	/// ATE's Empirical Distribution - 
	local density_opts recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(`real_att', lcolor(maroon) lpattern(longdash)) xtitle("ATT Estimate") ytitle("Density") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) xscale(range(0 `real_att')) legend(off) yscale(titlegap(0))
	/// Percentiles plot
	local line1 lcolor(ebblue) lpattern(shortdash) lwidth(medthin)
	local line2 lcolor(eltblue) lpattern(longdash) lwidth(medthin)
	local percentile_lines xline(`p050', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity att`i', `density_opts' title("`title`i'': Left Tail Test p-value = `pval1'", pos(11) size(small)) ///
				name(att_dens`i',replace) `percentile_lines'
	
	
	preserve 
	use "${oup}/sdid_results.dta", clear 
	qui keep if id == `i'
	qui keep if Y_treated != .
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absatt = abs(`real_att')
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum Y_treated if event_time < -1
	local vol_pre = r(mean)
	mat R[7,`i'] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum Y_treated if event_time == -1
	local vol_treat = r(mean)
	mat R[8,`i'] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,`i'] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absatt'/`excess_vol')
	if abs(`ate_excess_vol') > 300 {
	local ate_excess_vol = "."
	}
	mat R[10,`i'] = `ate_excess_vol'
	/// RMSE 
	qui sum rmspe 
	mat R[11,`i'] = r(mean)
	/// Id
	mat R[12,`i'] = `i'
	restore 
	
}

matlist R 
clear 
att_table

* Display
list, noobs sep(0) abbrev(32)
* 9. Export
* Save final results with valid SEs and Exact P-values
save "${oup}/synth_did_results_table.dta",replace

texsave Results AAA AA A BBB using "${oup}/synth_did_results_table.tex", ///
    replace ///
    nofix ///
    align(l c c c c) ///
    hlines(5) ///
    label("tab:synth_did_results_table") 

	*title("Average Treatment Effect on the Treated: MLF impact on Municipal Volatility") ///

	qui graph combine att_dens3 att_dens2 att_dens1 att_dens4, rows(2) cols(2) ycommon name(dens_combined, replace)
	qui graph display dens_combined, ysize(80) xsize(100) scale(.9)
	qui graph export "${oup}/ate_dens_main_att.pdf", $export 

end 

********************************************************************************
********************************************************************************
* Program 18: Treated Synth Graph
********************************************************************************
********************************************************************************
cap program drop create_treat_synth_graph 
program define create_treat_synth_graph, rclass 

use "${oup}/sdid_results.dta", clear 
keep if Y_sdid != .
* Map IDs to Credit Ratings (Columns)
gen rating = ""
replace rating = "A"   if id == 1
replace rating = "AA"  if id == 2
replace rating = "AAA" if id == 3
replace rating = "BBB" if id == 4
keep rating event_time Y* id mofd mn_pre

rename (Y_sdid Y_treated) (synthetic treated)

qui tab id 
global rows = r(r)

qui sum mofd if event_time == 0 
qui local xline = r(mean)

qui local title1 = "A"
qui local title2 = "AA"
qui local title3 = "AAA"
qui local title4 = "BBB"
qui local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
qui local lineopts1 lwidth(medthin) msize(vsmall)

forvalues i=1(1)$rows {
    preserve 
	qui keep if id == `i'
	qui sum mn_pre
	local yline = r(mean)
	twoway (line treated mofd, lcolor(black) lpattern(solid) mcolor(black) msymbol(circle) `lineopts1') ///
		(line synth mofd, lcolor(cranberry) lpattern(dash) mcolor(cranberry) msymbol(square) `lineopts1'),  ///
		$graphopts /// 
		ytitle("Volatility (SD of Yields, p.p.)",size(small)) /// 
		legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) /// 
		title("`title`i''") name(gr`i',replace) xline(`xline' , `lineopts') yline(`yline' , `lineopts')
	restore 
}

global combopts xcommon ycommon rows(2) cols(2)
qui grc1leg gr3 gr2 gr1 gr4, legendfrom(gr2) name(grcomb_main,replace) $combopts 
qui graph display grcomb_main, ysize(80) xsize(100) scale(.9)
qui graph export "${oup}/synth_graph_main_att.pdf", $export

end 

********************************************************************************
********************************************************************************
* Program 19: Smoke plot 
********************************************************************************
********************************************************************************
cap program drop create_smoke_plot
program define create_smoke_plot, rclass 

* 1. Load Real Results
use "${oup}/sdid_results.dta", clear 
keep if Y_sdid != .
keep event_time tr_eff_ev id mofd
tempfile sdid_treff 
save `sdid_treff'

* 2. Append Placebo Results
use "${oup}/sdid_placebo_distributions_clean.dta", clear 

gen p10 = tr_eff_ev
gen p90 = tr_eff_ev
gen p95 = tr_eff_ev
gen p05 = tr_eff_ev
gen p01 = tr_eff_ev
gen p99 = tr_eff_ev
gen sd  = tr_eff_ev

keep if placebo_id != .
gcollapse (sd) sd (p01) p01 (p05) p05 (p10) p10 (p90) p90 (p95) p95 (p99) p99, by(event_time id)

tempfile placebo_events
save `placebo_events' 

use `sdid_treff', clear 
merge 1:1 id event_time using `placebo_events', keep(match master) nogen

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

forvalues j = 1(1)4{

preserve 
use "${oup}/synth_did_results_table.dta", clear 
qui order Results A AA AAA BBB
qui rename (Results A AA AAA BBB) (names b1 b2 b3 b4) 
local att = b`j'[1]
local pval = b`j'[8]
local excess_vol = b`j'[7]
local rmspe = b`j'[10]
restore 


preserve 
keep if id == `j'

qui sum mofd if event_time == 0 
qui local xline = r(mean)

local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)

qui twoway (rarea p01 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p05 p95 mofd,      fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p10 p90 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected tr_eff_ev mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , `lineopts') yline(0 , `lineopts') /// 
		$smoke_options name(smoke`j', replace) title("`title`j''", size(small) pos(11)) ///
		legend(order(- 1 5) note("ATT = `att'" "p-value = `pval'" "RMSPE = `rmspe'" "ATT (% Excess Volatility) = `excess_vol'", pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none))) 

restore 

}

global combopts xcommon ycommon rows(2) cols(2)
qui graph combine smoke3 smoke2 smoke1 smoke4, name(smoke_combined,replace) $combopts
qui graph display smoke_combined, ysize(80) xsize(100) scale(.9)
qui graph export "${oup}/smoke_plot_combined_att.pdf", $export

end 

********************************************************************************
********************************************************************************
* Program 20: Program to implement the estimation for all dependent variables [Important]
********************************************************************************
********************************************************************************

cap program drop full_sdid_estimation 
program define full_sdid_estimation, rclass 
    /* Define syntax: 
       - Makes 'placebos' an optional argument.
       - Returns the value in local macro `placebos'.
    */
    syntax [, Placebos(string)]

    * Set default to "off" if the user didn't provide the option
    if "`placebos'" == "" {
        local placebos "off"
    }

    ********************************************************************************
    * Step 1: Estimate the synth did model 
    ******************************************************************************** * save data loaded in console - depvar already filtered

    * Analysis Window 
    qui keep if month_exp > 3 

    tempfile data_analysis
    save `data_analysis', replace 

    * Run Estimation 
    sdid_est_full

    tempfile sdid_results 
    save `sdid_results'
    save "${oup}/sdid_results.dta", replace

    ********************************************************************************
    * Step 2: Estimate the placebo
    * Placebo Estimation for Statistical Inference 
    * Only runs if placebos("on") is specified
    ********************************************************************************
    if "`placebos'" == "on" {
        noisily display "Running Placebo Loops..."
        use `data_analysis', clear 
        * Estimate Placebo Distribution for each credit rating 
        run_placebo_loops
    }
    else {
        noisily display "Skipping Placebo Loops (placebos set to off)..."
    }

    ********************************************************************************
    * Step 3: Construct Regression Table with Rank-based p-values 
    * INFERENCE: Exact P-Values and Standard Errors
    ********************************************************************************
    qui construct_att_table
    ********************************************************************************

    ********************************************************************************
    * Step 4. Get Treated vs Synth Graph 
    ********************************************************************************
    qui create_treat_synth_graph
    ********************************************************************************

    ********************************************************************************
    * Step 5. Smoke plot 
    ********************************************************************************
    qui create_smoke_plot
    ********************************************************************************

end

********************************************************************************
********************************************************************************
* Program 21: Robustness Check: CRF and MLF [Construct ATT Table] 
********************************************************************************
********************************************************************************

cap program drop construct_att_table_crf 
program define construct_att_table_crf, rclass 

* 1. Load Real Results
use "${oup}/sdid_results.dta", clear 
collapse (mean) att, by(id)
gen placebo_id = 0 // Marker for the "Real" treated unit
reshape wide att, i(placebo_id) j(id)
tempfile sdid_att 
save `sdid_att'

* 2. Append Placebo Results
use "${oup}/sdid_placebo_distributions.dta", clear 
cap drop survival

preserve 
gcollapse (mean) rmspe, by(placebo_id id)
qui gen survival = 0 
qui replace survival = 1 if rmspe <= $rmspe_cutoff
keep placebo_id id survival 
tempfile placebo_survival 
save `placebo_survival', replace 
restore 

merge m:1 id placebo_id using `placebo_survival', keep(match master) nogen
* keep only good placebos 
tabstat rmspe, by(survival) stat(mean n)
tab survival
keep if survival == 1

save "${oup}/sdid_placebo_distributions_clean.dta", replace 
***** save data for further analysis 

*use "${oup}/sdid_placebo_distributions_clean.dta", clear 
gcollapse (mean) att, by(placebo_id id)
reshape wide att, j(id) i(placebo_id)
*rename attp* att* 
append using `sdid_att'
sort placebo_id


/// Matrix to Store Results 
local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"	

matrix define R=J(12,$tot,.)
matrix colnames R = "A (Below Median)"	"A (Above Median)" "AA (Below Median)" "AA (Above Median)" "AAA (Below Median)" "AAA (Above Median)" "BBB (Below Median)" "BBB (Above Median)" 
matlist R 

* Matrix with regression results 


* 3. Calculate Inference Metrics
* We loop over the 4 outcomes (AAA, AA, A, BBB)
forvalues i = 1(1)$tot {
    * A. Get the Real ATT value (stored where placebo_id == 0)
    qui sum att`i' if placebo_id == 0
    local real_att = r(mean)
    mat R[1,`i'] = `real_att'
	
    * B. Calculate Standard Error 
    * (SD of the placebo distribution, usually excluding the real unit)
    qui sum att`i' if placebo_id != 0
    gen se`i' = r(sd)
    mat R[2,`i'] = r(sd)
	
	_pctile att`i' if placebo_id != 0, percentiles(2.5 97.5)
	mat R[3,`i'] = r(r1)
	mat R[4,`i'] = r(r2)
	
    * C. Two-Sided P-Value (Recommended)
    * Checks if abs(placebo) > abs(real)
    * Formula: (Count + 1) / (N_donors + 1)
    gen abs_diff`i' = abs(att`i') >= abs(`real_att')
    qui count if abs_diff`i' == 1 & placebo_id != 0
    local count_extreme = r(N)
    qui count if placebo_id != 0
    local N_placebos = r(N)
    
    gen pval_2sided`i' = (`count_extreme' + 1) / (`N_placebos' + 1)
	qui sum pval_2sided`i'
    mat R[6,`i'] = r(mean)
	
    * D. One-Sided P-Value (Left Tail, if you expect negative effects)
    * Checks if placebo < real
    gen left_diff`i' = att`i' <= `real_att'
    qui count if left_diff`i' == 1 & placebo_id != 0
    local count_lower = r(N)
    
    gen pval_1sided`i' = (`count_lower' + 1) / (`N_placebos' + 1)
	qui sum pval_1sided`i'
	mat R[5,`i'] = r(mean)
	qui local pval1 = round(r(mean),0.0001)
	
	
		/// Percentiles for lines in density plot
	qui cumul att`i' , gen(att`i'_cdf)
	/// Percentile 2.5% 
	qui sum att`i'  if att`i'_cdf <= 0.025
	local p025 = r(max)
	/// Percentile 5.0% 
	qui sum att`i'  if att`i'_cdf <= 0.05
	local p050 = r(max)	
	/// Percentile 95.0% 
	qui sum att`i'  if att`i'_cdf <= 0.95
	local p950 = r(max)
	/// Percentile 97.5% 
	qui sum att`i'  if att`i'_cdf <= 0.975
	local p975 = r(max)
	
	/// ATE's Empirical Distribution - 
	local density_opts recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(`real_att', lcolor(maroon) lpattern(longdash)) xtitle("ATT Estimate") ytitle("Density") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) xscale(range(0 $ate)) legend(off) yscale(titlegap(0))
	/// Percentiles plot
	local line1 lcolor(ebblue) lpattern(shortdash) lwidth(medthin)
	local line2 lcolor(eltblue) lpattern(longdash) lwidth(medthin)
	local percentile_lines xline(`p050', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity att`i', `density_opts' title("`title`i'': Left Tail Test p-value = `pval1'", pos(11) size(small)) name(att_dens`i',replace) `percentile_lines'
	
	
	preserve 
	use "${oup}/sdid_results.dta", clear 
	qui keep if id == `i'
	qui keep if Y_treated != .
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absatt = abs(`real_att')
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum Y_treated if event_time < -1
	local vol_pre = r(mean)
	mat R[7,`i'] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum Y_treated if event_time == -1
	local vol_treat = r(mean)
	mat R[8,`i'] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,`i'] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absatt'/`excess_vol')
	if abs(`ate_excess_vol') > 300 {
	local ate_excess_vol = "."
	}
	mat R[10,`i'] = `ate_excess_vol'
	/// RMSE 
	qui sum rmspe 
	mat R[11,`i'] = r(mean)
	/// Id
	mat R[12,`i'] = `i'
	restore 
	
}


matlist R 
 
/// Results as a transpose 
matrix define M = R'
/// Clear the environment 
clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
replace M6 = 0 if M6 == . 
/// Drop ate excess volatility if the effect is not interpretab;e 
replace M10 = . if M10 < -300 | M10 > 300
/// Statistical Significance: Left-sided test  
qui gen stars = "" 
qui replace stars = "*" if M5 < 0.1
qui replace stars = "**" if M5 < 0.05 
qui replace stars = "***" if M5 < 0.01
/// Format Variables 
qui tostring M1, gen(ate) force format(%12.4fc)
qui tostring M2, gen(se) force format(%12.4fc)
qui tostring M3, gen(ci_min) force format(%12.4fc)
qui tostring M4, gen(ci_max) force format(%12.4fc)
qui tostring M5, gen(pval1) force format(%12.4fc)
qui tostring M6, gen(pval2) force format(%12.4fc)
qui tostring M7, gen(vol_pre) force format(%12.4fc)
qui tostring M8, gen(vol_treat) force format(%12.4fc)
qui tostring M9, gen(excess_vol) force format(%12.4fc)
qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
qui tostring M11, gen(rmspe) force format(%12.4fc)
qui replace ate_excess_vol = ate_excess_vol + "\%"
qui replace ate_excess_vol = "NA" if ate_excess_vol == ".\%"
qui replace se = "(" + se + ")"
qui replace ate = ate + stars
qui gen cint = "(" + ci_min + "," + ci_max + ")"

qui gen id = _n
qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval1 pval2 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
qui keep id b*
qui reshape long b, i(id) j(vars) string
qui destring vars, gen(id1)
qui drop vars 
qui reshape wide b, i(id1) j(id)  
qui gen names = ""
qui replace names = "ATT (a)" if _n == 1
qui replace names = "SE" if _n == 2
qui replace names = "Conf Interval" if _n == 3
qui replace names = "Historic Volatility (b)" if _n == 4
qui replace names = "Volatility March 2020 (c)" if _n == 5
qui replace names = "Excess Volatility (d = c - b)" if _n == 6
qui replace names = "ATT, % Excess Volatility (e = d/a)" if _n == 7
qui replace names = "P-Value (Left Tail)" if _n == 8
qui replace names = "P-Value (Two Tails)" if _n == 9
qui replace names = "RMSPE" if _n == 10
qui drop id1

label variable b1 "A (Below Median)"		
label variable b2 "A (Above Median)"		
label variable b3 "AA (Below Median)"		
label variable b4 "AA (Above Median)"		
label variable b5 "AAA (Below Median)"		
label variable b6 "AAA (Above Median)"	
label variable b7 "BBB (Below Median)"		
label variable b8 "BBB (Above Median)"	   

qui rename (names b1 b2 b3 b4 b5 b6 b7 b8) (Results A_bm A_am AA_bm AA_am AAA_bm AAA_am BBB_bm BBB_am)
order Results AAA_bm AAA_am AA_bm AA_am A_bm A_am BBB_bm BBB_am
* Display
list, noobs sep(0) abbrev(32)
* 9. Export
* Save final results with valid SEs and Exact P-values
save "${oup}/synth_did_results_table.dta",replace

texsave Results AAA_bm AAA_am AA_bm AA_am A_bm A_am BBB_bm BBB_am using "${oup}/synth_did_results_table.tex", ///
    replace ///
    nofix ///
    align(l c c c c c c c) ///
    hlines(5) ///
    label("tab:synth_did_results_table") 

	*title("Average Treatment Effect on the Treated: MLF impact on Municipal Volatility") ///

global combopts xcommon ycommon rows(2) cols(2)
graph combine att_dens5 att_dens6 att_dens3 att_dens4, name(attdenscomb1,replace) $combopts 
graph combine att_dens1 att_dens2 att_dens7 att_dens8, name(attdenscomb2,replace) $combopts 

graph display attdenscomb1, ysize(80) xsize(100) scale(.9)
graph export "${oup}/att_dens_cares1.pdf", $export 

graph display attdenscomb2, ysize(80) xsize(100) scale(.9)
graph export "${oup}/att_dens_cares2.pdf", $export 



end

********************************************************************************
********************************************************************************
* Program 22: Robustness Check: CRF and MLF [Treated Synth Graph] 
********************************************************************************
********************************************************************************

cap program drop create_treat_synth_graph_crf 
program define create_treat_synth_graph_crf, rclass 

use "${oup}/sdid_results.dta", clear 
keep if Y_sdid != .
* Map IDs to Credit Ratings (Columns)
gen rating = ""

replace rating = "A (Below Median)"	  if id == 1
replace rating = "A (Above Median)"	  if id == 2
replace rating = "AA (Below Median)"  if id == 3
replace rating = "AA (Above Median)"  if id == 4
replace rating = "AAA (Below Median)" if id == 5
replace rating = "AAA (Above Median)" if id == 6
replace rating = "BBB (Below Median)" if id == 7
replace rating = "BBB (Above Median)" if id == 8

keep rating event_time Y* id mofd mn_pre

rename (Y_sdid Y_treated) (synthetic treated)

qui tab id 
global rows = r(r)

qui sum mofd if event_time == 0 
qui local xline = r(mean)

local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"			

forvalues i=1(1)$rows {
    preserve 
	
	qui keep if id == `i'
	qui sum mn_pre
	local yline = r(mean)
	qui local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
	qui local lineopts1 lwidth(medthin) msize(vsmall)
	twoway (line treated mofd, lcolor(black) lpattern(solid) mcolor(black) msymbol(circle) `lineopts1') ///
		(line synth mofd, lcolor(cranberry) lpattern(dash) mcolor(cranberry) msymbol(square) `lineopts1'),  ///
		$graphopts /// 
		ytitle("Volatility (SD of Yields, p.p.)",size(small)) /// 
		legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) /// 
		title("`title`i''") name(gr`i',replace) xline(`xline' , `lineopts') yline(`yline' , `lineopts')
	restore 
}


global combopts xcommon ycommon rows(2) cols(2)
grc1leg gr5 gr6 gr3 gr4, legendfrom(gr4) name(grcombrc1,replace) $combopts 
grc1leg gr1 gr2 gr7 gr8, legendfrom(gr2) name(grcombrc2,replace) $combopts 

graph display grcombrc1, ysize(80) xsize(100) scale(.9)
graph export "${oup}/synth_graph_main_att_cares1.pdf", $export 

graph display grcombrc2, ysize(80) xsize(100) scale(.9)
graph export "${oup}/synth_graph_main_att_cares2.pdf", $export 

end 

********************************************************************************
********************************************************************************
* Program 23: Robustness Check: CRF and MLF [Smoke Plot] 
********************************************************************************
********************************************************************************

cap program drop create_smoke_plot_crf
program define create_smoke_plot_crf, rclass 

* 1. Load Real Results
use "${oup}/sdid_results.dta", clear 
keep if Y_sdid != .
keep event_time tr_eff_ev id mofd
tempfile sdid_treff 
save `sdid_treff'

* 2. Append Placebo Results
use "${oup}/sdid_placebo_distributions_clean.dta", clear 

gen p10 = tr_eff_ev
gen p90 = tr_eff_ev
gen p95 = tr_eff_ev
gen p05 = tr_eff_ev
gen p01 = tr_eff_ev
gen p99 = tr_eff_ev
gen sd  = tr_eff_ev

keep if placebo_id != .
gcollapse (sd) sd (p01) p01 (p05) p05 (p10) p10 (p90) p90 (p95) p95 (p99) p99, by(event_time id)

tempfile placebo_events
save `placebo_events' 


use `sdid_treff', clear 
merge 1:1 id event_time using `placebo_events', keep(match master) nogen


local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"

forvalues j = 1(1)$tot{

preserve 
use "${oup}/synth_did_results_table.dta", clear 
qui rename (Results A_bm A_am AA_bm AA_am AAA_bm AAA_am BBB_bm BBB_am) (names b1 b2 b3 b4 b5 b6 b7 b8) 
local att = b`j'[1]
local pval = b`j'[8]
local excess_vol = b`j'[7]
local rmspe = b`j'[10]
restore 


preserve 
keep if id == `j'
qui sum mofd if event_time == 0 
qui local xline = r(mean)
local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)

qui twoway (rarea p01 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p05 p95 mofd,      fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p10 p90 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected tr_eff_ev mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , `lineopts') yline(0 , `lineopts') $smoke_options name(sm`j', replace) title("`title`j''", size(small) pos(11)) ///
		legend(order(- 1 5) note("ATT = `att'" "p-value = `pval'" "RMSPE = `rmspe'" "ATT (% Excess Volatility) = `excess_vol'", pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none))) 

restore 

}

global combopts xcommon ycommon rows(2) cols(2)

graph combine sm5 sm6 sm3 sm4, name(smcomb1,replace) $combopts 
graph combine sm1 sm2 sm7 sm8, name(smcomb2,replace) $combopts 

graph display smcomb1, ysize(80) xsize(100) scale(.9)
graph export "${oup}/smoke_plot_combined_att_cares1.pdf", $export 

graph display smcomb2, ysize(80) xsize(100) scale(.9)
graph export "${oup}/smoke_plot_combined_att_cares2.pdf", $export 


end 

********************************************************************************
********************************************************************************
* Program 24: Robustness Check: CRF and MLF [Full Implementation]
********************************************************************************
********************************************************************************

cap program drop sdid_crf 
program define sdid_crf, rclass 
    /* Define syntax: 
       - Makes 'placebos' an optional argument.
       - Returns the value in local macro `placebos'.
    */
    syntax [, Placebos(string)]

    * Set default to "off" if the user didn't provide the option
    if "`placebos'" == "" {
        local placebos "off"
    }

    ********************************************************************************
    * Step 1: Estimate the synth did model 
    ******************************************************************************** * save data loaded in console - depvar already filtered

    * Analysis Window 
    qui keep if month_exp > 3 
    *keep if month_exp <= $keep_post
	* Solve missing observation: replace with the observation from the following month 
	qui sum v if name == "A-p0-p50" & mofd == tm(2019m5)
	qui replace v = r(mean) if name == "A-p0-p50" & mofd == tm(2019m4)
    tempfile data_analysis
    save `data_analysis', replace 

    * Run Estimation 
    qui sdid_est_full

    tempfile sdid_results 
    save `sdid_results'
    save "${oup}/sdid_results.dta", replace

    ********************************************************************************
    * Step 2: Estimate the placebo
    * Placebo Estimation for Statistical Inference 
    * Only runs if placebos("on") is specified
    ********************************************************************************
    if "`placebos'" == "on" {
        noisily display "Running Placebo Loops..."
        use `data_analysis', clear 
        * Estimate Placebo Distribution for each credit rating 
        run_placebo_loops
    }
    else {
        noisily display "Skipping Placebo Loops (placebos set to off)..."
    }

    ********************************************************************************
    * Step 3: Construct Regression Table with Rank-based p-values 
    ********************************************************************************
    qui construct_att_table_crf
    ********************************************************************************

    ********************************************************************************
    * Step 4. Get Treated vs Synth Graph 
    ********************************************************************************
    qui create_treat_synth_graph_crf
    ********************************************************************************

    ********************************************************************************
    * Step 5. Smoke plot 
    ********************************************************************************
    qui create_smoke_plot_crf
    ********************************************************************************

end


********************************************************************************
********************************************************************************
* Program 25: Robustness Check: Dynamic Treatment Effect and Persistence 
********************************************************************************
********************************************************************************

cap program drop persistance_inference 
program define persistance_inference, rclass 
* Compute percentiles p-values 
	keep att period id placebo_id 
	* Get individual values of att for each placebo 
	gcollapse (mean) att, by(placebo_id period id)
	gsort id period placebo_id
	* Get ATT from baseline model 
	gen att_est = att if placebo_id == 0
	bysort period id: egen att_real = mean(att_est) 
	gsort id period placebo_id
	drop att_est
	* Checks if placebo < real
    gen left_diff = att <= att_real
    count if left_diff == 1 & placebo_id != 0
    gen count_lower = r(N)
    gen pval_1sided = (count_lower + 1) / (_N)
	/// Create Percentile Variables 
	qui gen p01 = . 
	qui gen p05 = . 
	qui gen p10 = . 
	qui gen p90 = . 
	qui gen p95 = . 
	qui gen p99 = . 
	/// Percentiles of the placebos 
	_pctile att     if placebo_id != 0 , percentiles(1 5 10 90 95 99)
	qui replace p01  = r(r1) 
	qui replace p05  = r(r2) 
	qui replace p10 = r(r3) 
	qui replace p90 = r(r4)
	qui replace p95 = r(r5) 
	qui replace p99 = r(r6)
	/// Keep only one row 
	keep if placebo_id == 0
end 

********************************************************************************
********************************************************************************
* Program 26: Robustness Check: Dynamic Treatment Effect and Persistence 
********************************************************************************
********************************************************************************


cap program drop sdid_persistence 
program define sdid_persistence, rclass 
    /* Define syntax: 
       - Makes 'placebos' an optional argument.
       - Returns the value in local macro `placebos'.
    */
    syntax [, Placebos(string)]

    * Set default to "off" if the user didn't provide the option
    if "`placebos'" == "" {
        local placebos "off"
    }

    ********************************************************************************
    * Step 1: Estimate the synth did model 
    ******************************************************************************** * save data loaded in console - depvar already filtered

    * Analysis Window 
    qui keep if month_exp > 3 
    *keep if month_exp <= $keep_post
	* Solve missing observation: replace with the observation from the following month 
	
    tempfile data_analysis
    save `data_analysis', replace 

	* Load data
	use `data_analysis', clear 
	* Change the duration of the post-treatment period 
	tab month_exp if month_exp >= ${treat_period} == 1, matrow(P)
	global periods = r(r)
	
	* For each period 
	forvalues j = 1(1)$periods{
		use `data_analysis', clear 
		* restrict post period 
		qui keep if month_exp <= P[`j',1]
		* Do estimation for all outcomes 
		qui sdid_est_full
		qui gen period = P[`j',1]
		* save results 
		tempfile persist_res`j'
		save `persist_res`j'', replace 
		}
 
use `persist_res1', clear 
forvalues j = 2(1)$periods{
	append using `persist_res`j''
}
	

    save "${oup}/sdid_results.dta", replace

    ********************************************************************************
    * Step 2: Estimate the placebo
    * Placebo Estimation for Statistical Inference 
    * Only runs if placebos("on") is specified
    ********************************************************************************
    if "`placebos'" == "on" {
        noisily display "Running Placebo Loops..."
		
	* For each period 
	forvalues j = 1(1)$periods{
        use `data_analysis', clear 
		* restrict post period 
		qui keep if month_exp <= P[`j',1]
        * Estimate Placebo Distribution for each credit rating 
        run_placebo_loops
		* Add period 
		gen period = P[`j', 1]
		tempfile placebo_per`j'
		save `placebo_per`j'', replace 
	}
	 
	use `placebo_per1', clear 
	forvalues j = 2(1)$periods{
	append using `placebo_per`j''
	}
    save "${oup}/sdid_placebo_distributions_persistance.dta", replace
	
    }
    else {
        noisily display "Skipping Placebo Loops (placebos set to off)..."
    }

    ********************************************************************************
    * Step 3: Append Results and Create Graph 
    ********************************************************************************
	* Append results 
	use "${oup}/sdid_results.dta", clear
	keep if month_exp != .
	drop weight donor_id asset_class varlab name
	gen placebo_id = 0
	append using "${oup}/sdid_placebo_distributions_persistance.dta"
	* keep only good placebos 
	qui gen survival = 0 
	qui replace survival = 1 if rmspe <= $rmspe_cutoff
	// keep also treated series 
	qui replace survival = 1 if placebo_id == 0
	keep if survival == 1
	drop survival
	tempfile persistance_data
	save `persistance_data', replace
	
	preserve 
	keep if event_time >= 0 & mofd != .
	keep event_time mofd
	duplicates drop event_time mofd, force
	gen period = $treat_period + _n -1
	tempfile dates 
	save `dates', replace 
	restore 
	
	* Periods 
	tab period, matrow(G)
	global period = r(r)
	
	* Ids 
	tab id, matrow(T)
	global tot = r(r)
	
	
	* For each period 
	forvalues j = 1(1)$periods{
	
	use `persistance_data', clear
	* keep data for period j
	qui keep if period == G[`j',1]
	
	* For each dependent variable i
	forvalues i =1(1)$tot{
	preserve 
	qui keep if id == `i'
	* compute pvalues and percentiles of placebo distribution 
	qui persistance_inference	
	tempfile id`i'
	save `id`i'', replace 
	restore 
	}
	
	* Append results for all dep vars
	use `id1', clear 
	forvalues i =2(1)$tot{
	qui append using `id`i''
	}
	* Save results for all dep vars in period j
	tempfile period_results`j'
	save `period_results`j'', replace 
	}
	
	* Append results 
	use `period_results1', clear 
	forvalues j = 2(1)$periods{
	append using `period_results`j''
	}
	
	* Create stars variable 
	gen stars = ""
	replace stars = "*" if pval_1sided <= 0.10 & pval_1sided > 0.05
	replace stars = "**" if pval_1sided <= 0.05 & pval_1sided > 0.01
	replace stars = "***" if pval_1sided <= 0.01 
	
	* Compute percentiles and ATT by periods in the post period 
	merge m:1 period using `dates', keep(match master) nogen
	* Export 
	save "${oup}/att_persistence_results.dta", replace 
	
	local title1 = "A"
	local title2 = "AA"
	local title3 = "AAA"
	local title4 = "BBB"
	
	* 1. Define Options for Axis 1 (Volatility)
	* Added axis(1) explicitly to ytitle/ylabel to avoid conflicts
	global dyn_options ytitle("Volatility (p.p.)", size(vsmall) axis(1)) ylabel(#8, nogrid labsize(vsmall) angle(0) axis(1)) xtitle("", size(vsmall)) xlabel(#21, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3) axis(1)) plotregion(lcolor()) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
	
	* 2. Define Options for Axis 2 (P-Values)
	* Range 0 to 1, with label size matching the left axis
	
	forvalues i = 1(1)4 {
		preserve 
		qui keep if id == `i'
		
		* Generate Symbol Variables
		gen att_sig3 = att_real if pval_1sided <= 0.01 
		gen att_sig2 = att_real if pval_1sided <= 0.05 & pval_1sided > 0.01
		gen att_sig1 = att_real if pval_1sided <= 0.10 & pval_1sided > 0.05
		gen att_ns   = att_real if pval_1sided > 0.10
		
		local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
		
		* Plot
		qui twoway ///
			/// --- LEFT AXIS (ATT & CI) ---
			(rarea p01 p99 mofd,      fc(gs13%40) lc(gs15%40) lw(medthick) yaxis(1)) ///
			(rarea p05 p95 mofd,      fc(gs10%40) lc(gs12%40) lw(medthick) yaxis(1)) ///	
			(rarea p10 p90 mofd,      fc(gs7%40)  lc(gs9%40)  lw(medthick) yaxis(1)) ///
			(line att_real mofd, sort lcolor(black) lpattern(solid)        yaxis(1)) ///
			(scatter att_sig3 mofd, mcolor(red)   msize(small) msymbol(triangle) yaxis(1)) ///
			(scatter att_sig2 mofd, mcolor(blue)  msize(small) msymbol(square)   yaxis(1)) ///
			(scatter att_sig1 mofd, mcolor(green) msize(small) msymbol(diamond)  yaxis(1)) ///
			(scatter att_ns   mofd, mcolor(black) msize(small) msymbol(Oh)       yaxis(1)), ///
			///
			/// --- RIGHT AXIS (P-VALUES) ---
			/// Plotting the p-value as a DASHED line on AXIS 2
			/// (line pval_1sided mofd, sort lcolor(gs8) lpattern(dash) lwidth(thin) yaxis(2)), ///
			///
			/// --- OPTIONS ---
			yline(0, axis(1) `lineopts') /// Zero line for ATT
			/// yline(0.1 0.05, axis(2) lcolor(gs12) lpattern(dot)) /// Thresholds for P-value (Right Axis)
			$dyn_options ///
			name(att`i', replace) title("`title`i''", size(small) pos(11)) ///
			legend(off) 
			
		restore 
	}

	qui graph combine att3 att2 att1 att4, rows(2) cols(2) ycommon name(cumulativeatt, replace)
	qui graph display cumulativeatt, ysize(80) xsize(100) scale(.9)
	qui graph export "${oup}/cumulativeatt_main.pdf", replace
	
	* End 
	
end


********************************************************************************
********************************************************************************
* Program 27: Robustness Check: Leave One Out For States 
********************************************************************************
********************************************************************************

cap program drop leave_one_state 
program define leave_one_state, rclass 
    /* Define syntax: 
       - Makes 'placebos' an optional argument.
       - Returns the value in local macro `placebos'.
    */
	
	* We set a default of -999 for state_code to check if the user input it later
    syntax , [placebos(string)]

    * Set default to "off" if the user didn't provide the option
    if "`placebos'" == "" {
        local placebos "off"
    }
	
	/// Build a measure of the average yield for each trade date (daily)
	qui gcollapse (mean) YIELD, by(rating_agg TRADE_DATE) 
	qui xtset rating_agg TRADE_DATE
	qui rename (YIELD TRADE_DATE) (yield date)
	qui reshape wide yield, i(date) j(rating_agg)
	global lab1 "3a" 
	global lab2 "2a" 
	global lab3 "a" 
	global lab4 "3b"

	forvalues i=1(1)4{
    label variable yield`i' "Yield - ${lab`i'}"
	qui rename yield`i' yield${lab`i'}
	}
	
	********************************************************************************
    * Step 1: Prepare Data for Analysis  
    ********************************************************************************

    * --------------------------
    qui clean_baseline
    qui synth_prep 
    * --------------------------
	
	qui replace varlab = "Municipal Bonds" if data == "SP Munis"
	qui cap drop asset_class
	qui gen asset_class = ""
	qui replace asset_class = "Outcome" if data == "Outcome"
	qui replace asset_class = "Municipal Bonds" if varlab == "Municipal Bonds"
	qui replace asset_class = "Stock Market Index" if regexm(varlab, "Index")
	qui replace asset_class = "Currency"           if regexm(varlab, "Spot Exchange Rate")
	qui replace asset_class = "Stock Market Index"           if regexm(varlab, "Currncy")
	qui replace asset_class = "Commodity"          if regexm(varlab, "Comdty")
	qui replace asset_class = "Commodity"          if regexm(varlab, "Equity")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "GOVT")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "Govt")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "GVOT")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "CTDEMII5Y")
	qui replace varlab = strtrim(stritrim(subinstr(varlab, "Spot Exchange Rate", "", .)))
	
	/// Rating Variable for Filtering 
	/// AAA --> rating_agg = 1; id = 3
	/// AA  --> rating_agg = 2; id = 2
	/// A   --> rating_agg = 3; id = 1
	/// BBB --> rating_agg = 4; id = 4
	qui gen rating_ind = . 
	qui replace rating_ind = 1 if id == 3
	qui replace rating_ind = 2 if id == 2
	qui replace rating_ind = 3 if id == 1
	qui replace rating_ind = 4 if id == 4
	
	* Exclude Muni Donors 
	drop if asset_class == "Municipal Bonds"

	********************************************************************************
    * Do Analysis only of the Affected Credit Rating 
    ********************************************************************************

	* Analysis Window 
	qui keep if month_exp > 3 
	
	* Check if missing data due to the state drop 
	qui sum month_exp if missing(v) & data == "Outcome"
	local month_dropped = r(mean)
	
	if `month_dropped' > 0 {
		qui tab month_exp if missing(v) & data == "Outcome"
		drop if month_exp == `month_dropped' 
		noisily display "Missing Months: Droppping Observations from Month `month_dropped'"

    }
	
	/// Keep only the affected rating 
	qui keep if rating_ind == $rating_st | data != "Outcome"
	/// Get id of affected category 
	qui sum id if rating_ind == $rating_st & data == "Outcome"
	global id_treated = r(mean)
	
	qui drop rating_ind
	
	qui tempfile data_analysis
	qui save `data_analysis', replace 

	* Run Estimation 
	qui sdid_prep
	qui sdid_est

	* Add id variable 
	qui gen id = $id_treated
	
    qui tempfile sdid_results 
    qui save `sdid_results'
    qui save "${oup}/sdid_results.dta", replace

    ********************************************************************************
    * Step 2: Estimate the placebo
    * Placebo Estimation for Statistical Inference 
	* Here every time we need to run the placebo distribution. 
	* Rationale: The treatment effect is estimated adjusting the variables to the mean 
	* and variance of the treated unit. Dropping a state changes the mean and sd. 
	* Hence, we need to estimate the distribution for this adjustments. 
    ********************************************************************************
    if "`placebos'" == "on" {
        noisily display "Running Placebo Loops..."
        qui use `data_analysis', clear 

		*Prepare data for analysis 
		qui sdid_prep

		* 1. Create Outcomes
		qui sum v if id == $id_treated & post == 0
		local pre_mean = r(mean)
		local pre_sd = r(sd)

		* We rescale everyone (including the placebo treated) to look like Real Unit `i`
		qui gen v_lev = `pre_sd' * v_norm + `pre_mean'

		* 1. DEFINE DONOR POOL
		* Identify the donors (exclude real treated units to avoid contamination)
 
		qui keep if data != "Outcome" 

		qui tab id, matrow(Donors)
		global num_donors = r(r)
		* Save this "clean" donor dataset to memory/disk to speed up the loop
		qui tempfile donor_data
		qui save `donor_data'


		forvalues j = 1(1)$num_donors {
		
		qui use `donor_data', clear 
		* Get the actual ID of the donor from the matrix stored earlier
		local donor_id = Donors[`j',1]
		* Analysis Window 
		qui keep if month_exp > 3 
		*qui keep if month_exp <= $keep_post
		* A. Set up Placebo Treatment
		* This donor becomes the "treated" unit
		qui replace treat = 0 
		qui replace treat = 1 if id == `donor_id'
		qui replace did = 0 
		qui replace did = 1 if treat == 1 & post == 1
		
		* D. Store Results
		* We need to save the ATT, the Target Unit (i), and the Placebo Unit (j)
		* C. Run SDID
		* Note: vce(noinference) makes this fast
		qui sdid v_lev id month_exp did, vce(noinference) method(sdid)
		
		qui local att = e(ATT)
		/// Get Output: weights and treated series 
		matrix lambda = e(lambda)[1..12,1]
		mat SDID = e(series)
		* Pre-Treatment Period
		mat Yc =SDID[1..12,2]	
		mat Yt =SDID[1..12,3]	
		** Results for Event Study Plot 
		matrix aux = lambda' * (Yt - Yc)
		scalar meanpre_o = aux[1,1]
		
		* 1. Create the difference vector 
		matrix diff = Yt - Yc
	
		* 2. Calculate Sum of Squared Errors (SSE)
		* We multiply Gap transposed by Gap to sum the squared elements
		matrix SSE_mat = diff' * diff 
		scalar sse = SSE_mat[1,1]
	
		* 3. Compute RMSPE
		* We divide by the number of pre-treatment periods (rows in your Yt matrix)
		scalar T_pre = rowsof(Yt)
		scalar rmspe = sqrt(sse / T_pre)
			
		qui clear 
		qui svmat SDID
		qui rename (SDID1 SDID2 SDID3) (month_exp Y_sdid Y_treated)
		qui svmat Yt 
		qui svmat Yc
		qui sum Yt1
		loc Yt_mn=r(mean) 
		loc Yt_sd=r(sd) 
		qui sum Yc1
		loc Yc_mn=r(mean) 
		loc Yc_sd=r(sd) 
		qui gen CohenD_sdid = abs(`Yt_mn' - `Yc_mn') / (0.5*`Yt_sd'^2 + 0.5*`Yc_sd'^2)^(1/2)
		qui drop Yt1 Yc1
		* Treatment Effect is in units of the dependent variable 
		qui gen tr_eff = Y_treated - Y_sdid
		/// see page 29 of sdid stata paper 
		qui gen tr_eff_ev = tr_eff - meanpre_o
		qui gen event_time = month_exp - $treat_period
		qui gen rmspe = rmspe
		qui gen id = $id_treated
		qui gen att = `att'
		qui gen placebo_id = `donor_id' 
		
		qui tempfile placebo_donor`j'
		qui save `placebo_donor`j'', replace    
		dis "Placebo: Treated Unit $id_treated: Donor `j'"

		} 
	
		/// Append all placebos 
		qui use `placebo_donor1', replace 
		forvalues j = 2(1)$num_donors {
			qui append using `placebo_donor`j''
		}
		
		qui save "${oup}/sdid_placebo_distributions.dta", replace
		qui tempfile placebo_distribution
		save `placebo_distribution', replace 
	* End Placebo Estimation 	
		
    }
    else {
        noisily display "Skipping Placebo Loops (placebos set to off)..."
    }

    ********************************************************************************
    * Step 3: Construct Regression Table with Rank-based p-values 
    * INFERENCE: Exact P-Values and Standard Errors
    ********************************************************************************
    * Assumption drop 10% worst placebos 
    
	* 1. Load Real Results
	*qui use "${oup}/sdid_results.dta", clear 
	qui use `sdid_results', clear 
	qui collapse (mean) att*, by(id)
	qui gen placebo_id = 0 // Marker for the "Real" treated unit
	qui reshape wide att*, i(placebo_id) j(id)
	qui rename att* att
	qui tempfile sdid_att 
	qui save `sdid_att'
	
	* 2. Append Placebo Results
	*qui use "${oup}/sdid_placebo_distributions.dta", clear
	qui use `placebo_distribution', clear 
	cap drop survival
	
	qui preserve 
	qui gcollapse (mean) rmspe, by(placebo_id id)
	* keep only good placebos 
	qui gen survival = 0 
	qui replace survival = 1 if rmspe <= $rmspe_cutoff
	qui keep placebo_id id survival 
	qui tempfile placebo_survival 
	qui save `placebo_survival', replace 
	restore 
	
	qui merge m:1 id placebo_id using `placebo_survival', keep(match master) nogen
	* keep only good placebos 
	qui keep if survival == 1
	qui save "${oup}/sdid_placebo_distributions_clean.dta", replace 
	
	qui use "${oup}/sdid_placebo_distributions_clean.dta", clear 
	qui gcollapse (mean) att*, by(placebo_id id)
	qui reshape wide att*, j(id) i(placebo_id)
	qui rename att* att
	qui append using `sdid_att'
	qui sort placebo_id
    
	
	/// Matrix to Store Results 
	matrix define R=J(12,1,.)
	matrix rownames R = "att" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"

	* 3. Calculate Inference Metrics
	* We loop over the 4 outcomes (AAA, AA, A, BBB)
    * A. Get the Real ATT value (stored where placebo_id == 0)
    qui sum att if placebo_id == 0
    local real_att = r(mean)
    mat R[1,1] = `real_att'
	
    * B. Calculate Standard Error 
    * (SD of the placebo distribution, usually excluding the real unit)
    qui sum att if placebo_id != 0
    gen se = r(sd)
    mat R[2,1] = r(sd)
	
	qui _pctile att if placebo_id != 0, percentiles(2.5 97.5)
	mat R[3,1] = r(r1)
	mat R[4,1] = r(r2)
	
    * C. Two-Sided P-Value (Recommended)
    * Checks if abs(placebo) > abs(real)
    * Formula: (Count + 1) / (N_donors + 1)
    gen abs_diff = abs(att) >= abs(`real_att')
    qui count if abs_diff == 1 & placebo_id != 0
    local count_extreme = r(N)
    qui count if placebo_id != 0
    local N_placebos = r(N)
    
    gen pval_2sided = (`count_extreme' + 1) / (`N_placebos' + 1)
	qui sum pval_2sided
    mat R[6,1] = r(mean)
	
    * D. One-Sided P-Value (Left Tail, if you expect negative effects)
    * Checks if placebo < real
    qui gen left_diff = att <= `real_att'
    qui count if left_diff == 1 & placebo_id != 0
    local count_lower = r(N)
    
    gen pval_1sided = (`count_lower' + 1) / (`N_placebos' + 1)
	qui sum pval_1sided
	mat R[5,1] = r(mean)
	qui local pval1 = round(r(mean),0.0001)
	
	qui use "${oup}/sdid_results.dta", clear 
	qui keep if id == $id_treated
	qui keep if Y_treated != .
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absatt = abs(`real_att')
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum Y_treated if event_time < -1
	local vol_pre = r(mean)
	mat R[7,1] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum Y_treated if event_time == -1
	local vol_treat = r(mean)
	mat R[8,1] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,1] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absatt'/`excess_vol')
	if abs(`ate_excess_vol') > 300 {
	local ate_excess_vol = "."
	}
	mat R[10,1] = `ate_excess_vol'
	/// RMSE 
	qui sum rmspe 
	mat R[11,1] = r(mean)
	/// Id
	mat R[12,1] = $id_treated 
	
	/// Results as a transpose 
	matrix define M = R'
	/// Clear the environment 
	qui clear 
	qui svmat M
	qui format M* %12.4fc
	qui replace M5 = 0 if M5 == . 
	qui replace M6 = 0 if M6 == . 
	/// Drop ate excess volatility if the effect is not interpretab;e 
	qui replace M10 = . if M10 < -300 | M10 > 300
	/// Statistical Significance: Left-sided test  
	qui gen stars = "" 
	qui replace stars = "*" if M5 < 0.1
	qui replace stars = "**" if M5 < 0.05 
	qui replace stars = "***" if M5 < 0.01
	/// Format Variables 
	qui tostring M1, gen(ate) force format(%12.4fc)
	qui tostring M2, gen(se) force format(%12.4fc)
	qui tostring M3, gen(ci_min) force format(%12.4fc)
	qui tostring M4, gen(ci_max) force format(%12.4fc)
	qui tostring M5, gen(pval1) force format(%12.4fc)
	qui tostring M6, gen(pval2) force format(%12.4fc)
	qui tostring M7, gen(vol_pre) force format(%12.4fc)
	qui tostring M8, gen(vol_treat) force format(%12.4fc)
	qui tostring M9, gen(excess_vol) force format(%12.4fc)
	qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
	qui tostring M11, gen(rmspe) force format(%12.4fc)
	qui replace ate_excess_vol = ate_excess_vol + "\%"
	qui replace ate_excess_vol = "NA" if ate_excess_vol == ".\%"
	qui replace se = "(" + se + ")"
	qui replace ate = ate + stars
	qui gen cint = "(" + ci_min + "," + ci_max + ")"
	qui gen id = _n
	qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval1 pval2 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
	qui keep id b*
	qui reshape long b, i(id) j(vars) string
	qui destring vars, gen(id1)
	qui drop vars 
	qui reshape wide b, i(id1) j(id)  
	qui gen names = ""
	qui replace names = "ATT (a)" if _n == 1
	qui replace names = "SE" if _n == 2
	qui replace names = "Conf Interval" if _n == 3
	qui replace names = "Historic Volatility (b)" if _n == 4
	qui replace names = "Volatility March 2020 (c)" if _n == 5
	qui replace names = "Excess Volatility (d = c - b)" if _n == 6
	qui replace names = "ATT, % Excess Volatility (e = d/a)" if _n == 7
	qui replace names = "P-Value (Left Tail)" if _n == 8
	qui replace names = "P-Value (Two Tails)" if _n == 9
	qui replace names = "RMSPE" if _n == 10
	qui drop id1

	qui gen id_treated = $id_treated
	qui gen flag = "No"
	qui replace flag = "Missing Month: `month_dropped'" if `month_dropped' > 0
	
end


************************************************************************
********************************************************************************
* Program 28: Robustenss Check: Leave one Out, States 
********************************************************************************
********************************************************************************

cap program drop leave_one_out_est 
program define leave_one_out_est, rclass 
 
********************************************************************************
* Step 1: Estimate the synth did model 
******************************************************************************** 
* save data loaded in console - depvar already filtered
* Analysis Window 
qui keep if month_exp > 3 

tempfile data_analysis
save `data_analysis', replace  

qui tab id if treat == 0, matrow(D)
global donors = r(r)

forvalues j = 1(1)$donors{
	
	preserve 
	qui use `data_analysis', clear  
	* leave donor j out
	qui drop if id == D[`j', 1]
	* estimate all outcomes 
	qui sdid_est_full
	* add id for excluded donor 
	qui gen leave_id = D[`j', 1]
	* save results 
	qui tempfile leave_`j'
	qui save `leave_`j'', replace 
	restore 
	
}

qui use `leave_1', clear 
forvalues j = 2(1)$donors{
qui append using `leave_`j''
}

dis "Leave one out: `j' / $donors"

qui save "${oup}/sdid_att_results_leave_out.dta", replace 


end 

********************************************************************************
********************************************************************************
* Program 29: Robustness Check: Leave One Out For States (CRF)
********************************************************************************
********************************************************************************

cap program drop leave_one_state_crf 
program define leave_one_state_crf, rclass 
    /* Define syntax: 
       - Makes 'placebos' an optional argument.
       - Returns the value in local macro `placebos'.
    */
	
	* We set a default of -999 for state_code to check if the user input it later
    syntax , [placebos(string)]

    * Set default to "off" if the user didn't provide the option
    if "`placebos'" == "" {
        local placebos "off"
    }
	
	/// Build a measure of the average yield for each trade date (daily)
	qui gcollapse (mean) YIELD, by(group TRADE_DATE) 
	qui xtset group TRADE_DATE
	qui rename (YIELD TRADE_DATE) (yield date)
	qui reshape wide yield, i(date) j(group)
	
	global lab1 "A-p0-p50"		
	global lab2 "A-p51-p100"		
	global lab3 "AA-p0-p50"		
	global lab4 "AA-p51-p100"		
	global lab5 "AAA-p0-p50"		
	global lab6 "AAA-p51-p100"	
	global lab7 "BBB-p0-p50"		
	global lab8 "BBB-p51-p100"	
	
	forvalues i=1(1)8 {
        
        * Check if the variable exists
        capture confirm variable yield`i'
        
        * If _rc (return code) is not 0, the variable is missing
        if _rc != 0 {
            noisily display as error "CRITICAL ERROR: The code cannot proceed."
            noisily display as error "Reason: Variable 'yield`i'' is missing."
            noisily display as error "Missing Category: ${lab`i'}"
            exit
        }
        
        * If it exists, apply the label
        cap label variable yield`i' "Yield - `lab`i''"
    }
	
	********************************************************************************
    * Step 1: Prepare Data for Analysis  
    ********************************************************************************

	/// Prep data for robustness check 
	qui clean_robust
	/// Run the program that preps the data 
	qui synth_prep
	
	qui replace varlab = "Municipal Bonds" if data == "SP Munis"
	cap drop asset_class
	qui gen asset_class = ""
	qui replace asset_class = "Outcome" if data == "Outcome"
	qui replace asset_class = "Municipal Bonds" if varlab == "Municipal Bonds"
	qui replace asset_class = "Stock Market Index" if regexm(varlab, "Index")
	qui replace asset_class = "Currency"           if regexm(varlab, "Spot Exchange Rate")
	qui replace asset_class = "Stock Market Index"           if regexm(varlab, "Currncy")
	qui replace asset_class = "Commodity"          if regexm(varlab, "Comdty")
	qui replace asset_class = "Commodity"          if regexm(varlab, "Equity")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "GOVT")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "Govt")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "GVOT")
	qui replace asset_class = "Sovereign Bond"     if regexm(varlab, "CTDEMII5Y") 
	qui replace varlab = strtrim(stritrim(subinstr(varlab, "Spot Exchange Rate", "", .)))

	
	/// Rating Variable for Filtering 
	qui gen rating_ind = . 
	qui replace rating_ind = 1 if id == 5
	qui replace rating_ind = 2 if id == 6
	qui replace rating_ind = 3 if id == 3
	qui replace rating_ind = 4 if id == 4
	qui replace rating_ind = 5 if id == 1
	qui replace rating_ind = 6 if id == 2
	qui replace rating_ind = 7 if id == 7
	qui replace rating_ind = 8 if id == 8
	
	********************************************************************************
    * Do Analysis only of the Affected Credit Rating 
    ********************************************************************************

	* Analysis Window 
	qui keep if month_exp > 3 
	qui sum v if name == "A-p0-p50" & mofd == tm(2019m5)
	qui replace v = r(mean) if name == "A-p0-p50" & mofd == tm(2019m4)
	
	* Check if missing data due to the state drop 
	qui sum month_exp if missing(v) & data == "Outcome"
	local month_dropped = r(mean)
	
	if `month_dropped' > 0 {
		qui tab month_exp if missing(v) & data == "Outcome"
		drop if month_exp == `month_dropped' 
		noisily display "Missing Months: Droppping Observations from Month `month_dropped'"

    }
	
	/// Keep only the affected rating 
	qui keep if rating_ind == $rating_st | data != "Outcome"
	/// Get id of affected category 
	qui sum id if rating_ind == $rating_st & data == "Outcome"
	global id_treated = r(mean)
	
	* erase this one 
	*qui drop if id > 15 
	qui drop rating_ind
	
	qui tempfile data_analysis
	qui save `data_analysis', replace 

	* Run Estimation 
	qui sdid_prep
	qui sdid_est

	* Add id variable 
	qui gen id = $id_treated
	
    qui tempfile sdid_results 
    qui save `sdid_results'
    qui save "${oup}/sdid_results.dta", replace

    ********************************************************************************
    * Step 2: Estimate the placebo
    * Placebo Estimation for Statistical Inference 
	* Here every time we need to run the placebo distribution. 
	* Rationale: The treatment effect is estimated adjusting the variables to the mean 
	* and variance of the treated unit. Dropping a state changes the mean and sd. 
	* Hence, we need to estimate the distribution for this adjustments. 
    ********************************************************************************
    if "`placebos'" == "on" {
        noisily display "Running Placebo Loops..."
        qui use `data_analysis', clear 

		*Prepare data for analysis 
		qui sdid_prep

		* 1. Create Outcomes
		qui sum v if id == $id_treated & post == 0
		local pre_mean = r(mean)
		local pre_sd = r(sd)

		* We rescale everyone (including the placebo treated) to look like Real Unit `i`
		qui gen v_lev = `pre_sd' * v_norm + `pre_mean'

		* 1. DEFINE DONOR POOL
		* Identify the donors (exclude real treated units to avoid contamination)
 
		qui keep if data != "Outcome" 
		qui tab id, matrow(Donors)
		global num_donors = r(r)
		* Save this "clean" donor dataset to memory/disk to speed up the loop
		qui tempfile donor_data
		qui save `donor_data'


		forvalues j = 1(1)$num_donors {
		
		qui use `donor_data', clear 
		* Get the actual ID of the donor from the matrix stored earlier
		local donor_id = Donors[`j',1]
		* Analysis Window 
		qui keep if month_exp > 3 
		*qui keep if month_exp <= $keep_post
		* A. Set up Placebo Treatment
		* This donor becomes the "treated" unit
		qui replace treat = 0 
		qui replace treat = 1 if id == `donor_id'
		qui replace did = 0 
		qui replace did = 1 if treat == 1 & post == 1
		
		* D. Store Results
		* We need to save the ATT, the Target Unit (i), and the Placebo Unit (j)
		* C. Run SDID
		* Note: vce(noinference) makes this fast
		qui sdid v_lev id month_exp did, vce(noinference) method(sdid)
		
		qui local att = e(ATT)
		/// Get Output: weights and treated series 
		matrix lambda = e(lambda)[1..12,1]
		mat SDID = e(series)
		* Pre-Treatment Period
		mat Yc =SDID[1..12,2]	
		mat Yt =SDID[1..12,3]	
		** Results for Event Study Plot 
		matrix aux = lambda' * (Yt - Yc)
		scalar meanpre_o = aux[1,1]
		
		* 1. Create the difference vector 
		matrix diff = Yt - Yc
	
		* 2. Calculate Sum of Squared Errors (SSE)
		* We multiply Gap transposed by Gap to sum the squared elements
		matrix SSE_mat = diff' * diff 
		scalar sse = SSE_mat[1,1]
	
		* 3. Compute RMSPE
		* We divide by the number of pre-treatment periods (rows in your Yt matrix)
		scalar T_pre = rowsof(Yt)
		scalar rmspe = sqrt(sse / T_pre)
			
		qui clear 
		qui svmat SDID
		qui rename (SDID1 SDID2 SDID3) (month_exp Y_sdid Y_treated)
		qui svmat Yt 
		qui svmat Yc
		qui sum Yt1
		loc Yt_mn=r(mean) 
		loc Yt_sd=r(sd) 
		qui sum Yc1
		loc Yc_mn=r(mean) 
		loc Yc_sd=r(sd) 
		qui gen CohenD_sdid = abs(`Yt_mn' - `Yc_mn') / (0.5*`Yt_sd'^2 + 0.5*`Yc_sd'^2)^(1/2)
		qui drop Yt1 Yc1
		* Treatment Effect is in units of the dependent variable 
		qui gen tr_eff = Y_treated - Y_sdid
		/// see page 29 of sdid stata paper 
		qui gen tr_eff_ev = tr_eff - meanpre_o
		qui gen event_time = month_exp - $treat_period
		qui gen rmspe = rmspe
		qui gen id = $id_treated
		qui gen att = `att'
		qui gen placebo_id = `donor_id' 
		
		qui tempfile placebo_donor`j'
		qui save `placebo_donor`j'', replace    
		dis "Placebo: Treated Unit $id_treated: Donor `j'"

		} 
	
		/// Append all placebos 
		qui use `placebo_donor1', replace 
		forvalues j = 2(1)$num_donors {
			qui append using `placebo_donor`j''
		}
		
		qui save "${oup}/sdid_placebo_distributions.dta", replace
		qui tempfile placebo_distribution
		save `placebo_distribution', replace 
	* End Placebo Estimation 	
		
    }
    else {
        noisily display "Skipping Placebo Loops (placebos set to off)..."
    }

    ********************************************************************************
    * Step 3: Construct Regression Table with Rank-based p-values 
    * INFERENCE: Exact P-Values and Standard Errors
    ********************************************************************************

	* 1. Load Real Results
	*qui use "${oup}/sdid_results.dta", clear 
	qui use `sdid_results', clear 
	qui collapse (mean) att*, by(id)
	qui gen placebo_id = 0 // Marker for the "Real" treated unit
	qui reshape wide att*, i(placebo_id) j(id)
	qui rename att* att
	qui tempfile sdid_att 
	qui save `sdid_att'
	
	* 2. Append Placebo Results
	*qui use "${oup}/sdid_placebo_distributions.dta", clear
	qui use `placebo_distribution', clear 
	cap drop survival
	
	qui preserve 
	qui gcollapse (mean) rmspe, by(placebo_id id)
	qui gen survival = 0 
	qui replace survival = 1 if rmspe <= $rmspe_cutoff
	qui keep placebo_id id survival 
	qui tempfile placebo_survival 
	qui save `placebo_survival', replace 
	restore 
	
	qui merge m:1 id placebo_id using `placebo_survival', keep(match master) nogen
	* keep only good placebos 
	qui keep if survival == 1
		
	qui gcollapse (mean) att*, by(placebo_id id)
	qui reshape wide att*, j(id) i(placebo_id)
	qui rename att* att
	qui append using `sdid_att'
	qui sort placebo_id
    
	
	/// Matrix to Store Results 
	matrix define R=J(12,1,.)
	matrix rownames R = "att" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"

	* Matrix with regression results 


	* 3. Calculate Inference Metrics
	* We loop over the 4 outcomes (AAA, AA, A, BBB)
    * A. Get the Real ATT value (stored where placebo_id == 0)
    qui sum att if placebo_id == 0
    local real_att = r(mean)
    mat R[1,1] = `real_att'
	
    * B. Calculate Standard Error 
    * (SD of the placebo distribution, usually excluding the real unit)
    qui sum att if placebo_id != 0
    gen se = r(sd)
    mat R[2,1] = r(sd)
	
	qui _pctile att if placebo_id != 0, percentiles(2.5 97.5)
	mat R[3,1] = r(r1)
	mat R[4,1] = r(r2)
	
    * C. Two-Sided P-Value (Recommended)
    * Checks if abs(placebo) > abs(real)
    * Formula: (Count + 1) / (N_donors + 1)
    gen abs_diff = abs(att) >= abs(`real_att')
    qui count if abs_diff == 1 & placebo_id != 0
    local count_extreme = r(N)
    qui count if placebo_id != 0
    local N_placebos = r(N)
    
    gen pval_2sided = (`count_extreme' + 1) / (`N_placebos' + 1)
	qui sum pval_2sided
    mat R[6,1] = r(mean)
	
    * D. One-Sided P-Value (Left Tail, if you expect negative effects)
    * Checks if placebo < real
    qui gen left_diff = att <= `real_att'
    qui count if left_diff == 1 & placebo_id != 0
    local count_lower = r(N)
    
    gen pval_1sided = (`count_lower' + 1) / (`N_placebos' + 1)
	qui sum pval_1sided
	mat R[5,1] = r(mean)
	qui local pval1 = round(r(mean),0.0001)
	

	qui use `sdid_results', clear 
	qui keep if id == $id_treated
	qui keep if Y_treated != .
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absatt = abs(`real_att')
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum Y_treated if event_time < -1
	local vol_pre = r(mean)
	mat R[7,1] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum Y_treated if event_time == -1
	local vol_treat = r(mean)
	mat R[8,1] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,1] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absatt'/`excess_vol')
	if abs(`ate_excess_vol') > 300 {
	local ate_excess_vol = "."
	}
	mat R[10,1] = `ate_excess_vol'
	/// RMSE 
	qui sum rmspe 
	mat R[11,1] = r(mean)
	/// Id
	mat R[12,1] = $id_treated 
	
	/// Results as a transpose 
	matrix define M = R'
	/// Clear the environment 
	qui clear 
	qui svmat M
	qui format M* %12.4fc
	qui replace M5 = 0 if M5 == . 
	qui replace M6 = 0 if M6 == . 
	/// Drop ate excess volatility if the effect is not interpretab;e 
	qui replace M10 = . if M10 < -300 | M10 > 300
	/// Statistical Significance: Left-sided test  
	qui gen stars = "" 
	qui replace stars = "*" if M5 < 0.1
	qui replace stars = "**" if M5 < 0.05 
	qui replace stars = "***" if M5 < 0.01
	/// Format Variables 
	qui tostring M1, gen(ate) force format(%12.4fc)
	qui tostring M2, gen(se) force format(%12.4fc)
	qui tostring M3, gen(ci_min) force format(%12.4fc)
	qui tostring M4, gen(ci_max) force format(%12.4fc)
	qui tostring M5, gen(pval1) force format(%12.4fc)
	qui tostring M6, gen(pval2) force format(%12.4fc)
	qui tostring M7, gen(vol_pre) force format(%12.4fc)
	qui tostring M8, gen(vol_treat) force format(%12.4fc)
	qui tostring M9, gen(excess_vol) force format(%12.4fc)
	qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
	qui tostring M11, gen(rmspe) force format(%12.4fc)
	qui replace ate_excess_vol = ate_excess_vol + "\%"
	qui replace ate_excess_vol = "NA" if ate_excess_vol == ".\%"
	qui replace se = "(" + se + ")"
	qui replace ate = ate + stars
	qui gen cint = "(" + ci_min + "," + ci_max + ")"
	qui gen id = _n
	qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval1 pval2 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
	qui keep id b*
	qui reshape long b, i(id) j(vars) string
	qui destring vars, gen(id1)
	qui drop vars 
	qui reshape wide b, i(id1) j(id)  
	qui gen names = ""
	qui replace names = "ATT (a)" if _n == 1
	qui replace names = "SE" if _n == 2
	qui replace names = "Conf Interval" if _n == 3
	qui replace names = "Historic Volatility (b)" if _n == 4
	qui replace names = "Volatility March 2020 (c)" if _n == 5
	qui replace names = "Excess Volatility (d = c - b)" if _n == 6
	qui replace names = "ATT, % Excess Volatility (e = d/a)" if _n == 7
	qui replace names = "P-Value (Left Tail)" if _n == 8
	qui replace names = "P-Value (Two Tails)" if _n == 9
	qui replace names = "RMSPE" if _n == 10
	qui drop id1

	qui gen id_treated = $id_treated
	qui gen flag = "No"
	qui replace flag = "Missing Month: `month_dropped'" if `month_dropped' > 0
	
end
