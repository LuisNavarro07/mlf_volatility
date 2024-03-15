//// Placebo per Outcome 

//// First, how many donors do we have? 
qui use "${tem}\TheFile.dta", clear 
qui tab id if status==0
global don = r(r)
/// We have so many donors 
display $don


/// Store the pre-treatment mean and variance of the treated units 
qui use "${tem}\TheFile.dta", clear 
qui gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
qui bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
qui bysort id: carryforward 	v_pre_sd, replace
/// Normalized Donor Unit (With its own mean and variance) Now is unit free
qui gen v_norm = (v - v_pre_mn) / v_pre_sd
qui tsset id wofd

********************************************************************************
/// For loop for each instrument. To compute the ATE. 
forvalues i = 1(1)8{
preserve 
******************************************
qui tab id if status==1, matrow(T)
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
qui use "${tem}\placeboap.dta", clear 
qui gen pre_mn = $tr_pr_mn
qui gen pre_sd = $tr_pr_sd
/// At each lap of the loop, create the treated and synthetic placebos, using the mean and variance of the treated unit. This allows to depict better the smokeplots. 
qui gen treat_lev = pre_sd*treated + pre_mn 
qui gen synth_lev = pre_sd*synth + pre_mn 	
qui gen tr_eff = treat_lev - synth_lev
/// Average Treatment Effect Estimation 
qui gen post = wofd - $tr_dt1 > 0
qui bysort id: egen ate = mean(tr_eff) if post == 1
qui bysort id: egen ate1 = mean(ate)
qui drop ate 
qui rename ate1 ate 
qui gen fileid = `i'
qui keep ate id fileid rmse cohend wofd treat_lev synth_lev tr_eff
qui drop if wofd == . 
qui tempfile placebo_out`i'
qui save `placebo_out`i''
restore 
}

*************************************************
/// Append the results 
qui use `placebo_out1', clear 
qui drop if _n >= 1 
forvalues i = 1(1)8{
qui append using `placebo_out`i''
}
sort fileid id wofd
format wofd %tmMon_CCYY
tab wofd
save "${tem}\synth_placebos.dta", replace 