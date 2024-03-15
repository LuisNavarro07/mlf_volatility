*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Average Treatment Effect Analysis by Treated Units  
*************************************************************************
*************************************************************************
/// Load Synthetic Control Estimates for Treated Units 
use "${tem}\synth_treated_sp.dta", clear 
tab fileid
global rows = r(r)
display $rows

 

matrix define M=J($rows ,4,.)
matrix colnames M = "ate" "cohend" "pval" "rmse"


forvalues j = 1(1)$rows { 
	local j = 1 
	//// 1.- Store All Treated Unit Characteristics 
	preserve 
	qui use "${tem}\synth_treated_sp.dta", clear
	*qui drop if cohend < $cohend_cutoff
	qui gcollapse (mean) ate cohend rmse, by(state_id fileid)
	/// keep only instrument `k' and donors 
	qui sort state_id 
	/// ATE for state k
	qui sum ate if fileid == `j'
	mat M[`j',1] = r(mean)
	global ate = r(mean)
	/// Cohen D for state k
	qui sum cohend if fileid == `j'
	mat M[`j',2] = r(mean)
	/// RMSE for state k
	qui sum rmse if fileid == `j'
	mat M[`j',4] = r(mean)
	restore 
	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	preserve 
	qui use "${tem}\placeboempiricaldistribution.dta", clear 
	/// keep only the empirical distribution of state j
	qui keep if fileid == `j'
	gcollapse (mean) ate, by(state_id fileid)
	/// absolute value of the ATE for the treated unit 
	qui gen atetreat = abs($ate)
	qui gen absate = abs(ate)
	local abs1 = abs($ate)
	/// count how many times the 
	qui gen pcount = atetreat > absate
	sum pcount
	global pvalue = round(r(mean),0.001)
	mat M[`j',3] = r(mean)
	qui kdensity absate, recast(line) lcolor(black) lwidth(thin) lpattern(solid) xline(`abs1', lcolor(maroon) lpattern(dash) lwidth(medthick)) xtitle("Average Treatment Effect") title("ATE's Empirical Distribution - $name - pvalue = $pvalue", pos(11) size(small)) ytitle("Kernel Density") xlabel(#10, angle(0) labsize(small))  ylabel(#10, angle(0) labsize(small)) name(sp`j',replace)
	restore 
}

esttab mat(M,fmt(4 4 4 4))
esttab mat(M,fmt(4 4 4 4)) using "${oup}\ate_state_treated.tex", replace 
