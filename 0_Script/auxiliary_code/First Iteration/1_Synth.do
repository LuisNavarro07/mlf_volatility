*********************************************************************************
**** This file runs the first synth, of US based munibonds refering a first pool of donor data including: corp, vinde, 
**** as a control.
**** 	Dates of reference for MLF 
****		--> 09Apr2020 (Authorization) w=(2021,15)
****		--> 02Jun2020 (IL Announce)   w=(2020,23)
****		--> 18Dec2020 (IL Withdraw)   w=(2020,51)
**** Author: Luis Navarro & Felipe Lozano
**** Date:   Mar 8, 2022
*********************************************************************************
// Set Work Environment 
* Felipe
cd "G:\.shortcut-targets-by-id\13LAXgK7hsYAOEVzlCPjoUszW6P3HLzpE\MLF_Volatility\"
qui do "ProfileDoFile_Felipe.do"
**Luis
*cd "G:\.shortcut-targets-by-id\13LAXgK7hsYAOEVzlCPjoUszW6P3HLzpE\MLF_Volatility\" 
do "ProfileDoFile_Luis.do"

global graph_options ytitle(, size(vsmall)) ylabel(#15, nogrid labsize(tiny) angle(0)) xtitle("", size(small)) xlabel(, labsize(vsmall) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) ytitle("") legend(on size(vsmall) rows(1) cols(2) pos(6) region(lcolor(black)))
capture log close
*log using "$log/Synth01_$dt.smcl", replace
*********************************************************************************
*** Outcomes
loc outcomes "sd range"
loc renaming ""
foreach v of loc outcomes{
    loc renaming "`renaming' `v'"
}
di "`renaming'"
lab def vr 1 "sd" 2 "range", modify
local out = 1 // based on the ordering above

*** Treatments
/// Week of Treatment is 13th week of 2020 
loc tr_dt1 =tw(2020w13)
loc tr_dt2 =tw(2020w23)
loc tr_dt3 =tw(2020w51)
loc w = 1
******************************************************
use "$cln/financial_market_volatility.dta", clear
*** Making sure the data are balanced on the outcomes
drop if wofd<=`=tw(2019,12)'
drop if wofd==`=tw(2021,1)' 
/*capture // we identified sec_id 3 (AA) & 4 (A) with missing values. 
	drop if sd==.
	bysort sec_id: gen cnt=_N
	tab cnt
restore*/
tsset sec_id wofd
replace sec_id = 		sec_id-1 if sec_id<=6 
replace sec_id = 1000 +	sec_id-5 if sec_id>6  

rename (`renaming')(v1 v2)
keep sec_id wofd v*
greshape long v, i(sec_id wofd) j(sertype)	
sort sec_id sertype wofd

gegen id = group(sec_id sertype)
gen status = sec_id<1000

order id status sec_id sertype 

tempfile TheFile
save 	`TheFile'
save "${tem}\TheFile.dta", replace 

preserve 
keep id varlab
duplicates drop id, force 
encode varlab, gen(des)
save "${tem}\varnames.dta", replace 
restore 

local title1 "AAA Bonds"
local title2 "AAA Bonds"
local title3 "AA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "A Bonds"
local title7 "BBB Bonds"
local title8 "BBB Bonds"


/// Standard Deviation and Range go Separate
********************************************************************************
/// Look Across Type of Outcome 


local t = 1
forvalues t=1/8{
		use `TheFile', clear
		tab id if status==1, matrow(T)
		tab id if status==0, matrow(C)
		loc t_id = T[`t',1]
		keep if id== `t_id' | sec_id>1000
		/// Mean of each instrument in the Pre-treatment Period
		gegen v_pre_mn = mean(v) if wofd<`tr_dt`w'', by(id)
		bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of each instrument in the Pre-treatment Period
		gegen v_pre_sd = sd(v) if wofd<`tr_dt`w'', by(id)
		bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Variables
		gen v_norm = (v - v_pre_mn) / v_pre_sd
		
		sum v_pre_mn  if id==`t_id'
		loc tr_pr_mn=r(mean)
		sum v_pre_sd  if id==`t_id'
		loc tr_pr_sd=r(mean)
		
		tsset id wofd
		local levels ""				/*Lags to be included*/
		local i = 0
	
		loc tr_dt_pre1 = `tr_dt`w'' -1
		loc tr_dt_preT = `tr_dt`w'' -12
		//All lags up to 12 weeks (1Q)
		forvalues q = `tr_dt_pre1'(-1)`tr_dt_preT'{ 
			local levels "`levels' v(`q')"
		}
	
	tempfile SCM_id_`t'
	synth v `levels' `Xs', trunit(`t_id') trperiod(`tr_dt`w'') keep(`SCM_id_`t'')
	matrix RMSPE = e(RMSPE)
		mat Y=e(X_balance)
		mat Yt=Y[1...,1]
		mat Yc=Y[1...,2]
		mat rmse1=(Yt-Yc)'*(Yt-Yc)
		mat rmse1=rmse1/`=rowsof(Yt)'
	keep if id==`t_id'
	
	preserve	
		use `SCM_id_`t'', clear
		rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		gen pre_mn = `tr_pr_mn'
		gen pre_sd = `tr_pr_sd'
		*svmat Real--> Check I retrieve the same info
		gen treat_lev = pre_sd*treated + pre_mn 
		gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		
		qui gen id = `t_id'
		qui gen RMSPE = RMSPE[1,1]
	
		format wofd %twMon_CCYY	
		twoway (line treat_lev wofd, lcolor(black) lpattern(solid) lwidth(thin)) (line synth_lev wofd, lcolor(cranberry) lpattern(solid) lwidth(thin)) , xline(`tr_dt`w'', lcolor(maroon) lpattern(dash)) $graph_options name(synth`t', replace) title("`title`t''") legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility")) xlabel(#40, nogrid labsize(tiny) angle(90))
		graph export "${oup}\Synth_Graph`t'.png", $export

		tempfile scm_`t'
		save 	`scm_`t''
		gen fileid = `t'
		save "${tem}\scm_`t'.dta", replace 
	restore	

	matrix RMSPE`t' = RMSPE 
	matrix drop RMSPE

}


// title("Synthetic Control Volatility Estimates: Standard Deviation", size(small) pos(12) color(black))
grc1leg synth1 synth3 synth5 synth7, legendfrom(synth1) rows(2) cols(2) xcommon plotregion(lcolor(white)) plotregion(color(white)) graphregion(color(white) margin(4 4 4 4)) plotregion(lcolor(black)) name(synthcombined1,replace) 
graph export "${oup}\Graph2_SynthOut1.png", $export

// title("Synthetic Control Volatility Estimates: Range", size(small) pos(12) color(black))
grc1leg synth2 synth4 synth6 synth8, legendfrom(synth2) rows(2) cols(2) xcommon plotregion(lcolor(white)) plotregion(color(white)) graphregion(color(white) margin(4 4 4 4)) plotregion(lcolor(black)) name(synthcombined2,replace) 
graph export "${oup}\Graph2_SynthOut2.png", $export

use "${tem}\scm_1.dta", clear  
local t = 2
forvalues t=2/8{
	append using "${tem}\scm_`t'.dta", force 
} 
save "${tem}\scm_append.dta", replace
