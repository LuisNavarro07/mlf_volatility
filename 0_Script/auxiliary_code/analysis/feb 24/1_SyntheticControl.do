********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Estimate Synthetic Control for Treated Units  
*** This Update: January 2024 
********************************************************************************
********************************************************************************
/*
/// Define the Program that Runs the Estimation 
cap program drop synth_estimation
program define synth_estimation, rclass
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

/// Define Predictors - statistical model for matching 
/// Match on 3 variables: observed volatility jump at 15, average January - February of t, and Average of the Complete Previous Year. 

display "$predictors"

/// For Loop to Estimate the Synthetic Controls For Each Treated State 
timer on 1 
forvalues t=1/$tr_units {
		preserve 
		timer on 2
		*********************************************************************
		global t_id = T[`t',1]
		/// Keep only treated + donors 
		qui keep if id == ${t_id} | year_exp >= 1
		/// Save mean and variance in the pretreatment period 
		qui sum v_pre_mn  if id == ${t_id}
		qui global tr_pr_mn=r(mean)
		qui sum v_pre_sd  if id == ${t_id}
		qui global tr_pr_sd=r(mean)
		************************************************************************
		/// run the synth 
		qui tsset id month_exp
		qui tempfile SCM_id_`t'
		synth v_norm ${predictors}, trunit(${t_id}) trperiod(${treat_period}) keep(`SCM_id_`t'') fig
		************************************************************************
		/// Goodness of Fit MSE and Cohen D
		/// RMSE  
		matrix define RMSPE`t' = e(RMSPE)
		mat Y=e(X_balance)
		mat Yt=Y[1...,1]
		mat Yc=Y[1...,2]
		mat rmse1=(Yt-Yc)'*(Yt-Yc)
		mat rmse1=rmse1/`=rowsof(Yt)'
		/// Cohen's D statistic  
		qui svmat Y 
		qui sum Y1 
		global sdpre = r(sd)
		qui gen absdf = abs((Y1 - Y2)/$sdpre ) 
		qui sum absdf 
		global cohend = r(mean)
		qui drop Y1 Y2 absdf 
		restore 
		********************************************************************
		preserve 
		qui use `SCM_id_`t'', clear
		qui rename (_Y_treated _Y_synthetic _time) (treated synth month_exp)
		qui gen pre_mn = $tr_pr_mn
		qui gen pre_sd = $tr_pr_sd
		*svmat Real--> Check I retrieve the same info
		qui gen treat_lev = pre_sd*treated + pre_mn 
		qui gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		/// Save RMSE 
		qui gen rmse = rmse1[1,1]
		qui gen cohend = $cohend 
		/// Average Treatment Effect Estimation 
		qui gen post = month_exp > ${treat_period}
		qui egen ate = mean(tr_eff) if post == 1
		qui egen ate1 = mean(ate)
		qui drop ate 
		qui rename ate1 ate 
		qui gen id = ${t_id}
		qui gen fileid = `t'
		/// Store the Synth Data for Graphs
		qui keep ate id fileid rmse cohend month_exp treat_lev synth_lev tr_eff treated synth 
		qui drop if month_exp == .  
		tempfile scm_`t'
		save `scm_`t''
		restore 
		**********************************************************************
		/// Store Weights Separately 
		/*
		preserve
		use `SCM_id_`t'', clear
		capture drop id 
		rename (_Co_Number _W_Weight) (id weight)
		duplicates report id 
		merge 1:1 id using  "${tem}\varnames.dta", keep(match master) nogen
		qui keep id weight
		qui gen trunit = `t'
		save "${tem}\scm_weight_`t'.dta", replace 
		restore 
		*/
		**********************************************************************
		timer off 2
		timer list 2
		display "Treatment Unit `t' out of $tr_units"
		timer clear 2
}
timer off 1 
timer list 1
timer clear 1

/// Append the Results and Save Them 
use `scm_1' , clear
drop if _n >= 1
forvalues i=1(1)$tr_units { 
	append using `scm_`i''
}
/// Expresses Months relative to intervention time. 
replace month_exp = month_exp - ${treat_period} 
/// Month 0 == Period of the Intervention
/// Pre-Treatment Period: All Negative Months 
tab month_exp
label variable treated "Observed Volatility - Standardized Units"
label variable synth "Synthetic Volatility - Standardized Units"
label variable month_exp "Months Since the Intervention"
label variable treat_lev "Observed Volatility - Series Units"
label variable synth_lev  "Synthetic Volatility - Series Units"
label variable tr_eff "Treatment Effect - Series Units"

end 
*/

********************************************************************************
//// Run the Synth
use "${cln}\synth_clean.dta", clear 
*drop if mofd >= tm(2019m1) & mofd <= tm(2019m3)
/// Estimate the Synth 
synth_estimation
/// Save the Results 
save "${tem}\synth_treated_rc.dta", replace 
********************************************************************************

exit 
