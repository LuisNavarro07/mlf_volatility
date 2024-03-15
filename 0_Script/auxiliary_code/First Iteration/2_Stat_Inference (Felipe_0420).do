//// Statistical Inference of the Synthetic Control 

global tr_dt1 =tw(2020w13)
use "${tem}\TheFile.dta", clear 
qui tab id if status==0
global controls = r(r)

local title1 "AAA Bonds"
local title2 "AAA Bonds"
local title3 "AA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "A Bonds"
local title7 "BBB Bonds"
local title8 "BBB Bonds"

//// For Loop To estimate the Placebos 
timer on 1 
local k = 1 
local i = 1

*forvalues k = 1(1)8 {
    timer on 2
forvalues i = 1(1)$controls  {
	quietly use "${tem}\TheFile.dta", clear 
		************************************************************************
		/// Store Mean and Variance from the Treated Unit 
		qui tab id if status==1, matrow(T)
		qui global treat_id = T[`k',1]
		/// Mean of treated unit in the Pre-treatment Period
		qui gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of treated unit in the Pre-treatment Period
		qui gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Variables -- Normalizatoin is computed using mean and variance of the treated unit 
		qui gen v_norm = (v - v_pre_mn) / v_pre_sd
		/// Mean Used for Normalizatoin 
		qui sum v_pre_mn  if id == ${treat_id}
		qui global tr_pr_mn=r(mean)
		/// Standard Deviation Used For Normalization 
		qui sum v_pre_sd  if id == ${treat_id}
		qui global tr_pr_sd=r(mean)
		/// Drop normalized treated unit  
		qui drop v_norm v_pre_mn v_pre_sd
		***********************************************************************
		// Drop Treated Units: Placebos are Estimated Only in the Donor Pool 		
		qui drop if status == 1
		qui tab id if status==0, matrow(C)
		qui global t_id = C[`i',1]
		*keep if id== ${t_id} | sec_id>1000
		/// Mean of each instrument (donor) in the Pre-treatment Period
		qui gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of each instrument in the Pre-treatment Period
		qui gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Donor Unit (With its own mean and variance) Now is unit free
		qui gen v_norm = (v - v_pre_mn) / v_pre_sd
		************************************************************************
		/// Setting for the Synth 
		qui tsset id wofd
		qui local levels ""				/*Lags to be included*/
		qui loc tr_dt_pre1 = ${tr_dt1} -1
		qui loc tr_dt_preT = ${tr_dt1} -12
		//All lags up to 12 weeks (1Q)
		qui forvalues q = `tr_dt_pre1'(-1)`tr_dt_preT'{ 
			local levels "`levels' v(`q')"
		}
		qui global levels `levels'
		/// File to Save the Results 
		qui tempfile SCM_placebo_`i'`k'
		//// Run the Synthetic Control 
		qui synth v ${levels}, trunit(${t_id}) trperiod(${tr_dt1}) keep(`SCM_placebo_`i'_`k'')
		/// Store the Results: Goodness of Fit 
		qui matrix define RMSPE`t' = e(RMSPE)
		qui mat Y=e(X_balance)
		qui mat Yt=Y[1...,1]
		qui mat Yc=Y[1...,2]
		qui mat rmse1=(Yt-Yc)'*(Yt-Yc)
		qui mat rmse1=rmse1/`=rowsof(Yt)'
		/// Cohen's D statistic  
		qui svmat Y 
		qui sum Y1 
		qui global sdpre = r(sd)
		qui gen absdf = abs((Y1 - Y2)/$sdpre ) 
		qui sum absdf 
		qui global cohend = r(mean)
		qui drop Y1 Y2 absdf 
		************************************************************************
	
		qui use `SCM_placebo_`i'_`k'', clear
		qui rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		/// Mean and variance of the treatment effect of the treated series. Expressed in units of the treatment variable  
		qui gen pre_mn = $tr_pr_mn
		qui gen pre_sd = $tr_pr_sd
		//// Express the Treatment Effect of the Placebos in units of treated variable `k' 
		qui gen treat_lev = pre_sd*treated + pre_mn 
		qui gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		/// Save RMSE and CohenD 
		qui gen rmse = rmse1[1,1]
		qui gen cohend = $cohend 
		/// Average Treatment Effect Estimation 
		qui gen post = wofd - $tr_dt1 > 0
		qui egen ate = mean(tr_eff) if post == 1
		qui egen ate1 = mean(ate)
		drop ate 
		rename ate1 ate 
		/// Keep only variables that we need 
		*qui keep ate rmse cohend wofd treat_lev synth_lev tr_eff
		qui keep ate rmse cohend wofd treated synth
		qui drop if wofd == .  
		/// Identifiers of the Dataset 
		qui gen id = ${t_id}
		qui gen tr_unit = `k'
		qui save "${tem}\placebo_unit`i'_`k'.dta", replace 
		capture timer off 2
		capture timer list 2
		display "Control Unit `i' -- Treat `k' "
		capture timer clear 2
} 
*}

timer off 1 
timer list 1
timer clear 1

use "${tem}\placebo_unit1_1.dta", clear
drop if _n > = 1
*forvalues k = 1(1)8{
forvalues i = 1(1)$controls  {
append using "${tem}\placebo_unit`i'_`k'.dta"
}
*}
save "${tem}\placebos_append_v2.dta", replace