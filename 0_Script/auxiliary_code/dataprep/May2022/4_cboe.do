/// Clean Data from the Chicago Board of Trade
/// Source: Wharton Research Data Services 
use "${raw}\cboe.dta", clear 
rename Date date 
keep vix vxo vxn vxd date 
save "${tem}\cboe_close.dta", replace 

