//// Statistical Inference of the Synthetic Control 


/// Experiment 1 -- April 
global tr_dt1 = tm(2020m4)
global exp = "apr"
/// Experiment 2 -- June 
*global tr_dt1 = tm(2020m6)
*global exp = "jun"


global cohend_cutoff = 0.15
/// 1) Estimate the Synth
******************************************************************************
do "${cod}\code_analysis\1_Synth_TreatedUnits.do"
****************************************************

/// 1) Estimate each of the Placebos (Unit Free)
******************************************************************************
do "${cod}\code_analysis\2_1_PlaceboEstimation.do"
*****************************************************************************

/// 2) Compute the Placebos per outcome (Treated Unit)
******************************************************************************
do "${cod}\code_analysis\2_2_PlaceboOutcome.do"
*****************************************************************************

/// 3) Create the empirical distribution to do placebo analysis 
******************************************************************************
do "${cod}\code_analysis\2_3_PlaceboEmpiricalDistribution.do"
*****************************************************************************

/// 4) Do the Smokeplots
******************************************************************************
do "${cod}\code_analysis\2_4 SmokePlot.do"
*****************************************************************************

/// 5) Create the Table with ATE, pvalues
******************************************************************************
do "${cod}\code_analysis\2_5_State_Inference.do"
*****************************************************************************

/// 6) Create the Treatment Effect Graphs
******************************************************************************
do "${cod}\code_analysis\2_6_Graphs.do"
*****************************************************************************