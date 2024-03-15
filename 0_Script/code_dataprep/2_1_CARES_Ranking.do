********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: CARES Act Distribution Categorization 
*** This Update: January 2023 
********************************************************************************
********************************************************************************
import excel "${raw}/FFIS_COVID_19_State_by_State_Allocations.20.xlsx", sheet("clean_allocations") firstrow clear 

statastates, name(State)
drop if state_fips == . 


/// Create Allocation Variables 
rename (State CoronavirusReliefFund TOTAL) (state crf total)
keep state crf total state_abbrev

destring crf total, replace 
format crf total %12.0fc
drop if state_abbrev == "DC"
gen crf_rule = "Fixed Allocation" if crf <= 1250000
replace crf_rule = "Variable Allocation" if crf > 1250000

cumul crf, gen(crf_ecfd)
cumul total, gen(total_ecdf)

sort total_ecdf
gen fedsupport_categories = ""
replace fedsupport_categories = "p0-p25" if total_ecdf <= 0.25
replace fedsupport_categories = "p25-p50" if total_ecdf > 0.25 & total_ecdf <= 0.50
replace fedsupport_categories = "p50-p75" if total_ecdf > 0.50 & total_ecdf <= 0.75
replace fedsupport_categories = "p75-p100" if total_ecdf > 0.75

drop crf total crf_ecfd total_ecdf state
rename state_abbrev StateCode
sort StateCode
save "${tem}\cares_rankings.dta",replace 

