//// Run the Synth 

use "${tem}\TheFilesp.dta", clear 

local levels ""				/*Lags to be included*/
loc tr_dt_pre1 = ${tr_dt1} -1
loc tr_dt_preT = ${tr_dt1} -12
global tr_dt_pre1 = `tr_dt_pre1'
global tr_dt_preT = `tr_dt_preT'
//All lags up to 12 weeks (1Q)
forvalues q = `tr_dt_pre1'(-1)`tr_dt_preT'{ 
local levels "`levels' v(`q')"
}
global levels `levels'
display "${levels}"
format wofd %tmMon_CCYY 
label variable wofd "Date"
/// Mean of each instrument in the Pre-treatment Period
sort id wofd 
gegen v_pre_mn = mean(v) if wofd < ${tr_dt1}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
gegen v_pre_sd = sd(v) if wofd < ${tr_dt1}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd

tab id if status==1, matrow(T)
qui tab id if status==0, matrow(C)

timer on 1 
forvalues t=1/100{
		preserve 
		timer on 2
		*********************************************************************
		/// Define Treated unit
		global t_id = T[`t',1]
		/// Keep only treated + donors 
		qui keep if id== ${t_id} | sec_id>1000
		/// Save meand an variance in the pretreatment period 
		qui sum v_pre_mn  if id == ${t_id}
		qui global tr_pr_mn=r(mean)
		qui sum v_pre_sd  if id == ${t_id}
		qui global tr_pr_sd=r(mean)

		/// run the synth 
		qui tsset id wofd
		qui tempfile SCM_id_`t'
		qui synth v_norm ${levels}, trunit(${t_id}) trperiod(${tr_dt1}) keep(`SCM_id_`t'')
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
		qui rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		qui gen pre_mn = $tr_pr_mn
		qui gen pre_sd = $tr_pr_sd
		*svmat Real--> Check I retrieve the same info
		qui gen treat_lev = pre_sd*treated + pre_mn 
		qui gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		qui gen rw = wofd - $tr_dt1
		/// Save RMSE 
		qui gen rmse = rmse1[1,1]
		qui gen cohend = $cohend 
		/// Average Treatment Effect Estimation 
		qui gen post = rw > 0
		qui egen ate = mean(tr_eff) if post == 1
		qui egen ate1 = mean(ate)
		qui drop ate 
		qui rename ate1 ate 
		qui gen id = ${t_id}
		qui gen fileid = `t'
		/// Store the Synth Data for Graphs
		qui keep ate id fileid rmse cohend wofd treat_lev synth_lev tr_eff treated synth 
		qui drop if wofd == .  
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
		display "Treatment Unit `t' out of 100"
		timer clear 2
}
timer off 1 
timer list 1
timer clear 1


use `scm_1' , clear
drop if _n >= 1
forvalues i=1(1)100{ 
	append using `scm_`i''
}
drop id 
clonevar id = fileid 
drop fileid 
gen fileid = 1 if mod(id,2)
replace fileid = 3 if fileid == . 
format wofd %tmMon_CCYY
tab wofd
save "${tem}\synth_treated_sp.dta", replace 

/*
use "${tem}\scm_weight_1.dta", clear
drop if _n >= 1
forvalues t=1(1)8{ 
	append using "${tem}\scm_weight_`t'.dta" 
}
save "${tem}\scm_append_weights.dta", replace 
*/