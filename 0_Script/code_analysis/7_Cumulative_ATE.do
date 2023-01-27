********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Robustness Checks: Cumulative Average Treatment Effect 
*** This Update: January 2023
********************************************************************************
********************************************************************************

///Crosswalks for months 
use "${cln}\synth_clean.dta", clear 
replace month_exp = month_exp - ${treat_period}
drop if treat == 0 
keep month_exp mofd
duplicates drop mofd, force 
tempfile dates
save `dates', replace 

/// Treatment Effect by Period 
qui use "${tem}\synth_treated.dta", clear
/// Estimate the Average Treatment Effect for the specific window 
egen group = group(id fileid)
qui drop ate

forvalues i=1(1)$treat_period {
bysort group: egen ate`i' = mean(tr_eff) if month_exp >=0 & month_exp <= `i'
}
qui gcollapse (mean) ate*, by(id)
reshape long ate, i(id) j(month_exp)

merge m:1 month_exp using `dates', keep(match master) nogen

label define id 1 "A" 2 "AA" 3 "AAA" 4 "BBB"
label values id id 

twoway  (connected ate month_exp if id == 1, lpattern(solid) lwidth(thin) msize(vsmall) msymbol(circle) mcolor(black) lcolor(black)) ///
		(connected ate month_exp if id == 2, lpattern(solid) lwidth(thin) msize(vsmall) msymbol(triangle) mcolor(blue) lcolor(blue)) ///
		(connected ate month_exp if id == 3, lpattern(dash) lwidth(thin)  msize(vsmall) msymbol(circle) mcolor(cranberry) lcolor(cranberry)) ///
		(connected ate month_exp if id == 4, lpattern(dash) lwidth(thin)  msize(vsmall) msymbol(triangle) mcolor(green) lcolor(green)), ///
		xlabel(#16, labsize(small) angle(0)) ylabel(#10, labsize(small) angle(0)) title(" ", size(medsmall) pos(11)) name(cumulativeate, replace) yline(0, lpattern(dash) lcolor(gray)) legend(on order(1 "A" 2 "AA" 3 "AAA" 4 "BBB") rows(1)) ytitle("") xtitle("Months After MLF Implementation", size(small))
graph export "${oup}\Figure4_CumulativeATE.pdf", replace 
