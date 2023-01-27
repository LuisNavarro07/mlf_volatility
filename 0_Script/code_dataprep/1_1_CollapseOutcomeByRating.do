********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Outcome Variable Aggregation  
*** This Update: January 2023 
********************************************************************************
********************************************************************************

********************************************************************************
/// Collapse Data to Have Credit Rating by Day Observations 
use "${tem}\statebondsfull_secondary.dta",clear 
/// Code Note: Collapsing by the gloabl rating_agg ensures we are taking the right categories (defined in the master file)
/// Collapse the data by credit rating and day. So we are taking the average across states, fixing the credit rating. 
/// To use spread yield instead of the nominal yield, then substitute spread_yield for YIELD at lines 17 and 20. 
gcollapse (mean) YIELD (sum) PAR_TRADED, by(${rating_agg} TRADE_DATE) 
qui rename ${rating_agg} rating_agg
qui xtset rating_agg TRADE_DATE
qui rename (YIELD TRADE_DATE PAR_TRADED) (yield date par)
qui reshape wide yield par, i(date) j(rating_agg)

global lab0 "3a" 
global lab1 "2a" 
global lab2 "a" 
global lab3 "3b"

forvalues i=0(1)3{
    label variable yield`i' "Yield - ${lab`i'}"
	label variable par`i' "Par Traded - ${lab`i'}"
	qui rename yield`i' yield${lab`i'}
	qui rename par`i' par${lab`i'}
}
save "${tem}\secondary_rating.dta",replace 
*********************************************************************************