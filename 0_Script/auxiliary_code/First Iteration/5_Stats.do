/// Statistical Inference 
*global tr_dt1 =tw(2020w13)
global tr_dt1 = tm(2020m3)


use "${tem}\scm_append_treated.dta", clear 
gen treat = 1 
append using  "${tem}\synt_placebos.dta"
replace treat = 0 if treat == . 
qui gen post = wofd - $tr_dt1 > 0 
replace fileid = id if treat == 1 
tab fileid

global cohend_cutoff = 0.25

matrix define M=J(8,4,.)
matrix colnames M = "ate" "cohend" "pval" "rmse"
matrix rownames M = "AAA (SD)" "AAA (R)" "AA (SD)" "AA (R)" "A (SD)" "A (R)" "BBB (SD)" "BBB (R)"
forvalues k = 1(1)8{
	preserve 
	/// keep only outcome `k' and donors 
	qui drop if treat == 1 & id != `k'
	qui gcollapse (mean) ate cohend rmse, by(id fileid)
		/// ATE for outcome k
	qui sum ate if id == `k'
	mat M[`k',1] = r(mean)
	local ate1 = r(mean)
	global ate = abs(r(mean))
	/// Cohen D for outcome k
	qui sum cohend if id == `k'
	mat M[`k',2] = r(mean)
	/// RMSE for outcome k
	qui sum rmse if id == `k'
	mat M[`k',4] = r(mean)
	/// Keep only placebos with good pretreatment fit 
	qui drop if id == `k'
	/// Only use the distribution of the placebos computed for unit k 
	qui keep if fileid == `k'
	qui keep if cohend <= $cohend_cutoff
	/// Compute Pvalue 
	qui gen pcount = (abs(ate) - $ate) > 1 
	qui sum pcount
	mat M[`k',3] = r(mean)
	//// Do a histrogram 
	*histogram ate, xline(`ate1') name(ate`k', replace) bin(50)
	restore 
}



esttab mat(M,fmt(4 4 4 4))
esttab mat(M,fmt(4 4 4 4)) using "${oup}\synth_stats.tex", replace

preserve 
svmat M
keep M*
drop if M1 == .
rename (M1 M2 M3 M4 M5) (id ate cohend pval rmse)
save "${oup}\synth_stats.dta", replace 
restore 