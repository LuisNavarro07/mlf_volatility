/// Synth 
graph drop _all 
use "${tem}\TheFile.dta", clear 
//// Store how many placebo units we have 
qui tab id if status==0
global don = r(r)
display $don

/// Describe the ATE for the treated units. Create the Cohend cutoff
use "${tem}\synth_treated.dta", clear 
gcollapse (mean) ate cohend, by(id)
list id ate cohend
sum cohend, detail 
list 
tab id
global rows = r(N)
display $rows

*******************************************************************
/// Treatmennt Effects and Smokeplots 
use "${tem}\placeboap.dta", clear 

/// Goodness of Fit 
preserve 
// Survival Test 
gcollapse (mean) cohend , by(id) 
qui gen survival = cohend < $cohend_cutoff
qui egen survrate = mean(survival)
sum survrate
qui cumul cohend, gen(ecdf)
sort ecdf
gsort survival id 
sum survrate
local survrate = round(r(mean),0.001)
local donors = round(r(sum),1)
local tot = round(r(N),1)
twoway line ecdf cohend, sort xline($cohend_cutoff, lcolor(black)) name(survival,replace) title("Placebo Distribution - Survival Rate `survrate' - `donors' out of `tot donors'",size(small))
save "${tem}\placebosforinference.dta", replace 
restore 

/// Merge 
merge m:1 id using "${tem}\placebosforinference.dta", keep(match master) nogen
keep if survival == 1
/// Remove Volatile Series 
drop if id == 148
save "${tem}\placeboempiricaldistribution.dta", replace 

****************************************************************

/// Build Smokelines
forvalues i = 1(1)$rows{
qui use "${tem}\synth_treated.dta", clear
qui gen treat = 1 
qui tab id if treat == 1, matrow(T)
qui global t_id = T[`i',1]

qui use "${tem}\TheFile.dta", clear 
qui sort id wofd 
qui gegen v_pre_mn = mean(v) if wofd < ${tr_dt1}, by(id)
qui bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if wofd < ${tr_dt1}, by(id)
qui bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
qui sum v_pre_mn  if id == ${t_id}
qui global tr_pr_mn=r(mean)
qui sum v_pre_sd  if id == ${t_id}
qui global tr_pr_sd=r(mean)

qui use "${tem}\placeboempiricaldistribution.dta" , clear  
qui gen pre_mn = $tr_pr_mn
qui gen pre_sd = $tr_pr_sd
qui gen treat_lev = pre_sd*treated + pre_mn 
qui gen synth_lev = pre_sd*synth + pre_mn  
qui gen tr_eff = treat_lev - synth_lev  
/// Average Treatment Effect Estimation 
qui gen post = wofd - $tr_dt1 > 0
qui bysort id: egen ate = mean(tr_eff) if post == 1 
qui bysort id: egen ate1 = mean(ate)
qui drop ate 
qui rename ate1 ate 
qui gen fileid = $t_id
qui keep ate id fileid rmse cohend wofd treat_lev synth_lev tr_eff synth treated
qui drop if wofd == . 
qui tempfile placebotreated`i'
qui save `placebotreated`i''
display "Lap `i' out of $rows"
}

qui use `placebotreated1', clear 
qui drop if _n >= 1 
forvalues i = 1(1)$rows{
qui append using `placebotreated`i''
}
merge m:1 id using  "${tem}\varnames.dta", keep(match master) nogen
drop if id == 29 
save "${tem}\synth_placebos.dta", replace 
**************************************************************