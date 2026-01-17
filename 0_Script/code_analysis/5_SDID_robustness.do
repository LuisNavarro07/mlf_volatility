********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@uw.edu) 
/// Update: January 2026
/// Script: Robustness Check: CRF, Persistence, and Leave One Out by State
********************************************************************************
********************************************************************************

clear 
graph drop _all 
set trace off

********************************************************************************
* Load Programs for SDID Estimation 
qui do "${cod}/code_analysis/0_Programs_SDID.do"  
********************************************************************************
 

********************************************************************************
/// Robustness Check - CARES Act 
********************************************************************************
global oup "2_Output/cares_act"
use "${cln}/synth_clean_crf.dta", clear 
drop if asset_class == "Municipal Bonds"

sdid_crf, placebos(on)
********************************************************************************


********************************************************************************
/// Robustness Check - Persistance and Dynamic Treatment Effect   
********************************************************************************
global oup "2_Output/persistence"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"

drop depvar 
sdid_persistence, placebos(on)
********************************************************************************


********************************************************************************
/// Robustness Check - Leave One Out By State 
********************************************************************************
global oup "2_Output/leave_one_state"
* Load Individual bond Data 
use "${tem}/statebondsfull_secondary.dta",clear 
qui drop rating rating_agg rating_agg_str
/// Assign Credit Rating 
qui merge m:1 StateCode using "${tem}/state_ratings_data.dta", keep(match master) nogen 
qui gen rating_agg_str = ""
qui replace rating_agg_str = "AAA" if rating_agg == 1
qui replace rating_agg_str = "AA" if rating_agg == 2
qui replace rating_agg_str = "A" if rating_agg == 3
qui replace rating_agg_str = "BBB" if rating_agg == 4
qui replace rating_agg_str = "NR" if rating_agg == 5
/// Assumption: Drop Not Rated States 
drop if rating_agg_str == "NR"
/// variable for loop
encode StateCode, gen(state_code)
tempfile bond_data
save `bond_data', replace

* Keep crosswalk state to ratings 
keep state_code StateCode rating_agg rating_agg_str
duplicates drop state_code StateCode rating_agg rating_agg_str, force
tempfile state_ratings
save "${tem}/state_ratings_list_loop.dta", replace


* For loop: for all states  
tab state_code, matrow(S)
global states_tot = r(r)

forvalues i = 1(1)$states_tot{
	
	local state_code = S[`i',1]
	noisily display "Begin Estimation for State `state_code'"

	qui use `bond_data', clear 	
	qui sum rating_agg if state_code == `state_code'
	global rating_st = r(mean)
	/// Drop state `k' [Parameter from the function]
	qui drop if state_code == `state_code'
	/// Do the function 
	leave_one_state, placebos("on")
	/// Add labels 
	qui gen state_code = `state_code'

	qui tempfile leave_state_`i'
	qui save `leave_state_`i'', replace 
	noisily display "End Estimation for State `state_code'"
}

use `leave_state_1', clear 
forvalues i = 2(1)$states_tot{
	append using `leave_state_`i''
}

qui merge m:1 state_code using "${tem}/state_ratings_list_loop.dta", keep(match master) nogen

save "${oup}/results_state_leave_one_out.dta", replace

* create regression table 
* Columns: Credit Ratings 
* Rows: States 

* Baseline + Each Row for state 
* Report just coefficients no standard errors 
use "${oup}/results_state_leave_one_out.dta", clear
keep if names == "ATT (a)"
keep b1 id_treated StateCode state_code rating_agg 
reshape wide b1, i(state_code StateCode) j(id_treated)
order state_code StateCode b13 b12 b11 b14
rename (b13 b12 b11 b14) (AAA AA A BBB)
sort rating_agg state_code

tempfile state_leave_one_res
save `state_leave_one_res', replace 

use "2_Output/baseline/synth_did_results_table.dta", clear 
keep if Results == "ATT (a)"
rename Results StateCode
replace StateCode = "Baseline"
append using `state_leave_one_res'

save "${oup}/regtable_state_leave_one_out.dta", replace


texsave StateCode AAA AA A BBB using "${oup}/regtable_state_leave_one_out.tex", ///
    replace ///
    nofix ///
    align(l c c c c) ///
    hlines(5) ///
    label("tab:regtable_state_leave_one_out") 

exit
********************************************************************************



exit 
/*
* Fiscal Position Analysis 
use "1_Data/Raw/acfr_data2023.dta", clear 
keep state_code state_id year tpg_total_np tpg_operatingrev gf_unassigned gf_revenues
gen liquidity_gf = gf_unassigned/gf_revenues
gen solvency_tpg = tpg_total_np/tpg_operatingrev
keep if year >= 2015 & year <= 2019
gcollapse (mean) liquidity_gf solvency_tpg, by(state_code)
rename state_code StateCode

tempfile metrics 
save `metrics', replace 

global oup "2_Output/leave_one_state" 
use "${oup}/regtable_state_leave_one_out.dta", clear 
gen order = _n
merge 1:1 StateCode using `metrics', keep(match master) nogen
sort order
sort rating_agg solvency_tpg
*/
