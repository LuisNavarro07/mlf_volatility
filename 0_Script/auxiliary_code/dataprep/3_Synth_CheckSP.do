********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Prepare Data for Synthetic Control 
*** This Update: September 2022 
********************************************************************************
********************************************************************************

/// Merge the Data
use "${tem}\secondary_rating.dta", clear  
keep date yield*
label variable yieldnr "Not Rated"
label variable yield3a "AAA Bonds"
label variable yield2a "AA Bonds"
label variable yielda "A Bonds"
label variable yield3b "BBB Bonds"

********************************************************************************
/// To use the synth package the data needs to be in a panel structure where each unit is a financial instrument. Oh boy, we need to reshape this stuff carefully. 
/// First, lets rename the securities 

/// Rename variables to do the reshape 
local varlist yieldnr yield3a yield2a yielda yield3b
local i = 2
foreach var of local varlist {
	global name`i' =  "`var'"
	rename `var' var`i'
	local i = `i' + 1
}

/// Reshape Long 
reshape long var, i(date) j(sec_id)
rename var volatility 
tsset sec_id date
/// Drop Not Rated Issuers  
drop if sec_id == 2
sort sec_id date

/// Names and Varlabs
gen name = ""
replace name = "AAA" if sec_id == 3
replace name = "AA" if sec_id == 4
replace name = "A" if sec_id == 5
replace name = "BBB" if sec_id == 6 
gen varlab = "State Bonds - " + name 
gen data = "Outcome"
********************************************************************************
/// Append the Donors 
append using "${tem}\bloombergprices_clean.dta"
replace data = "Donor Prices" if data == ""
append using  "${tem}\spgoindex.dta"
replace data = "SP Munis" if data == ""
********************************************************************************
/// Compute the Standard Deviation of Weekly Prices 
gen wofd= wofd(date + 1)
/// Collapse at the weekly levels - This gets the weekly volatility measure  
gcollapse (mean) date (sd) volatility, by(wofd name varlab data)
//// Collapse by Month: Average of the 4 weeks at each month 
gen mofd = mofd(date)
gcollapse (mean) volatility date, by(mofd varlab name data) 
format mofd %tmMon_CCYY
gen year = year(date)
gen treat = 0 
replace treat = 1 if data == "Outcome"
tempfile data
save `data', replace 
********************************************************************************
/// Exclude Data From SP Muni Index on the Treatment Period 
*drop if data == "SP Munis" & year >= 2019 
gsort -treat name mofd 
********************************************************************************
/// Manual Replacement of the first unit of volatility for BBB January 2019 
sum volatility if name == "BBB" & mofd == tm(2019m2)
replace volatility = r(mean) if name == "BBB" & mofd == tm(2019m1) 
mdesc volatility
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
keep if data == "SP Munis" & year_exp == 1
replace treat = 1 
replace month_exp = month + 12 if year == 2020 
replace month_exp = month + 24 if year == 2021 
tempfile treated 
save `treated' , replace 
restore 

//// Now the Financial Instruments 
preserve 
keep if data == "Donor Prices" & year_exp == 1
replace treat = 0
replace month_exp = month + 12 if year == 2020 
replace month_exp = month + 24 if year == 2021 
tempfile donors 
save `donors' , replace 
restore 


/// Second: Now I need to reshape the dataset so each cohort
keep if data == "SP Munis"
drop if year_exp == 1

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
append using `donors'
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
save "${cln}\synth_clean.dta", replace 
********************************************************************************
/// Save State Names 
preserve 
keep if treat == 1 
keep id name 
duplicates drop id name, force 
save "${tem}\treated_names.dta", replace
restore 

/// All names 
preserve  
keep id name year_exp
duplicates drop id name, force 
save "${tem}\all_names.dta", replace
restore 
********************************************************************************
exit 
/*
/// Compare the Outcomes 
preserve 
use `data', clear 
keep if year >= 2019 
drop if year == 2022 
drop if data == "Donor Prices"
gcollapse (mean) volatility, by(mofd treat data)

twoway (line volatility mofd if treat == 1, lcolor(black) lpattern(solid)) (line volatility mofd if treat == 0, lcolor(blue) lpattern(dash)), legend(on order(1 "MSRB" 2 "SP Muni Index") size(small)) ytitle("Volatility", size(small)) xlabel(#36, labsize(small) angle(90)) xtitle("") ylabel(#10, labsize(small) angle(0)) title("Comparison of Volatility Outcomes", size(small) pos(11)) name(outcomes_comp, replace)
graph export "${oup}\OutcomeComparisonMRSB_SPMuni.png", $export 


exit 
*/