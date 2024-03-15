/// synth smokeplots 
******************************************************************
global smokeopts lcolor(gray*0.8) lwidth(vthin) lpattern(solid)
global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(small)) ylabel(#8, nogrid labsize(small) angle(0)) xtitle(, size(small)) xlabel(, labsize(small) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) xtitle("") ytitle("") $back

/// Load Data 
use "${tem}\synth_treated.dta", clear 
gen treat = 1 
*keep if cohend < $cohend_cutoff
append using "${tem}\synth_placebos.dta", force  
replace treat = 0 if treat == . 

gen window = wofd > ${tr_dt1} - 6  & wofd < ${tr_dt1}  + 6
*********************************************************
local title1 "AAA Bonds (SD)"
local title2 "AAA Bonds (Range)"
local title3 "AA Bonds (SD)"
local title4 "AA Bonds (Range)"
local title5 "A Bonds (SD)"
local title6 "A Bonds (Range)"
local title7 "BBB Bonds (SD)"
local title8 "BBB Bonds (Range)"
*********************************************************
/// 
tab fileid, matrow(F)
global rows_surv = r(r)
display $rows_surv

forvalues j=1(1)$rows {
// Store the name 
preserve
tab fileid, matrow(F)
local k = F[`j',1] 
/// Smokeplot: only keep the ones that we can use 
qui sort fileid id wofd
// Keep Treated Units and Placebos that satisfy Cohen's D Criterion
qui drop if treat == 1 & id !=  `k'
qui drop if fileid != `k'
// Relabel 
qui sort id wofd 
qui egen idd = group(id)
/// Treatment Effect 
local smoke1 "(line tr_eff wofd if idd == 1 & window == 1, lwidth(medthick) lpattern(solid) lcolor(maroon))"	
// Smoke lines 
qui sum idd 
global max = r(max)
local smoke ""
forvalues i = 2(1)$max { 
local smoke "`smoke' (line tr_eff wofd if idd == `i' & window == 1, $smokeopts)"
} 
qui global smoke `smoke' `smoke1'
twoway $smoke, legend(off) xline($tr_dt1 , lcolor(black) lpattern(dash)) $graph_options ytitle("") name(sp`k', replace) title(`title`j'', size(medsmall) pos(11)) 
restore 
}

graph combine sp1 sp3 sp5 sp7, rows(2) cols(2) name(smoke_combined1,replace) xcommon
graph export "${oup}\smokeplot_combined1_$exp.png", $export 

*graph combine sp2 sp4 sp6 sp8, rows(2) cols(2) name(smoke_combined2,replace) xcommon
*graph export "${oup}\smokeplot_combined2_$exp.png", $export 
