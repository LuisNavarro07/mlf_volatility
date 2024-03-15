*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: August 2022 
/// Script: Difference-in-Difference Treatment Effect Aggregation  
*************************************************************************
*************************************************************************

/// Load Data from Treatment Effect Estimates for both treated and donor units 
use "${tem}\synth_treated.dta", clear 
qui gen treat = 1 
append using "${tem}\placeboempiricaldistribution.dta", force  
qui replace treat = 0 if treat == . 
merge m:1 id using "${tem}\all_names.dta", keep(match master) nogen 
keep name id fileid tr_eff month_exp treat year_exp
gsort -treat fileid id month_exp 

/// Regression Approach - Canonical Difference-in-Difference
/// Post Variable 1: 2020 
qui gen post1 = month_exp >= 0 & month_exp <= 8
qui gen did1 = treat*post1
/// Post Variable 2: 2021 
qui gen post2 = month_exp >= 9 
qui gen did2 = treat*post2

save "${tem}\ate_did_dataset.dta", replace 
*******************************************************************************
/// Difference-in-Difference Regression 
/// Panel Structure 
egen idd = group(id fileid)
tsset idd month_exp
reghdfe tr_eff did1 did2, absorb(id month_exp) vce(robust)
global ate1 = _b[did1]
global ate2 = _b[did2]
************************************************************************
use "${tem}\placeboempiricaldistribution.dta", clear 
merge m:1 id using "${tem}\all_names.dta", keep(match master) nogen 
keep name id fileid tr_eff month_exp treat year_exp
gsort fileid id month_exp 
/// Create unique identifiers 
egen idd = group(id fileid)
tsset idd month_exp
sum idd
save "${tem}\randomization_data.dta", replace

preserve 
keep idd 
duplicates drop idd, force
tempfile stateid_randomization
save `stateid_randomization', replace 
save "${tem}\stateid_randomization.dta", replace  
restore 

/// Randomization Inference Algorithm
capture program drop _all 
program define randomization, rclass 
/// Create the randomization rule 
use "${tem}\stateid_randomization.dta", clear 
/// random treatment assignment 
gen treat = runiform() 
gsort -treat 
replace treat = 1 if _n <= 4  
tempfile randomizer 
save `randomizer', replace 

********************* 
/// Load Donors Data 
use "${tem}\randomization_data.dta", clear 
merge m:1 idd using `randomizer', keep(match master) nogen 
qui gen post1 = month_exp >= 0 & month_exp <= 8
qui gen did1 = treat*post1
/// Post Variable 2: 2021 
qui gen post2 = month_exp >= 9 
qui gen did2 = treat*post2
/// OLS Regression 
reghdfe tr_eff did1 did2, absorb(id month_exp) vce(robust)
return scalar b1 = _b[did1]
return scalar b2 = _b[did2]
end 


/// Run Simulation
global experiments = 1000
global seed 1234
set seed $seed
simulate r(b1) r(b2), reps($experiments): randomization
/// Store the Results
rename (_sim_1 _sim_2) (ate1 ate2)
matrix define R=J(2,3,.)
matrix colnames R = "ATE" "SE" "pvalue"
matrix rownames R = "2020" "2021"
/// absolute value of the ATE for the treated unit 
forvalues i=1(1)2{
qui gen atetreat`i' = abs(${ate`i'})
qui gen absate`i' = abs(ate`i')
global atetreat`i' = abs(${ate`i'})
/// count how many times the 
qui gen pcount`i' = absate`i' > atetreat`i'
sum pcount`i'
global pvalue`i' = round(r(mean),0.001)
/// Standard Errors 
sum ate`i' 
global sd`i' = r(sd)
/// Empirical Distribution
qui kdensity absate`i' , recast(line) lcolor(black) lwidth(medthin) lpattern(solid) xtitle("") title("ATE - Placebo Distribution: p = ${pvalue`i'}", pos(11) size(small)) ytitle("") xlabel(#10, angle(0) labsize(small)) ylabel(#10, angle(0) labsize(small)) name(ate_empirical`i',replace) xline(${atetreat`i'} , lcolor(maroon) lpattern(dash)) xscale(range(0 ${ate`i'}))


matrix R[`i',1] = ${ate`i'} 
matrix R[`i',2] = ${sd`i'}
matrix R[`i',3] = ${pvalue`i'}
}

esttab mat(R,fmt(4 4 4 4))
*esttab mat(R,fmt(4 4 4 4)) using "${oup}\ate_did.tex", replace 

clear 
svmat R
format R* %12.4fc
/// Statistical Significance 
gen stars = "" 
replace stars = "*" if R3 < 0.01
replace stars = "**" if R3 < 0.005 
replace stars = "***" if R3 < 0.001

tostring R1, gen(ate) force format(%12.4fc)
tostring R2, gen(se) force format(%12.4fc)
tostring R3, gen(pval) force format(%12.4fc)


replace se = "(" + se + ")"
replace ate = ate + stars


gen id = _n
rename (ate se pval) (b1 b2 b3)
keep id b*
reshape long b, i(id) j(vars) string
destring vars, gen(id1)
drop vars 
reshape wide b, i(id1) j(id)  
gen names = ""
replace names = "ATE" if _n == 1
replace names = "SE" if _n == 2
replace names = "P-Value (One Tail)" if _n == 3
drop id1
rename names Results
order Results 
save "${tem}\ate_did.dta", replace 
rename (b1 b2) (ATE_2020 ATE_2021)
order Results ATE_2020 ATE_2021
texsave * using "${oup}\ate_did.tex", replace  decimalalign nofix 