
********************************************************************************
********************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro (lunavarr@uw.edu) 
/// Update: January 2026
/// Script: Create Regression Table - Robustness Checks 
********************************************************************************
********************************************************************************


//// Create Regression Tables for Robustness Checks 
cap program drop cleantable
program define cleantable, rclass
use "${oup}/synth_did_results_table.dta", clear 
keep if _n <= 2 | _n >= 7 
drop if  _n == 4 | _n == 5  
replace Results = "ATT, % Excess Volatility" if _n == 3
end


/// Baseline
global oup "2_Output/baseline"
cleantable
replace Results = "Baseline" if _n == 1
tempfile baseline 
save `baseline', replace 

/// 1. Residualized Yields 
global oup "2_Output/res_out"
cleantable
replace Results = "Residualized Yield Volatility" if _n == 1
tempfile res_out 
save `res_out', replace 

/// 2. Bonds Spreads 
global oup "2_Output/spread"
cleantable
replace Results = "Bond Spreads Volatility" if _n == 1
tempfile spread 
save `spread', replace 

/// 3. Residualized Bonds Spreads 
global oup "2_Output/res_spread"
cleantable
replace Results = "Residualized Spread Volatility" if _n == 1
tempfile res_spread 
save `res_spread', replace 

/// 4. Yields: weighted by size of trade. 
global oup "2_Output/weighted_yield"
cleantable
replace Results = "Weighted-by-Volume Volatility" if _n == 1
tempfile weighted_yield 
save `weighted_yield', replace 

/// 5. Residualized Spreads: weighted by size of trade. 
global oup "2_Output/weighted_res_spread"
cleantable
replace Results = "Weighted Residualized Spread Volatility" if _n == 1
tempfile weighted_res_spread 
save `weighted_res_spread', replace 

/// 6. Fixed Credit Rating Profile 
global oup "2_Output/rating_varying"
cleantable
replace Results = "ATT" if _n == 1
tempfile rating_varying 
save `rating_varying', replace


/// 1. Estimate the model by asset class 
global oup "2_Output/donor_sens_commodity"
cleantable
replace Results = "Donors: Commodities" if _n == 1
tempfile donors_commodity 
save `donors_commodity', replace 

global oup "2_Output/donor_sens_currencies"
cleantable
replace Results = "Donors: Currencies" if _n == 1
tempfile donors_curr 
save `donors_curr', replace 

global oup "2_Output/donor_sens_sovereign"
cleantable
replace Results = "Donors: International Sovereign Bonds" if _n == 1
tempfile donors_sovereign
save `donors_sovereign', replace 

global oup "2_Output/donor_sens_stock"
cleantable
replace Results = "Donors: International Stock Indices" if _n == 1
tempfile donors_stock 
save `donors_stock', replace 


use `baseline', clear 
keep if _n == 1
replace Results = "Panel A: Alternative Volatility Measurements"
replace AAA = ""
replace AA = ""
replace A = ""
replace BBB = ""
tempfile templatea
save `templatea', replace

use `templatea', clear 
replace Results = "Panel B: Fixed Credit Rating Profile"
tempfile templateb
save `templateb', replace

use `templatea', clear 
replace Results = "Panel C: Composition of the Donor Pool"
tempfile templatec
save `templatec', replace

use `templatea', clear 
append using `baseline'
append using `weighted_yield'
append using `spread'
append using `res_out'
append using `weighted_res_spread'

append using `templateb'
append using `rating_varying'

append using `templatec'
append using `donors_sovereign'
append using `donors_commodity'
append using `donors_stock'
append using `donors_curr'

replace Results = "" if Results == "SE"
global oup "2_Output/baseline"

*texsave * using "${oup}/ATE_Results_Robustness.tex", replace  decimalalign nofix 
global texopts replace  decimalalign nofix align(lccccccccc) location(h)
texsave * using "${oup}/ATT_Results_Robustness.tex", $texopts

exit 
