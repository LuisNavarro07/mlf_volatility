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
global graph_options xtitle("", size(medsmall)) ytitle(size(small)) /// 
					ylabel(#10, nogrid labsize(small) angle(0)) /// 
					xlabel(#33, labsize(small) angle(90) nogrid) /// 
					title(, size(medsmall) pos(11) color(black)) $back 


cap program drop create_graph_yields 
program define create_graph_yields, rclass 

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
qui sum mofd if month_exp == 0
local xline = r(mean)

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
	    $graph_options name(gr_yields, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Bond Yields by Credit Rating") ytitle("Percentage Points (p.p.)")
		
/// Graph 2. Yields 
twoway  (connected v mofd if name == "AAA", `line1') /// 
		(connected v mofd if name == "AA" , `line2') /// 
		(connected v mofd if name == "A"  , `line3') /// 
		(connected v mofd if name == "BBB", `line4'), ///
		xline(`xline', lcolor(maroon) lpattern(dash)) ///
	    $graph_options name(gr_volatility, replace) legend(off order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") rows(1) cols(4) size(small)) title("Volatility by Credit Rating (Average of Intra-Week SD of Bond Yields)")  ytitle("Percentage Points (p.p.)")
		

end


********************************************************************************

/// Volatility by Rating Group 
global oup "2_Output"
use "${cln}/synth_clean_fixedcr.dta", clear 
drop if depvar == "Donors"

preserve 
keep if depvar == "Nominal Yield Baseline" 
create_graph_yields
grc1leg gr_yields gr_volatility, legendfrom(gr_yields) rows(2) cols(1) xcommon name(yields_comb, replace) xsize(16) ysize(8)
graph display yields_comb, xsize(80) ysize(100) scale(.9)
graph export "${oup}/Figure1_YieldVolatility.pdf", replace 
restore 




local name1 = "credit_varying"
local name2 = "baseline"
local name3 = "nominal_res"
local name4 = "nominal_weight"
local name5 = "spread_res"
local name6 = "spread_res_weight"
local name7 = "spread"
tab depvar 
* 1. Store the distinct values of depvar into a local macro called 'levels'
levelsof depvar, local(levels)

local i = 1
* 2. Loop over the items in that local macro
foreach x of local levels {
    
    preserve 
    keep if depvar == "`x'"
    drop depvar 

    * --- analysis code ---
    create_graph_yields
    * --------------------------
	grc1leg gr_yields gr_volatility, legendfrom(gr_yields) rows(2) cols(1) xcommon name(yields_comb`i', replace) xsize(16) ysize(8)

    * Save outcome 
	graph display yields_comb`i', xsize(80) ysize(100) scale(.9)
	graph export "${oup}/Figure1_YieldVolatility_`name`i''.pdf", replace 
    
    local i = `i' + 1
    
    restore
}


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
keep if depvar == "Donors"
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
gcollapse (mean) mofd, by(month_exp)
tempfile dates
save `dates', replace 
restore 




cap program drop smoke_donors
program define smoke_donors, rclass 

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
gcollapse (mean) p1 p2 p5 p95 p97 p99 avg, by(month_exp mofd)

		
end 

/// Commodities 
preserve 
keep if asset_class == "Commodity"
smoke_donors
sum mofd if month_exp == 0
local xline = r(mean)
twoway (rarea p1 p99 mofd, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(small) msymbol(circle)), ///
		title("Commodities", size(medsmall) pos(11)) legend(off) ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) $graph_options  /// 
		yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
		name(comm, replace) ytitle("Volatility (p.p.)")
restore 

/// Currencies 
preserve 
keep if asset_class == "Currency"
smoke_donors
sum mofd if month_exp == 0
local xline = r(mean)
twoway (rarea p1 p99 mofd, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(small) msymbol(circle)), ///
		title("Currencies", size(medsmall) pos(11)) legend(off) ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) $graph_options  /// 
		yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
		name(curr, replace) ytitle("Volatility (p.p.)")
restore 

/// Sovereign Bonds 
preserve 
keep if asset_class == "Sovereign Bond"
smoke_donors
sum mofd if month_exp == 0
local xline = r(mean)
twoway (rarea p1 p99 mofd, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(small) msymbol(circle)), ///
		title("Sovereign Bonds", size(medsmall) pos(11)) legend(off) ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) $graph_options  /// 
		yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
		name(sovbond, replace) ytitle("Volatility (p.p.)")
restore 

/// Stock Market Indices 
preserve 
keep if asset_class == "Stock Market Index"
smoke_donors
sum mofd if month_exp == 0
local xline = r(mean)
twoway (rarea p1 p99 mofd, fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd, fc(gs7%40)  lc(gs9%40) lw(medthick)) ///
		(connected avg mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(small) msymbol(circle)), ///
		title("International Stock Market Indices", size(medsmall) pos(11)) legend(off) ///
		xline(`xline', lcolor(black) lpattern(dash) lwidth(thin)) $graph_options  /// 
		yline(0, lcolor(black) lpattern(dash) lwidth(thin)) ///
		name(stocks, replace) ytitle("Volatility (p.p.)")
restore 
********************************************************************************

graph combine sovbond comm curr stocks, rows(2) cols(2) name(smoke_comb, replace)
graph display smoke_comb, xsize(100) ysize(80) scale(0.9)
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
