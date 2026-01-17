
********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@uw.edu) 
/// Update: January 2026
/// Script: Sensitivity Analysis to the Composition of the Donor Pool 
********************************************************************************
********************************************************************************
clear 
graph drop _all 
set trace off
********************************************************************************
********************************************************************************
/// Load Programs 
********************************************************************************
qui do "${cod}/code_analysis/0_Programs_SDID.do" 

********************************************************************************
* Program 6: Construct ATE Table - Modified Version: Load baseline placebo distribution 
cap program drop construct_att_table 
program define construct_att_table, rclass 

* 1. Load Real Results
use "${oup}/sdid_results.dta", clear 
collapse (mean) att, by(id)
gen placebo_id = 0 // Marker for the "Real" treated unit
reshape wide att, i(placebo_id) j(id)
tempfile sdid_att 
save `sdid_att'

* 2. Append Placebo Results
global base "2_Output/baseline"
use "${base}/sdid_placebo_distributions.dta", clear 
cap drop survival

preserve 
gcollapse (mean) rmspe, by(placebo_id id)
* keep only good placebos 
qui gen survival = 0 
qui replace survival = 1 if rmspe <= $rmspe_cutoff
keep placebo_id id survival 
tempfile placebo_survival 
save `placebo_survival', replace 
restore 

merge m:1 id placebo_id using `placebo_survival', keep(match master) nogen
* keep only good placebos 
tabstat rmspe, by(survival) stat(mean n)
tab survival
keep if survival == 1

save "${oup}/sdid_placebo_distributions_clean.dta", replace 
***** save data for further analysis 

*use "${oup}/sdid_placebo_distributions_clean.dta", clear 
gcollapse (mean) att, by(placebo_id id)
reshape wide att, j(id) i(placebo_id)
*rename attp* att* 
append using `sdid_att'
sort placebo_id
/// Matrix to Store Results 
local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB" 
matrix define R=J(12,4,.)
matrix colnames R = "A" "AA" "AAA" "BBB"
matrix rownames R = "att" "se" "ci_min" "ci_max"  "pval2" "pval1" "vol_pre" "vol_treat" "excess_vol" "ate_excess_vol" "rmspe" "id"

* Matrix with regression results 


* 3. Calculate Inference Metrics
* We loop over the 4 outcomes (AAA, AA, A, BBB)
forvalues i = 1(1)4 {
    * A. Get the Real ATT value (stored where placebo_id == 0)
    qui sum att`i' if placebo_id == 0
    local real_att = r(mean)
    mat R[1,`i'] = `real_att'
	
    * B. Calculate Standard Error 
    * (SD of the placebo distribution, usually excluding the real unit)
    qui sum att`i' if placebo_id != 0
    gen se`i' = r(sd)
    mat R[2,`i'] = r(sd)
	
	_pctile att`i' if placebo_id != 0, percentiles(2.5 97.5)
	mat R[3,`i'] = r(r1)
	mat R[4,`i'] = r(r2)
	
    * C. Two-Sided P-Value (Recommended)
    * Checks if abs(placebo) > abs(real)
    * Formula: (Count + 1) / (N_donors + 1)
    gen abs_diff`i' = abs(att`i') >= abs(`real_att')
    qui count if abs_diff`i' == 1 & placebo_id != 0
    local count_extreme = r(N)
    qui count if placebo_id != 0
    local N_placebos = r(N)
    
    gen pval_2sided`i' = (`count_extreme' + 1) / (`N_placebos' + 1)
	qui sum pval_2sided`i'
    mat R[6,`i'] = r(mean)
	
    * D. One-Sided P-Value (Left Tail, if you expect negative effects)
    * Checks if placebo < real
    gen left_diff`i' = att`i' <= `real_att'
    qui count if left_diff`i' == 1 & placebo_id != 0
    local count_lower = r(N)
    
    gen pval_1sided`i' = (`count_lower' + 1) / (`N_placebos' + 1)
	qui sum pval_1sided`i'
	mat R[5,`i'] = r(mean)
	qui local pval1 = round(r(mean),0.0001)
	
	
		/// Percentiles for lines in density plot
	qui cumul att`i' , gen(att`i'_cdf)
	/// Percentile 2.5% 
	qui sum att`i'  if att`i'_cdf <= 0.025
	local p025 = r(max)
	/// Percentile 5.0% 
	qui sum att`i'  if att`i'_cdf <= 0.05
	local p050 = r(max)	
	/// Percentile 95.0% 
	qui sum att`i'  if att`i'_cdf <= 0.95
	local p950 = r(max)
	/// Percentile 97.5% 
	qui sum att`i'  if att`i'_cdf <= 0.975
	local p975 = r(max)
	
	/// ATE's Empirical Distribution - 
	local density_opts recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(`real_att', lcolor(maroon) lpattern(longdash)) xtitle("ATT Estimate") ytitle("Density") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) xscale(range(0 $ate)) legend(off) yscale(titlegap(0))
	/// Percentiles plot
	local line1 lcolor(ebblue) lpattern(shortdash) lwidth(medthin)
	local line2 lcolor(eltblue) lpattern(longdash) lwidth(medthin)
	local percentile_lines xline(`p050', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity att`i', `density_opts' title("`title`i'': Left Tail Test p-value = `pval1'", pos(11) size(small))  name(att_dens`i',replace) `percentile_lines'
	
	
	preserve 
	use "${oup}/sdid_results.dta", clear 
	qui keep if id == `i'
	qui keep if Y_treated != .
	/// ATE in absolute value (to compute ATE in percent of Excess Volatility)
	local absatt = abs(`real_att')
	/// Volatility Pre-Treatment Period: Average Volatility Observed in the Pre-Treatment Period 
	qui sum Y_treated if event_time < -1
	local vol_pre = r(mean)
	mat R[7,`i'] = `vol_pre'
	/// Volatility Observed in March 2020: Spike due to COVID 
	qui sum Y_treated if event_time == -1
	local vol_treat = r(mean)
	mat R[8,`i'] = `vol_treat'
	/// Compute Excess Volatility: Difference in Average Volatility and Volatility During the Pandemic 
	local excess_vol = `vol_treat' - `vol_pre'
	mat R[9,`i'] = `excess_vol'
	/// ATE in Terms of Excess Volatility 
	local ate_excess_vol = 100*(`absatt'/`excess_vol')
	if abs(`ate_excess_vol') > 300 {
	local ate_excess_vol = "."
	}
	mat R[10,`i'] = `ate_excess_vol'
	/// RMSE 
	qui sum rmspe 
	mat R[11,`i'] = r(mean)
	/// Id
	mat R[12,`i'] = `i'
	restore 
	
}


matlist R 
clear 
att_table

* Display
list, noobs sep(0) abbrev(32)
* 9. Export
* Save final results with valid SEs and Exact P-values
save "${oup}/synth_did_results_table.dta",replace

texsave Results AAA AA A BBB using "${oup}/synth_did_results_table.tex", ///
    replace ///
    nofix ///
    align(l c c c c) ///
    hlines(5) ///
    label("tab:synth_did_results_table") 

	*title("Average Treatment Effect on the Treated: MLF impact on Municipal Volatility") ///

	qui graph combine att_dens3 att_dens2 att_dens1 att_dens4, rows(2) cols(2) ycommon name(dens_combined, replace)
	qui graph display dens_combined, ysize(80) xsize(100) scale(.9)
	qui graph export "${oup}/ate_dens_main_att.pdf", $export 

end 

********************************************************************************
* Donor Sensitivity: Only Commodities 
global oup "2_Output/donor_sens_commodity"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop depvar 
* Keep only donor commodities 
keep if asset_class == "Commodity" | asset_class == "Outcome"
drop if asset_class == "Municipal Bonds"

* do the full estimation 
full_sdid_estimation, placebos(off)

********************************************************************************
/*
********************************************************************************
* Donor Sensitivity: Only Municipal Bonds 
global oup "2_Output/donor_sens_munis"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop depvar 
* Keep only donor commodities 
keep if asset_class == "Municipal Bonds" | asset_class == "Outcome"
drop if asset_class == "Municipal Bonds"

* do the full estimation 
full_sdid_estimation, placebos(off)

********************************************************************************
*/
********************************************************************************
* Donor Sensitivity: Only Sovereign Bonds 
global oup "2_Output/donor_sens_sovereign"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop depvar 
* Keep only donor commodities 
keep if asset_class == "Sovereign Bond" | asset_class == "Outcome"
drop if asset_class == "Municipal Bonds"

* do the full estimation 
full_sdid_estimation, placebos(off)

********************************************************************************


********************************************************************************
* Donor Sensitivity: Only Stock Market Index 
global oup "2_Output/donor_sens_stock"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop depvar 

* Keep only donor commodities 
keep if asset_class == "Stock Market Index" | asset_class == "Outcome"
drop if asset_class == "Municipal Bonds"

* do the full estimation 
full_sdid_estimation, placebos(off)

********************************************************************************

********************************************************************************
* Donor Sensitivity: Only Currencies
global oup "2_Output/donor_sens_currencies"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop depvar 

* Keep only donor commodities 
keep if asset_class == "Currency" | asset_class == "Outcome"
drop if asset_class == "Municipal Bonds"

* do the full estimation 
full_sdid_estimation, placebos(off)

exit 
