
********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@uw.edu) 
/// Update: January 2026
/// Script: Leave one out sdid 
********************************************************************************
********************************************************************************
clear 
graph drop _all 
set trace off

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
	
	/*
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
	local density_opts recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline($ate, lcolor(maroon) lpattern(longdash)) xtitle("ATE Estimate") ytitle("Density") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) xscale(range(0 $ate)) legend(off) yscale(titlegap(0))
	/// Percentiles plot
	local line1 lcolor(ebblue) lpattern(shortdash) lwidth(medthin)
	local line2 lcolor(eltblue) lpattern(longdash) lwidth(medthin)
	local percentile_lines xline(`p050', `line1') 
	*xline(`p050', `line2') xline(`p950', `line2')

	qui kdensity att`i', `density_opts' title("`title`i'': Left Tail Test p-value = `pval1'", pos(11) size(small))  name(att_dens`i',replace) `percentile_lines'
	*/
	
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
/*
* Keep only the main result row for the table
keep if placebo_id == 0
gen pivot = 1
gcollapse (mean) att* se* pval*, by(pivot)

* 4. PREPARE FOR FIRST RESHAPE
* Rename p-values to a common stub for reshaping
rename pval_1sided* pval*
* Drop the 1-sided p-values (unless you want them instead)
drop pval_2sided* 
* i(pivot) keeps the single group together, j(id) identifies the rating (1,2,3,4)
reshape long att se pval, i(pivot) j(id)

* 5. FORMATTING (Add stars and parens)
gen stars = ""
replace stars = "*"   if pval <= 0.10
replace stars = "**"  if pval <= 0.05
replace stars = "***" if pval <= 0.01

* Create formatted string variables
* Adjust "%9.4f" to "%9.3f" or "%9.2f" if you prefer fewer decimals
gen s_att  = string(att, "%9.4f") + stars
gen s_se   = "(" + string(se, "%9.4f") + ")"
gen s_pval = string(pval, "%9.4f")

* Map IDs to Credit Ratings (Columns)
gen rating = ""
replace rating = "A"   if id == 1
replace rating = "AA"  if id == 2
replace rating = "AAA" if id == 3
replace rating = "BBB" if id == 4

* 6. PREPARE FOR SECOND RESHAPE (Metrics to Rows)
keep rating s_att s_se s_pval
* Rename to generic v1, v2, v3 so we can reshape them together
rename s_att  v1
rename s_se   v2
rename s_pval v3

* Create a dummy index for the reshape
* We want to reshape 'v', grouped by 'rating', indexed by metric type
reshape long v, i(rating) j(metric_type)

* 7. FINAL RESHAPE (Ratings to Columns)
* Now we flip it: metric_type becomes the row, rating becomes the column
reshape wide v, i(metric_type) j(rating) string

* 8. FINAL CLEANUP
* Create the label column
gen Variable = ""
replace Variable = "ATT"     if metric_type == 1
replace Variable = "SE"      if metric_type == 2
replace Variable = "p-value" if metric_type == 3

* Remove the 'v' prefix generated by reshape
rename v* *

* Order columns: Variable first, then Ratings
order Variable AAA AA A BBB

* Clean up temp vars
drop metric_type
*/

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

	*qui graph combine att_dens3 att_dens2 att_dens1 att_dens4, rows(2) cols(2) ycommon name(dens_combined, replace)
	*qui graph display dens_combined, ysize(80) xsize(100) scale(.9)
	*qui graph export "${oup}/ate_dens_main_att.pdf", $export 

end 


********************************************************************************
********************************************************************************

* Implement Estimation 

/// Leave One Out  
global oup "2_Output/leave_one_out"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
* Estimate leave one out approach 
leave_one_out_est


* Open Baseline Results 
use "2_Output/baseline/synth_did_results_table.dta",clear 
keep if Results == "ATT (a)"
* 1. Drop the label column 'Results' if it exists (it's not needed for the reshape)
capture drop Results

* 2. Generate a dummy ID for the current wide row to enable reshaping
gen row_id = _n

* 3. Reshape Long
* This takes columns AAA, AA, A, BBB and stacks them into one variable called 'value'
* The variable 'rating' will contain the strings "AAA", "AA", etc.
rename (AAA AA A BBB) (v3 v2 v1 v4)
reshape long v, i(row_id) j(id) 

* 4. Create the numeric ID variable based on your specific mapping
* Requirement: A=1, AA=2, AAA=3, BBB=4
gen rating = ""
replace rating = "A"   if id == 1
replace rating = "AA"  if id == 2
replace rating = "AAA" if id == 3
replace rating = "BBB" if id == 4

rename v RealATT
replace row_id = 1 if id == 3
replace row_id = 2 if id == 2
replace row_id = 3 if id == 1
replace row_id = 4 if id == 4

* 5. Clean up
sort row_id
list

tempfile real_att
save `real_att', replace
* Do Analysis of Leave one out distribution 
use "${oup}/sdid_att_results_leave_out.dta", clear 
drop if att == .
gcollapse (mean) att, by(id leave_id)

gen Mean = att 
gen SD = att 
gen P01 = att 
gen P05 = att 
gen P10 = att 
gen P90 = att 
gen P95 = att 
gen P99 = att 

gcollapse (mean) Mean (sd) SD (p01) P01 (p05) P05 (p10) P10 (p90) P90 (p95) P95 (p99) P99, by(id)

global vars Mean SD P01 P05 P10 P90 P95 P99

foreach x in $vars {
    replace `x' = round(`x', 0.0001)
	tostring `x', replace format(%12.4f) force
}


merge 1:1 id using `real_att', keep(match master) nogen 

order rating RealATT Mean SD P01 P05 P10 P90 P95 P99
sort row_id
drop id row_id
rename RealATT Baseline
global texopts replace  decimalalign nofix align(lccccccccc) location(h)
texsave * using "2_Output/baseline/sdid_att_table_leave_out.tex", replace
save "${oup}/sdid_att_table_leave_out.dta", replace  

********************************************************************************

