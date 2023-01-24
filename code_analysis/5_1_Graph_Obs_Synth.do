*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Average Treatment Effect Graph
*************************************************************************
*************************************************************************

// Treatement Effect Graphs 
use "${tem}\synth_treated.dta", clear 
global graphopts ytitle(,size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(medsmall) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("Months since MLF Implementation", size(small)) xlabel(#15, nogrid labsize(small) angle(0)) xline(0 , lcolor(black) lpattern(dash) lwidth(thin)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility") size(small) rows(1)) 

********************************************************************************
********************************************************************************
qui tab fileid 
global rows = r(r)
local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"

forvalues i=1(1)$rows {
    preserve 
	qui keep if fileid == `i'
	qui sum treat_lev if month_exp < 0 
	qui local yline = r(mean)
	twoway (line treat_lev month_exp if month_exp <= ${tr_eff_window}, lcolor(black) lpattern(solid) msize(vsmall) mcolor(black)) ///
		(line synth_lev month_exp if month_exp <= ${tr_eff_window}, lcolor(cranberry) lpattern(dash)),  ///
		$graphopts title("`title`i''") name(gr`i',replace) yline(`yline', lcolor(black) lpattern(dash) lwidth(thin))
	restore 
}

global combopts xcommon rows(2) cols(2)

grc1leg gr3 gr2 gr1 gr4, legendfrom(gr1) name(grcomb1,replace) $combopts 

graph export "${oup}\Figure2_ObservedSynthVolatility.pdf", replace 

