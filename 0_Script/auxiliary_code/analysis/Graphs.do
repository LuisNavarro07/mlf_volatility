

use "${cln}\synth_sp.dta", clear 
replace month_exp = month_exp - ${treat_period} 
preserve 
gen don = sec_id > 1000
gcollapse (mean) v month, by(month_exp year_exp don)
sort don year_exp month_exp 
twoway 	(line v month_exp if year_exp == 1 & don == 0, lcolor(black) lpattern(solid)) ///
		(line v month_exp if year_exp == 2 & don == 0, lcolor(navy) lpattern(dash)) ///
		(line v month_exp if year_exp == 3 & don == 0, lcolor(blue) lpattern(dash)) ///
		(line v month_exp if year_exp == 1 & don == 1, lcolor(dkgreen) lpattern(dash) yaxis(2)), ///
		xtitle("Months") xline(0,lcolor(maroon) lpattern(dash)) ytitle("Volatility") xlabel(#12) ylabel(#5) legend(on order(1 "2019-2021" 2 "2016-2019" 3 "2013-2015" 4 "2019-2021 (Instruments)") size(small) rows(1) cols(3))
graph export "${oup}\Volatility_ExpCohort.png", $export 
restore


// Treatement Effect Graphs 
graph drop _all 
use "${tem}\synth_treated_sp.dta", clear 
merge m:1 id using "${tem}\treated_names.dta", keep(match master) nogen


global graphopts ytitle(,size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("", size(small)) xlabel(#12, nogrid labsize(small) angle(0)) xline(0,lcolor(gray*0.8) lpattern(longdash) lwidth(thin)) yline(0,lcolor(gray*0.8) lpattern(longdash) lwidth(thin)) legend(on order(1 "Observed Volatility" 2 "Synthtic Volatility") size(small) rows(1)) 

tab fileid 
global rows = r(r)

forvalues i=1(1)$rows {
    preserve 
	qui keep if fileid == `i'
	local name = name[1]
	twoway (line treated month_exp, lcolor(black) lpattern(solid)) ///
		(line synth month_exp, lcolor(navy) lpattern(dash)),  ///
		$graphopts title("`name'") name(gr`i',replace)	
	restore 
}

global combopts xcommon ycommon rows(2) cols(4)

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
	graph export "${oup}\Synth_GraphAggregated.png", $export 
restore 

