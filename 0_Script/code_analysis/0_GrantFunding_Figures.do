*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro
/// Update: February 2024 (Luis Navarro) 
/// Script: CARES Act Funding Gigures
*************************************************************************
*************************************************************************

** Read ratings data 
use "${tem}/state_ratings_data.dta",clear 
tostring state_fips, gen(STATEFP)
replace STATEFP = "0" + STATEFP if length(STATEFP) == 1
tempfile ratingsmap
save `ratingsmap', replace 

** Read GDp data 
import delimited "${raw}/stateusgdp.csv", clear varnames(1)
rename geoname state
local j = 1997
forvalues i = 2(1)26{
	rename v`i' v`j'
	local j = `j' + 1
}
reshape long v, i(state) j(year)
rename v gdp 
statastates , name(state) nogen
xtset state_fips year
sort state_fips year
bysort state_fips: gen gdp_gr = 100*((gdp[_n] / gdp[_n-1]) -1)
bysort state_fips: egen gdp_gr_mean = mean(gdp_gr) if year < 2020
bysort state_fips: egen gdp_gr_mean1 = mean(gdp_gr_mean) 
drop gdp_gr_mean 
rename gdp_gr_mean1 gdp_gr_mean
keep if year == 2020
drop year 
tostring state_fips, gen(STATEFP)
gen len = length(STATEFP)
replace STATEFP = "0" + STATEFP if len == 1
drop len 
tempfile gdp 
save `gdp', replace 

** Read Census data 
import delimited "${raw}/StateData.csv", clear varnames(1)
keep if year4 == 2020
keep fips_code_state total_revenue health_total_expend total_expenditure
rename (fips_code_state) (state_fips)
statastates, fips(state_fips) nogen
tostring state_fips, gen(STATEFP)
tostring STATEFP, replace
gen len = length(STATEFP)
replace STATEFP = "0" + STATEFP if len == 1
drop len 
replace total_revenue = total_revenue*1000
replace total_expenditure = total_expenditure*1000

replace health_total_expend = health_total_expend*1000
tempfile revenues
save `revenues', replace

******************************************************************************

import excel "${raw}/Cares Act Distribution to Counties Cities.xlsx", sheet("StateTotalAllocation") clear firstrow case(lower)
drop if state == "Total" | state == ""
keep state category totalallocation paymenttostate
egen total_nation = sum(totalallocation)
egen total_states = sum(paymenttostate)
gen percent_states = 100*total_states/total_nation

replace total_nation = total_nation/1000000000
replace total_states = total_states/1000000000

*******************************************************************************

** Read cares data 
use "${tem}/states_funding_distribution.dta",clear 
sort pop_millions
tostring state_fips, gen(STATEFP)
gen len = length(STATEFP)
replace STATEFP = "0" + STATEFP if len == 1
drop len 
tempfile crf 
save `crf', replace 

/// revenues 
merge 1:1 STATEFP using `revenues', keep(match master) nogen
merge 1:1 STATEFP using `gdp', keep(match master) nogen

gen fedsupport_revenues = 100*total/total_revenue
gen fedsupport_expenditures = 100*total/total_expenditure

gen fedsupport_health = 100*total/health_total_expend
encode fedsupport_categories, gen(fedsupport_categories_g)

ttest fedsupport_revenues, by(fedsupport_categories_g) 

ttest fedsupport_health, by(fedsupport_categories_g) 
ttest gdp_gr, by(fedsupport_categories_g) 


drop if state == "DISTRICT OF COLUMBIA"

/// Do the graphs 
global m1 lcolor(cranberry) lwidth(thin) lpattern(dash) mcolor(cranberry) mlabcolor(cranberry) msymbol(circle) mlabel(state_abbrev) mlabposition(6) mlabsize(vsmall) msize(tiny)
global m2 lcolor(ebblue) lwidth(thin) lpattern(dash) mcolor(ebblue) mlabcolor(ebblue) msymbol(square) mlabel(state_abbrev) mlabposition(3) mlabsize(vsmall) msize(tiny)

/// Scatter 1
twoway (scatter crf_billions pop_millions if fedsupport_categories == "p0-p50", $m1) ///
       (scatter crf_billions pop_millions if fedsupport_categories == "p51-p100", $m2), ///
       legend(label(1 "Below Median") label(2 "Above Median") size(small)) $graph_options xtitle("Population (millions)") ytitle("CRF Allocation (US $ billions)") title("States CRF Allocation by Population") name(sc1, replace)


/// Scatter 2 
twoway (scatter total_percapita pop_millions if fedsupport_categories == "p0-p50", $m1) ///
       (scatter total_percapita pop_millions if fedsupport_categories == "p51-p100", $m2), ///
       legend(label(1 "Below Median") label(2 "Above Median") size(small)) $graph_options xtitle("Population (millions)") ytitle("Grant Funding per capita ($ US)") title("Total Grant Funding for COVID-19 by Population") name(sc2, replace)
	   
grc1leg sc2 sc1, legendfrom(sc1) rows(1) name(sc_comb, replace)
graph display sc_comb, ysize(60) xsize(100) scale(.9)
graph export "${oup}/Scatter_GrantFunding_States.pdf", replace

/// Fiscal Revenues 

/// Scatter 3
twoway (scatter fedsupport_revenues pop_millions if fedsupport_categories == "p0-p50", $m1) ///
	   (qfit fedsupport_revenues pop_millions if fedsupport_categories == "p0-p50", $m1) ///
       (scatter fedsupport_revenues pop_millions if fedsupport_categories == "p51-p100", $m2) ///
	   (qfit fedsupport_revenues pop_millions if fedsupport_categories == "p51-p100", $m2), ///
       legend(label(1 "Below Median") label(3 "Above Median") size(small)) $graph_options xtitle("Population (millions)") ytitle("Grant Funding (% Total Revenues)") title("States CRF Allocation by State Fiscal Revenues") name(sc3, replace)


/// Scatter 4
twoway (scatter gdp_gr pop_millions if fedsupport_categories == "p0-p50", $m1) ///
	   (qfit gdp_gr pop_millions if fedsupport_categories == "p0-p50", $m1) ///
       (scatter gdp_gr pop_millions if fedsupport_categories == "p51-p100", $m2) ///
	    (qfit gdp_gr pop_millions if fedsupport_categories == "p51-p100", $m2), ///
       legend(label(1 "Below Median") label(3 "Above Median") size(small)) $graph_options xtitle("Population (millions)") ytitle("GDP Growth Rate (%)") title("Total Grant Funding for COVID-19 and GDP Growth Rate in 2020") name(sc4, replace)
	   
grc1leg sc3 sc4, legendfrom(sc3) rows(1) name(sc_comb2, replace)
graph display sc_comb2, ysize(60) xsize(100) scale(.9)
graph export "${oup}/Scatter_GrantFundingRevenues_States.pdf", replace 


	   
/// Do the map 
use  "${raw}/Map/geo2xy_us_data.dta", clear
drop if NAME=="Puerto Rico"
merge 1:1 STATEFP using `crf', keep(match master) nogen
merge 1:1 STATEFP using `ratingsmap', keep(match master) nogen
merge 1:1 STATEFP using `revenues', keep(match master) nogen

/// Federal Categories 
gen fed_cat = ""
replace fed_cat = "Below Median" if fedsupport_categories == "p0-p50"
replace fed_cat = "Above Median" if fedsupport_categories == "p51-p100"
/// Distribution Across Ratings 
gen rating = ""
replace rating = "AAA"   if rating_agg == 1
replace rating = "AA"    if rating_agg == 2
replace rating = "A"     if rating_agg == 3
replace rating = "BBB"   if rating_agg == 4
replace rating = "NR"    if rating_agg == 5
/// Rating by Segment 
gen rating_segment = rating + "-" + fed_cat
replace rating_segment = "NR" if rating == "NR"

encode fed_cat, gen(fed_cat_g)
encode crf_rule, gen(crf_rule_g)
encode rating_segment, gen(rating_segment_g)

/// Plot the map: Above Below Median Rule 
spmap crf_rule_g  using "${raw}/Map/xy_coor.dta", id(_ID)  name(map_crf, replace) clm(unique) ///
	ocolor(black black black black black) fcolor(gray%10 ltblue ebblue%30 orange%50 cranberry) ///
	label(data("${raw}/Map/St_lab_NoPR.dta") xcoord(x_lab) ycoord(y_lab) label(stlab) ///
	by(lgroup) size(*.5) pos(0 6)) leg(pos(11) rows(1) ring(1)) title("Distribution of the CRF", pos(11) size(small))
	
graph export "${oup}/Map_CRF_Allocations.pdf", replace



/// Plot the map: CRF Rule 
spmap fed_cat_g  using "${raw}/Map/xy_coor.dta", id(_ID)  name(map_totalgrant, replace) clm(unique) ///
	ocolor(black black black black black) fcolor(gray%10 cranberry%40 ebblue%30 orange%50 ltblue) ///
	label(data("${raw}/Map/St_lab_NoPR.dta") xcoord(x_lab) ycoord(y_lab) label(stlab) ///
	by(lgroup) size(*.5) pos(0 6)) leg(pos(11) rows(1) ring(1)) title("Distribution of the Total Grant Funding Per Capita", pos(11) size(small))
	
graph export "${oup}/Map_FedGrant_Allocations.pdf", replace


graph combine map_crf map_totalgrant, rows(2) name(maps_comb, replace )
graph display maps_comb, ysize(100) xsize(70) scale(.9)

graph export "${oup}/Map_Combined_Allocations.pdf", replace


/// Plot the map: Ratings by 

spmap rating_segment_g  using "${raw}/Map/xy_coor.dta", id(_ID)  name(map_segments, replace) clm(unique) ///
	ocolor(black black black black black black black black black black) /// 
	fcolor(magenta%10 magenta%70 green%20 green%70  ebblue%20 ebblue%70 cranberry%20 cranberry%70) ///
	label(data("${raw}/Map/St_lab_NoPR.dta") xcoord(x_lab) ycoord(y_lab) label(stlab) ///
	by(lgroup) size(*.5) pos(0 6)) leg(pos(11) rows(3) ring(1)) title("Credit Rating Categories by Distribution of Grant Funding per Capita", pos(11) size(small))
	
graph display map_segments, ysize(100) xsize(90) scale(.9)
graph export "${oup}/Map_FedGrant_Segments.pdf", replace



