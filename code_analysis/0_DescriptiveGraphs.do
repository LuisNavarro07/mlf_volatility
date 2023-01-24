*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Descriptive Graphs 
*************************************************************************
*************************************************************************

global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(small)) ylabel(#8, nogrid labsize(small) angle(0)) xtitle(, size(small)) xlabel(#12, labsize(small) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) $back 

********************************************************************************
/// Yields by Rating Group 
use "${tem}\yields_raw.dta", clear  
rename volatility yield 
keep if data == "Outcome"
/// Compute the Average Yield of Weekly Prices 
gen wofd= wofd(date + 1)
/// Collapse at the weekly levels - This gets the weekly yield measure  
gcollapse (mean) date yield , by(wofd name varlab data)
//// Collapse by Month: Average of the 4 weeks at each month 
gen mofd = mofd(date)
gcollapse (mean) yield date, by(mofd varlab name data) 
replace data = "Yield" if data == "Outcome"
drop varlab  
tempfile yields 
save `yields', replace 

/// Volatility by Rating Group 
use "${cln}\synth_clean.dta", clear
keep if data == "Outcome"
replace data = "Volatility" if data == "Outcome"
rename v volatility
keep mofd volatility data name 
tempfile volatility
save `volatility', replace 

/// Merge both datasets 
use `yields', clear
merge 1:1 mofd name using `volatility', keep(match master) nogen
format mofd %tmMon_CCYY
gen year = year(date)

/// Intervention Line 
qui sum mofd if mofd == tm(2020m4)
local xline = r(mean)

/// Post Variable 
gen post = 0 
replace post = 1 if mofd >= tm(2020m4)

/// Statistical Summary of the Volatility during the Pre-treatment Period 
tabstat volatility if post == 0, by(name) statistics(mean sd cv)

/// Format Graph Lines 
local line1 lcolor(black) mcolor(black) msymbol(circle) lpattern(solid) msize(vsmall) lwidth(thin)
local line2 lcolor(cranberry) mcolor(cranberry) msymbol(circle) lpattern(dash) msize(vsmall) lwidth(thin)
local line3 lcolor(navy) mcolor(navy) msymbol(triangle) lpattern(solid) msize(vsmall) lwidth(thin)
local line4 lcolor(green) mcolor(green) msymbol(triangle) lpattern(dash) msize(vsmall) lwidth(thin)


/// Graph 1. Yields 
twoway  (connected yield mofd if name == "AAA", `line1') /// 
		(connected yield mofd if name == "AA" , `line2') /// 
		(connected yield mofd if name == "A"  , `line3') /// 
		(connected yield mofd if name == "BBB", `line4'), ///
		xline(`xline', lcolor(maroon) lpattern(dash)) ///
	    $graph_options xtitle("") ytitle("") xlabel(#11, angle(90) labsize(vsmall)) ylabel(#10, labsize(vsmall)) /// 
		name(gr_yields, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Bond Yields by Credit Rating (percentage points)") 
		
/// Graph 2. Yields 
twoway  (connected volatility mofd if name == "AAA", `line1') /// 
		(connected volatility mofd if name == "AA" , `line2') /// 
		(connected volatility mofd if name == "A"  , `line3') /// 
		(connected volatility mofd if name == "BBB", `line4'), ///
		xline(`xline', lcolor(maroon) lpattern(dash)) ///
	    $graph_options xtitle("") ytitle("") xlabel(#11, angle(90) labsize(vsmall)) ylabel(#10, labsize(vsmall)) /// 
		name(gr_volatility, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Volatility by Credit Rating (Average SD)")  
		
grc1leg gr_yields gr_volatility, legendfrom(gr_yields) rows(1) cols(2) xcommon name(Figure1, replace) xsize(16) ysize(8)
graph export "${oup}\Figure1_YieldVolatility.pdf", replace 

********************************************************************************
/// Outcome and Donors Graph
use "${cln}\synth_clean.dta", clear 
/// Mean of the Volatility in the Pre-treatment Period. That is, in the months from Septmeber to February 
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd
replace v = v_norm

********************************************************************************
/// Show only the ATE window 
*keep if month_exp < ${tr_eff_window}
********************************************************************************

preserve 
keep if treat == 1
keep month_exp mofd name v 
reshape wide v, i(mofd month_exp) j(name) string
tempfile treated 
save `treated', replace 
restore 

drop if treat == 1
/// do the smoke lines 
/// Create Percentile Variables 
gen p1 = . 
gen p2 = . 
gen p5 = . 
gen p50 = .
gen p95 = . 
gen p97 = . 
gen p99 = . 

/// Create Percentile Variables For each Experiment Month. So, for any period it will compute the percentiles at such period across all donor units, to then save it with the treated units. 
forvalues t= 1(1)36 {
	_pctile v_norm if month_exp == `t' & treat == 0, percentiles(1 2.5 5 50 95 97.5 99)
	qui replace p1 = r(r1) if month_exp == `t' 
	qui replace p2 = r(r2) if month_exp == `t' 
	qui replace p5 = r(r3) if month_exp == `t' 
	qui replace p50 = r(r4) if month_exp == `t' 
	qui replace p95 = r(r5) if month_exp == `t'
	qui replace p97 = r(r6) if month_exp == `t' 
	qui replace p99 = r(r7) if month_exp == `t'
}

gcollapse (mean) p* v, by(month_exp)
merge 1:1 month_exp using `treated', keep(match master) nogen

rename v volatility 
rename v* *

sum mofd if month_exp == ${treat_period}
local xline = r(mean)

twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(line AAA mofd, sort lcolor(black) lpattern(solid)) ///
		(line AA mofd, sort lcolor(blue) lpattern(solid)) ///
		(line A mofd, sort lcolor(green) lpattern(solid)) ///
		(line BBB mofd, sort lcolor(cranberry) lpattern(solid)), ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options legend(order(4 "AAA" 5 "AA" 6 "A" 7 "BBB" 2 "90/95/99 C.I") pos(6) rows(1) cols(4) size(vsmall)) xtitle("") title("Volatility on the Municipal Bond Market", size(medsmall) pos(11)) name(out_smoke, replace)
graph export "${oup}\OutcomeSmoke1.pdf", replace
		

		
local varlist AAA AA A BBB
foreach var of local varlist {
	twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(line `var' mofd, sort lcolor(black) lpattern(solid)), ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options legend(order(4 "Volatility" 2 "90/95/99 C.I") pos(6) rows(1) cols(4) size(vsmall)) xtitle("") title("`var' ", size(medsmall) pos(11)) name(`var', replace)
		
}
	
grc1leg AAA AA A BBB , legendfrom(AAA) rows(2) cols(2) xcommon ycommon name(out_smoke_comb, replace)
graph export "${oup}\OutcomeSmoke2.pdf", replace 


********************************************************************************
/*
grc1leg gr1 gr2 gr3 gr4 gr5 gr6 gr7 gr8, legendfrom(gr1) name(grcomb1,replace) $combopts 
graph export "${oup}\Synth_GraphCombined1.png", $export 
grc1leg gr9 gr10 gr11 gr12 gr13 gr14 gr15 gr16, legendfrom(gr9) name(grcomb2,replace) $combopts 
graph export "${oup}\Synth_GraphCombined2.png", $export 
grc1leg gr17 gr18 gr19 gr20 gr21 gr22 gr23 gr24, legendfrom(gr17) name(grcomb3,replace) $combopts 
graph export "${oup}\Synth_GraphCombined3.png", $export 
grc1leg gr25 gr26 gr27 gr28 gr29 gr30 gr31 gr32, legendfrom(gr25) name(grcomb4,replace) $combopts 
graph export "${oup}\Synth_GraphCombined4.png", $export 


/// Aggregated Effect
preserve 
gcollapse (mean) treated synth, by(month_exp)
	twoway (line treated month_exp, lcolor(black) lpattern(solid)) ///
		(line synth month_exp, lcolor(navy) lpattern(dash)),  ///
		$graphopts title("Averge Volatility: Observed vs Synthetic") name(gr_aggregated,replace)	
	*graph export "${oup}\Synth_GraphAggregated.png", $export 
restore 
*/
********************************************************************************

*legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small))
/*
use "${cln}\synth_sp.dta", clear 
merge m:1 state using "${tem}\state_ratings.dta", keep(match master) nogen
replace month_exp = month_exp - 7

/// Graph 1. Volatility: Treated Units and Donors 
***************************************************** 
preserve 
gcollapse (mean) v month, by(month_exp year_exp)
sort year_exp month_exp
twoway (line v month_exp if year_exp == 7, lcolor(gray) lpattern(dash)) ///
		(line v month_exp if year_exp == 6, lcolor(green) lpattern(dash)) ///
		(line v month_exp if year_exp == 5, lcolor(cranberry) lpattern(dash)) ///
		(line v month_exp if year_exp == 4, lcolor(maroon) lpattern(dash)) ///
		(line v month_exp if year_exp == 3, lcolor(blue) lpattern(dash)) ///
		(line v month_exp if year_exp == 2, lcolor(navy) lpattern(dash)) ///
		(line v month_exp if year_exp == 1, lcolor(black) lpattern(solid)), ///
		xtitle("Months since Policy") xline(15,lcolor(maroon*0.6) lpattern(dot)) ytitle("") xlabel(#12) ylabel(#5) legend(on order(1 "13-14" 2 "14-15" 3 "15-16" 4 "16-17" 5 "17-18" 6 "18-19" 7 "19-20") size(small) rows(2) cols(4)) $graph_options title("Volatility in the Municipal Market") $title name(voltreated,replace)
graph export "${oup}\Volatility_Monthly.png", $export 
restore

//// Graph 2. Volatility by Credit Rating in 2020 
********************************************
preserve 
keep if year_exp == 1 
gcollapse (mean) v , by(mofd max_ratag)
drop if max_ratag == . 
sort max_ratag mofd 
twoway (line v mofd if max_ratag == 1, lcolor(black) lpattern(dash)) ///
		(line v mofd if max_ratag == 2, lcolor(green) lpattern(dash)) ///
		(line v mofd if max_ratag == 3, lcolor(cranberry) lpattern(dash)) ///
		(line v mofd if max_ratag == 4, lcolor(purple) lpattern(dash)) ///
		(line v mofd if max_ratag == 0, lcolor(gray) lpattern(dash)), ///
		xtitle("") xline(15,lcolor(maroon*0.6) lpattern(dot)) ytitle("") xlabel(#12) ylabel(#5) legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB" 5 "NR") size(small) rows(2) cols(4)) $graph_options title("Volatility in the Municipal Market by Credit Rating") $title name(volrating,replace)
graph export "${oup}\Volatility_Monthly_Rating.png", $export 

drop if max_ratag == 0 

twoway (line v mofd, lcolor(black) lpattern(solid)), by(max_ratag) ///
		xtitle("") xline(15,lcolor(maroon*0.6) lpattern(dot)) ytitle("") xlabel(#12) ylabel(#5) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB" 5 "NR") size(small) rows(2) cols(4)) $graph_options title("") $title name(volrating2,replace)
graph export "${oup}\Volatility_Monthly_Rating2.png", $export 
restore


*/

