/// Prepare Everything for the Synth 
/// Save The File for Regressions 
use "$cln/financial_market_volatility.dta", clear
*** Making sure the data are balanced on the outcomes
drop if wofd<=`=tw(2019,12)'
drop if wofd==`=tw(2021,1)' 
/*capture // we identified sec_id 3 (AA) & 4 (A) with missing values. 
	drop if sd==.
	bysort sec_id: gen cnt=_N
	tab cnt
restore*/
/// Donors recieve a sec_id > 1000 
tsset sec_id wofd
replace sec_id = 		sec_id-1 if sec_id<=6 
replace sec_id = 1000 +	sec_id-5 if sec_id>6  

/// Assumptions -- 
/// Drop stock indices 
drop if sec_id >= 1058 & sec_id <= 1061
drop if sec_id > 1106
/// Drop Venezuela 
drop if sec_id ==1012
drop if sec_id ==1053
/// Drop Oil 
drop if sec_id ==1029 | sec_id == 1033 | sec_id == 1035
drop if sec_id ==1025 | sec_id == 1026 |sec_id == 1063 

/// Reshape the data into a long format. Each row is a security-vol measure
rename (sd range)(v1 v2)
keep sec_id wofd v*
greshape long v, i(sec_id wofd) j(sertype)	
sort sec_id sertype wofd
/// Create Unique Ids. 
gegen id = group(sec_id sertype)
gen status = sec_id<1000
order id status sec_id sertype 

/// Store the Varnames 
preserve 
replace varlab = varlab + " (SD)" if sertype == 1 
replace varlab = varlab + " (Range)" if sertype == 2 
keep id varlab
duplicates drop id, force 
encode varlab, gen(des)
save "${tem}\varnames.dta", replace 
restore 

/// Assumption: Turn everything into monthly data 
gen td = dofw(wofd)
gen mofd = mofd(td)
format mofd %tmMon_CCYY
drop wofd td 
/// Collapse to Month  
gcollapse (mean) v , by(mofd id status sertype sec_id varlab)
/// Rename the variable month as week to make the code works 
/// DO NOT GET CONFUSED 
rename mofd wofd

save "${tem}\TheFile.dta", replace 