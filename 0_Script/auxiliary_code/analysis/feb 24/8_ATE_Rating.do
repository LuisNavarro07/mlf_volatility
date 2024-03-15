*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: ATE Heterogeneity by Credit Risk 
*************************************************************************
*************************************************************************
use "${tem}\ate_did_dataset.dta", clear
merge m:1 state using "${tem}\state_ratings.dta", keep(match master) nogen

/// create dummy variables for ratings 
tab max_ratag, gen(rd)
/// Panel Structure 
egen id = group(state_id fileid)
tsset id month_exp

// Create Interaction Variables 
forvalues i=1/5{
	gen didrat`i' = did*rd`i'
	copydesc rd`i' didrat`i'
}

********************************************************************
/// Analysis OLS Regression by Credit Rating 

reghdfe tr_eff did didrat2 didrat3 didrat4 didrat5, absorb(id month_exp) vce(robust)
estimates store ate_rating 
global ate_r1 = _b[did]
global ate_r2 = _b[didrat2]
global ate_r3 = _b[didrat3]
global ate_r4 = _b[didrat4]
global ate_r5 = _b[didrat5]
esttab ate_rating, label se(%12.4fc) b(%12.4fc) 


************************************************************************
use "${tem}\placeboempiricaldistribution.dta", clear 
merge m:1 state_id using "${tem}\all_names.dta", keep(match master) nogen 
keep state state_id fileid tr_eff month_exp treat year_exp
merge m:1 state using "${tem}\state_ratings.dta", keep(match master) nogen
gsort fileid state_id month_exp 
/// Create unique identifiers 
egen id = group(state_id fileid)
tsset id month_exp
sum id
tempfile randomization_data
save "${tem}\randomization_data_rating.dta", replace

preserve 
keep id 
duplicates drop id, force
tempfile stateid_randomization
save "${tem}\stateid_randomization.dta", replace 
restore 

/// Randomization Inference Algorithm
capture program drop _all 
program define randomization, rclass 
/// Create the randomization rule 
use "${tem}\stateid_randomization.dta", clear 
/// random treatment assignment 
gen treat = runiform() > 0.5
tempfile randomizer 
save `randomizer', replace 

********************* 
/// Load Donors Data 
use "${tem}\randomization_data_rating.dta", clear 
merge m:1 id using `randomizer', keep(match master) nogen 
qui gen post = month_exp >= 0 
qui gen did = treat*post 
/// create dummy variables for ratings 
qui tab max_ratag, gen(rd)
// Create Interaction Variables 
forvalues i=1/5{
	gen didrat`i' = did*rd`i'
	copydesc rd`i' didrat`i'
}
/// Interaction Fixed Effects Regression 
qui tsset id month_exp
qui reghdfe tr_eff did didrat2 didrat3 didrat4 didrat5, absorb(id month_exp) vce(robust)
return scalar b1 = _b[did]
return scalar b2 = _b[didrat2]
return scalar b3 = _b[didrat3]
return scalar b4 = _b[didrat4]
return scalar b5 = _b[didrat5]
end 

/// Run Simulation
global experiments = 1000
set seed $seed
simulate r(b1) r(b2) r(b3) r(b4) r(b5), reps($experiments): randomization
rename (_sim_1 _sim_2 _sim_3 _sim_4 _sim_5) (ate_r1 ate_r2 ate_r3 ate_r4 ate_r5)

/*
Note on the Variables 
r1 = did
r2 = AAA 
r3 = AA
r4 = A 
r5 = BBB
*/

matrix define R=J(5,3,.)
matrix rownames R = "ATE" "AAA" "AA" "A" "BBB"
matrix colnames R = "Beta" "SE" "pvalue"
local name1 = "ATE"
local name2 = "AAA"
local name3 = "AA"
local name4 = "A"
local name5 = "BBB"
forvalues i=1(1)5{
/// Store the Results
/// absolute value of the ATE for the treated unit 
qui gen atetreat`i' = abs(${ate_r`i'})
qui gen absate`i' = abs(ate_r`i')
global atetreat`i' = abs(${ate_r`i'})
/// count how many times the 
qui gen pcount`i' = absate`i' > atetreat`i'
qui sum pcount`i'
global pvalue`i' = round(r(mean),0.001)
/// Standard Errors 
qui sum ate_r`i' 
global sd`i' = r(sd)
/// Empirical Distribution
qui kdensity absate`i', recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xline(${atetreat`i'} , lcolor(maroon) lpattern(dash)) xtitle("") title("`name`i''- Placebo Distribution: p = $pvalue", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(ate_`i',replace) xscale(range(0 ${ate_r`i'})) 

matrix R[`i',1] = ${ate_r`i'} 
matrix R[`i',2] = ${sd`i'}
matrix R[`i',3] = ${pvalue`i'}
}

esttab mat(R,fmt(4 4 4 4))

esttab mat(R,fmt(4 4 4 4)) using "${oup}\ate_did_ratings.tex", replace 
