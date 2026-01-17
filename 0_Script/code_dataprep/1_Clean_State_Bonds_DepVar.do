********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Clean Bloomberg State Data and Merge with MSRB Secondary Market
*** This Update: January 2026
********************************************************************************
********************************************************************************

********************************************************************************
* Load Programs for SDID Estimation 
qui do "${cod}/code_analysis/0_Programs_SDID.do"  
********************************************************************************
 

********************************************************************************
/// Secondary Market Bonds: Preparation 
********************************************************************************

// Load Data 

/// Bloomberg Primary Market Bonds
/// All Bonds (Active and Matured) issued by State Governments between 2019 and 2021

forvalues i=1(1)2{
import excel "${raw}/state_bonds_bloomberg.xlsx", sheet("Sheet`i'") firstrow clear
tempfile statebonds`i'
save `statebonds`i'', replace 
}

use `statebonds1', clear
append using `statebonds2'

* Clean Bonds [Creates: statebondsfull_secondary.dta ]
clean_bonds 

/// Export Bonds Secondary Market - Sample to Compute Volatility Measures 
save "${tem}/statebondsfull_secondary.dta",replace 

********************************************************************************
********************************************************************************


********************************************************************************
/// Baseline Dependent Variable: Nominal Yields 
********************************************************************************

/// Load data 
use "${tem}/statebondsfull_secondary.dta",clear 

/// Create Yields for Volatility Calculations
create_yields_depvar
/// Label Results

gen depvar = "Nominal Yield Baseline"
tempfile nominal_yield_baseline 
save `nominal_yield_baseline', replace



/// Weighted Nominal Yield by Par Traded 
/// Load Data 
use "${tem}/statebondsfull_secondary.dta",clear 

/// Create Yields for Volatility Calculations
create_yields_depvar_weight
/// Label Results
gen depvar = "Nominal Yield Weighted"
tempfile nominal_yield_weighted 
save `nominal_yield_weighted', replace 




********************************************************************************
/// Alternative 1: Create residualized yields to compute volatility measures 
********************************************************************************

/// Load Data 
use "${tem}/statebondsfull_secondary.dta",clear 

/// Compute Residualized Yield
create_residualized_yield
/// Create Yields for Volatility Calculations
create_yields_depvar
/// Label Results
gen depvar = "Nominal Yield Residualized"
tempfile nominal_yield_residualized 
save `nominal_yield_residualized', replace 


********************************************************************************
/// Alternative 2: Compute Bond Spread
********************************************************************************

use "${tem}/statebondsfull_secondary.dta",clear 
/// Compute Bond Spreads
compute_bond_spread
/// Create Yields for Volatility Calculations
create_yields_depvar

/// Label Results
gen depvar = "Spread Yield"
tempfile spread_yield
save `spread_yield', replace 


********************************************************************************
/// Alternative 3: Compute Residualized Bond Spread
********************************************************************************

use "${tem}/statebondsfull_secondary.dta",clear 
/// Compute Bond Spreads
compute_bond_spread
/// Create Residualized Bond Spread 
create_residualized_spread
/// Create Yields for Volatility Calculations
create_yields_depvar

/// Label Results
gen depvar = "Spread Residualized"
tempfile spread_residualized
save `spread_residualized', replace 


/// Weighted Residualized Spread 
use "${tem}/statebondsfull_secondary.dta",clear 
/// Compute Bond Spreads
compute_bond_spread
/// Create Residualized Bond Spread 
create_residualized_spread
/// Create Yields for Volatility Calculations
create_yields_depvar_weight

/// Label Results
gen depvar = "Spread Residualized Weighted"
tempfile spread_residualized_weighted
save `spread_residualized_weighted', replace 


********************************************************************************

********************************************************************************
/// Robustness Check: Groups by Credit Rating, allowing states to change 
********************************************************************************

use "${tem}/statebondsfull_secondary.dta",clear 
/// Create Yields for Dependent Variable - Credit Rating 
create_yields_depvar_rating

tempfile credit_rating_varying
gen depvar = "Nominal Yield - Credit Rating Varying"
save `credit_rating_varying', replace 
save "${tem}/secondary_rating.dta", replace  
********************************************************************************


********************************************************************************
/// Append All Results 
********************************************************************************
use `nominal_yield_baseline', clear 
append using `nominal_yield_weighted'
append using `nominal_yield_residualized'
append using `spread_yield'
append using `spread_residualized'
append using `spread_residualized_weighted'
append using `credit_rating_varying'
save "${tem}/secondary_rating_fixedcr.dta",replace 
********************************************************************************


*********************************************************************************
/// Data for Robustness Checks on Heterogeneity of Federal Support 
use "${tem}/statebondsfull_secondary.dta",clear 
create_yields_depvar_crf
save "${tem}/secondary_rating_crf.dta",replace 
*********************************************************************************

exit 
