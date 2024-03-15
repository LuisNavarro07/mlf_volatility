use "$cln/financial_market_volatility.dta", clear
*** Making sure the data are balanced on the outcomes
global baropts ytitle("Unit Weight", size(small)) ylabel(#5, nogrid labsize(medsmall) angle(0)) title(, size(small) pos(11) color(black)) plotregion(lcolor(black)) graphregion(margin(4 4 4 4)) plotregion(lcolor(black)) legend(off size(vsmall) rows(1) cols(2) pos(6) region(lcolor(black)))
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

rename (sd range)(v1 v2)
keep sec_id wofd v*
greshape long v, i(sec_id wofd) j(sertype)	
sort sec_id sertype wofd

gegen id = group(sec_id sertype)
gen status = sec_id<1000

order id status sec_id sertype 

preserve 
replace varlab = varlab + " (SD)" if sertype == 1 
replace varlab = varlab + " (Range)" if sertype == 2 
keep id varlab
duplicates drop id, force 
encode varlab, gen(des)
save "${tem}\varnames.dta", replace 
restore 

tempfile TheFile
save 	`TheFile'
save "${tem}\TheFile.dta", replace 


local title1 "AAA Bonds"
local title2 "AAA Bonds"
local title3 "AA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "A Bonds"
local title7 "BBB Bonds"
local title8 "BBB Bonds"


use "${tem}\TheFile.dta", clear 
global tr_dt1 =tw(2020w13)


local t = 1
forvalues t=1/1{
		use "${tem}\TheFile.dta", clear 

		tab id if status==1, matrow(T)
		global outno = r(r)
		tab id if status==0, matrow(C)
		global donno = r(r)
		global t_id = T[`t',1]
		keep if id== ${t_id} | sec_id>1000
		/// Mean of each instrument in the Pre-treatment Period
		gegen v_pre_mn = mean(v) if wofd< ${tr_dt1}, by(id)
		bysort id: carryforward 	v_pre_mn, replace   
		/// Standard Deviation of each instrument in the Pre-treatment Period
		gegen v_pre_sd = sd(v) if wofd< ${tr_dt1}, by(id)
		bysort id: carryforward 	v_pre_sd, replace
		/// Normalized Variables
		gen v_norm = (v - v_pre_mn) / v_pre_sd
		
		sum v_pre_mn  if id == ${t_id}
		global tr_pr_mn=r(mean)
		sum v_pre_sd  if id == ${t_id}
		global tr_pr_sd=r(mean)
		
		tsset id wofd
		local levels ""				/*Lags to be included*/
		local i = 0
	
		loc tr_dt_pre1 = ${tr_dt1} -1
		loc tr_dt_preT = ${tr_dt1} -12
		//All lags up to 12 weeks (1Q)
		forvalues q = `tr_dt_pre1'(-1)`tr_dt_preT'{ 
			local levels "`levels' v(`q')"
		}
	global levels `levels'
	display "${levels}"
	tempfile SCM_id_`t'
	synth v ${levels}, trunit(${t_id}) trperiod(${tr_dt1}) keep(`SCM_id_`t'')

	local t = 1
	matrix define RMSPE`t' = e(RMSPE)
		matrix define Y`t' =e(X_balance)
		matrix define Yt`t' =Y[1...,1]
		matrix define Yc`t' =Y[1...,2]
		matrix define rmse1`t' =(Yt-Yc)'*(Yt-Yc)
		matrix define ate`t' =rmse1`t' /`=rowsof(Yt)'
	*keep if id== ${t_id}	
	
	preserve	
		use `SCM_id_`t'', clear
		rename (_Y_treated _Y_synthetic _time) (treated synth wofd)
		gen pre_mn = $tr_pr_mn
		gen pre_sd = $tr_pr_sd
		*svmat Real--> Check I retrieve the same info
		gen treat_lev = pre_sd*treated + pre_mn 
		gen synth_lev = pre_sd*synth + pre_mn 	
		qui gen tr_eff = treat_lev - synth_lev
		
		qui gen id = ${t_id}
		qui gen RMSPE = RMSPE[1,1]
		
		
		tempfile scm_`t'
		save 	`scm_`t''
		gen fileid = `t'
		save "${tem}\scm_`t'.dta", replace 
		
		/// Create the Synthetic Control Graphs and the Weights Graphs 
		format wofd %twMon_CCYY
		twoway (line treat_lev wofd, lcolor(black) lpattern(solid) lwidth(thin)) (line synth_lev wofd, lcolor(cranberry) lpattern(solid) lwidth(thin)) , xline(${tr_dt1}, lcolor(maroon) lpattern(dash)) $graph_options name(synth`t', replace) title("`title`t''") legend(on order(1 "Observed Volatility" 2 "Synthetic Volatility")) xlabel(#40, nogrid labsize(tiny) angle(90))
		graph export "${oup}\Synth_Graph`t'.png", $export
		
		drop id 
		rename (_Co_Number _W_Weight) (id weight)
		duplicates report id 
		merge 1:1 id using  "${tem}\varnames.dta", keep(match master) nogen
		graph hbar (asis) weight if weight > 0 , over(des, sort(weight) descending) name(weight`t', replace) bar(1, color(gray)) title("`title`t''") $baropts 
		graph export "${oup}\Weight_Graph`t'.png", $export

	restore	
	
	

	
}

