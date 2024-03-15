*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Smokeplots for all Treated Units 
*************************************************************************
*************************************************************************
graph drop _all 
global smokeopts lcolor(gray*0.8) lwidth(vthin) lpattern(solid)
global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(small)) ylabel(#8, nogrid labsize(small) angle(0)) xtitle(, size(small)) xlabel(#12, labsize(small) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) xtitle("") ytitle("") $back legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small))

/// Load Data 
use "${tem}\synth_treated.dta", clear 
qui gen treat = 1 
append using "${tem}\placeboempiricaldistribution.dta", force  
qui replace treat = 0 if treat == . 
tab fileid, matrow(F)
global rows = r(r)
*merge m:1 id using "${tem}\treated_names.dta", keep(match master) nogen 

local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"


/// For Each Treated Unit 
forvalues j=1(1)$rows {
preserve
qui keep if fileid == `j'
sort id month_exp

gen p1 = . 
gen p2 = . 
gen p5 = . 
gen p95 = . 
gen p97 = . 
gen p99 = . 

/// Create Percentile Variables For each Experiment Month 
forvalues t= -15(1)20 {
	_pctile tr_eff if month_exp == `t' & treat == 0, percentiles(1 2.5 5 95 97.5 99)
	replace p1 = r(r1) if month_exp == `t' & treat == 1
	replace p2 = r(r2) if month_exp == `t' & treat == 1
	replace p5 = r(r3) if month_exp == `t' & treat == 1
	replace p95 = r(r4) if month_exp == `t' & treat == 1
	replace p97 = r(r5) if month_exp == `t' & treat == 1 
	replace p99 = r(r6) if month_exp == `t' & treat == 1
	
}

keep if treat == 1
twoway (rarea p1 p99 month_exp,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 month_exp, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 month_exp,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(line tr_eff month_exp, sort lcolor(maroon) lpattern(solid)), ///
		xline(0 , lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options name(gr`j', replace) title("`title`j''", size(medsmall) pos(11)) legend(off)
restore 
}

grc1leg gr3 gr2 gr1 gr4, legendfrom(gr1) name(grcomb1,replace) $combopts 
graph export "${oup}\SmokeCombinedOut.png", $export 

/*
grc1leg gr1 gr2 gr3 gr4 gr5 gr6 gr7 gr8, legendfrom(gr1) name(grcomb1,replace) $combopts 
graph export "${oup}\SmokeCombined1.png", $export 
grc1leg gr9 gr10 gr11 gr12 gr13 gr14 gr15 gr16, legendfrom(gr9) name(grcomb2,replace) $combopts 
graph export "${oup}\SmokeCombined2.png", $export 
grc1leg gr17 gr18 gr19 gr20 gr21 gr22 gr23 gr24, legendfrom(gr17) name(grcomb3,replace) $combopts 
graph export "${oup}\SmokeCombined3.png", $export 
grc1leg gr25 gr26 gr27 gr28 gr29 gr30 gr31 gr32, legendfrom(gr25) name(grcomb4,replace) $combopts 
graph export "${oup}\SmokeCombined4.png", $export 
*/

/*
//// Aggregated SmokePlot 
preserve 
bysort month_exp: egen max = max(tr_eff) if treat == 0 
bysort month_exp: egen min = min(tr_eff) if treat == 0 
gsort -treat month_exp 
gcollapse (mean) tr_eff max min, by(month_exp treat)
qui gen xzero = 0 
twoway 	(rarea max min month_exp if treat == 0, sort fcolor(gray*0.4) lcolor(gray) fintensity(inten50)) ///
		(line tr_eff month_exp if treat == 1, sort lcolor(maroon) lpattern(solid)) ///
		(line xzero month_exp if treat == 1, sort lcolor(black) lpattern(dash) lwidth(thin)), ///
		xline(0 , lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options name(sp_ag, replace) title("Average Treatment Effect - Smokeplot", size(medsmall) pos(11)) 
graph export "${oup}\SmokeAggregated.png", $export
restore 
*/
exit 
