//// Statistical Inference of the Synthetic Control 
/// SP data 

/// Experiment 1 -- April 
global tr_dt1 = tm(2020m4)
global exp = "apr"
/// Experiment 2 -- June 
*global tr_dt1 = tm(2020m6)
*global exp = "jun"


global cohend_cutoff = 0.15
/// Add the SP data to the regression dataset. 
do "${cod}\code_dataprep\6_merge_sp.do"

/// 0) Shape the data to do the synth 
do "${cod}\code_analysis\sp\0_PrepareForSynth_sp.do"

/// 1) Estimate the Synth
******************************************************************************
do "${cod}\code_analysis\sp\1_Synth_TreatedUnits_sp.do"
****************************************************

/// 1) Estimate each of the Placebos (Unit Free) - Same as in the general case. The placebos are the same. 
******************************************************************************
do "${cod}\code_analysis\2_1_PlaceboEstimation.do"
*****************************************************************************

/// 2) Compute the Placebos per outcome (Treated Unit)
******************************************************************************
do "${cod}\code_analysis\sp\2_2_PlaceboOutcome_sp.do"
*****************************************************************************

/// 3) Create the empirical distribution to do placebo analysis 
******************************************************************************
do "${cod}\code_analysis\sp\2_3_PlaceboEmpiricalDistribution_sp.do"
*****************************************************************************

/// 4) Do the Smokeplots
******************************************************************************
do "${cod}\code_analysis\sp\2_4 SmokePlot_sp.do"
*****************************************************************************

/// 5) Create the Table with ATE, pvalues
******************************************************************************
do "${cod}\code_analysis\sp\2_5_State_Inference_sp.do"
*****************************************************************************

/// 6) Create the Treatment Effect Graphs
******************************************************************************
do "${cod}\code_analysis\sp\2_6_Graphs_sp.do"
*****************************************************************************