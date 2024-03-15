********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Prepare Data for Synthetic Control 
*** This Update: January 2024
********************************************************************************
********************************************************************************

/// Merge the Data
use "${tem}/secondary_rating.dta", clear  
keep date yield*
*label variable yieldnr "Not Rated"
label variable yield3a "AAA Bonds"
label variable yield2a "AA Bonds"
label variable yielda "A Bonds"
label variable yield3b "BBB Bonds"

********************************************************************************
/// To use the synth package the data needs to be in a panel structure where each unit is a financial instrument. Oh boy, we need to reshape this stuff carefully. 
/// First, lets rename the securities 

/// Rename variables to do the reshape 
local varlist yield3a yield2a yielda yield3b
local i = 1
foreach var of local varlist {
	global name`i' =  "`var'"
	rename `var' var`i'
	local i = `i' + 1
}

/// Reshape Long 
reshape long var, i(date) j(sec_id)
rename var volatility 
tsset sec_id date
/// Drop Not Rated Issuers  
*drop if sec_id == 2
sort sec_id date

/// Names and Varlabs
gen name = ""
replace name = "AAA" if sec_id == 1
replace name = "AA" if sec_id == 2
replace name = "A" if sec_id == 3
replace name = "BBB" if sec_id == 4 
gen varlab = "State Bonds - " + name 
gen data = "Outcome"
********************************************************************************
/// Add Yield as an outcome. This is to do the graphs 
clonevar yield = volatility
********************************************************************************
/// Append the Donors 
append using "${tem}/bloombergprices_clean.dta"
replace data = "Donor Prices" if data == ""
append using  "${tem}/spgoindex.dta"
replace data = "SP Munis" if data == ""

********************************************************************************
/// Compute the Standard Deviation of Weekly Prices 
gen wofd= wofd(date + 1)
/// Collapse at the weekly levels - This gets the weekly volatility measure  
gcollapse (mean) date yield (sd) volatility, by(wofd name varlab data)
//// Collapse by Month: Average of the 4 weeks at each month 
gen mofd = mofd(date)
gcollapse (mean) volatility yield date, by(mofd varlab name data) 
format mofd %tmMon_CCYY
gen year = year(date)
gen treat = 0 
replace treat = 1 if data == "Outcome"
tempfile data
save `data', replace 
********************************************************************************
/// Exclude Data From SP Muni Index on the Treatment Period 
drop if data == "SP Munis" & year >= 2019 
gsort -treat name mofd 
********************************************************************************
/// Manual Replacement of the first unit of volatility for BBB January 2019 
sum volatility if name == "BBB" & mofd == tm(2019m2)
replace volatility = r(mean) if name == "BBB" & mofd == tm(2019m1) 
mdesc volatility
********************************************************************************
/// Now I need to express everything in Experiment Time 
/// This variable refers to the experiment cohort 
gen year_exp = . 
/// Variables to determine experiment-months. 36 periods. Treatment Happens in April of t+1, so it is the 16th period 
gen month = month(dofm(mofd))
gen month_exp = month 
/// Two Steps: First Save the Treated Cohort 
replace year_exp = 1 if mofd >= tm(2019m1) & mofd <= tm(2021m12)
/// Store only the treated cohort (including donors from it)
preserve 
drop if data == "SP Munis"
replace month_exp = month + 12 if year == 2020 
replace month_exp = month + 24 if year == 2021 
tempfile treated 
save `treated' , replace 
restore 

/// Second: Now I need to reshape the dataset so each cohort
keep if data == "SP Munis"

/// List of Cohorts: 
local cohort5 mofd >= tm(2013m1) & mofd <= tm(2015m12)
local cohort4 mofd >= tm(2014m1) & mofd <= tm(2016m12)
local cohort3 mofd >= tm(2015m1) & mofd <= tm(2017m12)
local cohort2 mofd >= tm(2016m1) & mofd <= tm(2018m12)


/// Keep observations at each cohort 
forvalues i=2(1)5{
preserve 
keep if `cohort`i''
sum year 
local initial = r(min)
replace month_exp = month + 12 if year == (`initial' + 1)
replace month_exp = month + 24 if year == (`initial' + 2)
replace year_exp = `i'
tempfile cohort`i'
save `cohort`i'', replace 
restore 
}

/// Append them 
use `cohort2', clear 
forvalues i=3(1)5{
	append using `cohort`i''
}

/// Save them 
tempfile munis
save `munis', replace 


/// Finally, append them together with the treated untis 
use `treated', clear 
append using `munis'

********************************************************************************
/// Create IDs 
/// First with Treated Units 
egen id = group(name) if data == "Outcome"
/// Second Identify Donors from the SP Data 
egen id_sp = group(name year_exp) if data == "SP Munis"
replace id = id_sp + 2000  if data == "SP Munis"
/// Third Identify Donors from the Bloomberg data 
egen id_bloom = group(name) if data == "Donor Prices"
replace id = id_bloom + 3000 if data == "Donor Prices"
drop id_bloom id_sp
********************************************************************************
/// Homogeneous IDs 
egen id1 = group(id)
drop id 
rename id1 id 
tsset id month_exp
rename volatility v 
save "${cln}/synth_clean.dta", replace 
********************************************************************************
/// Save State Names 
preserve 
keep if treat == 1 
keep id name 
duplicates drop id name, force 
save "${tem}/treated_names.dta", replace
restore 

/// All names 
preserve  
keep id name year_exp
duplicates drop id name, force 
save "${tem}/all_names.dta", replace
restore 
********************************************************************************
/// Compare the Outcomes between MSRB and SP Municipal Bond Indices 
preserve 
use `data', clear 
keep if year >= 2019 
drop if year == 2022 
drop if data == "Donor Prices"
gcollapse (mean) volatility, by(mofd treat data)
drop data
reshape wide volatility, i(mofd) j(treat)
label variable volatility0 "SP Munis"
label variable volatility1 "MSRB"

center volatility0, gen(vol0)
center volatility1, gen(vol1) 

local lineopts lwidth(thin) 
local gropts legend(off order(1 "MSRB" 2 "SP Muni Index") size(small)) ytitle("Volatility", size(small)) xlabel(#36, labsize(small) angle(90)) xtitle("") ylabel(#10, labsize(small) angle(0)) 


twoway (line volatility1 mofd, lcolor(black) lpattern(solid) `lineopts') (line volatility0 mofd, lcolor(cranberry) lpattern(dash) `lineopts'), title("Comparison of Volatility Measures", size(small) pos(11)) name(outcomes_normal, replace) `gropts'
twoway (line vol1 mofd, lcolor(black) lpattern(solid) `lineopts') (line vol0 mofd, lcolor(cranberry) lpattern(dash) `lineopts'), title("Comparison of Volatility Measures - Standardized Variables", size(small) pos(11)) name(outcomes_center, replace) `gropts'


local note1 "{bf:Note:}Both panels compare the volatility measures obtained from MSRB data, and the Standard and Poors Municipal Bond Indices. {br}Panel on the left shows the raw volatility computations (i.e. monthly average of intra-weekly standard deviation of nominal bond yields). {br}Panel on the right shows the standardized variables. Each variable is standardized using their own mean and standard deviation."


grc1leg outcomes_normal outcomes_center, name(outcomes_comp, replace) rows(1) xsize(10) ysize(5) 
graph display outcomes_comp, ysize(50) xsize(85) scale(.9)
graph export "${oup}/OutcomeComparisonMRSB_SPMuni.pdf", replace 
restore 

exit 
