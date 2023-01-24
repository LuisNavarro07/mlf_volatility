********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Estimate Synthetic Control for Treated Units  
*** This Update: September 2022 
********************************************************************************
********************************************************************************

//// Run the Synth
use "${cln}\synth_clean.dta", clear 

/// Mean of the Volatility in the Pre-treatment Period. That is, in the months from Septmeber to February 
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd
/// Organize Dataset
sort id year_exp month_exp
order id treat year month year_exp month_exp v v_pre_mn v_pre_sd v_norm 
/// Table of Treated States 
tab id if treat==1, matrow(T)
global tr_units = r(r)
/// Table of Placebo units
tab id if treat==0, matrow(P)
global pc_units = r(r)

xtset id month_exp

gen strnm = string(id) + name
labmask id, val(strnm) 
gen TP = treat==1 & month_exp>=${treat_period}
order id month_exp TP

keep if id == 1 | id > 4 
 
scul v_norm, ahead(3) treat(TP) 

* trying v instead of v_norm
* trying including lags of v_norm
* trying other treated all the time i=1, now i=2
