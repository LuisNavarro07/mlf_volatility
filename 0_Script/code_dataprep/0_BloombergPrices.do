********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Clean Bloomberg Prices 
*** This Update: September 2022 
********************************************************************************
********************************************************************************
clear all 
/// Bloomberg Prices 
forvalues i=1(1)17{
qui import excel "${raw}/BloombergPrices.xlsx", firstrow sheet("Sheet`i'") clear case(lower)
tempfile price`i'
qui save `price`i'', replace 
}

use `price2', clear
qui merge 1:1 date using `price1', keep(match master) nogen
forvalues i=3(1)17{
qui merge 1:1 date using `price`i'', keep(match master) nogen
}

drop c1comdty wacomdty o1comdty s1comdty
qui destring _all, replace 
gen yr = year(date)
drop if yr == 2018 

// Drop all variables that we don't have at least 95% of total observationbs
global all ctpen10ygovt ctcad10ygovt ctskk10ygovt ctkrw10ygovt ctdop10ygovt ctjmd10ygovt ctitl10ygovt ctngn10ygovt ctfim10ygovt ctpte10ygovt ctmxn10ygovt ctcop10ygovt ctchf10ygovt ctclp10ygovt ctcny10ygovt ctrub10ygovt spxindex ftsemibindex nkyindex induindex mexbolindex ctthb10ygovt egpt10yindex ctsgd10ygovt ctdkk10ygovt ctsek10ygovt ctaud10ygovt ctats10ygovt cthkd10ygovt clacomdty coacomdty sbacomdty coalinequity xb1comdty ng1comdty gc1comdty si1comdty hg1comdty xptusdcurrncy cc1comdty lc1comdty ho1comdty qs1comdty jx1comdty rr1comdty sm1comdty bo1comdty rs1comdty kc1comdty jo1comdty lb1comdty or1comdty dl1comdty fc1comdty lh1comdty ctfrf9ygovt ctesp9ygovt ctsar10ygovt ctdem9ygovt ctinr9ygovt ctbef9ygovt ctgrd20ygovt ctiep3ygovt ctnok3ygovt ctuah3ygovt ctrub3ygovt ctats3ygovt ctczk3ygovt ctdkk3ygovt ctdkk5ygovt ctskk5ygovt ctbef3ygovt ctdemii5y ctinr2ygovt ctsar2ygovt ctcny3ygovt cthkd5ygovt ctbrl5ygovt ctbrlii30tgovt ctbrl3ygovt ctnzd5ygovt ctpln2ygovt ctngn2ygovt ctjpyii5ygovt cteurhr9ygvot cteurlt2ygvot ctzar10ygovt ctgbpii5ygovt ctgbp10ygovt ctmry5ygovt ctgtq20ygovt ctlvl2ygovt cteurro6ygovt ctyhb2ygovt ctphp2ygovt daxindex cacindex aexindex ibexindex omxindex smiindex bsxindex igpaindex buxindex rtsiindex saxindex egx30index kse100index nse200index hisindex kospiindex sensexindex shsz300index as51index atxindex aseindex bel20index omxc25index hexindex icexiindex croxindex ctxeurindex rotxlindex utxeurindex tpxindex

local varlist ${all}
foreach var of local varlist {
	quietly mdesc `var' 
	if r(percent) > 5 {
		drop `var'
	}
}

global vars ctjmd10ygovt ctmxn10ygovt ctchf10ygovt ctclp10ygovt spxindex ftsemibindex induindex mexbolindex ctsek10ygovt clacomdty coacomdty coalinequity xb1comdty ng1comdty gc1comdty si1comdty hg1comdty xptusdcurrncy cc1comdty lc1comdty ho1comdty qs1comdty rr1comdty sm1comdty bo1comdty rs1comdty kc1comdty jo1comdty lb1comdty or1comdty dl1comdty fc1comdty lh1comdty ctfrf9ygovt ctgrd20ygovt ctiep3ygovt ctnok3ygovt ctczk3ygovt ctdkk3ygovt ctdkk5ygovt ctbef3ygovt ctdemii5y ctbrl5ygovt ctbrlii30tgovt ctbrl3ygovt ctnzd5ygovt ctpln2ygovt cteurlt2ygvot ctzar10ygovt ctgbpii5ygovt ctgbp10ygovt ctlvl2ygovt cteurro6ygovt daxindex cacindex aexindex ibexindex omxindex smiindex bsxindex igpaindex buxindex rtsiindex saxindex kse100index nse200index hisindex kospiindex sensexindex as51index atxindex aseindex bel20index omxc25index hexindex icexiindex croxindex ctxeurindex rotxlindex utxeurindex


/// Assumption -- Carryforward for missing spaces 
sort date
tsset date
local varlist $vars
foreach var of local varlist {
    qui carryforward `var', replace 
}

mdesc 

*********************************************************************************
/// Build the Outcome 


/// Describe the Variables 
describe $vars
tempfile varnames
descsave $vars, saving(`varnames', replace)

preserve 
use `varnames', clear
keep order name varlab 
gen sec_id = order + 1
drop order 
save `varnames', replace 
restore 


local varlist $vars
local i = 2
foreach var of local varlist {
	global name`i' =  "`var'"
	rename `var' var`i'
	local i = `i' + 1
}

reshape long var, i(date) j(sec_id)
drop yr 
merge m:1 sec_id using `varnames', keep(match master) nogen 
rename var volatility 
* Drop SP500
drop if name == "spxindex"
********************************************************************************
/// Add Yield as an outcome. This is to do the graphs 
clonevar yield = volatility
********************************************************************************
save "${tem}/bloombergprices_clean.dta", replace 

exit 

*********************************************************************************
/*
/// Create Variance Measure 
gen wofd = wofd(date)
gen volatility = var
/// Volatility is calculated via collapse - sd
gcollapse (sd) volatility (mean) date , by(wofd sec_id)
gen mofd = mofd(date)
/// Monthly observations are the average of the weekly sd 
gcollapse (mean) volatility date, by(mofd sec_id)
gen year = year(date)
format mofd %tmMon_CCYY
merge m:1 sec_id using `varnames', keep(match master) nogen 
/// to differentiate between treated units and controls 
replace sec_id = sec_id + 1000
gen treat = 0 
save "${tem}\bloombergprices_clean.dta", replace 
*/

*********************************************************************************
preserve 
import excel "${raw}/BloombergPrices.xlsx", firstrow sheet("Des") clear case(lower)
replace name = lower(subinstr(name, " ", "", .))
duplicates drop name, force 
save "${tem}/bloombergnames.dta", replace 
restore 

/// Excel Formula ="label variable "&A4&" """&B4&""""
capture label variable bo1comdty "Soybean Oil-Commodity"
capture label variable c1comdty "Corn-Commodity"
capture label variable cc1comdty "Cocoa -Commodity"
capture label variable clacomdty "WTI-Commodity"
capture label variable coacomdty "Brent-Commodity"
capture label variable coalinequity "Coal-Commodity"
capture label variable ctats10ygovt "Austria Sovereign Bonds-Sovereign Bond 10 YR"
capture label variable ctats3ygovt "Austria-Sovereign Bond 3 YR"
capture label variable ctbef3ygovt "Belgium-Sovereign Bond 3 YR"
capture label variable ctbef9ygovt "Belgium-Sovereign Bond 9 YR"
capture label variable ctbrl3ygovt "Brazil-Sovereign Bond 3 YR"
capture label variable ctbrl5ygovt "Brazil-Sovereign Bond 5 YR"
capture label variable ctbrlii30tgovt "Brazil-Sovereign Bond 30 YR"
capture label variable ctcad10ygovt "Canada-Sovereign Bond 10 YR"
capture label variable ctchf10ygovt "Switzerland-Sovereign Bond 10 YR"
capture label variable ctclp10ygovt "Chile-Sovereign Bond 10 YR"
capture label variable ctcny10ygovt "China-Sovereign Bond 10 YR"
capture label variable ctcny3ygovt "China-Sovereign Bond 3 YR"
capture label variable ctcop10ygovt "Colombia-Sovereign Bond 10 YR"
capture label variable ctczk3ygovt "Czesch-Sovereign Bond 3 YR"
capture label variable ctdem9ygovt "Germany-Sovereign Bond 9 YR"
capture label variable ctdemii5y "Germany-Sovereign Bond  YR"
capture label variable ctdkk3ygovt "Denmark-Sovereign Bond 3 YR"
capture label variable ctdkk5ygovt "Denmark-Sovereign Bond 5 YR"
capture label variable ctdop10ygovt "Dominican Republic-Sovereign Bond 10 YR"
capture label variable ctesp9ygovt "Spain-Sovereign Bond 9 YR"
capture label variable cteurhr9ygvot "Croatia-Sovereign Bond 9 YR"
capture label variable cteurlt2ygvot "Lithuiania-Sovereign Bond 2 YR"
capture label variable cteurro6ygovt "Romania-Sovereign Bond 6 YR"
capture label variable ctfim10ygovt "Finland-Sovereign Bond 10 YR"
capture label variable ctfrf9ygovt "France-Sovereign Bond 9 YR"
capture label variable ctgbp10ygovt "England-Sovereign Bond 10 YR"
capture label variable ctgbpii5ygovt "England-Sovereign Bond 5 YR"
capture label variable ctgrd20ygovt "Greece-Sovereign Bond 20 YR"
capture label variable ctgtq20ygovt "Guatemala-Sovereign Bond 20 YR"
capture label variable cthkd5ygovt "Hong Kong-Sovereign Bond 5 YR"
capture label variable ctiep3ygovt "Ireland-Sovereign Bond 3 YR"
capture label variable ctinr2ygovt "India-Sovereign Bond 2 YR"
capture label variable ctinr9ygovt "India-Sovereign Bond 9 YR"
capture label variable ctitl10ygovt "Italy-Sovereign Bond 10 YR"
capture label variable ctjmd10ygovt "Jamaica-Sovereign Bond 10 YR"
capture label variable ctjpyii5ygovt "Japan-Sovereign Bond 5 YR"
capture label variable ctkrw10ygovt "South Korea-Sovereign Bond 10 YR"
capture label variable ctlvl2ygovt "Latvia-Sovereign Bond 2 YR"
capture label variable ctmry5ygovt "Malasyia-Sovereign Bond 5 YR"
capture label variable ctmxn10ygovt "Mexico-Sovereign Bond 10 YR"
capture label variable ctngn10ygovt "Nigeria-Sovereign Bond 10 YR"
capture label variable ctngn2ygovt "Nigeria-Sovereign Bond 2 YR"
capture label variable ctnok3ygovt "Norway-Sovereign Bond 3 YR"
capture label variable ctnzd5ygovt "New Zealand-Sovereign Bond 5 YR"
capture label variable ctpen10ygovt "Peru-Sovereign Bond 10 YR"
capture label variable ctphp2ygovt "Phillipines-Sovereign Bond 2 YR"
capture label variable ctpln2ygovt "Poland-Sovereign Bond 2 YR"
capture label variable ctpte10ygovt "Portugal-Sovereign Bond 10 YR"
capture label variable ctrub10ygovt "Russia-Sovereign Bond 10 YR"
capture label variable ctrub3ygovt "Russia-Sovereign Bond 3 YR"
capture label variable ctsar10ygovt "Saudi Arabia-Sovereign Bond 10 YR"
capture label variable ctsar2ygovt "Saudi Arabia-Sovereign Bond 2 YR"
capture label variable ctskk10ygovt "Slovakia-Sovereign Bond 10 YR"
capture label variable ctskk5ygovt "Slovakia-Sovereign Bond 5 YR"
capture label variable ctuah3ygovt "Ukraine-Sovereign Bond 3 YR"
capture label variable ctyhb2ygovt "Thailand-Sovereign Bond 2 YR"
capture label variable ctzar10ygovt "South Africa-Sovereign Bond 10 YR"
capture label variable dl1comdty "Ethanol-Commodity"
capture label variable fc1comdty "Feeder Cattle-Commodity"
capture label variable ftsemibindex "FTSE-Stock Exchange"
capture label variable gc1comdty "Gold-Commodity"
capture label variable hg1comdty "Copper-Commodity"
capture label variable ho1comdty "Heating Oil-Commodity"
capture label variable induindex "Indu-Stock Exchange"
capture label variable jo1comdty "Orange Juice-Commodity"
capture label variable jx1comdty "Kerosene-Commodity"
capture label variable kc1comdty "Coffee-Commodity"
capture label variable lb1comdty "Lumber-Commodity"
capture label variable lc1comdty "Live Cattle-Commodity"
capture label variable lh1comdty "Lean Hogs-Commodity"
capture label variable mexbolindex "Mex StockEx-Stock Exchange"
capture label variable ng1comdty "Natural Gas-Commodity"
capture label variable nkyindex "Nikkei-Stock Exchange"
capture label variable o1comdty "Oats-Commodity"
capture label variable or1comdty "Rubber-Commodity"
capture label variable qs1comdty "Gasoil-Commodity"
capture label variable rr1comdty "Rough Rice-Commodity"
capture label variable rs1comdty "Canola-Commodity"
capture label variable s1comdty "Soybean-Commodity"
capture label variable sbacomdty "SBA-Commodity"
capture label variable si1comdty "Silver-Commodity"
capture label variable sm1comdty "Soybean Meal-Commodity"
capture label variable spxindex "SP500-Stock Exchange"
capture label variable wacomdty "WA-Commodity"
capture label variable xb1comdty "Gasoline-Commodity"
capture label variable xptusdcurrncy "Platinum-Commodity"
capture label variable daxindex "Germany Stock Index"
capture label variable cacindex "France Stock Index"
capture label variable aexindex "Netherlands Stock Index"
capture label variable ibexindex "Spain Stock Index"
capture label variable omxindex "Sweden Stock Index"
capture label variable smiindex "Switzerland Stock Index"
capture label variable bsxindex "Bermuda Stock Index"
capture label variable igpaindex "Chile Stock Index"
capture label variable buxindex "Hungary Stock Index"
capture label variable rtsiindex "Russia Stock Index"
capture label variable saxindex "Slovakia Stock Index"
capture label variable egx30index "Egypt Stock Index"
capture label variable kse100index "Pakistan Stock Index"
capture label variable nse200index "Kenya Stock Index"
capture label variable hisindex "Hong Kong Stock Index"
capture label variable kospiindex "South Korea Stock Index"
capture label variable sensexindex "India Stock Index"
capture label variable shsz300index "Shanghai Stock Index"
capture label variable as51index "Australia Stock Index"
capture label variable atxindex "Austria Stock Index"
capture label variable aseindex "Greece Stock Index"
capture label variable bel20index "Belgium Stock Index"
capture label variable omxc25index "Denmark Stock Index"
capture label variable hexindex "Finland Stock Index"
capture label variable icexiindex "Iceland Stock Index"
capture label variable croxindex "Croatia Stock Index"
capture label variable ctxeurindex "Czesch Stock Index"
capture label variable rotxlindex "Romania Stock Index"
capture label variable utxeurindex "Ukraine Stock Index"
capture label variable tpxindex "Japan Stock Index"

exit 




