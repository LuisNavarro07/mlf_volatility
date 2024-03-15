*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@iu.edu) 
/// Update: February 2024
/// Script: Estimate the Placebo Treatment Effects (Unit-Free) Baseline Model
*************************************************************************
*************************************************************************
//// Estimation of the Placebos 
timer on 1
cap log using "${tem}/LogPlacebos.log"
qui use "${cln}/synth_clean_fixedcr.dta", clear 
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd
qui tsset id month_exp

//// For Loop To estimate the Placebos 
qui tab id if treat==0
global don = r(r)
/// For loop 
forvalues i = 1(1)$don  {
preserve
timer on 2 
// Drop Treated Units: Placebos are Estimated Only in the Donor Pool 		
qui drop if treat == 1
qui tab id if treat==0, matrow(C)
qui global t_id = C[`i',1]
qui tempfile scm_placebo`i'
*** To ensure compatibility, the global levels (i.e. the lags used as predictors) is defined in the synth do file. 
qui synth v_norm ${predictors}, trunit(${t_id}) trperiod(${treat_period}) keep(`scm_placebo`i'')
/// Store the Results: Goodness of Fit 
matrix define RMSPE`i' = e(RMSPE)
mat Y=e(X_balance)
mat Yt=Y[1...,1]
mat Yc=Y[1...,2]
mat rmse1=(Yt-Yc)'*(Yt-Yc)
mat rmse1=rmse1/`=rowsof(Yt)'
/// Cohen's D statistic  
qui svmat Y 
qui sum Y1 
qui global sdpre = r(sd)
qui gen absdf = abs((Y1 - Y2)/$sdpre ) 
qui sum absdf 
qui global cohend = r(mean)
qui drop Y1 Y2 absdf 
qui use `scm_placebo`i'', clear
qui rename (_Y_treated _Y_synthetic _time) (treated synth month_exp)
qui drop if month_exp == . 
qui keep treat synth month_exp 
/// Save RMSE 
qui gen rmse = rmse1[1,1]
qui gen cohend = $cohend 
qui gen id = ${t_id} 
capture drop Y1 Y2 absdf 
tempfile placebo`i'
qui save  `placebo`i'', replace 
timer off 2
timer list 2
display "Placebo `i' out of $don"
timer clear 2 
restore 
}
timer off 1 
timer list 1 
timer clear 1 
cap log close, replace 
************************************************************************
************************************************************************
/// Append the placebos in one dataset 
use `placebo1' , clear 
drop if _n > = 1
forvalues i = 1(1)$don  {
append using `placebo`i''
}
save "${tem}/placeboap_main.dta", replace 

********************************************************************************
********************************************************************************
/// Identify the placebos that pass the Cohen D criterion 
/// 4. Placebo Empirical Distribution: This is not Estimated Again.
use "${tem}/placeboap_main.dta", clear 
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
save "${tem}/placebosforinferencerce_main.dta", replace 
restore 
exit 
********************************************************************************
********************************************************************************
*** End Script 
