# Liquidity and Volatility in the Municipal Bond Market: Evidence from the Municipal Liquidity Facility and other early interventions
# Felipe Lozano-Rojas & Luis Navarro

## FOLDER STRUCTURE
The replication package is organized into the following directories based on script path references:

- /0_Script/ /code_dataprep/ : Contains scripts for initial data cleaning and preparation. 
- /code_analysis/ : Contains the analytical scripts provided in this package. 
- /1_Data/ /Raw/ : Raw data files including Bloomberg bond data, MSRB trades, and economic indices. 
- /Clean/ : Finalized datasets ready for analysis. 
- /Temp/ : Intermediate data files generated during script execution. 
- /2_Output/ : All generated figures and tables. 

**MASTER SCRIPT**
MasterDoFile_Up.do
Orchestrates the entire project workflow by executing data cleaning and analysis scripts in sequence.
Sets critical global parameters, including the treatment intervention period (period 16) and the analysis window for post-treatment effects.
Establishes the statistical cutoff for the placebo distribution (85th percentile of RMSPE) to ensure high-quality matches in the synthetic control group.

## SCRIPTS IN /code_dataprep/

**0_BloombergPrices.do**
Imports and cleans Bloomberg price data for various asset classes used as potential donor units.
Drops variables with high missing values (over 5%) and uses carryforward techniques to handle missing daily data.
Reshapes the cleaned data into a long format suitable for panel analysis.

**0_CARES_Ranking.do**
Categorizes states based on their CARES Act Coronavirus Relief Fund (CRF) allocations.
Merges population data with federal funding allocations to calculate per capita support.
Creates categorical groups (e.g., above and below median) based on total federal funding provided per capita.

**1_Clean_State_Bonds_DepVar.do**
Processes primary and secondary market state government bond data from Bloomberg and MSRB.
Generates multiple versions of the dependent variable for robustness, including nominal yields, residualized yields, and bond spreads (yield minus Treasury benchmark).
Prepares the specific dataset used for the credit rating heterogeneity analysis.

**2_StateSPMuniData.do**
Cleans and standardizes S&P Municipal Bond General Obligation (GO) indices for 34 states.
Performs manual corrections for specific state data inconsistencies and reshapes the index data for inclusion in the donor pool.

**3_SynthFinalPrepBaseline.do**
Performs the final merging of treated units with all donor pools (Bloomberg, FRED currencies, and S&P Munis).
Collapses daily yield data into weekly and monthly volatility measures (standard deviation of yields).
Generates the final analysis datasets: synth_clean_fixedcr.dta and synth_clean_crf.dta.


## SCRIPTS IN /code_analysis/

**0_Programs_SDID.do**
Central library defining core programs used across the analysis.
Includes procedures for cleaning Bloomberg bond data and standardizing credit ratings.
Defines data preparation routines for building balanced panels and calculating weekly/monthly volatility.
Contains the primary logic for Synthetic Difference-in-Differences (SDID) estimation and placebo-based inference.


**1_SDID_estimation_full.do**
Executes the main analysis using baseline specifications.
Runs SDID models for nominal yields, residualized yields, bond spreads, and weighted variations.

**2_SDID_donor_sensitivity.do**
Evaluates the impact of donor pool composition on results.
Reruns analysis by restricting donors to specific asset classes such as commodities, currencies, sovereign bonds, or stock indices.


**3_SDID_table_robust.do**
Consolidates results from various robustness checks into final regression tables.
Formats outputs for LaTeX using panels for alternative measurements and donor pool variations.

**4_SDID_leave_one_out.do**
Implements a donor-level leave-one-out sensitivity analysis.
Systematically excludes individual donor units to ensure results are not driven by specific outlier instruments.

**5_SDID_robustness.do**
Executes advanced robustness checks including the impact of the CARES Act Coronavirus Relief Fund (CRF).
Analyzes treatment effect persistence and performs a state-level leave-one-out analysis.

**0_DescriptiveStatistics.do**
Generates Table 1 of the study, comparing pre- and post-treatment means and standard deviations.
Conducts t-tests for municipal bonds and donor asset classes.

**0_GraphsYieldsVolatility.do**
Produces descriptive visualizations of bond yields and volatility by credit rating.
Generates "smoke plots" to visualize the volatility distribution within the donor pool.

**0_RatingsMap.do**
Creates a geographic visualization of state credit ratings across the United States.

**0_GrantFunding_Figures.do**
Produces analysis and maps related to the distribution of CARES Act grant funding.
Includes scatter plots relating funding to population, fiscal revenues, and GDP growth.

