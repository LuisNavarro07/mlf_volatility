/// Treatment Effects Graphs and Weights 
//// Observed vs Synthetic Graphs 
use "${tem}\scm_append_treated.dta", clear 
*global tr_dt1 =tw(2020w13)
global tr_dt1 = tm(2020m3)

qui gen rw = wofd - $tr_dt1
qui gen plot_area = rw < 13 & rw > -13
qui gen post = wofd >= $tr_dt1 & plot_area == 1 
/// Graph Options 
global graphopts ytitle(,size(small)) ylabel(#10, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) xtitle("Months Since Intervention", size(small)) xlabel(#25, nogrid labsize(small) angle(45))
local title1 "AAA Bonds"
local title2 "AAA Bonds"
local title3 "AA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "A Bonds"
local title7 "BBB Bonds"
local title8 "BBB Bonds"
/// Create The Graphs 
forvalues t=1(1)8{
// Obs vs Synth
twoway (line treat_lev rw if id == `t' & plot_area == 1, lcolor(black) lpattern(solid) lwidth(thin)) (line synth_lev rw if id == `t' & plot_area == 1, lcolor(cranberry) lpattern(solid) lwidth(thin)), xline(-1, lcolor(maroon) lpattern(dash)) $graphopts name(synth`t', replace)  title("`title`t''",pos(11) size(medsmall)) legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility")) ytitle("")
graph export "${oup}\Synth_Graph`t'.png", $export
// Treatment Effects 
*twoway (connected tr_eff rw if id == `t' & plot_area == 1, lwidth(vthin) lpattern(solid) lcolor(black) msize(tiny) mcolor(black)), xline(-1, lcolor(maroon) lpattern(dash)) $graphopts name(treff`t', replace) title("`title`t''",pos(11) size(medsmall)) ytitle("") yline(0,lcolor(black) lpattern(dash) lwidth(thin))
*graph export "${oup}\Synth_Graph_ATE`t'.png", $export
}
/// Combine Graphs 	
grc1leg synth1 synth3 synth5 synth7, legendfrom(synth1) rows(2) cols(2) xcommon name(synth_combined1, replace)
graph export "${oup}\Synth_GraphCombined1.png", $export

*graph combine treff1 treff3 treff5 treff7, rows(2) cols(2) xcommon name(treff_combined1, replace)
*graph export "${oup}\Synth_Graph_ATE_Combined1.png", $export

**** Robustness Checks 
grc1leg synth2 synth4 synth6 synth7, legendfrom(synth2) rows(2) cols(2) xcommon name(synth_combined2, replace)
graph export "${oup}\Synth_GraphCombined2.png", $export

*graph combine treff2 treff4 treff6 treff8, rows(2) cols(2) xcommon name(treff_combined2, replace)
*graph export "${oup}\Synth_Graph_ATE_Combined2.png", $export

**********************************************************************************
*********************************************************************************
// Weight Graphs 
use "${tem}\scm_append_weights.dta", clear  
merge m:1 id using  "${tem}\varnames.dta", keep(match master) nogen
global baropts ytitle("Unit Weight", size(small)) ylabel(#5, nogrid labsize(small) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) blabel(bar, size(vsmall) color(black) position(Outside) format(%6.4g))

local title1 "AAA Bonds"
local title2 "AAA Bonds"
local title3 "AA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "A Bonds"
local title7 "BBB Bonds"
local title8 "BBB Bonds"
// Weight Graphs 
forvalues i=1(1)8{
graph hbar (asis) weight if weight > 0 & trunit == `i', over(des, sort(weight) descending label(labcolor("black") labsize(vsmall))) name(weight`i', replace) bar(1, color(gray*1.4)) title("`title`i''", pos(11) size(medsmall)) $baropts 
}
graph combine weight1 weight3 weight5 weight7, rows(2) cols(2)
graph export "${oup}\Weight_GraphCombined1.png", $export

graph combine weight2 weight4 weight6 weight8, rows(2) cols(2)
graph export "${oup}\Weight_GraphCombined2.png", $export
********************************************************************************
//// Statistical Inference 

/// Treatment Effects
use "${tem}\scm_append_treated.dta", clear 
gcollapse (mean) ate cohend, by(id)
replace cohend = abs(cohend)
save "${tem}\treatment_effects.dta", replace 
matrix define A=J(4,2,.)
matrix define D=J(4,2,.)
matrix rownames A = "AAA" "AA" "A" "BBB"
matrix colnames A = "ATE" "Cohen D"
matrix rownames A = "AAA" "AA" "A" "BBB"
matrix colnames D = "ATE" "Cohen D"
forvalues i=1(1)4{
quietly sum ate if id == `i'
matrix A[`i',1] = r(mean)
quietly sum cohend if id == `i'
matrix A[`i',2] = r(mean)

quietly sum ate if id == `i' + 1
matrix D[`i',1] = r(mean)
quietly sum cohend if id == `i' + 1
matrix D[`i',2] = r(mean)
}


/// Placebo Distribution 
use "${tem}\placebos_append.dta", clear
gcollapse (mean) ate cohend, by(id)
quietly sum ate 
local mean = r(mean)
local sd = r(sd)
gen c_ate = (ate - `mean')/`sd'
cumul c_ate, gen(ate_cdf)
/// Standard Deviation
matrix define R=J(4,3,.)
matrix colnames R = "ATE" "P-value" "Cohen D"
matrix rownames R = "AAA" "AA" "A" "BBB"
sort ate_cdf
local j = 1
foreach i in 1 2 3 4 {
    matrix R[`j',1] = D[`i',1]
	matrix R[`j',3] = D[`i',2]
    quietly sum id 
	local max = r(max)
    quietly sum ate 
	local mean = r(mean)
	local sd = r(sd)
	/// Center the Treatment Effect under the Placebo Distribution
	local t = (D[`i',1]-`mean')/`sd'
	/// We want to calculate Pr(ATE<0). So we count how many times this happens under 
	/// the empirical distribution of the ATE. 
	/// Dummy Variable to Test whether the treatment effect is lower than each placebo ate. 
    gen p`i' = `t' < c_ate
	/// Count how many times the ATE estimated was lower than the Placebo 
	egen pc`i' = count(id) if p`i' == 1
	/// Fill the missings of the count made 
	egen pcc`i' = mean(pc`i')
	/// P value is the percentage of times the ATE was lower than the placebo ate 
	gen pval`i' = pcc`i'/`max'
	drop p`i' pc`i' pcc`i'
	/// Store Everything in a matrix
	quietly sum pval`i' 
	matrix R[`j',2] = r(mean)
	local j = `j' + 1
}
matlist R
esttab matrix(R,fmt(4 4 4)) 
esttab matrix(R,fmt(4 4 4)) using "${oup}\ate_pval_sd.tex", replace 
drop p*
******************************************************
/// Range 
/// Standard Deviation
matrix define R=J(4,3,.)
matrix colnames R = "ATE" "P-value" "Cohen D"
matrix rownames R = "AAA" "AA" "A" "BBB"
sort ate_cdf
local j = 1
foreach i in 1 2 3 4 {
    matrix R[`j',1] = A[`i',1]
	matrix R[`j',3] = A[`i',2]
    quietly sum id 
	local max = r(max)
    quietly sum ate 
	local mean = r(mean)
	local sd = r(sd)
	/// Center the Treatment Effect under the Placebo Distribution
	local t = (A[`i',1]-`mean')/`sd'
	/// We want to calculate Pr(ATE<0). So we count how many times this happens under 
	/// the empirical distribution of the ATE. 
	/// Dummy Variable to Test whether the treatment effect is lower than each placebo ate. 
    gen p`i' = `t' < c_ate
	/// Count how many times the ATE estimated was lower than the Placebo 
	egen pc`i' = count(id) if p`i' == 1
	/// Fill the missings of the count made 
	egen pcc`i' = mean(pc`i')
	/// P value is the percentage of times the ATE was lower than the placebo ate 
	gen pval`i' = pcc`i'/`max'
	drop p`i' pc`i' pcc`i'
	/// Store Everything in a matrix
	quietly sum pval`i' 
	matrix R[`j',2] = r(mean)
	local j = `j' + 1
}
matlist R
esttab matrix(R,fmt(4 4 4)) 
esttab matrix(R,fmt(4 4)) using "${oup}\ate_pval_range.tex", replace 
save "${tem}\placebo_distribution.dta", replace 