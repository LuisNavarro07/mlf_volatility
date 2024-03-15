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

global policy "C:\Users\fal20381\Dropbox\MCLs_Labor\data\Medical Cannabis Policy Files\OPTIC\SYNTH"
global data   "$policy\Data"
global output "$policy\Red_RRs_v5_normal_ds/Regs/"	
global scrp   "$policy/ScriptsRED"	

capture log close
log using "$output/RegsTb_normal_ds_$S_DATE.smcl", replace
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
loc tit_1	"Opioid Daily Supply"
loc tit_2	"NSAID Daily Supply"
loc tit_3	"Other pain Daily Supply"
loc tit_4 	"Anticonvulsant Daily Supply"
loc tit_5 	"Antidepressant Daily Supply"
loc tit_6	"Benzodiazapine Daily Supply"
loc tit_7 	"Z-drug Daily Supply"
loc tit_8	"Barbituates Daily Supply"	

lab def pols 1 "MML Passing" 2 "MML Legal" 3 "MML Dispensary" 4 "MML Home Cult." 5 "OPTIC Effect." 6 "OPTIC Disp. Active" 7 "OPTIC Disp. Legal", modify
*********************************************************************** Case Study DnD *
*loc out "barb_rate"
*loc p 	"mml_disp" 


use "$output/FinalEffects_test_normal_ds_$S_DATE.dta", replace

rename (RRs1 RRs2 RRs3 RRs4 RRs5 RRs6 RRs7 RRs8 RRs9)(Pol Out St MeanPre Eff std pval1 pval2 StdErr)
lab val Pol pols 
statastates, f(St) 
keep if _merge==3
drop _merge

label var Eff ""
label var StdErr ""
label var pval2 "" 

local out = 1
forvalues out=1/8{
preserve	
	keep if Out==`out'
	sort Pol St
	
	loc p = 1
	tab St if Pol==`p', matrow(S)
	labmask St, val(state_abb)
	replace pval2=pval2/100
	
	forvalues p=1/7{
		estpost tabstat Eff StdErr pval2 MeanPre if Pol==`p', by(St) 
		estimates store m`p'
	}	
	
	esttab m1 m2 m3 m4 m5 m6 m7, cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))")  ///
		unstack noobs  mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home C."  ///
		"OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") title("MML Effect over `tit_`out''")

	esttab m1 m2 m3 m4 m5 m6 m7 using "$output/Table_`tit_`out''.csv", replace ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))")  ///
		unstack noobs  mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home C."  ///
		"OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") ///
		title("MML Effect over `tit_`out'' - Complete")
		
	esttab m1 m2 m3 m4 using "$output/Table_`tit_`out''.csv", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home Cult.") title("MML Effect over `tit_`out''")
		
	esttab m5 m6 m7 using "$output/Table_`tit_`out''.csv", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit("OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") title("MML Effect over `tit_`out''")
		
	
	esttab m1 m2 m3 m4 m5 m6 m7 using "$output/Table_`tit_`out''.tex", replace ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))")  ///
		unstack noobs  mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home C."  ///
		"OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") ///
		title("MML Effect over `tit_`out'' - Complete")
		
	esttab m1 m2 m3 m4 using "$output/Table_`tit_`out''.tex", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home Cult.") title("MML Effect over `tit_`out''")
		
	esttab m5 m6 m7 using "$output/Table_`tit_`out''.tex", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit("OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") title("MML Effect over `tit_`out''")

		
	esttab m1 m2 m3 m4 m5 m6 m7 using "$output/Table_`tit_`out''.rtf", replace ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))")  ///
		unstack noobs  mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home C."  ///
		"OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") ///
		title("MML Effect over `tit_`out'' - Complete")
		
	esttab m1 m2 m3 m4 using "$output/Table_`tit_`out''.rtf", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit( "MML Passing"  "MML Legal"  "MML Dispens."  "MML Home Cult.") title("MML Effect over `tit_`out''")
		
	esttab m5 m6 m7 using "$output/Table_`tit_`out''.rtf", append ///
		cells("Eff(fmt(a4))" "StdErr(fmt(a4) par( ( ) ))" "pval2(fmt(a4))" "MeanPre(fmt(a4))") unstack noobs   ///
		mtit("OPTIC Effect."   "OPTIC Disp. Active"  "OPTIC Disp. Legal") title("MML Effect over `tit_`out''")		
restore		
}	

log close q























