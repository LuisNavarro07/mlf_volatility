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

*global policy "C:\Users\fal20381\Dropbox\MCLs_Labor\data\Medical Cannabis Policy Files\OPTIC\SYNTH"
*global data   "$policy\Data"
*global output "$policy\Red_RRs_v5_normal_ds"	
*global scrp   "$policy/ScriptsRED"	

capture log close
log using "$output/Figs/Figs_normal_ds_$S_DATE.smcl", replace
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
loc tit_benzo_ds 		"Benzodiazapine prescription"
loc tit_z_drugs_ds 	"Z-drug prescription"
loc tit_barb_ds		"Barbituates prescription"	

loc pol_effMML            "MCL Effective"
loc pol_effREC            "RCL Effective"
loc pol_meddisp_leg       "Legal Medical Dispensary"
loc pol_meddisp_act 	  "Active Medical Dispensary"
loc pol_active_dispREC    "Active Recreational Dispensary"
/*
loc sct_opioid_ds_effMML  	"-20 -0.2 20 -0.2"	
loc sct_nsaid_ds_effMML  		"-20 -0.2 20 -0.2"
loc sct_op_ds_effMML 			"-5  -0.2  5 -0.2"
loc sct_anticon_ds_effMML 	"-10 -0.2 10 -0.2"
loc sct_antidep_ds_effMML 	"-20 -0.2 20 -0.2"
loc sct_benzo_ds_effMML 		"-10 -0.2 10 -0.2"
loc sct_z_drugs_ds_effMML 	"-10 -0.2 10 -0.2"
loc sct_barb_ds_effMML 		"-.5 -0.2 .5 -0.2"

loc sct_opioid_ds_meddisp_leg  "-20 -0.2 20 -0.2"	
loc sct_nsaid_ds_meddisp_leg   "-20 -0.2 20 -0.2"
loc sct_op_ds_meddisp_leg	 	 "-5  -0.2  5 -0.2"
loc sct_anticon_ds_meddisp_leg "-10 -0.2 10 -0.2"
loc sct_antidep_ds_meddisp_leg "-20 -0.2 20 -0.2"
loc sct_benzo_ds_meddisp_leg	 "-10 -0.2 10 -0.2"
loc sct_z_drugs_ds_meddisp_leg "-10 -0.2 10 -0.2"
loc sct_barb_ds_meddisp_leg	 "-.5 -0.2 .5 -0.2"

loc sct_opioid_ds_meddisp_act  "-20 -0.2 20 -0.2"	
loc sct_nsaid_ds_meddisp_act   "-20 -0.2 20 -0.2"
loc sct_op_ds_meddisp_act 	 "-5  -0.2  5 -0.2"
loc sct_anticon_ds_meddisp_act "-10 -0.2 10 -0.2"
loc sct_antidep_ds_meddisp_act "-20 -0.2 20 -0.2"
loc sct_benzo_ds_meddisp_act   "-10 -0.2 10 -0.2"
loc sct_z_drugs_ds_meddisp_act "-10 -0.2 10 -0.2"
loc sct_barb_ds_meddisp_act    "-.5 -0.2 .5 -0.2"
*********************************************************************** Case Study PLOTS */
loc out "opioid_ds"
loc p 	"mml_pass" 

foreach p of local pols{
cd "$output/Figs/"
capture putpdf clear
putpdf begin, landscape halign(center)
putpdf paragraph

foreach out of local outcomes{
		capture graph close _all
		capture graph drop  _all
		
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		di "About to start policy `p' and outcome `out'"
		********************************************************************************** Link to outcome variable(s) 	
		cd "$policy/data"
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
			tab status,m
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
 	
		preserve
			use "$output/PCB_Estimation_`p'_`out'_treat.dta", clear
			capture rename RMSPE rmse1
			*keep statefips id tr_eff  tt_treat_pcb year rmse1
			keep statefips id tr_eff tt_treat_pcb year rmse1 
			sum rmse1, d      //sum rmse2			
			keep if rmse1<=`=r(p95)'
			tab statefips, matrow(T)
			
			sort statefips id year
			bysort statefips id: gen newid=_n==1
			bysort statefips: replace newid=sum(newid)
			drop id
			rename newid id
			
			sort statefips tt_treat_pcb tr_eff
			bysort statefips tt_treat_pcb: gen ctile=100*_n/_N if tt_treat_pcb!=.
			
			gen   dist_lb95=abs(ctile-2.5)			
			gegen mind_lb95=min(dist_lb95), by(statefips tt_treat_pcb)
			gen	bound=3 if dist_lb95==mind_lb95
			
			gen   dist_up95=abs(ctile-97.5)			
			gegen mind_up95=min(dist_up95), by(statefips tt_treat_pcb)
			replace bound=4 if dist_up95==mind_up95
		
			gen   dist_lb90=abs(ctile-5)			
			gegen mind_lb90=min(dist_lb90), by(statefips tt_treat_pcb)
			replace bound=1 if dist_lb90==mind_lb90
			
			gen   dist_up90=abs(ctile-95)			
			gegen mind_up90=min(dist_up90), by(statefips tt_treat_pcb)
			replace bound=2 if dist_up90==mind_up90
			
			bysort statefips tt_treat_pcb bound: replace bound=. if _n!=1
			
			tab statefips bound 
			
			drop ctile*
			sort statefips id year
			
			tempfile PCBs 
			save 	`PCBs'
		restore
		append using `PCBs'
		
		
		tab statefips if status==1, matrow(A)		
		loc s = 3
		loc CombRaw ""
		loc CombPcb ""
			forvalues s=1/`=rowsof(A)'{
			loc st = A[`s',1] 
			local f`st' : label `lbe' `st' 
			
			qui sum year_`p' if statefips==`st'
			loc impl=r(mean)
			
			qui sum tt_treat_`p' if statefips==`st'
			loc strt = r(min)
			loc end  = r(max) 
			
			qui tab id if statefips==`st', matrow(PB)
			local smoke ""
			forvalues b = 1/`=rowsof(PB)'{
				local smoke "`smoke' line tr_eff tt_treat_pcb if statefips==`st' & id==PB[`b',1], lc(gs13%80) lw(vthin) ||"
			}
			
			loc c=4
			if `=rowsof(A)'<=6{
				loc c = 3
			}
			
			gr two ///
				line tr_eff tt_treat_`p' if statefips==`st' & id==., lc(black gs10) xlabel(`strt'(1)`end', labsize(vsmall)) xaxis(1)  ||  ///
				line tr_eff tt_treat_pcb if statefips==`st' & bound==3, sort lc(navy) lp(dash) || ///
				line tr_eff tt_treat_pcb if statefips==`st' & bound==4, sort lc(navy) lp(dash) || ///
				scatteri 0 `ref_date' 0 `end_date', c(l) m(i) lc(maroon) xlabel(2007(3)2020, labsize(vsmall) axis(2)) xaxis(2) || ///				
				`smoke' ///
				line tr_eff tt_treat_pcb if statefips==`st' & bound==1, sort lc(navy) lp(dash) || ///
				line tr_eff tt_treat_pcb if statefips==`st' & bound==2, sort lc(navy) lp(dash) || ///
				line tr_eff year 		 if statefips==`st' & id==., lc(black gs10) xlabel(`ref_date'(3)`end_date', labsize(vsmall) axis(2)) xaxis(2)  ///	
				xline(0, lp(solid) lc(maroon)) xline(-5, lp(dash) lc(maroon)) xline(6, lp(dash) lc(maroon))  graphregion(color(white))  ylab(, labsize(vsmall)) ///
				xti("",axis(2)) xti("Years to/from treatment",axis(1) size(vsmall)) subti("`f`st''") ///
				yti("Daily Supply", size(vsmall)) ///
				leg(order(1 3 5 -1) label(1 "Treatment") label(3 "90/95 C.I.") label(5 "Placebo Effects") ///
					pos(6) ring(1) size(small) cols(3) region(lstyle(none))) ///
				name(TrPcb_`out'_`st', replace)	note(,size(small))	 	
			loc CombPcb "`CombPcb' TrPcb_`out'_`st'"
			
			
			gr two ///
				line `out' /*`out'_synth*/ `out'_synth_lev tt_treat_`p' if statefips==`st', lc(black gs10) xlabel(`strt'(1)`end', labsize(vsmall)) xaxis(1)  ||  ///
				line `out' /*`out'_synth*/ `out'_synth_lev year 		 if statefips==`st', lc(black gs10) xlabel(2007(3)2020, labsize(vsmall) axis(2)) xaxis(2) ///
				xline(0, lp(solid) lc(maroon)) xline(-5, lp(dash) lc(maroon)) xline(6, lp(dash) lc(maroon))  graphregion(color(white))  ylab(, labsize(vsmall)) ///
				xti("",axis(2)) xti("Years to/from treatment",axis(1) size(vsmall)) subti("`f`st''") ///
				yti("Daily Supply", size(vsmall)) ///
				leg(order(1 2) label(1 "Real") label(2 "Synthetic") pos(6) ring(1) size(small) cols(2) region(lstyle(none))) ///
				name(Raw_`out'_`st', replace)	
			loc CombRaw "`CombRaw' Raw_`out'_`st'"	
			}	
			di "`CombRaw'"
			grc1leg `CombRaw', graphregion(color(white)) subtitle("`tit_`out''")  cols(`c') name(Raw, replace)
			graph display Raw, ysize(20) xsize(25)
			gr export "$output/Figs/TrRaw_`p'_`out'_states.pdf", replace			
			gr export "$output/Figs/TrRaw_`p'_`out'_states.png", replace
			putpdf image "$output/Figs/TrRaw_`p'_`out'_states.png", linebreak width(25)
				
			
			di "`CombPcb'"	
			grc1leg `CombPcb', graphregion(color(white)) subtitle("`tit_`out''")  cols(`c') name(Pcbo, replace)
			graph display Pcbo, ysize(20) xsize(25)
			gr export "$output/Figs/TrPcb_`p'_`out'_states.pdf", replace
			gr export "$output/Figs/TrPcb_`p'_`out'_states.png", replace
			putpdf image "$output/Figs/TrPcb_`p'_`out'_states.png", linebreak width(25)
		
} // Outcome Loop	
cd "$output/Figs/"
putpdf save Results_`p'.pdf, replace
} // Policy Loop
log close


/*
grc1leg  Raw_opioid_ds_9 Raw_opioid_ds_17 Raw_opioid_ds_24 Raw_opioid_ds_25 Raw_opioid_ds_33 Raw_opioid_ds_36, graphregion(color(white)) subtitle("`tit_`out''")  cols(3) name(Raw, replace)
graph display Raw, ysize(15) xsize(25)