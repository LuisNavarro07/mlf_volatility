
*********************************************************************************
*global tr_dt1 =tw(2020w13)
global tr_dt1 = tm(2020m3)

*********************************************************************************
/// Treatmennt Effects and Smokeplots 
use "${tem}\scm_append_treated.dta", clear 
qui gen treat = 1 
append using "${tem}\synt_placebos.dta"
qui replace treat = 0 if treat == . 
qui gen rw = wofd - $tr_dt1
format wofd %tmMon_CCYY
qui gen post = rw > 0 
replace fileid = id if treat == 1


/// Goodness of Fit - Drop 30%
global cohend_cutoff = 0.70

preserve 
// Survival Test 
gcollapse (mean) cohend, by(id)
qui cumul cohend, gen(ecdf)
sort cohend
qui gen survival = ecdf < $cohend_cutoff
qui egen survrate = mean(survival)
qui sum survrate
global survrate = round(r(mean),0.001)
qui sum cohend if survival == 1
local cohencut = r(max)
twoway line ecdf cohend, sort xline(`cohencut', lcolor(red)) title("Placebo Survival Rate = $cohend_cutoff (Cutoff = `cohencut' )", pos(11) size(small)) xlabel(#10) ylabel(#10) name(placebo_surv_rate, replace)
keep id survival 
gsort survival id 
save "${tem}\placebosforinference.dta", replace 
restore 

****************************************************************
global smokeopts lcolor(gray*0.8) lwidth(vthin) lpattern(solid) 
global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(small)) ylabel(#8, nogrid labsize(small) angle(0)) xtitle(, size(small)) xlabel(, labsize(small) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) xtitle("") ytitle("") $back



merge m:1 id using "${tem}\placebosforinference.dta", keep(match master) nogen

gen window = rw >= -4 & rw <= 4 


local title1 "AAA Bonds (SD)"
local title2 "AAA Bonds (Range)"
local title3 "AA Bonds (SD)"
local title4 "AA Bonds (Range)"
local title5 "A Bonds (SD)"
local title6 "A Bonds (Range)"
local title7 "BBB Bonds (SD)"
local title8 "BBB Bonds (Range)"

forvalues k=1(1)8{ 
global outcome = `k'
// Store the name 
global name = "`title`k''"
display "$name"

/// Do the Smokeplot 
preserve
/// Smokeplot: only keep the ones that we can use 
qui sort id rw
// Keep Treated Units and Placebos that satisfy Cohen's D Criterion
qui drop if treat == 1 & id !=  ${outcome}
qui drop if fileid != ${outcome} | survival == 0
// Relabel 
qui sort fileid id rw 
qui egen idd = group(id)
/// Treatment Effect 
local smoke1 "(line tr_eff rw if idd == 1 & window == 1, lwidth(medthick) lpattern(solid) lcolor(maroon))"	
// Smoke lines 
qui sum idd 
global max = r(max)
local smoke ""
forvalues i = 2(1)$max { 
local smoke "`smoke' (line tr_eff rw if idd == `i' & window == 1, $smokeopts)"
}
/// graph  
qui global smoke `smoke' `smoke1'
twoway $smoke, legend(off) xline(0, lcolor(black) lpattern(dash)) $graph_options ytitle("") name(smokeplot`k', replace) title("$name", size(medsmall) pos(11)) 
restore 

}

graph combine smokeplot1 smokeplot3 smokeplot5 smokeplot7, rows(2) cols(2) name(smoke_combined1,replace)
graph export "${oup}\smokeplot_combined1.png", $export 

graph combine smokeplot2 smokeplot4 smokeplot6 smokeplot8, rows(2) cols(2) name(smoke_combined2,replace)
graph export "${oup}\smokeplot_combined2.png", $export 

/*
*******************************************************************************
/// Treatmen Effects Plots - SD 
local treated "(line tr_eff rw if id == 1, lwidth(thin) lpattern(solid) lcolor(black) msize(tiny) mcolor(black))"	
local color2 = "maroon"
local color3 = "navy"
local color4 = "dkgreen"
local j = 2
foreach i in 3 5 7{ 
local treated "`treated' (line tr_eff rw if id == `i', lwidth(thin) lpattern(solid) lcolor(`color`j'') mcolor(`color`j'') msize(tiny))"
local j = `j' + 1
}
twoway `treated', legend(on rows(2) cols(4) size(vsmall)) $graphopts xline(-1, lcolor(gray) lpattern(dash) lwidth(thin)) name(tr_effects1,replace) legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") size(vsmall) rows(1) cols(2) pos(6) region(lcolor(black))) ytitle("") yline(0, lcolor(gray) lpattern(dash) lwidth(vthin))
graph export "${oup}\Synth_TrEffects1.png", $export

/// Treatmen Effects Plots - Range 
local treated "(connected tr_eff rw if id == 2, lwidth(vthin) lpattern(solid) lcolor(black) msize(tiny) mcolor(black))"	
local color2 = "maroon"
local color3 = "navy"
local color4 = "dkgreen"
local j = 2
foreach i in 4 6 8{ 
local treated "`treated' (connected tr_eff rw if id == `i', lwidth(vthin) lpattern(solid) lcolor(`color`j'') mcolor(`color`j'') msize(tiny))"
local j = `j' + 1
}
twoway `treated', legend(on rows(2) cols(4) size(vsmall)) $graphopts xline(-1, lcolor(black) lpattern(dash) lwidth(thin)) name(tr_effects2,replace) legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB") size(vsmall) rows(1) cols(2) pos(6) region(lcolor(black))) ytitle("") 
graph export "${oup}\Synth_TrEffects2.png", $export


********************************************************************************
/// Difference in Differences Model for Treatment Effect
use "${tem}\scm_append_treated.dta", clear 
append using "${tem}\placebos_append.dta"
qui gen rw = wofd - $tr_dt1
qui gen plot_area = rw < 13 & rw > -13
qui gen post = wofd >= $tr_dt1 & plot_area == 1 
drop fileid 
xtset id rw
keep if plot_area == 1
replace cohend = abs(cohend)
gen treat = id < 9 
gen did = treat*post
reghdfe tr_eff did, absorb(rw id) cluster(id)
*/