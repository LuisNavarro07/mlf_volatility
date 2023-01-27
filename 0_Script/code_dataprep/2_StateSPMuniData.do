********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Clean S&P Municipal Bond Indices 
*** This Update: September 2022 
********************************************************************************
********************************************************************************
/// Read the variables 
forvalues i=1(1)10{
qui import excel "${raw}\sp_muni_raw.xlsx", sheet("Sheet`i'") firstrow clear case(lower)
tempfile muni`i'
qui save `muni`i''
}

use `muni1', clear
drop if _n >= 1

forvalues i=1(1)10{
    qui append using `muni`i''
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
	qui keep `var' dates
	qui rename `r`i''
	qui tempfile `var'
	qui save `var', replace 
	restore 
	local i = `i' + 1
}

/// Append Corrected variables 
preserve 
use af, clear
drop mass_index 
foreach var of local varlist {
qui merge 1:1 dates using `var', keep(match master) nogen
}
tempfile corrections 
save `corrections', replace 
restore
/// Drop missings 
qui drop if spmunicipalbondalabamagener == .
/// Drop Incorrect Variables
qui drop $shape 

merge 1:1 dates using `corrections', keep(match master) nogen
rename spmunicipalbond* *

/// Until I know how to solve the merge, I will exclude them 
qui drop nc_gen nc_index mass_index ri_index
**********************************************************************************
/// General Obligation 
global goindex alabamagener coloradogene generaloblig californiage georgiagener connecticutg floridagener illinoisgene delawaregene mainegeneral louisianagen marylandgene indianagener massachusetts michigangene minnesotagen missourigene nebraskagene nevadagenera newjerseyge newmexicoge ohiogeneral oklahomagene oregongenera pennsylvania rhodeisland southcarolin tennesseegen texasgeneral utahgeneral virginiagene washingtonge wisconsingen 

/// Assumption: only use general obligation bond indices 
keep dates $goindex 


local i = 0 
foreach var of varlist _all {
    local name`i' = "`var'"
	qui rename `var' v`i'
	local i = `i' + 1
}
local varno = `i'
rename v0 dates
reshape long v, i(dates) j(id)
qui gen name = ""

forvalues i=1(1)`varno'{
qui replace name = "`name`i''" if id == `i'
}

qui split name, parse("gen")
qui replace name1 = "rhode island" if name == "rhodeisland"
qui replace name1 = "go index" if name == "generaloblig"
qui replace name1 = "california" if name == "californiage"
qui replace name1 = "connecticut" if name == "connecticutg"
qui replace name1 = "new jersey" if name == "newjerseyge"
qui replace name1 = "new mexico" if name == "newmexicoge"
qui replace name1 = "south carolina" if name == "southcarolin"
qui replace name1 = "washington" if name == "washingtonge"
qui drop name name2 
/// drop goindex
qui drop if name1 == "go index"
qui rename name1 state 
qui statastates, name(state) nogen
qui rename v volatility 
qui rename state name 
qui egen sec_id = group(name)
qui drop state* id
qui rename dates date 
qui save "${tem}\spgoindex.dta", replace 
exit 
