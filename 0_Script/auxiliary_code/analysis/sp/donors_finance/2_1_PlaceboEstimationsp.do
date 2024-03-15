		************************************************************************
		//// Estimation of the Placebos 
		timer on 1
		cap log using "${tem}\LogPlacebossp.log"
		qui use "${tem}\TheFilesp.dta", clear 
		qui gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of each instrument in the Pre-treatment Period
		qui gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
		qui bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Donor Unit (With its own mean and variance) Now is unit free
		qui gen v_norm = (v - v_pre_mn) / v_pre_sd
		qui tsset id wofd

		//// For Loop To estimate the Placebos 
		qui tab id if status==0
		global don = r(r)
		/// For loop 
		forvalues i = 1(1)$don  {
		preserve
		timer on 2 
		// Drop Treated Units: Placebos are Estimated Only in the Donor Pool 		
		qui drop if status == 1
		qui tab id if status==0, matrow(C)
		qui global t_id = C[`i',1]
		qui tempfile scm_placebo`i'
		*** To ensure compatibility, the global levels (i.e. the lags used as predictors) is defined in the synth do file. 
		qui synth v ${levels}, trunit(${t_id}) trperiod(${tr_dt1}) keep(`scm_placebo`i'')
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
		qui rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		qui drop if wofd == . 
		qui keep treat synth wofd 
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
save "${tem}\placeboapsp.dta", replace 