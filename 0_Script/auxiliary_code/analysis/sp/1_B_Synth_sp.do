*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
*************************************************************************
*************************************************************************
use "${cln}\synth_sp.dta", clear 
preserve 
gcollapse (mean) volatility month, by(month_exp year_exp)
sort year_exp month_exp
twoway (line volatility month_exp if year_exp == 7, lcolor(gray) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 6, lcolor(green) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 5, lcolor(cranberry) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 4, lcolor(maroon) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 3, lcolor(blue) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 2, lcolor(navy) lpattern(dash)) ///
		(line volatility month_exp if year_exp == 1, lcolor(black) lpattern(solid)), ///
		xtitle("Months") xline(15,lcolor(maroon*0.6) lpattern(dot)) ytitle("Volatility") xlabel(#12) ylabel(#5) legend(on order(1 "2013-2014" 2 "2014-2015" 3 "2015-2016" 4 "2016-2017" 5 "2017-2018" 6 "2018-2019" 7 "2019-2020") size(small) rows(3) cols(4))
restore

********************************************************************************
//// Run the Synth 

use "${cln}\synth_sp.dta", clear 
/// Mean of the Volatility in the Pre-treatment Period. That is, in the months from Septmeber to February 
sort state_id year_exp month_exp
gegen v_pre_mn = mean(v) if month_exp < 7, by(state_id)
bysort state_id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
gegen v_pre_sd = sd(v) if month_exp < 7, by(state_id)
bysort state_id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd

sort state_id year_exp month_exp
order state_id treat year month year_exp month_exp v v_pre_mn v_pre_sd v_norm 

tab state_id if treat==1, matrow(T)
global tr_units = r(r)
qui tab state_id if treat==0, matrow(C)


/// Define Predictors 
global ownpred v
global otherpred lnpop gdpgr taxes deficit
global predictors $ownpred $otherpred 
display "$predictors"

timer on 1 
forvalues t=1/$tr_units {
		preserve 
		timer on 2
		*********************************************************************
		/// Define Treated unit
		global t_id = T[`t',1]
		/// Keep only treated + donors 
		qui keep if state_id == ${t_id} | year_exp > 1
		/// Save meand an variance in the pretreatment period 
		qui sum v_pre_mn  if state_id == ${t_id}
		qui global tr_pr_mn=r(mean)
		qui sum v_pre_sd  if state_id == ${t_id}
		qui global tr_pr_sd=r(mean)
		/// run the synth 
		qui tsset state_id month_exp
		qui tempfile SCM_id_`t'
		qui synth v_norm ${predictors}, trunit(${t_id}) trperiod(7) keep(`SCM_id_`t'') 
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
		qui gen post = month_exp > 6
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

use `scm_1' , clear
drop if _n >= 1
forvalues i=1(1)$tr_units { 
	append using `scm_`i''
}
replace month_exp = month_exp - 7 
tab month_exp
save "${tem}\synth_treated_sp.dta", replace 

exit 