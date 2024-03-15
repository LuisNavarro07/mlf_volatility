*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: January 2023 
/// Script: Descriptive Graphs 
*************************************************************************
*************************************************************************

global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options xtitle("Months since the Intervention", size(medsmall)) ytitle(size(small)) ylabel(#10, nogrid labsize(small) angle(0)) xlabel(#16, labsize(small) angle(0) nogrid) title(, size(medsmall) pos(11) color(black)) $back 

********************************************************************************

/// Volatility by Rating Group 
use "${cln}/synth_clean_fixedcr.dta", clear 
drop if month_exp <= 3
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
qui gen v_norm = (v - v_pre_mn) / v_pre_sd
/// Organize Dataset
sort id year_exp month_exp
order id treat year month year_exp month_exp v v_pre_mn v_pre_sd v_norm 
/// Change the Labels of the Graphs 
replace month_exp = month_exp - ${treat_period}

***********************************************
/// Outcomes 
qui keep if data == "Outcome"
/// Intervention Line 
qui sum month_exp if month_exp == 0
local xline = r(mean)

/// Format Graph Lines 
local line1 lcolor(black) mcolor(black) msymbol(circle) lpattern(solid) msize(vsmall) lwidth(thin)
local line2 lcolor(cranberry) mcolor(cranberry) msymbol(circle) lpattern(dash) msize(vsmall) lwidth(thin)
local line3 lcolor(navy) mcolor(navy) msymbol(triangle) lpattern(solid) msize(vsmall) lwidth(thin)
local line4 lcolor(green) mcolor(green) msymbol(triangle) lpattern(dash) msize(vsmall) lwidth(thin)


/// Graph 1. Yields 
twoway  (connected yield month_exp if name == "AAA", `line1') /// 
		(connected yield month_exp if name == "AA" , `line2') /// 
		(connected yield month_exp if name == "A"  , `line3') ///
		(connected yield month_exp if name == "BBB", `line4'), ///
		xline(`xline', lcolor(maroon) lpattern(dash)) ///
	    $graph_options name(gr_yields, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Bond Yields by Credit Rating (percentage points)") ytitle("Yield (Percentage Points)")
		
/// Graph 2. Yields 
twoway  (connected v_norm month_exp if name == "AAA", `line1') /// 
		(connected v_norm month_exp if name == "AA" , `line2') /// 
		(connected v_norm month_exp if name == "A"  , `line3') /// 
		(connected v_norm month_exp if name == "BBB", `line4'), ///
		xline(`xline', lcolor(maroon) lpattern(dash)) ///
	    $graph_options name(gr_volatility, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Volatility by Credit Rating (Average SD on Standardized Units)")  ytitle("Standard Deviation (Percentage Points)")
		
grc1leg gr_yields gr_volatility, legendfrom(gr_yields) rows(2) cols(1) xcommon name(yields_comb, replace) xsize(16) ysize(8)
graph display yields_comb, xsize(80) ysize(100) scale(.9)
graph export "${oup}/Figure1_YieldVolatility.pdf", replace 

*/// Export the Main Figure 
*if "${rating_agg}" == "rating_agg_var" {
*	graph export "${oup}\Figure1_YieldVolatility.pdf", replace xsize(16) ysize(8)
*}
*else if  "${rating_agg}" == "rating_agg_stfix" {
*	graph export "${oup}\Figure1_YieldVolatility_RCStFix.pdf", replace xsize(16) ysize(8)
*}


**********************************************************************************
/// Smokeplots of Volatility 
use "${cln}/synth_clean_fixedcr.dta", clear 
drop if month_exp <= 3
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
qui gen v_norm = (v - v_pre_mn) / v_pre_sd
/// Organize Dataset
sort id year_exp month_exp
order id treat year month year_exp month_exp v v_pre_mn v_pre_sd v_norm 
/// Change the Labels of the Graphs 
replace month_exp = month_exp - ${treat_period}

/// Save dates 
preserve 
keep if data == "Outcome"
gcollapse (mean) mofd, by(month_exp)
tempfile dates
save `dates', replace 
restore 


/// First for SP Muni Donors 
preserve 
keep if data == "SP Munis"
/// Create Percentile Variables 
qui gen p1 = . 
qui gen p2 = . 
qui gen p5 = . 
qui gen p95 = . 
qui gen p97 = . 
qui gen p99 = . 
qui gen avg = . 
/// Create Percentile Variables For each Experiment Month. So, for any period it will compute the percentiles at such period across all donor units, to then save it with the treated units. 
qui tab month_exp
local months = r(r)
forvalues t= -15(1)20 {
	qui _pctile v_norm 			if month_exp == `t', percentiles(1 2.5 5 95 97.5 99)
	qui replace p1 = r(r1)  if month_exp == `t'
	qui replace p2 = r(r2)  if month_exp == `t'
	qui replace p5 = r(r3)  if month_exp == `t'
	qui replace p95 = r(r4) if month_exp == `t'
	qui replace p97 = r(r5) if month_exp == `t' 
	qui replace p99 = r(r6) if month_exp == `t'
	/// Compute the mean 
	qui sum v_norm 				if month_exp == `t' 
	qui local avg = r(mean)
	qui replace avg = `avg' if month_exp == `t' 
}
/// Keep treated and do the graph 
gcollapse (mean) p1 p2 p5 p95 p97 p99 avg, by(month_exp)
qui sum month_exp if month_exp == 0
local xline = r(mean)
twoway  (rarea p1 p99 month_exp, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 month_exp, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 month_exp, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg month_exp, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(small) msymbol(plus)), ///
		xline(`xline' , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options ///
		name(munis_smoke, replace) title("S&P Municipal GO Bond Indices", size(medsmall) pos(11)) legend(off) ytitle("Volatility (Avg Intra Week SD)")
restore 
********************************************************************************

/// Second Donor Prices
preserve 
keep if data == "Donor Prices"
/// Create Percentile Variables 
qui gen p1 = . 
qui gen p2 = . 
qui gen p5 = . 
qui gen p95 = . 
qui gen p97 = . 
qui gen p99 = . 
qui gen avg = . 
/// Create Percentile Variables For each Experiment Month. So, for any period it will compute the percentiles at such period across all donor units, to then save it with the treated units. 
qui tab month_exp
local months = r(r)
forvalues t= -15(1)20 {
	qui _pctile v_norm 			if month_exp == `t', percentiles(1 2.5 5 95 97.5 99)
	qui replace p1 = r(r1)  if month_exp == `t'
	qui replace p2 = r(r2)  if month_exp == `t'
	qui replace p5 = r(r3)  if month_exp == `t'
	qui replace p95 = r(r4) if month_exp == `t'
	qui replace p97 = r(r5) if month_exp == `t' 
	qui replace p99 = r(r6) if month_exp == `t'
	/// Compute the mean 
	qui sum v_norm 				if month_exp == `t' 
	qui local avg = r(mean)
	qui replace avg = `avg' if month_exp == `t' 
}
/// Keep treated and do the graph 
gcollapse (mean) p1 p2 p5 p95 p97 p99 avg, by(month_exp)
merge 1:1 month_exp using `dates', keep(match master) nogen
qui sum month_exp if month_exp == 0
local xline = r(mean)
twoway  (rarea p1 p99 month_exp, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 month_exp, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 month_exp, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg month_exp, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options ///
		name(stocks_smoke, replace) title("Stock Market Indices and Commodities", size(medsmall) pos(11)) legend(off) ytitle("Volatility (Avg Intra Week SD)") yline(0, lcolor(black) lpattern(dash) lwidth(thin))
restore 

graph combine munis_smoke stocks_smoke, rows(2) cols(1) name(smoke_comb, replace)
graph display smoke_comb, xsize(80) ysize(100) scale(.9)
graph export "${oup}/Figure11_VolatilityDonors.pdf", replace





exit 
*****************************************************************************
/*
********************************************************************************
/// States by Credit Rating: 
use "${tem}\state_ratings.dta", clear 
rename (state_name state_fips) (state statefips)
maptile rating_agg, geoid(statefips) geography(state) fcolor(Reds) twopt(legend(lab(1 "NR") lab(2 "AAA") lab(3 "AA") lab(4 "A") lab(5 "BBB") pos(5) rows(4) ) title(""))
*/

exit 
