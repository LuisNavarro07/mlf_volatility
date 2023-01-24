cd "/home/fal20381/Desktop/SCUL_Trial/"

capture log using "SCUL_Trial.smcl", replace

glo treat_period 16
//// Run the Synth
use "synth_clean.dta", clear 

/// Mean of the Volatility in the Pre-treatment Period. That is, in the months from Septmeber to February 
sort id year_exp month_exp
qui gegen v_pre_mn = mean(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_mn, replace   
/// Standard Deviation of each instrument in the Pre-treatment Period
qui gegen v_pre_sd = sd(v) if month_exp < ${treat_period}, by(id)
bysort id: carryforward 	v_pre_sd, replace
/// Normalized Variables
gen v_norm = (v - v_pre_mn) / v_pre_sd
/// Organize Dataset
sort id year_exp month_exp
order id treat year month year_exp month_exp v v_pre_mn v_pre_sd v_norm 
/// Table of Treated States 
tab id if treat==1, matrow(T)
global tr_units = r(r)
/// Table of Placebo units
tab id if treat==0, matrow(P)
global pc_units = r(r)

/// Look at vars included for SCUL
gen strnm = string(id) + name
labmask id, val(strnm) 

tempfile TheFile
save 	`TheFile'

gen TP = treat==1 & month_exp>=${treat_period}
order id month_exp TP

keep if id == 4 | id > 4 
keep id month_exp TP v


xtset id month_exp
*set trace on 
scul v, treat(TP) 


stop 
*/

******************************************************************
******************************************************************
* 1- Create a SCUL implementable DS and save it in temporary folder
******************************************************************
********************** Treated IDs
loc i=3
*forvalues i=1/$tr_units{
	use `TheFile', clear
	
	keep if id==`i' | treat==0
	isid id month_exp
	keep id month_exp v_norm
	
	greshape wide v_norm, i(month_exp) j(id)
	
	rename v_norm`i' Y0

	tsset month_exp
	
	forvalues lg=1/15{
		gsort month_exp		
		loc rl =`lg'-1
		gen Y`lg' = l.Y`rl'
		gsort -month_exp
		carryforward Y`lg', replace
	}
	order month_exp Y*
	forvalues lg=1/15{
		loc nm = 1000+`lg'		
		rename Y`lg' v_norm`nm'	
	}
	rename Y0 v_norm`i'
	greshape long v_norm, i(month_exp) j(id)
	compress
	
	gen TP = id==`i' & month_exp>=${treat_period}

	xtset id month_exp
*set trace on 
scul v, treat(TP)
	
