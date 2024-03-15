*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: January 2024
/// Script: Construct the Placebos/Smokelines for each Treated State (State-Units) Robustness Check
*************************************************************************
*************************************************************************
//// Placebo per Outcome 
cap program drop placebo_outcome_rc
program define placebo_outcome_rc, rclass 
/// Store the pre-treatment mean and variance of the treated units 
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
qui gen v_norm = (v - v_pre_mn) / v_pre_sd
qui tsset id month_exp
********************************************************************************
/// Compute Placebos adjusted by mean and variance of each outcome 
qui tab id if treat==1, matrow(T)
global rows = r(r)
 
forvalues i = 1(1)$rows{
preserve 
******************************************
global t_id = T[`i',1]
/// Mean Used for Normalization 
qui sum v_pre_mn  if id == ${t_id}
qui global tr_pr_mn=r(mean)
/// Standard Deviation Used For Normalization 
qui sum v_pre_sd  if id == ${t_id}
qui global tr_pr_sd=r(mean)
/// Drop normalized treated unit  
qui drop v_norm v_pre_mn v_pre_sd
********************************************
/// Load Appended Placebo Data. Here there is the empirical placebo distribution, unit free 
qui use "${tem}/placeboap_rc_fixedrating.dta", clear 
qui gen pre_mn = $tr_pr_mn
qui gen pre_sd = $tr_pr_sd
/// At each lap of the loop, create the treated and synthetic placebos, using the mean and variance of the treated unit. This allows to depict better the smokeplots. 
qui gen treat_lev = pre_sd*treated + pre_mn 
qui gen synth_lev = pre_sd*synth + pre_mn 	
qui gen tr_eff = treat_lev - synth_lev
/// Average Treatment Effect Estimation 
qui gen post = month_exp > ${treat_period}
qui bysort id: egen ate = mean(tr_eff) if post == 1
qui bysort id: egen ate1 = mean(ate)
qui drop ate 
qui rename ate1 ate 
qui gen fileid = `i'
qui keep ate id fileid rmse cohend month_exp treat_lev synth_lev tr_eff
qui drop if month_exp == . 
qui tempfile placebo_out`i'
qui save `placebo_out`i''
restore 
}

*************************************************
/// Append the results 
qui use `placebo_out1', clear 
qui drop if _n >= 1 
forvalues i = 1(1)$rows{
qui append using `placebo_out`i''
}
sort fileid id month_exp
replace month_exp = month_exp - ${treat_period} 
tab month_exp
end 
*******************************************************************************
/// run the program 
placebo_outcome_rc
exit 
********************************************************************************
********************************************************************************
*** End Script 
