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
log using "${oup}\LogMLF_Volatility.log", replace 
timer on 5
********************************************************************************
/// Parameters Definition 
global rmspe_cutoff = 0.15
global tr_eff_window = 15
//// Experiment Time Goes for 26 Months. January t-1 to December t + 1. So if intervention happened at April 2020, then that is equivalent of having treatment at period 16. 
global treat_period = 16 
global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4) v(3) v(2) v(1) 
/// Rating Aggregation:
/// Fixed Cohorts: States at each rating category do not change over time: rating_agg_stfix 
/// Fixed Ratings: Ratings at each category do not change over time: rating_agg_var
********************************************************************************

/// Data Cleaning and Preparation - Common for all Scenarios
********************************************************************************
/// 0) Clean Bloomberg Prices of Potential Donors
do "${cod}\code_dataprep\0_BloombergPrices.do" 
/// 01) Do the Separation by Credit Rating
do "${cod}\code_dataprep\01_CreditRatingsbyState.do" 
///	1)  Clean Bloomberg State Bond Data and Merge it with MSRB data 
do "${cod}\code_dataprep\1_Clean_State_Bonds_Bloomberg_MSRB.do"
/// 2) Clean Standard & Poor's Municipal Bond Index Data 
do "${cod}\code_dataprep\2_StateSPMuniData.do"

/// Main Results
********************************************************************************
/// Define the Rating Aggregation Criterion: Main Results follows instruments with the same ratings
global rating_agg rating_agg_var
/// Main Results: Data Prep 
///	1_1)  Build the Outcome Using the Adequate Aggregation Method 
do "${cod}\code_dataprep\1_1_CollapseOutcomeByRating.do"
/// 3) Prepare the Dataset to Implement the Synthetic Control Method 
do "${cod}\code_dataprep\3_SynthFinalPrep.do"
/// Main Results: Analysis 
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
/// 4) Goodness of Fit: Test Survival Criterion (Build the Empirical Distribution)
******************************************************************************
do "${cod}\code_analysis\4_PlaceboEmpiricalDistribution.do"
*****************************************************************************
/// 5) Table with ATE by state and pvalues
******************************************************************************
do "${cod}\code_analysis\5_ATE_pvalues2.do"
*****************************************************************************
/// 6) Treatment Effect Plot and Smokeplots 
******************************************************************************
do "${cod}\code_analysis\5_1_Graph_Obs_Synth.do"
do "${cod}\code_analysis\6_SmokePlot.do"
/// 7) Descriptive Stats 
do "${cod}\code_analysis\0_DescriptiveStatistics.do"
do "${cod}\code_analysis\0_DescriptiveGraphs.do"
********************************************************************************
********************************************************************************

/// Robustness Checks: Fixed Cohorts by State 
********************************************************************************
/// Define the Rating Aggregation Criterion: Main Results follows instruments with the same ratings
global rating_agg rating_agg_stfix
//// The Predictors of the Model Change Because we drop 3 months 
global predictors v(15) v(14) v(13) v(12) v(11) v(10) v(9) v(8) v(7) v(6) v(5) v(4)
/// Main Results: Data Prep 
///	1_1)  Build the Outcome Using the Adequate Aggregation Method 
do "${cod}\code_dataprep\1_1_CollapseOutcomeByRating.do"
/// 3) Prepare the Dataset to Implement the Synthetic Control Method 
do "${cod}\code_dataprep\3_SynthFinalPrep.do"
/// Main Results: Analysis 
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
/// 4) Goodness of Fit: Test Survival Criterion (Build the Empirical Distribution)
******************************************************************************
do "${cod}\code_analysis\4_PlaceboEmpiricalDistribution.do"
*****************************************************************************
/// 5) Table with ATE by state and pvalues
******************************************************************************
do "${cod}\code_analysis\5_ATE_pvalues2.do"
*****************************************************************************
/// 6) Treatment Effect Plot and Smokeplots  
******************************************************************************
do "${cod}\code_analysis\5_1_Graph_Obs_Synth.do"
do "${cod}\code_analysis\6_SmokePlot.do"
/// 7) Descriptive Stats 
do "${cod}\code_analysis\0_DescriptiveStatistics.do"
do "${cod}\code_analysis\0_DescriptiveGraphs.do"
*****************************************************************************

/// Last Step: Export all the tables 
do "${cod}\code_analysis\ExportResults.do"
********************************************************************************
********************************************************************************


timer off 5
timer list 5
timer clear 5 
log close 
exit 