********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: CARES Act Distribution Categorization 
*** This Update: January 2023 
********************************************************************************
********************************************************************************
/// Population Estimates
import delimited "${raw}/nst-est2019-alldata.csv", clear varnames(1)
drop if state == 0 
statastates, name(name)
drop if state_fips == .
keep state_fips popestimate2019
tempfile population
save `population', replace 

/// CRF Allocations 
import excel "${raw}/crf_allocations.xlsx", sheet("Sheet1") firstrow clear 
statastates, name(state)
drop if state_fips == .
merge 1:1 state_fips using `population', keep(match master) nogen
replace crf_allocation = 495138063.60 if state == "DISTRICT OF COLUMBIA"
gen crf_allocation_percapita = crf_allocation/popestimate2019
keep state_fips state crf_allocation* popestimate2019 
gen crf_rule = "Fixed Allocation" if crf_allocation <= 1250000000
replace crf_rule = "Variable Allocation" if crf_allocation > 1250000000
tempfile crf_allocation
save `crf_allocation', replace 

/// Total Allocations 
import excel "${raw}/FFIS_COVID_19_State_by_State_Allocations.20.xlsx", sheet("clean_allocations") firstrow clear 
statastates, name(State)
drop if state_fips == . 

/// Create Allocation Variables 
rename (State CoronavirusReliefFund TOTAL) (state crf total)
keep state total state_abbrev
merge 1:1 state using `crf_allocation', keep(match master) nogen
destring total, replace
replace total = total*1000
/// create some variables 
gen total_percapita = total/popestimate2019
gen crf_percapita = crf_allocation/popestimate2019
gen crf_billions = crf_allocation/1000000000
gen pop_millions = popestimate2019/1000000

//// Rule: Total Funding Provided Per Capita 
cumul total_percapita, gen(total_percapita_ecfd)
sort total_percapita_ecfd

gen fedsupport_categories = ""
replace fedsupport_categories = "p0-p50" if   total_percapita_ecfd <= 0.50
replace fedsupport_categories = "p51-p100" if  total_percapita_ecfd > 0.50 

/// Extra: CRF Rule 
/*
cap drop fedsupport_categories
cumul crf_percapita, gen(crf_percapita_ecfd)
sort crf_percapita_ecfd

gen fedsupport_categories = ""
replace fedsupport_categories = "p0-p50" if   crf_percapita_ecfd <= 0.50
replace fedsupport_categories = "p51-p100" if  crf_percapita_ecfd > 0.50 
*/


save "${tem}/states_funding_distribution.dta",replace 

keep state_abbrev fedsupport_categories
rename state_abbrev StateCode
sort StateCode
save "${tem}/cares_rankings.dta",replace 





