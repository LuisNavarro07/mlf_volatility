********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Prepare Data for Synthetic Control - Robustness Check  
*** This Update: January 2024
********************************************************************************
********************************************************************************

********************************************************************************
/// Program for analysis 
*------------------------------------------------------------------------------
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
*------------------------------------------------------------------------------


*------------------------------------------------------------------------------
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
*------------------------------------------------------------------------------

*------------------------------------------------------------------------------
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
*------------------------------------------------------------------------------


********************************************************************************


********************************************************************************
/// Preprare data for Synthetic Control Analysis - Baseline Specification
/// Load Data 

********************************************************************************
/// Baseline Dependent Variable: Nominal Yields 
********************************************************************************

use "${tem}/secondary_rating_fixedcr.dta", clear  
keep if depvar == "Nominal Yield Baseline"
drop depvar
/// Prep data for baseline analysis 
clean_baseline
/// Run the program that preps the data 
synth_prep

/// Keep Donors 
preserve 
keep if data != "Outcome"
gen depvar = "Donors"
tempfile donors
save `donors', replace 
restore 

/// Keep Dependent Variable
preserve
keep if data == "Outcome"
gen depvar = "Nominal Yield Baseline"
tempfile nominal_yield_baseline
save `nominal_yield_baseline', replace 
restore 


********************************************************************************
/// Alternative 1: Create residualized yields to compute volatility measures 
********************************************************************************

use "${tem}/secondary_rating_fixedcr.dta", clear  
tab depvar 

* 1. Store the distinct values of depvar into a local macro called 'levels'
levelsof depvar, local(levels)

local i = 1

* 2. Loop over the items in that local macro
foreach x of local levels {
    
    preserve 
    
    keep if depvar == "`x'"
    drop depvar 

    * --------------------------
    clean_baseline
    synth_prep 
    * --------------------------

    * Save outcome 
    keep if data == "Outcome"
    
    * Generate the ID variable again. 
    gen depvar = "`x'"

    tempfile out_`i'
    save `out_`i'', replace 
    
    local i = `i' + 1
    
    restore
}

* Combine all the tempfiles into one dataset at the end
clear
forvalues j = 1/`=`i'-1' {
    append using `out_`j''
}

/// Append donors 
append using `donors'

replace varlab = "Municipal Bonds" if data == "SP Munis"
cap drop asset_class
gen asset_class = ""
replace asset_class = "Outcome" if data == "Outcome"
replace asset_class = "Municipal Bonds" if varlab == "Municipal Bonds"
replace asset_class = "Stock Market Index" if regexm(varlab, "Index")
replace asset_class = "Currency"           if regexm(varlab, "Spot Exchange Rate")
replace asset_class = "Stock Market Index"           if regexm(varlab, "Currncy")
replace asset_class = "Commodity"          if regexm(varlab, "Comdty")
replace asset_class = "Commodity"          if regexm(varlab, "Equity")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "GOVT")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "Govt")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "GVOT")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "CTDEMII5Y")

replace varlab = strtrim(stritrim(subinstr(varlab, "Spot Exchange Rate", "", .)))

save "${cln}/synth_clean_fixedcr.dta", replace 



********************************************************************************
/// Preprare data for Synthetic Control Analysis - Robustness Check: Heterogeneity by CRF 
/// Load Data 
use "${tem}/secondary_rating_crf.dta", clear  
/// Prep data for robustness check 
clean_robust
/// Run the program that preps the data 
synth_prep

replace varlab = "Municipal Bonds" if data == "SP Munis"
cap drop asset_class
gen asset_class = ""
replace asset_class = "Outcome" if data == "Outcome"
replace asset_class = "Municipal Bonds" if varlab == "Municipal Bonds"
replace asset_class = "Stock Market Index" if regexm(varlab, "Index")
replace asset_class = "Currency"           if regexm(varlab, "Spot Exchange Rate")
replace asset_class = "Stock Market Index"           if regexm(varlab, "Currncy")
replace asset_class = "Commodity"          if regexm(varlab, "Comdty")
replace asset_class = "Commodity"          if regexm(varlab, "Equity")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "GOVT")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "Govt")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "GVOT")
replace asset_class = "Sovereign Bond"     if regexm(varlab, "CTDEMII5Y")

replace varlab = strtrim(stritrim(subinstr(varlab, "Spot Exchange Rate", "", .)))

/// Save the dataset 
save "${cln}/synth_clean_crf.dta", replace 
exit 

********************************************************************************
