/// Do file For Loop for Placebos 
use "${tem}\TheFile.dta", clear 
		// Drop Treated Units: Placebos are Estimated Only in the Donor Pool 
		drop if status == 1
		*tab id if status==1, matrow(T)
		*global outno = r(r)
		tab id if status==0, matrow(C)
		global donno = r(r)
		global t_id = C[`u',1]
		keep if id== ${t_id} | sec_id>1000
		/// Mean of each instrument in the Pre-treatment Period
		gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
		bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of each instrument in the Pre-treatment Period
		gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
		bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Variables
		gen v_norm = (v - v_pre_mn) / v_pre_sd
		sum v_pre_mn  if id == ${t_id}
		global tr_pr_mn=r(mean)
		sum v_pre_sd  if id == ${t_id}
		global tr_pr_sd=r(mean)
		tsset id wofd
		local levels ""				/*Lags to be included*/
		loc tr_dt_pre1 = ${tr_dt1} -1
		loc tr_dt_preT = ${tr_dt1} -12
		//All lags up to 12 weeks (1Q)
		forvalues q = `tr_dt_pre1'(-1)`tr_dt_preT'{ 
			local levels "`levels' v(`q')"
		}
		global levels `levels'
	*display "${levels}"
	tempfile SCM_placebo_`t'_`u'
	synth v ${levels}, trunit(${t_id}) trperiod(${tr_dt1}) keep(`SCM_placebo_`t'_`u'')

	/*
	matrix define RMSPE`t' = e(RMSPE)
	matrix define Y`t' =e(X_balance)
	matrix define Yt`t' =Y[1...,1]
	matrix define Yc`t' =Y[1...,2]
	matrix define rmse`t' =(Yt-Yc)'*(Yt-Yc)
	matrix define ate`t' =rmse`t' /`=rowsof(Yt)'
	*keep if id== ${t_id}	
	*/
	*preserve	
		use `SCM_placebo_`t'_`u'', clear
		rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		gen pre_mn = $tr_pr_mn
		gen pre_sd = $tr_pr_sd
		*svmat Real--> Check I retrieve the same info
		gen treat_lev = pre_sd*treated + pre_mn 
		gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		qui gen post = wofd > $tr_dt1
		qui gen id = ${t_id}
		*qui gen rmse = rmse`t'[1,1]
		/// Average Treatment Effect Estimation 
		qui egen ate = mean(tr_eff) if post == 1
		qui egen ate1 = mean(ate)
		drop ate 
		rename ate1 ate 
		/// Coady and Alex's Pretreatment Period Goodnes of Fit Test 
		/// Cohen's D statistic 
		/*
		sum treat_lev if post == 0 
		global sd_out = r(sd)
		qui gen prediff = tr_eff/$sd_out if post == 0 
		qui egen cohend = mean(prediff) if post == 0 
		qui egen cohend1 = mean(cohend)
		drop cohend
		rename cohend1 cohend
		*/
		*tempfile scm_`t'
		*save 	`scm_`t''
		gen fileid = `t'
		keep ate id fileid
		order id fileid ate 
		drop if _n > 1 
		save "${tem}\placebo_b`t'_unit`u'.dta", replace 
	*restore	