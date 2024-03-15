*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@iu.edu) 
/// Update: February 2024
/// Script: Average Treatment Effect Analysis by Treated Units  
*************************************************************************
*************************************************************************
graph drop _all 
********************************************************************************
/// Load dates 
preserve 
use "${cln}/synth_clean.dta", clear 
replace month_exp = month_exp - ${treat_period}
drop if treat == 0 
keep month_exp mofd
duplicates drop mofd, force 
tempfile dates
save `dates', replace 
restore 
********************************************************************************
/// Synth Graphs  
use "${tem}\synth_treated_rc.dta", clear 
global graphopts ytitle("Avg Intra-Week Std.Dev",size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("", size(small)) xlabel(#30, nogrid labsize(small) angle(90)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) yscale(titlegap(0))
********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
merge m:1 month_exp using `dates', keep(match master) nogen
qui sum mofd if month_exp == 0 
local xline = r(mean)
********************************************************************************
tab fileid 
global rows = r(r)

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"
local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
local lineopts1 lwidth(medthin) msize(vsmall)

forvalues i=1(1)$rows {
    preserve 
	qui keep if fileid == `i'
	twoway (line treated mofd, lcolor(black) lpattern(solid) mcolor(black) msymbol(circle) `lineopts1') ///
		(line synth mofd, lcolor(cranberry) lpattern(dash) mcolor(cranberry) msymbol(square) `lineopts1'),  ///
		$graphopts title("`title`i''") name(gr`i',replace) xline(`xline' , `lineopts') yline(0 , `lineopts')
	restore 
}

global combopts xcommon ycommon rows(2) cols(2)

grc1leg gr3 gr2 gr1 gr4, legendfrom(gr1) name(grcomb1,replace) $combopts 
graph display grcomb1, ysize(80) xsize(100) scale(.9)
graph export "${oup}/Synth_GraphAggregated_${tr_eff_window}.pdf", $export

/// Load Synthetic Control Estimates for Treated Units 
use "${tem}\synth_treated_rc.dta", clear 
qui tab fileid
global cols = r(r)
display $cols

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

matrix define R=J(12,$cols,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "ate" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"

matlist R 

/// Compute Table with Main Results 
forvalues j = 1(1)$cols { 
	//// 1.- Store All Treated Unit Characteristics 
	*preserve 
	qui use "${tem}\synth_treated_rc.dta", clear
	egen group = group(id fileid)
	qui drop ate tr_eff
	/// Estimate Treatment Effect Using Treated and Synthetic Series (Adjusted for their own mean and standard deviation) 
	bysort group: gen tr_eff = treat_lev - synth_lev
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	/// Pre-Measures in Volatility 
	/// Keep only instrument `k' and donors 
	qui keep if fileid == `j'
	/// Average Treatment Effect 
	qui sum ate 
	global ate = r(mean)
	mat R[1,`j'] = $ate
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absate = abs($ate)
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum treat_lev if month_exp < -1
	local vol_pre = r(mean)
	mat R[7,`j'] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum treat_lev if month_exp == -1
	local vol_treat = r(mean)
	mat R[8,`j'] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,`j'] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absate'/`excess_vol')
	mat R[10,`j'] = `ate_excess_vol'
	/// RMSE 
	qui sum rmse 
	mat R[11,`j'] = r(mean)
	/// Id
	qui sum id 
	mat R[12,`j'] = r(mean)

	*restore 
	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	*preserve 
	qui use "${tem}/placeboempiricaldistribution_rc.dta", clear 
	/// Estimate the Average Treatment Effect for the specific window 
	qui egen group = group(id fileid)
	qui drop ate
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	qui gcollapse (mean) ate, by(id fileid group)
	/// keep only the empirical distribution of state j
	qui keep if fileid == `j'
	/// Standard Error 
	qui sum ate 
	local se = r(sd)
	mat R[2,`j'] = `se'
	/// Hypothesis Testing and P Values 
	qui cumul ate, gen(cdf)
	qui gsort cdf
	/// Hypothesis Testing and P Values 
	_pctile ate, percentiles(2.5 97.5)
	mat R[3,`j'] = r(r1)
	mat R[4,`j'] = r(r2)
	/// Two Tail Test 
	qui gen pcount = $ate >= ate
	/// p-value 
	qui sum cdf if pcount == 1
	if r(N) == 0 {
		local pval2 = 0
	}
	else {
		local pval2 = round((1-r(max)),0.001)
	}
	mat R[5,`j'] = `pval2'
	/// One Tail Test 
	qui gen atetreat = abs($ate)
	qui gen absate = abs(ate)
	/// count how many times the 
	qui drop pcount 
	qui gen pcount = absate > atetreat
	qui sum pcount
	local pval1 = round(r(mean),0.001)
	mat R[6,`j'] = `pval1'
	
	/// Percentiles for lines in density plot
	cap drop ate_cdf
	qui cumul ate, gen(ate_cdf)
	/// Percentile 2.5% 
	sum ate if ate_cdf <= 0.025
	local p025 = r(max)
	/// Percentile 5.0% 
	sum ate if ate_cdf <= 0.05
	local p050 = r(max)	
	/// Percentile 95.0% 
	sum ate if ate_cdf <= 0.95
	local p950 = r(max)
	/// Percentile 97.5% 
	sum ate if ate_cdf <= 0.975
	local p975 = r(max)
	
	/// ATE's Empirical Distribution - 
	local density_opts recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline($ate, lcolor(maroon) lpattern(longdash)) xtitle("ATE Estimate") ytitle("Density") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) xscale(range(0 $ate)) legend(off) yscale(titlegap(0))
	/// Percentiles plot
	local line1 lcolor(ebblue) lpattern(shortdash) lwidth(medthin)
	local line2 lcolor(eltblue) lpattern(longdash) lwidth(medthin)
	local percentile_lines xline(`p025', `line1') xline(`p975', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity ate, `density_opts' title("`title`j'': Two Tail Test p-value = `pval2'", pos(11) size(small))  name(ate_dens`j',replace) `percentile_lines'
	
	*qui kdensity absate, `density_opts' title("`title`j'': One Tail Test p-value = `pval1'", pos(11) size(small)) name(gr1`j',replace
	
	*restore 
}

graph combine ate_dens1 ate_dens2 ate_dens3 ate_dens4, rows(2) cols(2) ycommon name(dens_combined, replace)
graph display dens_combined, ysize(80) xsize(100) scale(.9)
graph export "${oup}/ate_dens_rc.pdf", $export 

		

/// Results as a transpose 
matrix define M = R'
*matlist M
*esttab matrix(M, fmt(4 4 4 4))

clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
/// Statistical Significance 
qui gen stars = "" 
qui replace stars = "*" if M5 < 0.01
qui replace stars = "**" if M5 < 0.005 
qui replace stars = "***" if M5 < 0.001
qui tostring M1, gen(ate) force format(%12.4fc)
qui tostring M2, gen(se) force format(%12.4fc)
qui tostring M3, gen(ci_min) force format(%12.4fc)
qui tostring M4, gen(ci_max) force format(%12.4fc)
qui tostring M5, gen(pval2) force format(%12.4fc)
qui tostring M6, gen(pval1) force format(%12.4fc)
qui tostring M7, gen(vol_pre) force format(%12.4fc)
qui tostring M8, gen(vol_treat) force format(%12.4fc)
qui tostring M9, gen(excess_vol) force format(%12.4fc)
qui tostring M10, gen(ate_excess_vol) force format(%12.4fc)
qui tostring M11, gen(rmspe) force format(%12.4fc)
qui replace ate_excess_vol = ate_excess_vol + "\%"
qui replace se = "(" + se + ")"
qui replace ate = ate + stars
qui gen cint = "(" + ci_min + "," + ci_max + ")"


qui gen id = _n
qui rename (ate se cint vol_pre vol_treat excess_vol ate_excess_vol pval2 pval1 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8 b9 b10)
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
qui replace names = "P-Value (Two Tail)" if _n == 8
qui replace names = "P-Value (One Tails)" if _n == 9
qui replace names = "RMSPE" if _n == 10
qui drop id1
qui rename (names b1 b2 b3 b4) (Results A AA AAA BBB)
qui order Results AAA AA A BB
list  
save "${tem}/ATE_Results_Full_rc.dta", replace 
*******************************************************************
/// Export Tables
drop if Results == "Conf Interval" | Results == "P-Value (One Tail)" | Results == "P-Value (Two Tails)" 
replace Results = "Average Treatment Effect" if Results == "ATE"
replace Results = "" if Results == "SE"
list 
texsave * using "${oup}/ATE_Results_rc_${tr_eff_window}.tex", replace  decimalalign nofix 


exit 
