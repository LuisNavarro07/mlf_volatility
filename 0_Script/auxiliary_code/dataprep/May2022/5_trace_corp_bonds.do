/// TRACE Data - Wharton Research Data Services
/*
TRACE: All broker-dealers who are FINRA member firms have an obligation to report transactions in TRACE-eligible securities FINRA is the Financial Industry Regulatory Authority, a non-governmental regulator of the entire securities industry. It was formed in the summer of 2007 from the NYSE and the NASD.

TRACE is a program operated by FINRA for reporting of certain fixed-income securities.
We use the following dataset: BTDS: corporate bonds (U.S. dollar-denominated, investment grade and high yield).

*/
/// TRACE - Bond Trades (BTDS)
use "${raw}\trace_standard.dta", clear 
/// We have information of 64,818 different corporate bonds (The limitation is that I dont have data on the characteristics of the bonds)
/// Collapse to have daily average yield observations 
gcollapse (mean) yld_pt, by(trd_exctn_dt)
rename (yld_pt trd_exctn_dt) (trace_yield date)
save "${tem}\trace_corp_data.dta", replace 