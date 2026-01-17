********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Descriptive Statistics 
*** This Update: January 2023
********************************************************************************
********************************************************************************

//// Run the Synth
use "${cln}/synth_clean_fixedcr.dta", clear 
keep if depvar == "Nominal Yield Baseline" | depvar == "Donors"
drop if asset_class == "Municipal Bond"
drop if month_exp <= 3

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

********************************************************************************
/// Post Variable 
qui gen post = 0 
qui replace post = 1 if month_exp >= ${treat_period}
/// Assumption: Drop Observations Outside Treatment Effect Window Estimation 
drop if month_exp >= ${treat_period} + ${tr_eff_window}
///
gen datatype = 0 
replace datatype = 1 if asset_class == "Commodity"
replace datatype = 2 if asset_class == "Currency"
replace datatype = 3 if asset_class == "Sovereign Bond"
replace datatype = 4 if asset_class == "Stock Market Index"

********************************************************************************
/// First the Outcomes Only 
qui tab id if data == "Outcome"
local rows = 2*r(r)
dis `rows'
local title1 = "A"
local title2 = "AA"
local title3 = "AAA"
local title4 = "BBB"
/// Define Matrix To Store Values 
matrix define R=J(`rows',8,.)
matrix rownames R = "A" "A_se" "AA" "AA_se" "AAA" "AAA_se" "BBB" "BBB_se"
matrix colnames R = "Yield_Pre" "Yield_Post" "Yield_Diff" "Yield_Pval" "Vol_Pre" "Vol_Post" "Vol_Diff" "Vol_Pval"
/// Estimate the Mean Difference 
local j = 1 
forvalues i=1(1)4{
/// First the Yield 
qui ttest yield if id == `i' & data == "Outcome", by(post) unequal
/// Store the Results 
/// Means: Pre, Post and Mean Diff 
matrix R[`j', 1] = r(mu_1)
matrix R[`j', 2] = r(mu_2)
matrix R[`j', 3] = r(mu_2) - r(mu_1)
matrix R[`j', 4] = r(p)
/// Standard Deviation and Pvalue 
matrix R[`j'+ 1 , 1] = r(sd_1)
matrix R[`j'+ 1 , 2] = r(sd_2)
matrix R[`j'+ 1 , 3] = r(se)
/// Second the Volatility 
qui ttest v if id == `i' & data == "Outcome", by(post) unequal
/// Means: Pre, Post and Mean Diff 
matrix R[`j', 5] = r(mu_1)
matrix R[`j', 6] = r(mu_2)
matrix R[`j', 7] = r(mu_2) - r(mu_1)
matrix R[`j', 8] = r(p)
/// Standard Deviation and Pvalue 
matrix R[`j'+ 1, 5] = r(sd_1)
matrix R[`j'+ 1, 6] = r(sd_2)
matrix R[`j'+ 1, 7] = r(se)
local j = `j' + 2
}

esttab mat(R, fmt(4 4 4 4 4))
********************************************************************************
/// Donor Pool 
********************************************************************************
/// First the Outcomes Only 


local donors1 = "Commodity"
local donors2 = "Currency"
local donors3 = "Sovereign Bond"
local donors4 = "Stock Market Index"


/// Define Matrix To Store Values 
matrix define   D=J(8,8,.)
matrix rownames D = "Comm" "Comm_se" "Curr" "Curr_se" "SB" "SB_se" "Stock" "Stock_se" 
matrix colnames D = "Yield_Pre" "Yield_Post" "Yield_Diff" "Yield_Pval" "Vol_Pre" "Vol_Post" "Vol_Diff" "Vol_Pval"
/// Estimate the Mean Difference 
local j = 1 
forvalues i = 1(1)4{
/// First the Yield 
ttest yield if datatype ==  `i' , by(post) unequal
/// Store the Results 
/// Means: Pre, Post and Mean Diff 
matrix D[`j', 1] = r(mu_1)
matrix D[`j', 2] = r(mu_2)
matrix D[`j', 3] = r(mu_2) - r(mu_1)
matrix D[`j', 4] = r(p)
/// Standard Deviation and Pvalue 
matrix D[`j'+ 1 , 1] = r(sd_1)
matrix D[`j'+ 1 , 2] = r(sd_2)
matrix D[`j'+ 1 , 3] = r(se)
/// Second the Volatility 
ttest v if datatype ==  `i'  , by(post) unequal
/// Means: Pre, Post and Mean Diff 
matrix D[`j', 5] = r(mu_1)
matrix D[`j', 6] = r(mu_2)
matrix D[`j', 7] = r(mu_2) - r(mu_1)
matrix D[`j', 8] = r(p)
/// Standard Deviation and Pvalue 
matrix D[`j'+ 1, 5] = r(sd_1)
matrix D[`j'+ 1, 6] = r(sd_2)
matrix D[`j'+ 1, 7] = r(se)
local j = `j' + 2
}

esttab mat(D, fmt(4 4 4 4 4))
********************************************************************************
/// Append the Results 
matrix define F = R \ D
matlist F

/// Export the Results 
clear 
svmat F

tostring F1 F2 F3 F5 F6 F7, replace force 

local varlist F1 F2 F3 F5 F6 F7
foreach var of local varlist {
qui gen point_pos = strpos(`var',".")
qui replace `var' = substr(`var',1,point_pos + 4) 
qui gen negdec = strpos(`var',"-.")
qui replace `var' = substr(`var',2,point_pos + 4) if negdec == 1
qui replace `var' = "0" + `var' if strpos(`var',".") == 1 & negdec == 0 
qui replace `var' = "-0" + `var' if strpos(`var',".") == 1 & negdec == 1
qui replace `var' = "0" + `var' if length(`var') == 5 
qui drop point_pos negdec
}

qui rename (F1 F2 F3 F4 F5 F6 F7 F8) (y_pre y_post y_diff y_pval v_pre v_post v_diff v_pval)
qui gen id = _n 
qui gen variable = ""
qui replace variable = "A"			if id == 1
qui replace variable = "A_se"		if id == 2
qui replace variable = "AA"			if id == 3
qui replace variable = "AA_se"		if id == 4
qui replace variable = "AAA"		if id == 5
qui replace variable = "AAA_se"		if id == 6
qui replace variable = "BBB"		if id == 7
qui replace variable = "BBB_se"		if id == 8
qui replace variable = "Commodities"	if id == 9
qui replace variable = "Commodities_se"	if id == 10
qui replace variable = "Currencies"		if id == 11
qui replace variable = "Currencies_se" 	if id == 12
qui replace variable = "Sovereign Bonds"		if id == 13
qui replace variable = "Sovereign Bonds_se" 	if id == 14
qui replace variable = "International Stock Market Indices"		if id == 15
qui replace variable = "Stocks_se" 	if id == 16
/// Change the Order of the Table 
qui replace id = 1 if variable == "AAA"		
qui replace id = 2 if variable == "AAA_se"	
qui replace id = 3 if variable == "AA"		
qui replace id = 4 if variable == "AA_se"	
qui replace id = 5 if variable == "A"			
qui replace id = 6 if variable == "A_se"		
qui replace id = 7 if variable == "BBB"		
qui replace id = 8 if variable == "BBB_se"	
qui replace id = 9 if variable == "Sovereign Bonds"	
qui replace id = 10 if variable == "Sovereign Bonds_se"
qui replace id = 11 if variable == "Commodities"	
qui replace id = 12 if variable == "Commodities_se" 
qui replace id = 13 if variable == "Currencies"
qui replace id = 14 if variable == "Currencies_se"	
qui replace id = 15 if variable == "International Stock Market Indices" 
qui replace id = 16 if variable == "Stocks_se" 

sort id 
order variable 

/// Add parentheses to Standard Errors 
local varlist y_pre y_post y_diff v_pre v_post v_diff 
foreach var of local varlist {
forvalues i = 2(2)12 {
    replace `var' = "(" + `var' + ")" if _n == `i'
}
}

/// Remove Names from Standard Errors 
qui replace variable = "" if strpos(var,"_se") > 0
/// Stars Statistical Significance 
gen ystars = "" 
replace ystars = "*" if y_pval < 0.01
replace ystars = "**" if y_pval < 0.005 
replace ystars = "***" if y_pval < 0.001

gen vstars = "" 
replace vstars = "*" if v_pval < 0.01
replace vstars = "**" if v_pval < 0.005 
replace vstars = "***" if v_pval < 0.001

/// Add parentheses to Standard Errors 
local varlist y v 
foreach var of local varlist {
forvalues i = 1(2)11 {
    replace `var'_diff = `var'_diff + `var'stars  if _n == `i'
}
}

drop id y_pval v_pval ystars vstars
*******************************************************************************
save "${tem}/Table1_DescriptiveStats.dta", replace 
********************************************************************************
texsave * using "${oup}/Table1_DescriptiveStats.tex", replace  decimalalign nofix 
list
