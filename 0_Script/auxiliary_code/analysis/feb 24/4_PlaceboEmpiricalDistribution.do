*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Build the Placebo Empirical Distribution
*************************************************************************
*************************************************************************
*graph drop _all 
/*
use "${cln}/synth_clean.dta", clear 
//// Store how many placebo units we have 
qui tab id if treat==0
global don = r(r)
display $don

/// Describe the ATE for the treated units. Create the Cohend cutoff
use "${tem}/synth_treated_rc.dta", clear 
gcollapse (mean) ate cohend, by(id)
list id ate cohend
sum cohend, detail 
list 
tab id
global rows = r(N)
display $rows
*/
*******************************************************************
/// Treatmennt Effects and Smokeplots 
use "${tem}/placeboap.dta", clear 
/// Goodness of Fit 
preserve 
// Survival Test 
gcollapse (mean) rmse , by(id) 
qui cumul rmse, gen(ecdf)
gsort -ecdf
qui gen survival = rmse < (1-$rmspe_cutoff)
qui egen survrate = mean(survival)
sum survrate
gsort survival id 
sum survrate
local survrate = round(r(mean),0.001)
local donors = round(r(sum),1)
local tot = round(r(N),1)
twoway line ecdf rmse, sort xline($rmspe_cutoff, lcolor(black)) name(survival,replace) title("Placebo Distribution - Survival Rate `survrate' - `donors' out of `tot donors'",size(small))
save "${tem}/placebosforinference.dta", replace 
restore 

/// Merge with Placebos Final Dataset. 
use "${tem}/synth_placebos_rc.dta", clear 
merge m:1 id using "${tem}/placebosforinference.dta", keep(match master) nogen
keep if survival == 1

save "${tem}/placeboempiricaldistribution_rc.dta", replace 

****************************************************************
