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
global cols = r(r)
display $cols

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

matrix define R=J(10,$cols,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "ate" "se" "ci_min" "ci_max"  "pval2" "pval1" "baseline" "percent_change" "rmspe" "id"

matlist R 


forvalues j = 1(1)$cols { 
	//// 1.- Store All Treated Unit Characteristics 
	*preserve 
	qui use "${tem}\synth_treated.dta", clear
	/// Estimate the Average Treatment Effect for the specific window 
	egen group = group(id fileid)
	qui drop ate
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	table month_exp fileid if month_exp <= - 1, content(mean treated) 
	/// Baseline 
	 sum treated if fileid == `j' & month_exp <= -1
	local baseline = r(mean)
	mat R[7,`j'] = `baseline'
	qui gcollapse (mean) ate rmse, by(id fileid)
	/// keep only instrument `k' and donors 
	qui keep if fileid == `j'
	/// ATE for state k
	sum ate 
	mat R[1,`j'] = r(mean)
	global ate = r(mean)
	global pct = $ate/`baseline'
	dis $pct
	/// RMSE for state k
	qui sum rmse 
	mat R[9,`j'] = r(mean)
	/// Id
	qui sum id 
	mat R[10,`j'] = r(mean)
	// Percent Change 
	local pchange = round($ate/`baseline',0.001)
	mat R[8,`j'] = `pchange'
	*restore 
	
	/// 2.- Count How Many times the ATE for the treated unit exceeds the ATE at the placebo empirical distribution 
	*preserve 
	qui use "${tem}\placeboempiricaldistribution.dta", clear 
	/// Estimate the Average Treatment Effect for the specific window 
	egen group = group(id fileid)
	drop ate
	bysort group: egen ate = mean(tr_eff) if month_exp >=0 & month_exp <= ${tr_eff_window}
	qui gcollapse (mean) ate, by(id fileid group)
	/// keep only the empirical distribution of state j
	qui keep if fileid == `j'
	/// Standard Error 
	*regress ate 
	*local se = _se[_cons]
	sum ate 
	local se = r(sd)
	mat R[2,`j'] = `se'


	/// Hypothesis Testing and P Values 
	cumul ate, gen(cdf)
	gsort cdf
	/*
	/// CI Min - CI Max
	/// Interval at alpha = 0.05
	sum ate if cdf >= 0.95
	local c1 = r(min)
	mat R[3,`j'] = $ate - (`c1'*`se') 
	mat R[4,`j'] = $ate + (`c1'*`se') 
	*/
	
	/// Hypothesis Testing and P Values 
	_pctile ate, percentiles(2.5 97.5)
	mat R[3,`j'] = r(r1)
	mat R[4,`j'] = r(r2)
	
	/// Two Tail Test 
	gen pcount = $ate >= ate
	/// p-value 
	sum cdf if pcount == 1
	local pval2 = round((1-r(max)),0.001)
	mat R[5,`j'] = `pval2'
	
	/// One Tail Test 
	qui gen atetreat = abs($ate)
	qui gen absate = abs(ate)
	global atetreat = abs($ate)
	/// count how many times the 
	drop pcount 
	qui gen pcount = absate > atetreat
	qui sum pcount
	local pval1 = round(r(mean),0.001)
	mat R[6,`j'] = `pval1'
	
	/// ATE's Empirical Distribution - 
	*qui kdensity ate, recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline($ate, lcolor(maroon) lpattern(dash)) xtitle("") title("`title`j'': Two Tail Test p = `pval2'", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(gr2`j',replace) xscale(range(0 $ate)) legend(off)
	
		*qui kdensity absate, recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline($atetreat, lcolor(maroon) lpattern(dash)) xtitle("") title("`title`j'': One Tail Test p = `pval1'", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(gr1`j',replace) xscale(range(0 $ate)) legend(off)
		
*graph combine gr2`j' gr1`j', rows(1) cols(2) ycommon name(grcombined`j', replace)
		
	
	*restore 
}

/// Results as a transpose 
matrix define M = R'
matlist M
esttab matrix(M, fmt(4 4 4 4))

clear 
svmat M
format M* %12.4fc
replace M5 = 0 if M5 == . 
/// Statistical Significance 
gen stars = "" 
replace stars = "*" if M5 < 0.01
replace stars = "**" if M5 < 0.005 
replace stars = "***" if M5 < 0.001

tostring M1, gen(ate) force format(%12.4fc)
tostring M2, gen(se) force format(%12.4fc)
tostring M3, gen(ci_min) force format(%12.4fc)
tostring M4, gen(ci_max) force format(%12.4fc)
tostring M5, gen(pval2) force format(%12.4fc)
tostring M6, gen(pval1) force format(%12.4fc)
tostring M7, gen(baseline) force format(%12.4fc)
tostring M9, gen(rmspe) force format(%12.4fc)

replace se = "(" + se + ")"
replace ate = ate + stars
gen cint = "(" + ci_min + "," + ci_max + ")"
gen pct = (M1/M7)*100

tostring pct, gen(pct1) force format(%12.2fc)
replace pct1 = pct1 + "\%"
gen id = _n
rename (ate se cint baseline pct1 pval2 pval1 rmspe) (b1 b2 b3 b4 b5 b6 b7 b8)
keep id b*
reshape long b, i(id) j(vars) string
destring vars, gen(id1)
drop vars 
reshape wide b, i(id1) j(id)  
gen names = ""
replace names = "ATE" if _n == 1
replace names = "SE" if _n == 2
replace names = "Conf Interval" if _n == 3
replace names = "Baseline" if _n == 4
replace names = "\% Change" if _n == 5
replace names = "P-Value (One Tail)" if _n == 6
replace names = "P-Value (Two Tails)" if _n == 7
replace names = "RMSPE" if _n == 8
drop id1
rename names Results
order Results 
save "${tem}\ATE_Results_Full.dta", replace 
********************************************************************************
///Crosswalks for months 
use "${cln}\synth_clean.dta", clear 
replace month_exp = month_exp - ${treat_period}
drop if treat == 0 
keep month_exp mofd
duplicates drop mofd, force 
tempfile dates
save `dates', replace 

/// Treatment Effect by Period 
qui use "${tem}\synth_treated.dta", clear
/// Estimate the Average Treatment Effect for the specific window 
egen group = group(id fileid)
qui drop ate

forvalues i=1(1)$treat_period {
bysort group: egen ate`i' = mean(tr_eff) if month_exp >=0 & month_exp <= `i'
}
qui gcollapse (mean) ate*, by(id)
reshape long ate, i(id) j(month_exp)

merge m:1 month_exp using `dates', keep(match master) nogen

label define id 1 "A" 2 "AA" 3 "AAA" 4 "BBB"
label values id id 

twoway (line ate mofd if id == 1, lcolor(black) lwidth(thin)) ///
		(line ate mofd if id == 2, lcolor(blue) lwidth(thin)) ///
		(line ate mofd if id == 3, lcolor(cranberry) lwidth(thin)) ///
		(line ate mofd if id == 4, lcolor(green) lwidth(thin)), ///
		xlabel(#16, labsize(small) angle(90)) ylabel(#10, labsize(small) angle(0)) title("Cumulative ATE - Months After the Intervention", size(medsmall) pos(11)) name(cumulativeate, replace) yline(0, lpattern(dash)) legend(on order(1 "A" 2 "AA" 3 "AAA" 4 "BBB") rows(1)) ytitle("") xtitle("")
graph export "${oup}\cumulativeate.pdf", replace 

/*		
twoway (line ate mofd, lcolor(black) lwidth(thin)), ///
		xlabel(#16, labsize(small) angle(90)) ylabel(#10, labsize(small) angle(0)) title("Cumulative ATE - Months After the Intervention", size(medsmall) pos(11)) name(cumulativeate2, replace) yline(0, lpattern(dash)) legend(off order(1 "A" 2 "AA" 3 "AAA" 4 "BBB") rows(1)) ytitle("") xtitle("") by(id) label
*/		



		


exit 