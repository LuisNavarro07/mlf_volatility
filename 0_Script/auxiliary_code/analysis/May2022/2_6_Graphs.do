//// 2_6 Treatment Effects Graphs 

/// Treatment Effects Graphs and Weights 
//// Observed vs Synthetic Graphs 
use "${tem}\synth_treated.dta", clear 

/// Graph Options 
global graphopts ytitle(,size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("", size(small)) xlabel(#24, nogrid labsize(small) angle(45))
local title1 "AAA"
local title2 "AAA"
local title3 "AA"
local title4 "AA"
local title5 "A"
local title6 "A"
local title7 "BBB"
local title8 "BBB"
/// Create The Graphs 
forvalues t=1(1)8{
// Obs vs Synth
twoway (line treat_lev wofd if id == `t', lcolor(black) lpattern(solid) lwidth(thin)) (line synth_lev wofd if id == `t', lcolor(dknavy) lpattern(dash) lwidth(thin)), xline($tr_dt1, lcolor(maroon) lpattern(dash) lwidth(thin)) xline($tr_dt_preT, lcolor(dknavy) lpattern(dash) lwidth(thin)) $graphopts name(synth`t', replace)  title("`title`t''",pos(11) size(medsmall)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility")) ytitle("")
*graph export "${oup}\Synth_Graph`t'.png", $export
// Treatment Effects 
*twoway (connected tr_eff rw if id == `t', lwidth(vthin) lpattern(solid) lcolor(black) msize(tiny) mcolor(black)), xline(-1, lcolor(maroon) lpattern(dash)) $graphopts name(treff`t', replace) title("`title`t''",pos(11) size(medsmall)) ytitle("") yline(0,lcolor(black) lpattern(dash) lwidth(thin))
*graph export "${oup}\Synth_Graph_ATE`t'.png", $export
}
/// Combine Graphs 	
grc1leg synth1 synth3 synth5 synth7, legendfrom(synth1) rows(2) cols(2) xcommon name(synth_combined1, replace)
graph export "${oup}\Synth_GraphCombined1_$exp.png", $export 


*************************************************************

use "${tem}\synth_treated.dta", clear
twoway (line treat_lev wofd if id == 1, lcolor(black) lpattern(solid) lwidth(thin)) /// 
		(line treat_lev wofd if id == 3, lcolor(navy) lpattern(dash) lwidth(thin)) /// 
		(line treat_lev wofd if id == 5, lcolor(cranberry) lpattern(solid) lwidth(thin)) ///
		(line treat_lev wofd if id == 7, lcolor(dkgreen) lpattern(dash) lwidth(thin)), xline($tr_dt1, lcolor(maroon) lpattern(dash))   $graphopts name(volatility, replace)  title("Volatility by Credit Rating",pos(11) size(medsmall)) legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") size(small) rows(1)) ytitle("")
		graph export "${oup}\VolatilityGraph_$exp.png", $export 
		
/// yield Graph 
use "${tem}\financial_market_yields.dta", clear 
keep date yield3a yield2a yielda yield3b
gen mofd = mofd(date)
gcollapse (mean) yield3a yield2a yielda yield3b, by(mofd)
format mofd %tmMon_CCYY
twoway (line yield3a mofd, lcolor(black) lpattern(solid) lwidth(thin)) /// 
		(line yield2a mofd, lcolor(navy) lpattern(dash) lwidth(thin)) /// 
		(line yielda mofd, lcolor(cranberry) lpattern(solid) lwidth(thin)) ///
		(line yield3b mofd, lcolor(dkgreen) lpattern(dash) lwidth(thin)), xline($tr_dt1, lcolor(maroon) lpattern(dash))   $graphopts name(yield, replace)  title("Yield by Credit Rating",pos(11) size(medsmall)) legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") size(small) rows(1)) ytitle("")

grc1leg yield volatility, legendfrom(yield) rows(1) cols(2) xcommon
graph export "${oup}\VolatilityGraphCombined_$exp.png", $export 