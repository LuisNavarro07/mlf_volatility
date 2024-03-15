/// Bloomberg Primary Market Bonds
/// All Bonds (Active and Matured) issued by State Governments between 2019 and 2021

forvalues i=1(1)2{
import excel "${raw}\state_bonds_bloomberg.xlsx", sheet("Sheet`i'") firstrow clear
save "${tem}\statebonds`i'.dta",replace 
}

use "${tem}\statebonds1.dta", clear
append using "${tem}\statebonds2.dta"
save "${tem}\statebondsfull.dta",replace 

//// Secondary Market Bonds 
/// Import data from the full market and then match on the cusips. 
/// Data on 2021 bonds is not matched as the MSRB data does not have data for this period.
use "${raw}\msrb.dta", clear 
merge m:1 CUSIP using "${tem}\statebondsfull.dta", keep(match) nogen 
destring PAR_TRADED, replace 

/// Standardize Credit Ratings 
/// Credit Rating 
gen rat_emp = 0 
replace rat_emp = 1 if SPInitRtg == "#N/A N/A" & MdyInitRtg == "#N/A N/A" & FitchInitRtg == "#N/A N/A" 
replace SPInitRtg = "" if SPInitRtg == "#N/A N/A"
replace MdyInitRtg = "" if MdyInitRtg == "#N/A N/A"
replace FitchInitRtg = "" if FitchInitRtg == "#N/A N/A"


*** Standard and Poors 
generate StandardPoors = .
replace StandardPoors = 1 if SPInitRtg == "AAA"
replace StandardPoors = 2 if SPInitRtg == "AA+"
replace StandardPoors = 3 if SPInitRtg == "AA"
replace StandardPoors = 4 if SPInitRtg == "AA-"
replace StandardPoors = 5 if SPInitRtg == "A+"
replace StandardPoors = 6 if SPInitRtg == "A"
replace StandardPoors = 7 if SPInitRtg == "A-"
replace StandardPoors = 8 if SPInitRtg == "BBB+"
replace StandardPoors = 9 if SPInitRtg == "BBB"
replace StandardPoors = 10 if SPInitRtg == "BBB-"

**** Fitch
generate Fitch = .
replace Fitch = 1 if FitchInitRtg == "AAA"
replace Fitch = 2 if FitchInitRtg == "AA+"
replace Fitch = 3 if FitchInitRtg == "AA"
replace Fitch = 4 if FitchInitRtg == "AA-"
replace Fitch = 5 if FitchInitRtg == "A+"
replace Fitch = 6 if FitchInitRtg == "A"
replace Fitch = 7 if FitchInitRtg == "A-"
replace Fitch = 8 if FitchInitRtg == "BBB+"
replace Fitch = 9 if FitchInitRtg == "BBB"
replace Fitch = 10 if FitchInitRtg == "BBB-"


**** Moodys
generate Moodys = .
replace Moodys = 1 if MdyInitRtg == "Aaa"
replace Moodys = 2 if MdyInitRtg == "Aa1"
replace Moodys = 3 if MdyInitRtg == "Aa2"
replace Moodys = 4 if MdyInitRtg == "Aa3"
replace Moodys = 5 if MdyInitRtg == "A1"
replace Moodys = 6 if MdyInitRtg == "A2"
replace Moodys = 7 if MdyInitRtg == "A3"
replace Moodys = 8 if MdyInitRtg == "Baa1"
replace Moodys = 9 if MdyInitRtg == "Baa2"
replace Moodys = 10 if MdyInitRtg == "Baa3"

global creditrat SPInitRtg MdyInitRtg FitchInitRtg Fitch StandardPoors Moodys rating
generate rating = max(Moodys,Fitch,StandardPoors)

encode FitchInitRtg, gen(fitch1)
encode MdyInitRtg, gen(moody1)
encode SPInitRtg, gen(sp1)
copydesc FitchInitRtg fitch1
copydesc MdyInitRtg moody1 
copydesc SPInitRtg sp1 
drop FitchInitRtg MdyInitRtg SPInitRtg
rename fitch1 FitchInitRtg 
rename moody1 MdyInitRtg
rename sp1 SPInitRtg

gen rating_agg = 0 
replace rating_agg = 1 if rating == 1
replace rating_agg = 2 if rating == 2 | rating == 3 |rating == 4
replace rating_agg = 3 if rating == 5 | rating == 6 |rating == 7
replace rating_agg = 4 if rating == 8 | rating == 9 |rating == 10
label define rating_agg 0 "NR" 1 "AAA" 2 "AA" 3 "A" 4 "BBB"
label values rating_agg rating_agg
save "${tem}\statebondsfull_secondary.dta",replace 

/// Collapse Data to Have Credit Rating by Day Observations 
use "${tem}\statebondsfull_secondary.dta",clear 
/// Collapse the data by credit rating and day. So we are taking the average across states, fixing the credit rating. 
gcollapse (mean) YIELD (sum) PAR_TRADED, by(rating_agg TRADE_DATE) 
xtset rating_agg TRADE_DATE
rename (YIELD TRADE_DATE PAR_TRADED) (yield date par)
reshape wide yield par, i(date) j(rating_agg)

global lab0 "nr" 
global lab1 "3a" 
global lab2 "2a" 
global lab3 "a" 
global lab4 "3b"

forvalues i=0(1)4{
    label variable yield`i' "Yield - ${lab`i'}"
	label variable par`i' "Par Traded - ${lab`i'}"
	rename yield`i' yield${lab`i'}
	rename par`i' par${lab`i'}
}
save "${tem}\secondary_rating.dta",replace 

/// Now we will also create a variable for all the Municipal Market - Including States 
use "${raw}\msrb.dta", clear 
destring PAR_TRADED, replace 
gcollapse (mean) YIELD (sum) PAR_TRADED, by(TRADE_DATE) 
rename (YIELD TRADE_DATE PAR_TRADED) (yield_muni_market date par_muni_market)
save "${tem}\secondary_fullmkt.dta",replace 