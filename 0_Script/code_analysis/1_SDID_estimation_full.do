
********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@uw.edu) 
/// Update: December 2025
/// Script: Run Baseline Model of synth did  
********************************************************************************
********************************************************************************
clear 
graph drop _all 
set trace off
/// Load dates 


* Load Programs for SDID Estimation 
qui do "${cod}/code_analysis/0_Programs_SDID.do" 
*-------------------------------------------------------------------------------
********************************************************************************
* Implement Estimation 

/// Baseline 
global oup "2_Output/baseline"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)


/// Residualized Nominal Yield 
global oup "2_Output/res_out"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Residualized" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)



/// Spread 
global oup "2_Output/spread"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Spread Yield" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)



/// Residualized Spread 
global oup "2_Output/res_spread"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Spread Residualized" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)


/// Weighted Nominal Yield 
global oup "2_Output/weighted_yield"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Weighted" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)


/// Weighted Residualized Spread 
global oup "2_Output/weighted_res_spread"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Spread Residualized Weighted" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)


/// Credit Rating Varying 
global oup "2_Output/rating_varying"
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield - Credit Rating Varying" | depvar == "Donors"
drop if asset_class == "Municipal Bonds"
drop depvar 
full_sdid_estimation, placebos(off)


********************************************************************************

exit 
