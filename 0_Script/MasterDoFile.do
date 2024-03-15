********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Master Do File 
*** This Update: Februrary 2024 
********************************************************************************
********************************************************************************
//// Statistical Inference of the Synthetic Control 
/// SP data 
clear all 
cap log using "${oup}/LogMLF_Volatility.log"
timer on 5
/// Data Cleaning and Preparation
********************************************************************************
/// 0) Clean Bloomberg Prices of Potential Donors
do "${cod}/code_dataprep/0_BloombergPrices.do" 
/// 0) CARES Ranking for Robustness Check 
do "${cod}/code_dataprep/0_CARES_Ranking.do"
/// 1) Clean Bloomberg State Bond Data and Merge it with MSRB data 
do "${cod}/code_dataprep/1_Clean_State_Bonds_Bloomberg_MSRB.do"
/// 2) Clean Standard & Poor's Municipal Bond Index Data 
do "${cod}/code_dataprep/2_StateSPMuniData.do"
/// 3) Prepare the Dataset to Implement the Synthetic Control Method 
do "${cod}/code_dataprep/3_SynthFinalPrep.do"
/// 4) Prepare the Dataset to Implement the Synthetic Control Method -- Robustnes Check Data with CARES Heterogeneity 
do "${cod}/code_dataprep/4_SynthFinalPrepRobustnessCheck.do"

********************************************************************************
/// Parameters Definition 
global rmspe_cutoff = 0.15
global tr_eff_window = 15
//// Experiment Time Goes for 26 Months. January t-1 to December t + 1. So if intervention happened at April 2020, then that is equivalent of having treatment at period 16. 
global treat_period = 16 
global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4)

/// Descriptive Statistics 
/// 1) Graphs of Bond Yields and Volatility Measures
do "${cod}/code_analysis/0_GraphsYieldsVolatility.do"
/// 2) Table with Descriptive Statistics 
do "${cod}/code_analysis/0_DescriptiveStatistics.do"
/// 3) Credit Rating Map
do "${cod}/code_analysis/0_RatingsMap.do"
********************************************************************************

/// Main Results 
/// Analysis 
/// 0) Load Programs that will be used for the estimation 
do "${cod}/code_analysis/0_Programs.do"
/// 1) Estimate the placebo distribution: this is done once for the baseline and robustness check for cares heterogeneity 
do "${cod}/code_analysis/1_PlacebosForBaseline.do"
/// 2) Estimate the Baseline Model 
do "${cod}/code_analysis/2_BaselineModel.do"
/// 3) Estimate the Robustness Check for Cares Act Heterogeneity
do "${cod}/code_analysis/3_RC_CaresAct.do"
/// Robustness Check for the Credit Rating Categorization 
/// 4) Estimate the placebos for the robustness check 
/// Change the specification of the model
global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4) v(3) v(2) v(1)
do "${cod}/code_analysis/4_PlacebosForRC.do"
/// Estimate the Robustness Check 
do "${cod}/code_analysis/5_RC_CreditRating.do"

********************************************************************************

*******************************************************************************

timer off 5
timer list 5
timer clear 5 
cap log close 		
exit 
