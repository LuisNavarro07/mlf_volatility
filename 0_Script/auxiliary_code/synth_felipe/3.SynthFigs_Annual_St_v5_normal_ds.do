*********************************************************************************
*** This file creates the final figures from the synth files
***   	_v1 on its own series
***   	_v2 on other series as pcb as well
***		_v3 policies coded on _v2
***		_v4 inverse hyperbolic sine transformation or normalize (line 75)
***			_ihs hiper transform  vs _normal 
***		_v5 V4 on final data from Haile.
***			_ds daily supply  vs _rt rates	vs _rx No Rx
*********************************************************************************
global policy "/N/project/gupta_S_09_2019/NIH_R01_ProjectExtract/"
global output "$policy/Results_ARCHIVE/Synth_Annual_v5_normal_ds/"
global scrp   "$policy/scripts/Synth"

capture log close
log using "$output/Regs_normal_ds_$S_DATE.smcl", replace
******************************************************************************* SYNTH --- Extensive Margin
********************************* File parameters
loc ref_date=2007  
loc end_date=2020
loc prew 	  "5"	
loc posw	  "6"	

loc pols "effMML effREC meddisp_leg meddisp_act active_dispREC mml_pass mml_legal mml_disp mml_hcult rec_pass rec_legal rec_disp rec_hcult"
loc pols "mml_pass mml_legal mml_disp mml_hcult effMML meddisp_leg meddisp_act"
loc Xs ""
loc outcomes "opioid_ds nsaid_ds op_ds anticon_ds antidep_ds benzo_ds z_drugs_ds barb_ds"

set scheme s2color
********************* LABELS
loc tit_opioid_ds 	"Opioid prescription"
loc tit_nsaid_ds  	"NSAID prescription"
loc tit_op_ds 		"Other pain prescription"
loc tit_anticon_ds 	"Anticonvulsant prescription"
loc tit_antidep_ds 	"Antidepressant prescription"
loc tit_benzo_ds 	"Benzodiazapine prescription"
loc tit_z_drugs_ds 	"Z-drug prescription"
loc tit_barb_ds		"Barbituates prescription"

loc pol_effMML            "MCL Effective"
loc pol_effREC            "RCL Effective"
loc pol_meddisp_leg       "Legal Medical Dispensary"
loc pol_meddisp_act 	  "Active Medical Dispensary"
loc pol_active_dispREC    "Active Recreational Dispensary"
*********************************************************************** Case Study DnD */
loc out "barb_Rxrt"
loc p 	"mml_pass" 

mat RRs= J(1,9,.)

local polN=1
foreach p of local pols{

local outN=1
*set trace on 
foreach out of local outcomes{
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		********************************************************************************** Link to outcome variable(s) 	
		cd "$policy/data"	//Carbonate-RED
		*cd "$data"		
		use "collapsed_state_year_rates_0720_vDec2021.dta", clear
		******************************************* Coded policies
		qui do "$scrp/SynthPolicyAnnual_St_coded.do"
			qui gen year_`p' = yofd(date_`p')
			qui gen pre_`p' = year_`p' - `ref_date'
			qui gen pos_`p' = `end_date' - year_`p'
			
			*Never treated
			qui g status 	   = 2 if year_`p'==.
			*Treated --> Ka and Kb bounds for states
			qui replace status = 1 if pre_`p'>=`prew' & pos_`p'>=`posw' & year_`p'!=.
			*Always treated based on more than 5 years of treatment
			qui replace status = 3 if pre_`p'<=0
			* Eliminate those with no enough pre nor post
			lab def stt 1 "Treated" 2 "Never Treated" 3 "Always Treated (no pre)"
			lab val statu stt
			qui tab status,m
			qui drop if status ==.
			qui drop if status ==3
		
			qui replace year_`p' = year_`p' + 1 if month(date_`p')==12 & day(date_`p')>10 
			qui gen TP = year>year_`p'
			qui gen tt_treat_`p'= year-year_`p'
		*******************************************
		merge 1:1 year statefips using "$output/Actual_Effects_`p'_`out'_opened.dta", nogen 
		labmask statefips, values(state_name)
		levelsof statefips, local(stts)
		local lbe : value label statefips
		tsset statefips year
		isid year statefips
		
		keep if status==1		
		capture rename RMSPE rmse1
		keep statefips year year_`p' tt_treat_`p' tr_eff  rmse1 `out' `out'_synth `out'_synth_lev status
		*keep statefips year year_`p' tt_treat_`p' tr_eff2 rmse2 `out' `out'_synth2 `out'_synth2_lev status
		
		preserve
			use "$output/PCB_Estimation_`p'_`out'_treat.dta", clear
			capture rename RMSPE rmse1
			keep statefips id tr_eff  tt_treat_pcb year rmse1
			*keep statefips id tr_eff2 tt_treat_pcb year rmse2 
			sum rmse1, d      //sum rmse2			
			keep if rmse1<=`=r(p95)'
			
			sort statefips id year
			bysort statefips id: gen newid=_n==1
			bysort statefips: replace newid=sum(newid)
			drop id
			rename newid id
			
			tempfile PCBs 
			save 	`PCBs'
		restore
		append using `PCBs'
		replace id = 10000 if status==1
		
		tab statefips if status==1, matrow(A)
		loc s = 6		
		forvalues s=1/`=rowsof(A)'{
			loc st = A[`s',1] 
			local f`st' : label `lbe' `st' 
		
			qui sum year_`p' if statefips==`st'
			loc impl=r(mean)			
			qui sum tt_treat_`p' if statefips==`st'
		*bsln		
			sum `out' if statefips==`st' & (tt_treat_`p'<0) & (tt_treat_`p'>=-`prew')
			loc bsln = r(mean)
			di "`bsln'"
			
			qui g TP = (year>=`impl') & statefips==`st' & status==1
			
			*Real Effect
			di "`p' -- `out' -- T=`f`st''(`st'); `s'/`=rowsof(A)'"
			di "`p' -- `out' -- T=`f`st''(`st'); `s'/`=rowsof(A)'"
			di "`p' -- `out' -- T=`f`st''(`st'); `s'/`=rowsof(A)'"
			capture noisily reghdfe tr_eff TP if statefips==`st', a(id year) vce(cluster id)
			if _rc!=2001{
				mat T = r(table)
				mat RR=`polN', `outN', `st', `bsln', T["b","TP"], T["se","TP"],T["pvalue","TP"]
				mat Bpcb=T["b","TP"]
				drop TP
				*PCB - Effs		
				qui tab id if status!=1 & statefips==`st', matrow(PCB)
				forvalues pcb=1/`=rowsof(PCB)'{
					qui g TP = (year>=`impl') & statefips==`st' & id==`pcb'
					qui reghdfe tr_eff TP if statefips==`st' & status!=1, a(id year) vce(cluster id)
					mat Bpcb = Bpcb \ _b[TP] 
					drop TP
				}
				preserve
					clear
					svmat Bpcb
					gen Reff=Bpcb1[1]
					sort Bpcb1		
					g ptile = 100 * _n/(_N)
					sum ptile if Bpcb1==Reff //The real coeff is greater than XX % of the distribution
					mat RR = RR, r(mean)
					sum Bpcb1
					mat RR = RR, r(sd)					
				restore
				mat RRs = RRs \ RR	
			} // no obs capture			
		} //Treated States				
	local ++outN 	
} // Outcome Loop	
mat list RRs
cd "$output/Figs/"
local ++polN
} // Policy Loop
clear 
svmat RRs
drop if RRs1==.

save "$output/FinalEffects_test_normal_ds_$S_DATE.dta", replace

log close


