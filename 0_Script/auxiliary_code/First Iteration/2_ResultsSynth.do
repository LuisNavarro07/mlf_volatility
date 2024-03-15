*********************************************************************************
**** This file runs the first synth, of US based munibonds refering a first pool of donor data including: corp, vinde, 
**** as a control.
**** 	Dates of reference for MLF 
****		--> 09Apr2020 (Authorization) w=(2021,15)
****		--> 02Jun2020 (IL Announce)   w=(2020,23)
****		--> 18Dec2020 (IL Withdraw)   w=(2020,51)
**** Author: Luis Navarro & Felipe Lozano
**** Date:   Mar 8, 2022
*********************************************************************************
// Set Work Environment 
* Felipe
cd "G:\.shortcut-targets-by-id\13LAXgK7hsYAOEVzlCPjoUszW6P3HLzpE\MLF_Volatility\"
qui do "ProfileDoFile_Felipe.do"
**Luis
*cd "G:\.shortcut-targets-by-id\13LAXgK7hsYAOEVzlCPjoUszW6P3HLzpE\MLF_Volatility\" 
do "ProfileDoFile_Luis.do"

/// First Descriptive Statistics 
use "$cln/financial_market_volatility.dta", clear
gen var_sd = sd 
gen var_range = range 
gcollapse (mean) yield sd range (sd) var_sd var_range, by(sec_id varlab)


use "${tem}\scm_1.dta", clear

use "${tem}\scm_append.dta", clear
keep fileid _Co_Number _W_Weight
rename (_Co_Number _W_Weight) (id weight)
xtset id fileid
merge m:1 id using  "${tem}\varnames.dta", keep(match master) nogen
gen selected = weight > 0 
tab fileid
/// Report the Weights 
local title_1 "AAA Bonds"
local title_2 "AAA Bonds"
local title_3 "AA Bonds"
local title_4 "AA Bonds "
local title_5 "A Bonds"
local title_6 "A Bonds"
local title_7 "BBB Bonds"
local title_8 "BBB Bonds"

preserve 
keep if selected == 1
forvalues i = 1(1)8{
keep if fileid == `i'
graph hbar (asis) weight, over(varlab, sort(weight) descending) name(weight`i', replace)
}
restore 

preserve 
keep id varlab
duplicates drop id, force 
encode varlab, gen(des)
save "${tem}\varnames.dta"
restore 