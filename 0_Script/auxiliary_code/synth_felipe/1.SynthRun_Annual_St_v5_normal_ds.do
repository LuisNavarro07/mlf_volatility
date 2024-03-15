*********************************************************************************
*** This file runs Synth
***   	_v1 on its own series
***   	_v2 on other series as pcb as well
***		_v3 policies coded on _v2
***		_v4 inverse hyperbolic sine transformation or normalize (line 75)
***			_ihs hiper transform  vs _normal 
***		_v5 V4 on final data from Haile.
***			_ds daily supply  vs _rt rates	
***		Feb2022 version includes all adults.
*********************************************************************************
global policy "/N/project/gupta_S_09_2019/NIH_R01_ProjectExtract/"
global output "$policy/Results_ARCHIVE/Synth_Annual_v5_normal_ds"
global scrp   "$policy/scripts/Synth"
cd "$policy/data"

*global policy "C:\Users\fal20381\Dropbox\MCLs_Labor\data\Medical Cannabis Policy Files\"
*global data   "$policy\OPTIC\SYNTH\Data"
*global output "$policy\OPTIC\SYNTH\Red_RRs_v5_normal_ds"	
*global scrp   "$policy"
*cd "$data"

capture log close
log using "$output/Log_Run_normal_ds_$S_DATE.smcl", replace
******************************************************************************* SYNTH
********************************* File parameters
loc ref_date=2007  
loc end_date=2020
loc prew 	  "5"	
loc posw	  "6"	

loc pols "effMML effREC meddisp_leg meddisp_act active_dispREC mml_pass mml_legal mml_disp mml_hcult rec_pass rec_legal rec_disp rec_hcult"
loc pols "mml_pass mml_legal mml_disp mml_hcult effMML meddisp_leg meddisp_act"
loc Xs ""
loc outcomes "opioid_ds nsaid_ds op_ds anticon_ds antidep_ds benzo_ds z_drugs_ds barb_ds"
lab def vr 1 "opioid_ds" 2 "nsaid_ds" 3 "op_ds" 4 "anticon_ds" 5 "antidep_ds" 6 "benzo_ds" 7 "z_drugs_ds" 8 "barb_ds", modify

loc out "opioid_ds"
loc p 	"meddisp_act"

loc renaming ""
foreach v of loc outcomes{
    loc renaming "`renaming' `v'"
}
di "`renaming'"
********************************************************************************** TREATED LOOP SEPARATE
foreach p of local pols{
********************************************************************************** Link to outcome variable(s) 	*
use "collapsed_state_year_rates_0720_vFeb2022.dta", clear
tsset statefips year
isid year statefips
rename (`renaming')(v1 v2 v3 v4 v5 v6 v7 v8)
keep state_name statefips state year v*
greshape long v, i(state_name statefips state year) j(a)

gegen miss_units= count(v), by(statefips a)
replace miss_units= (`end_date'-`ref_date'+1) - miss_units
tab miss_u a, matcell(miss) matrow(m2)
mat miss = miss/(`end_date'-`ref_date'+1)
mat miss = m2, miss
mat colnames miss = "miss" "opioid" "nsaid" "op" "anticon" "antidep" "benzo" "z_drugs" "barb"
mat list miss
putexcel set "$output/Missing.xlsx", sheet(Table1, replace) modify 
putexcel A2 = matrix(miss), names
drop if miss_u!=0
drop miss_u
 
sort state_name a year 
lab val a vr
loc v=1
******************************************* Coded policies
qui do "$scrp/SynthPolicyAnnual_St_coded.do"
	gen year_`p' = yofd(date_`p')
	gen pre_`p' = year_`p' - `ref_date'
	gen pos_`p' = `end_date' - year_`p'
	
	*Never treated
	g status 	   = 2 if year_`p'==.
	*Treated --> Ka and Kb bounds for states
	replace status = 1 if pre_`p'>=`prew' & pos_`p'>=`posw' & year_`p'!=.
	*Always treated based on more than 5 years of treatment
	replace status = 3 if pre_`p'<=0
	* Eliminate those with no enough pre nor post
	lab def stt 1 "Treated" 2 "Never Treated" 3 "Always Treated (no pre)"
	lab val statu stt
	tab status,m
	drop if status ==.
	drop if status ==3

	replace year_`p' = year_`p' + 1 if month(date_`p')==12 & day(date_`p')>10 
	gen TP = year>year_`p'
	gen tt_treat_`p'= year-year_`p'
******************************************* 
tempfile `p'_file
save 	``p'_file', replace
qui d
di "The number of obs is `=r(N)'"
di "The number of obs is `=r(N)'"
  
foreach out of local outcomes{
	use 	``p'_file', clear	
	rename v `out'_real
	*********************************************************************************
	******************************   treated  states   ******************************
	*********************************************************************************
	tab statefips if status==1, matrow(A)
	tab statefips if status==2, matrow(B)
	tempfile TheFile
	save 	`TheFile', replace
	qui d

	*local t = 7 // AZ statefips ==4
	forvalues t = 1/`=rowsof(A)'{
		use `TheFile', clear
		loc st = A[`t',1]
		keep if status==2 | statefips==A[`t',1]		
		drop if status==1 & a!=`v'		
		gsort status statefips a year
		gegen id2=group(statefips a) if statefips!=A[`t',1]
		gen 	id = id2+1 
		replace id = 1 if status==1
		
		tsset id year
		isid year id
	
		sum year_`p'		
		loc imp0 = r(mean) 
		loc imp1 = `imp0' - 1
		
		gsort status statefips a year
		gegen `out'_pre_mn = mean(`out'_real) if year<`imp0', by(status statefips a)
		bysort status statefips a: carryforward `out'_pre_mn, replace
		gegen `out'_pre_sd = sd(`out'_real) if year<`imp0', by(status statefips a)
		bysort status statefips a: carryforward `out'_pre_sd, replace		
		gen `out'= (`out'_real - `out'_pre_mn) / `out'_pre_sd
		
		sum `out'_pre_mn  if status==1
		loc tr_pr_mn=r(mean)
		sum `out'_pre_sd  if status==1
		loc tr_pr_sd=r(mean) 
		if r(mean)==0 | r(N)==0{
			di "For state `st' policy `p' and variable `out', no variation in pre"
			di "For state `st' policy `p' and variable `out', no variation in pre"
			di "For state `st' policy `p' and variable `out', no variation in pre"		
		}
		
		if r(mean)!=0 & r(N)!=0{			
			display "Treat St - `st' ; policy - `p'; Var - `out' ; treatment `t' out of `=rowsof(A)'"
			display "Treat St - `st' ; policy - `p'; Var - `out' ; treatment `t' out of `=rowsof(A)'"
			display "Treat St - `st' ; policy - `p'; Var - `out' ; treatment `t' out of `=rowsof(A)'"
			
			local levels ""				/*Lags to be included*/
			local i = 0
			
			forvalues q = `imp1'(-1)`ref_date'{    //All the lags up to the beginning of the sample or 20 lags
					if `i'<20{
						local levels "`levels' `out'(`q')"
					}
					loc ++i
				}	
			di "`levels'"			
			tempfile SCM_`out'_st`st'		
			synth `out' `levels' `Xs', trunit(1) trperiod(`imp0') keep(`SCM_`out'_st`st'')
			matrix RMSPE = e(RMSPE)
				mat Y=e(X_balance)
				mat Yt=Y[1...,1]
				mat Yc=Y[1...,2]
				mat rmse1=(Yt-Yc)'*(Yt-Yc)
				mat rmse1=rmse1/`=rowsof(Yt)'
			keep if id==1
			mkmat `out'_real, mat(Real)
			mat list Real	
			preserve	
				use `SCM_`out'_st`st'', clear
				rename (_Y_treated _Y_synthetic _time) (`out'_treated `out'_synth year)
				gen `out'_pre_mn = `tr_pr_mn'
				gen `out'_pre_sd = `tr_pr_sd'
				*svmat Real--> Ccheck I retrieve the same info
				gen `out'_treat_lev = `tr_pr_sd'*`out'_treated + `tr_pr_mn' 
				gen `out'_synth_lev = `tr_pr_sd'*`out'_synth + `tr_pr_mn' 	
				qui gen tr_eff = `out'_treat_lev - `out'_synth_lev
				
				qui gen statefips = `st'
				qui gen RMSPE = RMSPE[1,1]
	
				tempfile aja_`st'
				save 	`aja_`st''
			restore	
		}	
	
	} /*Treated Units*/
******************************************************* Merge to *
	loc st = A[1,1]
	*use "$output/SCM_`out'_st`st'.dta", clear
	use `aja_`st'', clear 
	forvalues t = 2/`=rowsof(A)'{	    
		loc st = A[`t',1]
		capture append using `aja_`st''	
	}
	*loc st = A[1,1]
	*rm "$output/SCM_`out'_st`st'.dta"
		
	drop _Co_ _W_
	drop if year==.
	
	tempfile RRs
	save `RRs'
	save "$output/Actual_Effects_`p'_`out'_opened.dta", replace
	
	
	
	use "collapsed_state_year_rates_0720_vFeb2022.dta", clear
	******************************************* Coded policies
	qui do "$scrp/SynthPolicyAnnual_St_coded.do"
		gen year_`p' = yofd(date_`p')
		gen pre_`p' = year_`p' - `ref_date'
		gen pos_`p' = `end_date' - year_`p'
		
		*Never treated
		g status 	   = 2 if year_`p'==.
		*Treated --> Ka and Kb bounds for states
		replace status = 1 if pre_`p'>=`prew' & pos_`p'>=`posw' & year_`p'!=.
		*Always treated based on more than 5 years of treatment
		replace status = 3 if pre_`p'<=0
		* Eliminate those with no enough pre nor post
		lab def stt 1 "Treated" 2 "Never Treated" 3 "Always Treated (no pre)"
		lab val statu stt
		tab status,m
		drop if status ==.
		drop if status ==3
	
		replace year_`p' = year_`p' + 1 if month(date_`p')==12 & day(date_`p')>10 
		gen TP = year>year_`p'
		gen tt_treat_`p'= year-year_`p'
		*merge 1:1 year statefips using "Policy_`p'_file.dta", nogen
	*******************************************
	merge 1:1 statefips year using `RRs'
	
	
	gcollapse (mean) tr_eff `out'_treat_lev `out'_synth_lev  (count) st_count=tr_eff, by(tt_treat_`p')
	
	sum st_count
	keep if st_count==`r(max)'
	
	
	gr tw line `out'_treat_lev `out'_synth_lev  tt_treat_`p'
	save "$output/Actual_Effects_`p'_`out'.dta", replace
	loc v = `v'+1
} // Outcome Loop
} // Policy Loop
*********************************************************************************
******************************   Pcb - Inference   ******************************
*********************************************************************************/
********************************************************************************** TREATED LOOP SEPARATE
foreach p of local pols{	
******************************************************************************************* Link to outcome variable(s)
	use "collapsed_state_year_rates_0720_vFeb2022.dta", clear
	tsset statefips year
	isid year statefips
	rename (opioid_ds nsaid_ds op_ds anticon_ds antidep_ds benzo_ds z_drugs_ds barb_ds)(v1 v2 v3 v4 v5 v6 v7 v8)
	keep state_name statefips state year v*
	greshape long v, i(state_name statefips state year) j(a)
	gegen miss_units= count(v), by(statefips a)
	replace miss_units= (`end_date'-`ref_date'+1) - miss_units
	drop if miss_u!=0
	drop miss_u
	
	lab val a vr
	loc v=1
	******************************************* Coded policies
	qui do "$scrp/SynthPolicyAnnual_St_coded.do"
		gen year_`p' = yofd(date_`p')
		gen pre_`p' = year_`p' - `ref_date'
		gen pos_`p' = `end_date' - year_`p'
		
		*Never treated
		g status 	   = 2 if year_`p'==.
		*Treated --> Ka and Kb bounds for states
		replace status = 1 if pre_`p'>=`prew' & pos_`p'>=`posw' & year_`p'!=.
		*Always treated based on more than 5 years of treatment
		replace status = 3 if pre_`p'<=0
		* Eliminate those with no enough pre nor post
		lab def stt 1 "Treated" 2 "Never Treated" 3 "Always Treated (no pre)"
		lab val statu stt
		tab status,m
		drop if status ==.
		drop if status ==3
	
		replace year_`p' = year_`p' + 1 if month(date_`p')==12 & day(date_`p')>10 
		gen TP = year>year_`p'
		gen tt_treat_`p'= year-year_`p'
		*merge 1:1 year statefips using "Policy_`p'_file.dta", nogen
	*******************************************
	tab status, m
	
	tempfile `p'_file
	save 	``p'_file'
	
	foreach out of local outcomes{
	use 	``p'_file', clear
	rename v `out'_real
	*********************************************************************************
	tab statefips if status==1, matrow(A)
	tab statefips if status==2, matrow(B)
	tempfile TheFile
	save 	`TheFile'
	*
	local t = 1  // AZ statefips ==4
	forvalues t = 1/`=rowsof(A)'{
		use `TheFile', clear
		loc st = A[`t',1]
		keep if status==2 | statefips==A[`t',1]
		drop if status==1 & a!=`v'
		gsort status statefips a year
		gegen id2=group(statefips a) if statefips!=A[`t',1]
		gen 	 id = id2+1 
		replace  id = 1 if status==1
	
		
		carryforward year_`p', gen(year_pcb)
		qui sum year_`p'
		loc imp0 = r(mean) 
		loc imp1 = `imp0' - 1
		 
		drop pre_* pos_* TP* tt_treat_`p'
		gen tt_treat_pcb= year-year_pcb
		
		gsort status statefips a year
		gegen `out'_pre_mn = mean(`out'_real) if year<`imp0', by(status statefips a)
		bysort status statefips a: carryforward `out'_pre_mn, replace
		gegen `out'_pre_sd = sd(`out'_real) if year<`imp0', by(status statefips a)
		bysort status statefips a: carryforward `out'_pre_sd, replace		
		gen `out'= (`out'_real - `out'_pre_mn) / `out'_pre_sd
			
		sum `out'_pre_mn  if status==1
		loc tr_pr_mn=r(mean)
		sum `out'_pre_sd  if status==1
		loc tr_pr_sd=r(mean) 
		if r(mean)==0 | r(N)==0{
			di "For state `st' policy `p' and variable `out', no variation in pre"
			di "For state `st' policy `p' and variable `out', no variation in pre"
			di "For state `st' policy `p' and variable `out', no variation in pre"		
		} 
 		if r(mean)!=0 & r(N)!=0{
			tempfile ThePCBFile
			save 	`ThePCBFile'
						
			drop if id==1
			drop if `out'_pre_sd==0
			tab id2, matrow(PCB)   
			
			loc t2 = 1
			forvalues t2 = 1/`=rowsof(PCB)'{
				tsset id2 year
					
				sum statefips if id2==`t2'
				loc st_pcb = r(mean)
				sum a if id2==`t2'
				loc var = r(mean)
				
				display "Pol - `p' ; Out - `out' ; Treat - `st' ; Pcb_st - `st_pcb' ; Pcb_var - `var' ; pcb `t2' out of `=rowsof(PCB)'"
				display "Pol - `p' ; Out - `out' ; Treat - `st' ; Pcb_st - `st_pcb' ; Pcb_var - `var' ; pcb `t2' out of `=rowsof(PCB)'"
				display "Pol - `p' ; Out - `out' ; Treat - `st' ; Pcb_st - `st_pcb' ; Pcb_var - `var' ; pcb `t2' out of `=rowsof(PCB)'"
								
				local levels ""				/*Lags to be included*/
				local i = 0
				forvalues q = `imp1'(-1)`ref_date'{    //All the lags up to the begining of the sample or 20 lags
						if `i'<20{
							local levels "`levels' `out'(`q')"
						}
						loc ++i
					}
				di "`levels'"							
				tempfile SCM_`out'_id`t2'
				synth `out' `levels' `Xs', trunit(`t2') trperiod(`imp0') keep(`SCM_`out'_id`t2'')
				matrix RMSPE = e(RMSPE)	  
				mat Y=e(X_balance)
				mat Yt=Y[1...,1]
				mat Yc=Y[1...,2]
				mat rmse1=(Yt-Yc)'*(Yt-Yc)
				mat rmse1=rmse1/`=rowsof(Yt)'
					
				preserve	
					use `SCM_`out'_id`t2'', clear
					rename (_Y_treated _Y_synthetic _time) (`out'_treated `out'_synth year)
					
					gen `out'_pre_mn = `tr_pr_mn'
					gen `out'_pre_sd = `tr_pr_sd'
					gen `out'_treat_lev = `tr_pr_sd'*`out'_treated + `tr_pr_mn' 
					gen `out'_synth_lev = `tr_pr_sd'*`out'_synth + `tr_pr_mn' 	
					qui gen tr_eff = `out'_treat_lev - `out'_synth_lev
					
					qui gen RMSPE = RMSPE[1,1]	
					qui gen statefips= `st'
					qui gen id = `t2'
					qui gen state_ctrl = `st_pcb'
					qui gen a = `var'
					qui gen year_pcb = `imp0'
					qui gen tt_treat_pcb = year-year_pcb
					qui drop if tr_eff==.
					order id statefips state_ctrl a year year_pcb tt_treat_pcb
					
					order id statefips
					line `out'_treat_lev  `out'_synth_lev  year 
					drop _Co_Number _W_Weight
					gsort tt_treat_pcb
					tempfile pcb_`t2'
					save 	`pcb_`t2''					
				restore	
			} //Placebos
		} //If statement	
		************
		use `pcb_1', clear			
		forvalues t2=2/`=rowsof(PCB)'{
			capture append using `pcb_`t2''
		}
		order id year tt_treat_pcb statefips tr_eff
		tempfile PCB_RRs_`t'
		save 	`PCB_RRs_`t''
		} //Treated Units
		use `PCB_RRs_1', clear
		forvalues t=2/`=rowsof(A)'{
			qui append using `PCB_RRs_`t''
		}
		save "$output/PCB_Estimation_`p'_`out'_treat.dta", replace
		loc v = `v'+1
	} // Outcome Loop
} // Policy Loop

log close