/// Merge SP and States 
use "${tem}\spgoindex.dta", clear
merge m:1 state year using "${tem}\states_us_data.dta", keep(match master) nogen
/// drop 2022
drop if year > 2020

// Id in number
encode state, gen(id)
tsset id mofd 
sort id mofd

/// Carryfoward predictors. Assumption: Values of 2020 are the ones we have for 2019. 
local varlist taxes igrev chgmisc directexp igexp currexp capout gdpgr deficit revgdp expgdp lnpop
foreach var of local varlist {
	bysort state: carryforward `var', replace 
}


/// Create the donor groups. Each group has a set of two years. The last donor group is the treated series. 

// Gen Experiment Time
/*
Pre-period (6 months): September to February. Numbers from -6 to -1 
Post-Period (6 months): March to August. Numbers from 0 to 5 
*/

/// Gen Experiment Year: Set of 12 months, centered around March. 
gen year_exp = . 
replace year_exp = 7 if mofd >= tm(2013m9) & mofd < tm(2014m9)
replace year_exp = 6 if mofd >= tm(2014m9) & mofd < tm(2015m9)
replace year_exp = 5 if mofd >= tm(2015m9) & mofd < tm(2016m9)
replace year_exp = 4 if mofd >= tm(2016m9) & mofd < tm(2017m9)
replace year_exp = 3 if mofd >= tm(2017m9) & mofd < tm(2018m9)
replace year_exp = 2 if mofd >= tm(2018m9) & mofd < tm(2019m9)
replace year_exp = 1 if mofd >= tm(2019m9) & mofd < tm(2020m9)
drop if year_exp == . 
tab mofd year_exp

/// Seven Years, where the 7th is the year when the treatment happens. 

/// Generate Experiment Month Variable: March equals to zero. 
gen month = month(dofm(mofd))
gen month_exp = month - 3
replace month_exp = -3 if month == 12 
replace month_exp = -4 if month == 11 
replace month_exp = -5 if month == 10
replace month_exp = -6 if month == 9

/// Generate State by Experiment Year Id. This is the state_id identifier for the synth. States with year_exp = 1 will be the treated units. States with year_exp > 1 are donors. 
egen state_id = group(id year_exp)

/// Gen Treatment Variable 
gen treat = 0
replace treat = 1 if year_exp == 1 

order id state_id treat year month year_exp month_exp
sort year_exp state_id month_exp  

save "${cln}\synth_sp.dta", replace 
