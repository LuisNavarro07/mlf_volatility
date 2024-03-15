*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Average Treatment Effect Analysis by Treated Units  
*************************************************************************
*************************************************************************
graph drop _all 
/// Load Synthetic Control Estimates for Treated Units 
use "${tem}\synth_treated.dta", clear 
tab fileid
global rows = r(r)
display $rows

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

matrix define M=J($rows ,4,.)
matrix colnames M = "ate" "pval" "rmse" "id"
matrix rownames M = "A" "AA" "AAA" "BBB"

forvalues j = 1(1)$rows { 
	//// 1.- Store All Treated Unit Characteristics 
	preserve 
	qui use "${tem}\synth_treated.dta", clear
	/// Estimate the Average Treatment Effect for the specific window 
	egen group = group(id fileid)
	drop ate
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	qui gcollapse (mean) ate rmse, by(id fileid)
	/// keep only instrument `k' and donors 
	qui keep if fileid == `j'
	/// ATE for state k
	qui sum ate 
	mat M[`j',1] = r(mean)
	global ate = r(mean)
	/// RMSE for state k
	qui sum rmse 
	mat M[`j',3] = r(mean)
	qui sum id 
	mat M[`j',4] = r(mean)
	restore 
	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	preserve 
	qui use "${tem}\placeboempiricaldistribution.dta", clear 
	/// keep only the empirical distribution of state j
	qui keep if fileid == `j'
	/// Estimate the Average Treatment Effect for the specific window 
	egen group = group(id fileid)
	drop ate
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	qui gcollapse (mean) ate, by(id fileid)
	/// absolute value of the ATE for the treated unit 
	qui gen atetreat = abs($ate)
	qui gen absate = abs(ate)
	global atetreat = abs($ate)
	/// count how many times the 
	qui gen pcount = absate > atetreat
	qui sum pcount
	global pvalue = round(r(mean),0.001)
	mat M[`j',2] = r(mean)
	/// ATE's Empirical Distribution - 
	qui kdensity absate, recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline($atetreat, lcolor(maroon) lpattern(dash)) xtitle("") title("`title`j'': p = $pvalue", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(gr`j',replace) xscale(range(0 $ate)) legend(off)
	restore 
}

grc1leg gr3 gr2 gr1 gr4, legendfrom(gr1) name(grcomb1,replace) $combopts 
graph export "${oup}\ATEEmpDist_Combined.png", $export  


/// export the results to a Tex Table 
clear 
svmat M 
label variable M1 "ATE"
label variable M2 "P-Value"
label variable M3 "RMSE"
rename (M1 M2 M3 M4) (ate pval rmse id)
gen category = ""
replace category = "A" if id == 1 
replace category = "AA" if id == 2
replace category = "AAA" if id == 3
replace category = "BBB" if id == 4
drop id
order category
format ate pval rmse %12.4fc
texsave * using "${oup}\ATE_Results.tex", replace varlabels decimalalign nofix
list 
save "${oup}\ATE_Results.dta", replace 
exit 