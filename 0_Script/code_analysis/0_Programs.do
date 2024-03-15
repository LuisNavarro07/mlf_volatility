********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Define Programs Used for Estimation 
*** This Update: February 2024 
********************************************************************************
********************************************************************************
program drop _all 
********************************************************************************
/// 1. Synth Estimation 
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
		synth v_norm ${predictors}, trunit(${t_id}) trperiod(${treat_period}) keep(`SCM_id_`t'') 
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

********************************************************************************
//// Placebo per Outcome: Baseline Model
cap program drop placebo_outcome_main
program define placebo_outcome_main, rclass 
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
qui use "${tem}/placeboap_main.dta", clear 
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

********************************************************************************
//// Placebo per Outcome 
cap program drop placebo_outcome_rc
program define placebo_outcome, rclass 
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
qui use "${tem}/placeboap_rc.dta", clear 
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


********************************************************************************
/// Program: Create Table for Main Results 
program define ate_table, rclass
/// Results as a transpose 
matrix define M = R'
/// Clear the environment 
clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
replace M6 = 0 if M6 == . 
/// Drop ate excess volatility if the effect is not interpretab;e 
replace M10 = . if M10 < -300 | M10 > 300
/// Statistical Significance: Left-sided test  
qui gen stars = "" 
qui replace stars = "*" if M5 < 0.1
qui replace stars = "**" if M5 < 0.05 
qui replace stars = "***" if M5 < 0.01
/// Format Variables 
qui tostring M1, gen(ate) force format(%12.4fc)
qui tostring M2, gen(se) force format(%12.4fc)
qui tostring M3, gen(ci_min) force format(%12.4fc)
qui tostring M4, gen(ci_max) force format(%12.4fc)
qui tostring M5, gen(pval1) force format(%12.4fc)
qui tostring M6, gen(pval2) force format(%12.4fc)
qui tostring M7, gen(vol_pre) force format(%12.4fc)
qui tostring M8, gen(vol_treat) force format(%12.4fc)
qui tostring M9, gen(excess_vol) force format(%12.4fc)
qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
qui tostring M11, gen(rmspe) force format(%12.4fc)
qui replace ate_excess_vol = ate_excess_vol + "\%"
qui replace ate_excess_vol = "NA" if ate_excess_vol == ".\%"
qui replace se = "(" + se + ")"
qui replace ate = ate + stars
qui gen cint = "(" + ci_min + "," + ci_max + ")"

qui gen id = _n
qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval1 pval2 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
qui keep id b*
qui reshape long b, i(id) j(vars) string
qui destring vars, gen(id1)
qui drop vars 
qui reshape wide b, i(id1) j(id)  
qui gen names = ""
qui replace names = "Average Treatment Effect (a)" if _n == 1
qui replace names = "SE" if _n == 2
qui replace names = "Conf Interval" if _n == 3
qui replace names = "Historic Volatility (b)" if _n == 4
qui replace names = "Volatility March 2020 (c)" if _n == 5
qui replace names = "Excess Volatility (d = c - b)" if _n == 6
qui replace names = "ATE, % Excess Volatility (e = d/a)" if _n == 7
qui replace names = "P-Value (Left Tail)" if _n == 8
qui replace names = "P-Value (Two Tails)" if _n == 9
qui replace names = "RMSPE" if _n == 10
qui drop id1
qui rename (names b1 b2 b3 b4) (Results A AA AAA BBB)
qui order Results AAA AA A BB
end 

********************************************************************************




