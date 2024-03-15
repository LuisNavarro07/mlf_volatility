/// Graphs 

use "$cln/financial_market_volatility.dta", clear
gcollapse (mean) sec_id, by(varlab)
sort sec_id
drop if sec_id < 7
drop sec_id
texsave * using "${oup}\FinancialVariables.tex", replace 

local varlist ${all_variables}
foreach i of local varlist {
local a : variable label `i'
local a: subinstr local a "U.S. Dollar " "USD "
label var `i' "`a'"

local a : variable label `i'
local a: subinstr local a "Spot Exchange Rate" ""
label var `i' "`a'"

}

use "${tem}\statebondsfull_secondary.dta",clear 
gcollapse (mean) rating_agg, by(StateCode)

replace rating_agg = round(rating_agg)
rename StateCode state
statastates, ab(state)
replace rating_agg = 0 if rating_agg == .
sort rating_agg
drop state 
rename state_fips state
tostring state, replace
sort len state
gen len = length(state)
replace state = "0" + state if len == 1 

maptile rating, geo(state) cutvalues(1 2 3 4) propcolor twopt(legend(on order(1 "AAA" 2 "AA" 3 "A" 4 "BBB" 5 "NR")))
