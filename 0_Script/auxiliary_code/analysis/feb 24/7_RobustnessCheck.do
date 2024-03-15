********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Run Robustness Check: Heterogeneity by CARES Act.  
*** This Update: February 2024 
********************************************************************************
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

/// Load the Data for the Robustness Check 
use "${cln}/synth_clean_crf.dta", clear 
drop if month_exp <= 3
/// Manual Replacement of Missing data for category A-p0-p50
qui sum v if name == "A-p0-p50" & mofd == tm(2019m5)
replace v = r(mean) if name == "A-p0-p50" & mofd == tm(2019m4)
/// Drop BBB to Ensure Balanced Panel 
*drop if name == "BBB-Fixed Allocation" | name == "BBB-Variable Allocation" | name == "A-Fixed Allocation"
*drop if name == "BBB-p67-p100" | name == "BBB-p0-p33" | name == "BBB-p34-p66" | name == "A-p67-p100" | name == *"A-p34-p66"

/// Manual Replacement 
*sum v if name == "AA-Fixed Allocation" & month_exp == 2 
*local v1 = r(mean)
*replace v = `v1' if name == "AA-Fixed Allocation" & month_exp == 1

/// 1. Synth Estimation 
*global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4) 
synth_estimation
tempfile synth_treated
save `synth_treated', replace 

********************************************************************************
/// 2. Placebo Estimation: Does not needs to be run again. The placebos are the same from the baseline model. 
/// 3. Synth Outcome 
//// Load Data with Synth Results 
qui use "${cln}\synth_clean_crf.dta", clear 
/// Run the program that adjusts placebos using the mean and sd from data 
placebo_outcome
/// 4. Placebo Empirical Distribution: This is not Estimated Again.
merge m:1 id using "${tem}\placebosforinference.dta", keep(match master) nogen
keep if survival == 1
/// Save data 
tempfile placeboempiricaldistribution
save `placeboempiricaldistribution', replace
 
********************************************************************************
/// Synth Graph 
use `synth_treated', clear 
global graphopts ytitle("Avg Intra-Week Std.Dev",size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("Months Since the Intervention", size(small)) xlabel(#15, nogrid labsize(small) angle(90)) xline(0, lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) 
********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
merge m:1 month_exp using `dates', keep(match master) nogen
qui sum mofd if month_exp == 0 
local xline = r(mean)
********************************************************************************
tab fileid 
global rows = r(r)

*local title1 = "A - Variable Allocation"
*local title2 = "AA - Fixed Allocation"
*local title3 = "AA - Variable Allocation"
*local title4 = "AAA - Fixed Allocation"
*local title5 = "AAA - Variable Allocation"

local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"	

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

grc1leg gr5 gr6 gr3 gr4, legendfrom(gr4) name(grcombrc1,replace) $combopts 
grc1leg gr1 gr2 gr7 gr8, legendfrom(gr2) name(grcombrc2,replace) $combopts 

graph display grcombrc1, ysize(80) xsize(100) scale(.9)
graph export "${oup}/Synth_GraphAggregated_RC1p1_${tr_eff_window}.pdf", $export 

graph display grcombrc2, ysize(80) xsize(100) scale(.9)
graph export "${oup}/Synth_GraphAggregated_RC1p2_${tr_eff_window}.pdf", $export 
********************************************************************************
/// 5. ATE and Pvalues 
use `synth_treated', clear 
tab fileid
global cols = r(r)
display $cols

local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"	

matrix define R=J(12,$cols,.)
matrix colnames R = "A (Below Median)"	"A (Above Median)" "AA (Below Median)" "AA (Above Median)" "AAA (Below Median)" "AAA (Above Median)" "BBB (Below Median)" "BBB (Above Median)" 
matrix rownames R = "ate" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"
matlist R 


forvalues j = 1(1)$cols { 
	//// 1.- Store All Treated Unit Characteristics 
	qui use `synth_treated', clear
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

	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	*preserve 
	qui use `placeboempiricaldistribution' , clear 
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

}

/// Results as a transpose 
matrix define M = R'

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

label variable b1 "A (Below Median)"		
label variable b2 "A (Above Median)"		
label variable b3 "AA (Below Median)"		
label variable b4 "AA (Above Median)"		
label variable b5 "AAA (Below Median)"		
label variable b6 "AAA (Above Median)"	
label variable b7 "BBB (Below Median)"		
label variable b8 "BBB (Above Median)"	
rename names Results 
order Results b5 b6 b3 b4 b1 b2 b7 b8
tempfile ATE_Results_Full_RC
save `ATE_Results_Full_RC', replace 

*******************************************************************
/// Export Tables 
drop if Results == "Conf Interval" | Results == "P-Value (One Tail)" | Results == "P-Value (Two Tails)" 
replace Results = "" if Results == "SE"
list 
texsave * using "${oup}/ATE_Results_RC_CRF_${tr_eff_window}.tex", replace  decimalalign nofix varlabels


********************************************************************************

/// Load Data 
use `synth_treated', clear 
qui gen treat = 1 
append using `placeboempiricaldistribution', force  
qui replace treat = 0 if treat == . 
*drop if fileid >= 6 
tab fileid, matrow(F)
global rows = r(r)

********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
********************************************************************************

local title1 "A (Below Median)"		
local title2 "A (Above Median)"		
local title3 "AA (Below Median)"		
local title4 "AA (Above Median)"		
local title5 "AAA (Below Median)"		
local title6 "AAA (Above Median)"	
local title7 "BBB (Below Median)"		
local title8 "BBB (Above Median)"	
global smoke_options ytitle("Treatment Effect", size(vsmall)) ylabel(#18, nogrid labsize(vsmall) angle(0)) xtitle("", size(vsmall)) xlabel(#30, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(-5)) plotregion(lcolor()) legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 

/// For Each Treated Unit 
forvalues j=1(1)$rows {
preserve 	
use `ATE_Results_Full_RC', clear
*(order Results A AA AAA BBB
*rename (Results A AA AAA BBB) (names b1 b2 b3 b4) 

qui replace b`j' = subinstr(b`j', "\", "", .)

local ate = b`j'[1]
local pval = b`j'[8]
local excess_vol = b`j'[7]
local rmspe = b`j'[10]
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
merge 1:1 month_exp using `dates', keep(match master) nogen
qui sum mofd if month_exp == 0 
local xline = r(mean)
global smoke_options ytitle("Treatment Effect", size(vsmall)) ylabel(#8, nogrid labsize(vsmall) angle(0)) xtitle("", size(vsmall)) xlabel(#16, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 

twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected tr_eff mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , `lineopts') yline(0 , `lineopts') $smoke_options name(sm`j', replace) title("`title`j''", size(small) pos(11)) legend(order(- 1 5) note("ATE = `ate'" "p-value = `pval'" "RMSPE = `rmspe'" "ATE (% Excess Volatility) = `excess_vol'", pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none)))
restore 
}


graph combine sm5 sm6 sm3 sm4, name(grcombrc3,replace) $combopts 
graph combine sm1 sm2 sm7 sm8, name(grcombrc4,replace) $combopts 

graph display grcombrc3, ysize(80) xsize(100) scale(.9)
graph export "${oup}/SmokeCombinedOutRC11_${tr_eff_window}.pdf", $export 

graph display grcombrc4, ysize(80) xsize(100) scale(.9)
graph export "${oup}/SmokeCombinedOutRC12_${tr_eff_window}.pdf", $export 

