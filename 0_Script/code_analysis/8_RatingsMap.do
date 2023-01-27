*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Felipe Lozano  
/// Update: January 2023 (Luis Navarro) 
/// Script: Credit Ratings Map
*************************************************************************
*************************************************************************

use "${tem}\state_ratings.dta",clear 
tostring state_fips, gen(STATEFP)
replace STATEFP = "0" + STATEFP if length(STATEFP) == 1
tempfile ratingsmap
save `ratingsmap', replace 

use  "${raw}/Map/geo2xy_us_data.dta", clear
drop if NAME=="Puerto Rico"
merge 1:1 STATEFP using `ratingsmap', keep(match master) nogen

/// Assumption: If the state did not appear in our sample of rated states it is because it did not issued debt. 
/// In this case, it is equivalent of not being rated. So we group it with the unrated ones, that are not used for the analysis. 
replace rating_agg = 4 if rating_agg == . 

/// Plot the map 
spmap rating_agg  using "${raw}/Map/xy_coor.dta", id(_ID)  name(map_ratings, replace) clm(unique) ///
	fcolor("0 158 155" "86 180 233" "255 193 7" "216 27 96" "255 255 255") ocolor(black black black black)  ///
	label(data("${raw}/Map/St_lab_NoPR.dta") xcoord(x_lab) ycoord(y_lab) label(stlab) ///
	by(lgroup) size(*.5) pos(0 6)) leg(pos(12) rows(1)) 
	
	
graph export "${oup}/CreditRatingGRoupingRC.pdf", replace

	

