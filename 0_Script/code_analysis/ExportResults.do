*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: January 2023 
/// Script: Export Table of Main Results and Descriptive Statistics 
*************************************************************************
*************************************************************************
/// Descriptive Statistics 
use "${tem}\Table1_DescriptiveStats.dta", clear 
rename variable title
label variable y_pre	"Pre"
label variable y_post	"Post"
label variable y_diff	"Diff"
label variable v_pre	"Pre"
label variable v_post	"Post"
label variable v_diff	"Diff"
label variable title 	" "
list 
/// Export Main Results Table 
local title "Descriptive Statistics: Yield and Volatility around MLF's Implementation'"
local headerlines "& \multicolumn{3}{c}{Yield} & \multicolumn{3}{c}{Volatility} " "\cmidrule(lr){2-4} \cmidrule(lr){5-7}"
local fn "Notes: This table shows the mean for both the yield and our estimated intra-week volatility for each outcome, and across all the units from the donor pool. We report separately results from S&P Municipal Bond Indices donors (i.e. Donors Munis) and from stock market indices and commodities (i.e. Donors Others). Standard deviations are reported in parentheses. For the mean difference we report the standard error.  A */**/*** indicates significance at the 10/5/1\% levels."

/// Export the Main Figure 
if "${rating_agg}" == "rating_agg_var" {
	texsave using "${oup}\Table1_DescriptiveStatistics.tex", varlabels hlines(-4) nofix replace marker(tab:Table1_DescriptiveStatistics) title("`title'") footnote("`fn'") headerlines("`headerlines'") autonumber
}
else if  "${rating_agg}" == "rating_agg_stfix" {
	local title1 "Robustness Check Descriptive Statistics: Yield and Volatility around MLF's Implementation'"
	texsave using "${oup}\Table1_DescriptiveStatisticsRCStFix.tex", varlabels hlines(-4) nofix replace marker(tab:Table1_DescriptiveStatistics) title("`title1'") footnote("`fn'") headerlines("`headerlines'") autonumber
}



*****************************************************************************
/// Main Results 
use "${tem}\ATE_Results_Full.dta", clear
label variable AAA "AAA"
label variable AA "AA"
label variable A "A"
label variable BBB "BBB"
replace Results = "" if Results == "SE"
replace Results = "Average Treatment Effect" if Results == "ATE"
/// Export Main Results Table 
local title "Average Treatment Effects: MLF impact on Municipal Volatility"
local fn "\textbf{Note}: Each column shows the coefficient estimate of the Average Treatment Effect (ATE) \(\hat{\tau}\) by credit rating category. ATE estimation is done considering the 15 months following MLF's implementation. Percentage change reported captures the mean difference of the observed volatility after the intervention and the synthetic volatility, in terms of the average observed volatility. Mean of the dependent variable shows the average volatility in the pre-treatment period, excluding the spike observed in March 2020. Standard errors are reported in parentheses. This correspond to the standard deviation of the placebo distribuition of each coefficient. Statistical significance is determined using one-tail test with rank-based p-values. A */**/*** indicates significance at the 10/5/1\% levels."

/// Full Table 
texsave using "${oup}\Table2_MainResultsFull.tex", varlabels hlines(-3 -5) nofix replace marker(tab:Table2_MainResultsFull) title("`title'") footnote("`fn'") autonumber

****** Summarized Version 
/// Drop Confidence Interval and p-values 
drop if _n == 3 | _n == 6 | _n == 7  
texsave using "${oup}\Table2_MainResults.tex", varlabels hlines(-3) nofix replace marker(tab:Table2_MainResults) title("`title'") footnote("`fn'") autonumber
list 

*******************************************************************************
********************************************************************************
/// Robustness Checks 
use "${tem}\ATE_Results_Robustness_Stfix.dta", clear
label variable AAA "AAA"
label variable AA "AA"
label variable A "A"
label variable BBB "BBB"
replace Results = "" if Results == "SE"
replace Results = "Average Treatment Effect" if Results == "ATE"
/// Export Main Results Table 
local title "Average Treatment Effect: Estimates with Fixed Rating Cohorts"
texsave using "${oup}\Table2_RobustnessCheckStFixFull.tex", varlabels hlines(-3 -5) nofix replace marker(tab:Table2_RobustnessCheckStFixFull) title("`title'") footnote("`fn'") autonumber

****** Summarized Version 
/// Drop Confidence Interval and p-values 
drop if _n == 3 | _n == 6 | _n == 7  
local title "Average Treatment Effect: Estimates with Fixed Rating Cohorts"
texsave using "${oup}\Table2_RobustnessCheckStFix.tex", varlabels hlines(-3) nofix replace marker(tab:Table2_RobustnessCheckStFix) title("`title'") footnote("`fn'") autonumber
list  