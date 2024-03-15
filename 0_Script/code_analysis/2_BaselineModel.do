********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@iu.edu) 
/// Update: February 2024
/// Script: Run Baseline Model: Fixed Credit Rating Cohorts 
********************************************************************************
********************************************************************************
graph drop _all 
set trace off
/// Load dates 

********************************************************************************
preserve 
/// Note: synth_clean_fixedcr is the file for the baseline scenario. In the first iteration of the paper, this was a robustness check. 
use "${cln}/synth_clean_fixedcr.dta", clear 
replace month_exp = month_exp - ${treat_period}
drop if treat == 0 
keep month_exp mofd
duplicates drop mofd, force 
save "${tem}/dates.dta", replace 
restore 

********************************************************************************
/// Step1. Run the synthetic control for the treated units. 
/// Load the Data for the Robustness Check 
use "${cln}/synth_clean_fixedcr.dta", clear 
drop if month_exp <= 3
/// 1. Synth Estimation 
synth_estimation
save "${tem}/synth_treated.dta", replace 
********************************************************************************


********************************************************************************
/// 2. Do the Synth Graph 
use "${tem}/synth_treated.dta", clear 
global graphopts ytitle("Avg Intra-Week Std.Dev",size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("", size(small)) xlabel(#27, nogrid labsize(small) angle(90)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) yscale(titlegap(0))
********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
merge m:1 month_exp using "${tem}/dates.dta", keep(match master) nogen
qui sum mofd if month_exp == 0 
local xline = r(mean)
********************************************************************************
qui tab fileid 
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
grc1leg gr3 gr2 gr1 gr4, legendfrom(gr2) name(grcomb_main,replace) $combopts 
graph display grcomb_main, ysize(80) xsize(100) scale(.9)
graph export "${oup}/Synth_Graph_main.pdf", $export
********************************************************************************



********************************************************************************
/// 3. Express placebos in units of the treated series 
use "${cln}/synth_clean_fixedcr.dta", clear 
drop if month_exp <= 3
//// 
placebo_outcome_main
save "${tem}/synth_placebos.dta", replace 
********************************************************************************

********************************************************************************
/// 4. Identify the placebos that pass the cohen-d criterion 
use "${tem}/synth_placebos.dta", clear 
merge m:1 id using "${tem}/placebosforinferencerce_main.dta", keep(match master) nogen
tab survival
dis 25200/144
dis 29952/144
dis 1 - 25200/29952
keep if survival == 1
/// Save data 
tempfile placeboempiricaldistribution
save "${tem}/placeboempiricaldistribution_main.dta", replace
********************************************************************************
 
 
/// 5. ATE and Pvalues 
use "${tem}/synth_treated.dta", clear 
tab fileid
global cols = r(r)
display $cols

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"
/// Matrix to store results 
matrix define R=J(12,$cols,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "ate" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"
matlist R 

/// Loop to compute the ATE for each treated unit 
forvalues j = 1(1)$cols { 
	//// 1.- Store All Treated Unit Characteristics 

	qui use "${tem}/synth_treated.dta", clear
	egen group = group(id fileid)
	qui drop ate tr_eff
	/// Estimate Treatment Effect Using Treated and Synthetic Series (Adjusted for their own mean and standard deviation) 
	bysort group: gen tr_eff = treat_lev - synth_lev
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	/// Pre-Measures in Volatility 
	/// Keep only instrument `j' and donors 
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
	if abs(`ate_excess_vol') > 300 {
    local ate_excess_vol = "."
	}
	mat R[10,`j'] = `ate_excess_vol'
	/// RMSE 
	qui sum rmse 
	mat R[11,`j'] = r(mean)
	/// Id
	qui sum id 
	mat R[12,`j'] = r(mean)

	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	*preserve 
	qui use "${tem}/placeboempiricaldistribution_main.dta" , clear 
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
	/// Cavallo Permutation Test Approach: Left-sided one-tail test. 
	/// Hypothesis: negative coefficient, hence the left-test. 
	/// Left-sided test: count how many times the placebos are more negative than the treatment effect. 
	/// (Inutition: p-val = 0 implies the ATE is more negative than all the placebos, ie: is smaller in all cases). 
	/// The p-value is the number of time the ATE is larger than the placebo estimates. 
	qui gen pcount = ate < $ate 
	/// p-value 
	sum pcount 
    local pval1 = round(r(mean),0.001)
	mat R[5,`j'] = `pval1'
	
	/// Two Tail Test 
	qui drop pcount 
	qui gen atetreat = abs($ate)
	qui gen absate = abs(ate)
	/// count how many times the 
	qui gen pcount = absate < atetreat
	qui sum pcount
	local pval2= round(r(mean),0.001)
	mat R[6,`j'] = `pval2'
	
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
	local percentile_lines xline(`p050', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity ate, `density_opts' title("`title`j'': Left Tail Test p-value = `pval1'", pos(11) size(small))  name(ate_dens`j',replace) `percentile_lines'
	
}

graph combine ate_dens3 ate_dens2 ate_dens1 ate_dens4, rows(2) cols(2) ycommon name(dens_combined, replace)
graph display dens_combined, ysize(80) xsize(100) scale(.9)
graph export "${oup}/ate_dens_main.pdf", $export 
********************************************************************************


********************************************************************************
//// 5.1. Create Main Results Table 
ate_table 
list  
save "${tem}/ATE_Results_Full_main.dta", replace 

/// Export Tables 
drop if Results == "Conf Interval" | Results == "P-Value (One Tail)" | Results == "P-Value (Two Tails)" 
replace Results = "" if Results == "SE"
list 
texsave * using "${oup}/ATE_Results_main.tex", replace  decimalalign nofix 
********************************************************************************



********************************************************************************
/// 6. Smokeplots 
use "${tem}/synth_treated.dta", clear 
qui gen treat = 1 
append using "${tem}/placeboempiricaldistribution.dta", force  
qui replace treat = 0 if treat == . 
drop if fileid >= 6 
tab fileid, matrow(F)
global rows = r(r)

********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
********************************************************************************

/// For Each Treated Unit 
forvalues j=1(1)$rows {
preserve 	
use "${tem}/ATE_Results_Full_main.dta", clear
order Results A AA AAA BBB
rename (Results A AA AAA BBB) (names b1 b2 b3 b4) 

local ate = b`j'[1]
local pval = b`j'[8]
local excess_vol = b`j'[7]
local rmspe = b`j'[10]

dis "`ate'"
dis "`pval'"
dis "`excess_vol'"
dis "`rmspe'"
restore 

preserve
qui keep if fileid == `j'
sort id month_exp

/// Create Percentile Variables 
gen p1 = . 
gen p2 = . 
gen p5 = . 
gen p95 = . 
gen p97 = . 
gen p99 = . 

/// Create Percentile Variables For each Experiment Month. So, for any period it will compute the percentiles at such period across all donor units, to then save it with the treated units. 
forvalues t= -15(1)20 {
	_pctile tr_eff if month_exp == `t' & treat == 0, percentiles(1 2.5 5 95 97.5 99)
	qui replace p1 = r(r1) if month_exp == `t' & treat == 1
	qui replace p2 = r(r2) if month_exp == `t' & treat == 1
	qui replace p5 = r(r3) if month_exp == `t' & treat == 1
	qui replace p95 = r(r4) if month_exp == `t' & treat == 1
	qui replace p97 = r(r5) if month_exp == `t' & treat == 1 
	qui replace p99 = r(r6) if month_exp == `t' & treat == 1
}
/// Keep treated and do the graph 
keep if treat == 1
merge 1:1 month_exp using "${tem}/dates.dta", keep(match master) nogen
qui sum mofd if month_exp == 0 
local xline = r(mean)
local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
global smoke_options ytitle("Treatment Effect", size(vsmall)) ylabel(#8, nogrid labsize(vsmall) angle(0)) xtitle("", size(vsmall)) xlabel(#16, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 

twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected tr_eff mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , `lineopts') yline(0 , `lineopts') $smoke_options name(gr`j', replace) title("`title`j''", size(small) pos(11)) legend(order(- 1 5) note("ATE = `ate'" "p-value = `pval'" "RMSPE = `rmspe'" "ATE (% Excess Volatility) = `excess_vol'", pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none)))
restore 
}

graph combine gr3 gr2 gr1 gr4, name(grcombrc3,replace) $combopts 
graph display grcombrc3, ysize(80) xsize(100) scale(.9)
graph export "${oup}/SmokeCombinedOut_main.pdf", $export 

*******************************************************************************
/// Dynamic Treatment Effect 
********************************************************************************
 
/// Treatment Effect by Period 
use "${tem}/synth_treated.dta", clear 
qui gen treat = 1 
append using "${tem}/placeboempiricaldistribution.dta", force  
qui replace treat = 0 if treat == . 
drop if fileid >= 6 
tab fileid, matrow(F)
global rows = r(r)

********************************************************************************
/// Show only the ATE window 
keep if month_exp >= 0 & month_exp < ${tr_eff_window}
/// 1. Compute ATE until that period 
********************************************************************************

/// Pseudo code 

/// For each period, 
//// For all treated units and placebos 
/// 1. Compute the ATE up until that period. 
/// 2. Compute the percentiles of the placebo ditribution of that Treatment effect 
/// 3. Store the percentiles with the treatment effect. 


// for each treated series 

forvalues i = 1(1)4 {
forvalues j = 0(1)14 {
	
preserve
keep if fileid == `i'
/// Keep observations between the analysis window 
/// for each month 
keep if month_exp <= `j'


/// rename ate variable to compute the mean until each period  
cap drop ate
gen ate = tr_eff
gcollapse (mean) ate, by(id)

sum ate if id == `i'
global ate = r(mean)

/// Create Percentile Variables 
gen p1 = . 
gen p2 = . 
gen p5 = . 
gen p95 = . 
gen p97 = . 
gen p99 = . 

/// Percentiles of the placebos 
_pctile ate     if id != `i' , percentiles(1 2.5 5 95 97.5 99)
qui replace p1  = r(r1) 
qui replace p2  = r(r2) 
qui replace p5  = r(r3) 
qui replace p95 = r(r4)
qui replace p97 = r(r5) 
qui replace p99 = r(r6)
/// keep only placebos
keep if id == `i'
gen month_exp = `j'
merge m:1 month_exp using "${tem}/dates.dta", keep(match master) nogen

tempfile res`i'`j'
save `res`i'`j'', replace 


restore
}

}

use `res10', clear 
forvalues i = 1(1)4{
forvalues j = 0(1)14 {
	append using `res`i'`j'' 
} 
}
drop if _n == 1

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

/// Keep treated and do the graph 

local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)
global smoke_options ytitle("Average Treatment Effect", size(vsmall)) ylabel(#8, nogrid labsize(vsmall) angle(0)) xtitle("", size(vsmall)) xlabel(#14, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) legend(off order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
forvalues i = 1(1)4 {
preserve 
keep if id == `i'
twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected ate mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		yline(0 , `lineopts') $smoke_options name(ate`i', replace) title("`title`i''", size(small) pos(11)) 
		
restore 
}

graph combine ate3 ate2 ate1 ate4, rows(2) cols(2) ycommon name(cumulativeate, replace)
graph display cumulativeate, ysize(80) xsize(100) scale(.9)
graph export "${oup}/cumulativeate_main.pdf", replace 

exit 
/*
/// Estimate the Average Treatment Effect for the specific window 
egen group = group(id fileid)

cap drop ate

forvalues i=1(1)$treat_period {
bysort group: egen ate`i' = mean(tr_eff) if month_exp >=0 & month_exp <= `i'
}
qui gcollapse (mean) ate*, by(id)
reshape long ate, i(id) j(month_exp)

merge m:1 month_exp using "${tem}/dates.dta", keep(match master) nogen

label define id 1 "A" 2 "AA" 3 "AAA" 4 "BBB"
label values id id 

twoway  (connected ate mofd if id == 1, msize(vsmall) msymbol(circle) mcolor(black) lcolor(black) lwidth(thin)) ///
		(connected ate mofd if id == 2, msize(vsmall) msymbol(triangle) mcolor(blue)  lcolor(blue) lwidth(thin)) ///
		(connected ate mofd if id == 3, msize(vsmall) msymbol(square) mcolor(cranberry) lcolor(cranberry) lwidth(thin)) ///
		(connected ate mofd if id == 4, msize(vsmall) msymbol(diamond) mcolor(green) lcolor(green) lwidth(thin)), ///
		xlabel(#16, labsize(small) angle(90)) ylabel(#10, labsize(small) angle(0)) title("Cumulative ATE - Months After the Intervention", size(medsmall) pos(11)) name(cumulativeate, replace) yline(0, lpattern(dash) lcolor(gray)) legend(on order(1 "A" 2 "AA" 3 "AAA" 4 "BBB") rows(1)) ytitle("Average Treatment Effect") xtitle("") yscale(titlegap(0))
graph display cumulativeate, ysize(50) xsize(85) scale(.9)
graph export "${oup}/cumulativeate_main.pdf", replace 
*/

