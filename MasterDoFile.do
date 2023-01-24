********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Master Do File 
*** This Update: September 2022 
********************************************************************************
********************************************************************************
//// Statistical Inference of the Synthetic Control 
/// SP data 
clear all 
*cap log using "${oup}\LogMLF_Volatility.log"
timer on 5
/// Data Cleaning and Preparation
********************************************************************************
/// 0) Clean Bloomberg Prices of Potential Donors
do "${cod}\code_dataprep\0_BloombergPrices.do" 
/// 1) Clean Bloomberg State Bond Data and Merge it with MSRB data 
do "${cod}\code_dataprep\1_Clean_State_Bonds_Bloomberg_MSRB.do"
/// 2) Clean Standard & Poor's Municipal Bond Index Data 
do "${cod}\code_dataprep\2_StateSPMuniData.do"
/// 3) Prepare the Dataset to Implement the Synthetic Control Method 
do "${cod}\code_dataprep\3_SynthFinalPrep.do"

********************************************************************************
/// Parameters Definition 
global rmspe_cutoff = 0.15
global tr_eff_window = 15
//// Experiment Time Goes for 26 Months. January t-1 to December t + 1. So if intervention happened at April 2020, then that is equivalent of having treatment at period 16. 
global treat_period = 16 
global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4) v(3) v(2) v(1) 

*v(10(1)12) v(7(1)9) v(4(1)6) v(1(1)3)

/// Analysis 
********************************************************************************
/// 1) Estimate the Synthetic Control For Treated Units
******************************************************************************
do "${cod}\code_analysis\1_SyntheticControl.do"
****************************************************
/// 2) Placebo Distribution Estimation (Unit Free)
******************************************************************************
do "${cod}\code_analysis\2_PlaceboEstimation.do"
*****************************************************************************
/// 3) Create Smokelines, Placebo Distributions for each Treated Unit
******************************************************************************
do "${cod}\code_analysis\3_PlaceboOutcome.do"
*****************************************************************************

/// Treatment Effect Estimation and Statistical Inference 

/// 4) Goodness of Fit: Cohen D Test Survival Criterion 
******************************************************************************
do "${cod}\code_analysis\4_PlaceboEmpiricalDistribution.do"
*****************************************************************************
/// 5) Table with ATE by state and pvalues
******************************************************************************
do "${cod}\code_analysis\5_ATE_pvalues2.do"
*****************************************************************************
/// 6) Smokeplots 
******************************************************************************
do "${cod}\code_analysis\6_SmokePlot.do"
*****************************************************************************
/// 7) Treatment Effect Estimation with DID and Randomization Inference 
******************************************************************************
do "${cod}\code_analysis\7_DID_ATE.do"
*****************************************************************************
/// Last Step: do the synth graphs 
do "${cod}\code_analysis\0_DescriptiveGraphs.do"

timer off 5
timer list 5
timer clear 5 
		
exit 