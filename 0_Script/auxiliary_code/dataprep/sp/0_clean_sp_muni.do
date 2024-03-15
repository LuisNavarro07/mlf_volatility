/// Read the variables 
forvalues i=1(1)10{
qui import excel "${raw}\sp_muni_raw.xlsx", sheet("Sheet`i'") firstrow clear case(lower)
tempfile muni`i'
qui save `muni`i''
}

use `muni1', clear
drop if _n >= 1

forvalues i=1(1)10{
    append using `muni`i''
}


/// Manual Corrections 
local r1 af mass_index 
local r2 ak mass_index 
local r3 bd mass_index 
local r4 av nc_gen
local r5 ba nc_gen
local r6 bt nc_gen
local r7 bq nc_index
local r8 bf ri_index
local r9 bk ri_index

global shape af ak bd av ba bt bq bf bk 
local varlist $shape
local i = 1
foreach var of local varlist {
    preserve 
	qui drop if spmunicipalbondalabamagener == .
	keep `var' dates
	rename `r`i''
	tempfile `var'
	save `var', replace 
	restore 
	local i = `i' + 1
}


/// Append Corrected variables 
preserve 
use af, clear
drop mass_index 
foreach var of local varlist {
merge 1:1 dates using `var', keep(match master) nogen
}
tempfile corrections 
save `corrections', replace 
restore
/// Drop missings 
drop if spmunicipalbondalabamagener == .
/// Drop Incorrect Variables
drop $shape 



merge 1:1 dates using `corrections', keep(match master) nogen

rename spmunicipalbond* *

/// Until I know how to solve the merge, I will exclude them 
drop nc_gen nc_index mass_index ri_index

**********************************************************************************
/// General Obligation 
global goindex alabamagener coloradogene generaloblig californiage georgiagener connecticutg floridagener illinoisgene delawaregene mainegeneral louisianagen marylandgene indianagener massachusetts michigangene minnesotagen missourigene nebraskagene nevadagenera newjerseyge newmexicoge ohiogeneral oklahomagene oregongenera pennsylvania rhodeisland southcarolin tennesseegen texasgeneral utahgeneral virginiagene washingtonge wisconsingen 


keep dates $goindex 

local varlist $goindex
local i = 1 
foreach var of local varlist {
    local name`i' = "`var'"
	rename `var' v`i'
	local i = `i' + 1
}

reshape long v, i(dates) j(id)
gen name = ""

forvalues i=1(1)34{
replace name = "`name`i''" if id == `i'
}

split name, parse("gen")
replace name1 = "rhode island" if name == "rhodeisland"
replace name1 = "go index" if name == "generaloblig"
replace name1 = "california" if name == "californiage"
replace name1 = "connecticut" if name == "connecticutg"
replace name1 = "new jersey" if name == "newjerseyge"
replace name1 = "new mexico" if name == "newmexicoge"
replace name1 = "south carolina" if name == "southcarolin"
replace name1 = "washington" if name == "washingtonge"
drop name name2 
/// drop goindex
drop if name1 == "go index"
rename name1 state 
statastates, name(state) nogen



sort state dates 
rename dates date 
rename v spgoindex
/// Create Variance Measure 
gen wofd = wofd(date)
gen volatility = spgoindex
/// Volatility is calculated via collapse - sd
gcollapse (sd) volatility (mean) date , by(wofd state)
gen mofd = mofd(date)
/// Monthly observations are the average of the weekly sd 
gcollapse (mean) volatility date, by(mofd state)
gen year = year(date)
drop date
format mofd %tmMon_CCYY
save "${tem}\spgoindex.dta", replace 
********************************************************************************