//// 2_5 Statistical Inference 

/// Statistical Inference 
qui use "${tem}\placeboempiricaldistribution.dta", clear 
qui gen tr_eff = treated - synth  
/// Average Treatment Effect Estimation (Unit Free Placebos)
qui gen post = wofd - $tr_dt1 > 0
qui bysort id: egen ate = mean(tr_eff) if post == 1 
qui bysort id: egen ate1 = mean(ate)
qui drop ate 
qui rename ate1 ate 
qui gcollapse (mean) ate cohend, by(id)
qui gen absate = abs(ate)

matrix define M=J(4 ,4,.)
matrix colnames M = "ate" "cohend" "pval" "rmse"
matrix rownames M = "AAA" "AA" "A" "BBB"
local j = 1 
local numlist1 1 3 5 7 
	foreach k of local numlist1 { 
	
	//// 1.- Store All Treated Unit Characteristics 
	preserve 
	qui use "${tem}\synth_treated.dta", clear
	*qui drop if cohend < $cohend_cutoff
	qui gcollapse (mean) ate cohend rmse, by(id fileid)
	/// keep only instrument `k' and donors 
	qui sort id 
	/// ATE for instrument k
	qui sum ate if id == `k'
	mat M[`j',1] = r(mean)
	/// Cohen D for instrument k
	qui sum cohend if id == `k'
	mat M[`j',2] = r(mean)
	/// RMSE for instrument k
	qui sum rmse if id == `k'
	mat M[`j',4] = r(mean)
	restore 
	
	/// Unit Free ATE 
	preserve 
	qui use "${tem}\synth_treated.dta", clear
	*qui drop if cohend < $cohend_cutoff
	qui drop ate tr_eff
	qui gen tr_eff = treated - synth
	/// Average Treatment Effect Estimation 
	qui gen post = wofd - $tr_dt1 > 0
	qui bysort id: egen ate = mean(tr_eff) if post == 1
	qui bysort id: egen ate1 = mean(ate)
	qui drop ate 
	qui rename ate1 ate
	qui gcollapse (mean) ate, by(id fileid)
	qui sum ate if id == `k'
	global ate = r(mean)
	restore 

	
	preserve 
	qui gen atetreat = abs($ate)
	local abs1 = abs($ate)
	qui gen pcount = atetreat > absate
	qui sum pcount
	global pvalue = round(r(mean),0.001)
	mat M[`j',3] = r(mean)
	*qui kdensity absate, recast(line) lcolor(black) lwidth(thin) lpattern(solid) xline(`abs1', lcolor(maroon) lpattern(dash) lwidth(medthick)) xtitle("Average Treatment Effect") title("ATE's Empirical Distribution - $name - pvalue = $pvalue", pos(11) size(small)) ytitle("Kernel Density") xlabel(#10, angle(0) labsize(small))  ylabel(#10, angle(0) labsize(small)) name(sp`k',replace)
	restore 
	local j = `j' + 1
}

esttab mat(M,fmt(4 4 4 4))
esttab mat(M,fmt(4 4 4 4)) using "${oup}\ate_stats_$exp.tex", replace 
