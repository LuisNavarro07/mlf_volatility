*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
*************************************************************************
*************************************************************************
/// Merge SP and States 
use "${tem}\spgoindex.dta", clear
*merge m:1 state year using "${tem}\states_us_data.dta", keep(match master) nogen
/// drop 2022
append using "${tem}\bloombergprices_clean.dta"
replace varlab = name if varlab == ""

/// Gen Experiment Year: Set of 36 months, centered around April.
/// Overlap: Non Overlap Across Experiment Years
 
gen year_exp = . 
replace year_exp = 3 if mofd >= tm(2013m1) & mofd <= tm(2015m12)
replace year_exp = 2 if mofd >= tm(2016m1) & mofd <= tm(2018m12)
replace year_exp = 1 if mofd >= tm(2019m1) & mofd <= tm(2021m12)
drop if year_exp == . 
tab mofd year_exp

/// Experiment Time: 36 periods. Treatment Happens in April of t+1, so it is the 16th period 
gen month = month(dofm(mofd))
gen month_exp = month 
replace month_exp = month + 12 if year == 2014 | year == 2017 | year == 2020 
replace month_exp = month + 24 if year == 2015 | year == 2018 | year == 2021 


/// Generate State by Experiment Year Id. This is the state_id identifier for the synth. States with year_exp = 1 will be the treated units. States with year_exp > 1 are donors. 
egen id = group(sec_id year_exp)
sort id month_exp

/// Update Treatment Variable: Equals to one for states in the treatment period 
replace treat = 0 if year_exp > 1 

order id treat year month year_exp month_exp
sort year_exp month_exp  
tsset id month_exp
rename volatility v 
save "${cln}\synth_sp.dta", replace 

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