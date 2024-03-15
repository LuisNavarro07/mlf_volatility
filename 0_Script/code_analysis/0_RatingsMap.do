*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Felipe Lozano  
/// Update: February 2024 (Luis Navarro) 
/// Script: Credit Ratings Map
*************************************************************************
*************************************************************************

use "${tem}/state_ratings_data.dta",clear 
tostring state_fips, gen(STATEFP)
replace STATEFP = "0" + STATEFP if length(STATEFP) == 1
tempfile ratingsmap
save `ratingsmap', replace 

use  "${raw}/Map/geo2xy_us_data.dta", clear
drop if NAME=="Puerto Rico"
merge 1:1 STATEFP using `ratingsmap', keep(match master) nogen

/// Plot the map 
spmap rating_agg  using "${raw}/Map/xy_coor.dta", id(_ID)  name(map_ratings, replace) clm(unique) ///
	ocolor(black black black black black) fcolor(ebblue ebblue%30 orange%50 cranberry white) ///
	label(data("${raw}/Map/St_lab_NoPR.dta") xcoord(x_lab) ycoord(y_lab) label(stlab) ///
	by(lgroup) size(*.5) pos(0 6)) leg(pos(12) rows(1)) 
graph display map_ratings, ysize(60) xsize(100) scale(.9)
graph export "${oup}/map_credit_ratings_groups.pdf", replace

exit 
