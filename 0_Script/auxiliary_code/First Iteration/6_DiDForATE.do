/// Difference in Difference Aggregator*
*global tr_dt1 =tw(2020w13)
global tr_dt1 = tm(2020m3)

use "${tem}\scm_append_treated.dta", clear 
gen treat = 1 
append using  "${tem}\synt_placebos.dta"
replace treat = 0 if treat == . 
qui gen post = wofd - $tr_dt1 > 0 
gen did = treat*post 

replace fileid = id if treat == 1 
tab fileid

egen idd = group(id fileid)
 
tsset idd wofd
/// Generalized DID model, clustering at the security level. This is like a stacked diff in diff. Errors clustered at the 
reghdfe tr_eff did, absorb(idd wofd) cluster(id)