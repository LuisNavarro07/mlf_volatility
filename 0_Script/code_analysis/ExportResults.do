*************************************************************************
*************************************************************************
/// Project: Volatility in the Municipal Bond Market and the MLF
/// Authors: Felipe Lozano & Luis Navarro
/// Code: Luis Navarro 
/// Update: January 2023 
/// Script: Export Table of Main Results 
*************************************************************************
*************************************************************************

use "${tem}\ATE_Results_Full.dta", clear
label variable AAA "AAA"
label variable AA "AA"
label variable A "A"
label variable BBB "BBB"
replace Results = "" if Results == "SE"
replace Results = "Average Treatment Effect" if Results == "ATE"
/// Export Main Results Table 
local title "Average Treatment Effects: MLF impact on Municipal Volatility"
local fn "Notes: Each column shows the coefficient estimate of the Average Treatment Effect (ATE) \(\hat{\tau}\) by credit rating category. ATE estimation is done considering the 15 months following MLF's implementation. Percentage change reported captures the mean difference of the observed volatility after the intervention and the synthetic volatility, in terms of the average observed volatility. Standard errors are reported in parentheses. This correspond to the standard deviation of the placebo distribuition of each coefficient. Statistical significance is determined using one-tail test with rank-based p-values. A */**/*** indicates significance at the 10/5/1\% levels."
texsave using "${oup}\Table2_MainResultsFull.tex", varlabels hlines(-3 -5) nofix replace marker(tab:Table2_MainResultsFull) title("`title'") footnote("`fn'") 
list 

****** Summarized Version 
/// Drop Confidence Interval and p-values 
drop if _n == 3 | _n == 6 | _n == 7  

local title "Average Treatment Effects: MLF impact on Municipal Volatility"
local fn "Notes: Each column shows the coefficient estimate of the Average Treatment Effect (ATE) \(\hat{\tau}\) by credit rating category. ATE estimation is done considering the 15 months following MLF's implementation. Percentage change reported captures the mean difference of the observed volatility after the intervention and the synthetic volatility, in terms of the average observed volatility. Standard errors are reported in parentheses. This correspond to the standard deviation of the placebo distribuition of each coefficient. Statistical significance is determined using one-tail test with rank-based p-values. A */**/*** indicates significance at the 10/5/1\% levels."
texsave using "${oup}\Table2_MainResults.tex", varlabels hlines(-3) nofix replace marker(tab:Table2_MainResults) title("`title'") footnote("`fn'") 
list 