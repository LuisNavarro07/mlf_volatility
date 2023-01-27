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
use "${tem}\synth_treated.dta", clear 
tab fileid
global cols = r(r)
display $cols

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

/// Define Matrix To Store Values 
matrix define R=J(10,$cols,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "ate" "se" "ci_min" "ci_max"  "pval2" "pval1" "baseline" "percent_change" "rmspe" "id"
matlist R 

forvalues j = 1(1)$cols { 
	//// 1.- Store All Treated Unit Characteristics  
	qui use "${tem}\synth_treated.dta", clear
	/// keep only rating `j' 
	qui keep if fileid == `j'
	/// Estimate the Average Treatment Effect for the specific window 
	qui drop ate
	/// Compute the ATE as the mean of tr_eff, including the intervention period 
	bysort id: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	/// Store the Average Treatment Effect 
	qui sum ate 
	local ate = r(mean)
	mat R[1,`j'] = `ate'
	/// Percent Change in Volatility due to the Policy 
	/// Baseline: Observed Volatility 
	qui sum treat_lev if month_exp >=0 & month_exp <= ${tr_eff_window}
	local baseline = r(mean)
	/// Synthetic Volatility 
	/// Percent Change: Obs Volatility / Synth Volatility - 1
	qui sum synth_lev if month_exp >=0 & month_exp <= ${tr_eff_window}
	local synth_vol = r(mean)
	local pct = 100*((`baseline'/`synth_vol') - 1)
	mat R[8,`j'] = `pct'
	/// RMPSE 
	qui sum rmse 
	mat R[9,`j'] = r(mean)
	/// ID
	qui sum id 
	mat R[10,`j'] = r(mean)
	/// Mean of Dependent Variable in the Pre-treatment Period (Excluding March 2020)
	qui sum treat_lev if month_exp < -1 
	local pre_mean = r(mean)
	mat R[7,`j'] = `pre_mean'
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	qui use "${tem}\placeboempiricaldistribution.dta", clear 
	/// keep only the empirical distribution of credit rating j 
	qui keep if fileid == `j'
	/// Estimate the Average Treatment Effect for the specific window 
	qui drop ate
	qui bysort id: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	qui gcollapse (mean) ate, by(id)
	/// Standard Error 
	qui sum ate 
	local se = r(sd)
	mat R[2,`j'] = `se'
	
	/// Hypothesis Testing and P Values 
	qui cumul ate, gen(cdf)
	gsort cdf
	qui _pctile ate, percentiles(2.5 97.5)
	local ptile1 = r(r1)
	local ptile2 = r(r2)
	/// Normal Approximation of Confidence Interval (Hansen p 269)
	local cmin = `ate' - (`se'*`ptile1')
	local cmax = `ate' + (`se'*`ptile2')
	mat R[3,`j'] = `cmin'
	mat R[4,`j'] = `cmax'
	
	/// Two Tail Test 
	qui gen pcount = `ate' >= ate
	/// p-value 
	qui sum cdf if pcount == 1
	local pval2 = round((1-r(max)),0.001)
	mat R[5,`j'] = `pval2'
	
	/// One Tail Test 
	qui gen atetreat = abs(`ate')
	qui gen absate = abs(ate)
	/// count how many times the 
	qui drop pcount 
	qui gen pcount = absate > atetreat
	qui sum pcount
	local pval1 = round(r(mean),0.001)
	mat R[6,`j'] = `pval1'
	
/*
/// ATE's Empirical Distribution - 
qui kdensity ate, recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(`ate', lcolor(maroon) lpattern(dash)) xtitle("") title("`title`j'': Two Tail Test p = `pval2'", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(gr2`j',replace) xscale(range(0 `ate')) legend(off)
	
local atetreat = abs(`ate')
qui kdensity absate, recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(`atetreat', lcolor(maroon) lpattern(dash)) xtitle("") title("`title`j'': One Tail Test p = `pval1'", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(gr1`j',replace) xscale(range(0 `ate')) legend(off)
graph combine gr2`j' gr1`j', rows(1) cols(2) ycommon name(grcombined`j', replace)
*/

}

/// Results as a transpose 
matrix define M = R'
matlist M
esttab matrix(M, fmt(4 4 4 4))
*********************************************************************************
*** Summarize Main Results 
clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
qui tostring M*, replace force

local varlist M1 M2 M3 M4 M5 M6 M7 M8 M9 M10
foreach var of local varlist {
qui gen point_pos = strpos(`var',".")
qui replace `var' = substr(`var',1,point_pos + 4) 
qui gen negdec = strpos(`var',"-.")
qui replace `var' = substr(`var',2,point_pos + 4) if negdec == 1
qui replace `var' = "0" + `var' if strpos(`var',".") == 1 & negdec == 0 
qui replace `var' = "-0" + `var' if strpos(`var',".") == 1 & negdec == 1
qui replace `var' = "0" + `var' if length(`var') == 5 
qui drop point_pos negdec
}
/// Rename Variables 
rename (M1 M2 M3 M4 M5 M6 M7 M8 M9 M10) (ate se ci_min ci_max pval2 pval1 baseline pchange rmspe id)
/// Statistical Significance 
gen pvalr = real(pval2)
gen stars = "" 
replace stars = "*" if pvalr < 0.01
replace stars = "**" if pvalr < 0.005 
replace stars = "***" if pvalr < 0.001
/// Add Stars to Coefficient 
replace ate = ate + stars
/// Add Parenthesis to Standard Errors and Confidence Intervals 
replace se = "(" + se + ")"
gen cint = "(" + ci_min + ", " + ci_max + ")"
replace pchange = pchange + "\%"
drop ci_max ci_min id
gen id = _n
rename (ate se cint baseline pchange pval2 pval1 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8)
keep id b*
reshape long b, i(id) j(vars) string
destring vars, gen(id1)
drop vars 
reshape wide b, i(id1) j(id)  
gen names = ""
replace names = "ATE" if _n == 1
replace names = "SE" if _n == 2
replace names = "Conf Interval" if _n == 3
replace names = "Mean of Dep Variable" if _n == 4
replace names = "\% Change" if _n == 5
replace names = "P-Value (One Tail)" if _n == 6
replace names = "P-Value (Two Tails)" if _n == 7
replace names = "RMSPE" if _n == 8
drop id1
rename (names b1 b2 b3 b4) (Results A AA AAA BBB)
order Results AAA AA A BBB
********************************************************************************
if "${rating_agg}" == "rating_agg_var" {
	save "${tem}\ATE_Results_Full.dta", replace 
}
else if  "${rating_agg}" == "rating_agg_stfix" {
	save "${tem}\ATE_Results_Robustness_Stfix.dta", replace 
}

********************************************************************************
exit 