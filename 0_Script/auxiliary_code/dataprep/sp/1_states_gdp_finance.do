
/// Import US GDP data 
import delimited "${raw}\stateusgdpprev.csv", varnames(1) clear 
rename geoname state 
local j = 1990
forvalues i=2(1)9{
rename v`i' gdp`j'
local j = `j' + 1
}
reshape long gdp, i(state) j(year)
tempfile stategdp 
drop if year == 1997 
save `stategdp'

import delimited "${raw}\stateusgdp.csv", varnames(1) clear 
rename geoname state 
local j = 1997
forvalues i=2(1)26{
rename v`i' gdp`j'
local j = `j' + 1
}
reshape long gdp, i(state) j(year)
append using `stategdp'
sort state year 
gen state_name = upper(state)
drop state
bysort state_name: gen gdpgr = gdp[_n]/gdp[_n-1] - 1 
save "${tem}\states_us_gdp.dta", replace 
********************************************************************************
/// Import US States Fiscal Data 
import delimited "${raw}\StateData.csv", varnames(1) clear 
merge m:1 year4 using "${tem}\InflationData19.dta", keep(match master) nogen
drop if year4 < 1990
do "${cod}\code_dataprep\1_1_CensusVariables.do"
rename (fips_code_state year4) (state_fips year)
statastates, fips(state_fips) nogen 
merge 1:1 state_name year using "${tem}\states_us_gdp.dta", keep(match master) nogen

/// Create Predictor Variables
preserve 
tempfile predictors  
gen deficit = (total_revenue - total_expenditure)/total_revenue
gen revgdp = total_revenue/(gdp*1000)
gen expgdp = total_expenditure/(gdp*1000)
gen lnpop = ln(population)
order state_name year 
sort state_name year
global predictors currexp deficit revgdp expgdp gdpgr lnpop
keep $predictors year state_name 
save `predictors'
restore 

/// Merge Predictors 
merge m:1 state_name year using `predictors', keep(match master) nogen 

keep state_name year $predictors taxes igrev chgmisc directexp igexp currexp capout 
rename state_name state 
save "${tem}\states_us_data.dta", replace 
*********************************************************************************

