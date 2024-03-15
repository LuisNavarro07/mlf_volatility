*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Smokeplots for all Treated Units 
*************************************************************************
*************************************************************************
*graph drop _all 
global smokeopts lcolor(gray*0.8) lwidth(vthin) lpattern(solid)
global title title(,pos(11) size(3) color(black))
global smoke_options ytitle("Treatment Effect", size(vsmall)) ylabel(#18, nogrid labsize(vsmall) angle(0)) xtitle("", size(vsmall)) xlabel(#30, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(-5)) plotregion(lcolor()) legend(on order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small)) plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 


///Crosswalks for months 
use "${cln}\synth_clean.dta", clear 
replace month_exp = month_exp - ${treat_period}
drop if treat == 0 
keep month_exp mofd
duplicates drop mofd, force 
tempfile dates
save `dates', replace 


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

********************************************************************************
/// Show only the ATE window 
keep if month_exp < ${tr_eff_window}
********************************************************************************

/// For Each Treated Unit 
forvalues j=1(1)$rows {
preserve 	
use "${tem}\ATE_Results_Full.dta", clear
order Results A AA AAA BBB
rename (Results A AA AAA BBB) (names b1 b2 b3 b4) 

qui replace b`j' = subinstr(b`j', "\", "", .)

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
/// Save Treatment Effects and Statistics 

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
local lineopts lcolor(gray) lpattern(dash) lwidth(vthin)

twoway (rarea p1 p99 mofd,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 mofd, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 mofd,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(connected tr_eff mofd, sort lcolor(maroon) lpattern(solid) mcolor(maroon) msize(vsmall) msymbol(circle)), ///
		xline(`xline' , `lineopts') yline(0 , `lineopts') $smoke_options name(gr`j', replace) title("`title`j''", size(small) pos(11)) legend(order(- 1 5) note("ATE = `ate'" "p-value = `pval'" "RMSPE = `rmspe'" "ATE (% Excess Volatility) = `excess_vol'", pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none)))
*graph export "${oup}\smoke_`title`j''.png", $export 
restore 
}

graph combine gr3 gr2 gr1 gr4, name(smokecomb1,replace) $combopts 
graph display smokecomb1, ysize(50) xsize(85) scale(.9)
graph export "${oup}\SmokeCombinedOut_${tr_eff_window}.pdf", $export

exit 

********************************************************************************

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
