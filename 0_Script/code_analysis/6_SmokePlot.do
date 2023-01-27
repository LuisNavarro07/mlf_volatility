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
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(small)) ylabel(#10, nogrid labsize(vsmall) angle(0)) xtitle(, size(vsmall)) xlabel(#15, labsize(vsmall) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) xtitle("") ytitle("") $back legend(off order(1 "CI (SmokeArea)" 2 "Treatment Effect") rows(1) size(small))


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
qui tab fileid, matrow(F)
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

/// Store Labels From Results -- Fix Code 
preserve 	
use "${tem}\ATE_Results_Full.dta", clear
order Results A AA AAA BBB 
rename (A AA AAA BBB) (b1 b2 b3 b4)
keep Results b`j'
qui keep if Results == "ATE" | Results == "\% Change" | Results == "RMSPE"
qui replace b`j' = subinstr(b`j',"***","",1)
qui replace b`j' = subinstr(b`j',"**","",1)
qui replace b`j' = subinstr(b`j',"*","",1)
qui replace b`j' = subinstr(b`j',"\%","",1)
qui destring b`j', replace  
local ate =     b`j'[1]
local pchange = b`j'[2]
local rmspe =   b`j'[3]
restore 



preserve
qui keep if fileid == `j'
sort id month_exp
/// Save Treatment Effects and Statistics 
/// Create Percentile Variables 
qui gen p1 = . 
qui gen p2 = . 
qui gen p5 = . 
qui gen p95 = . 
qui gen p97 = . 
qui gen p99 = . 

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
qui sum month_exp if month_exp == 0 
local xline = r(mean)

twoway (rarea p1 p99 month_exp,     fc(gs13%40) lc(gs15%40) lw(medthick)) ///
		(rarea p2 p97 month_exp, fc(gs10%40) lc(gs12%40) lw(medthick)) ///	
		(rarea p5 p95 month_exp,      fc(gs7%40)  lc(gs9%40) lw(medthick))	///
		(line tr_eff month_exp, sort lcolor(maroon) lpattern(solid)), ///
		xline(`xline' , lcolor(black) lpattern(dash) lwidth(thin)) yline(0 , lcolor(black) lpattern(dash) lwidth(thin)) $graph_options name(gr`j', replace) title("`title`j''", size(small) pos(11)) xtitle("Months since MLF Implementation") 
*legend(on order(- 1 5) note("ATE = `ate'" "RMSPE = `rmspe'" "% Change = `pchange'",pos(11) size(vsmall)) label(1 "90/95/99 C.I.") pos(11) ring(0) cols(1) size(tiny) region(lstyle(none) fcolor(none)))
*graph export "${oup}\smoke_`title`j''.png", $export 
restore 
}

graph combine gr3 gr2 gr1 gr4, name(grcomb1,replace) xcommon  
/// Export the Smoke Plot
if "${rating_agg}" == "rating_agg_var" {
	graph export "${oup}\Figure3_SmokeplotCombined.pdf", replace 
}
else if  "${rating_agg}" == "rating_agg_stfix" {
	graph export "${oup}\Figure3_SmokeplotCombined_RCStfix.pdf", replace
}


exit 
