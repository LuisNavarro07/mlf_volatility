
loc i = 1 
use "${tem}\scm_append.dta", clear
drop _Co_Number _W_Weight treat_lev synth_lev tr_eff fileid
keep if treated!=.
keep if id == `i' 



append using "${tem}\placebos_append_v2.dta"

keep if wofd>=`=tw(2019w36)' & wofd<=`=tw(2020w36)'
drop tr_unit
keep if cohend==. | cohend <= 0.25

gegen idd = group(id) if id > 8

gen tr_eff0 = treated - synth

qui tab idd, matrow(PCB)
 
	local smoke ""
	forvalues b = 1/`=rowsof(PCB)'{
		local smoke "`smoke' line tr_eff0 wofd if idd==`b', lc(gs13%80) lw(vthin) ||"
	}

di "`=rowsof(PCB)'"
di "`=rowsof(PCB)'"
di "`=rowsof(PCB)'"	
gr two ///
		line tr_eff0 wofd if id ==`i', lc(black gs10) || ///
		`smoke' ///
		line tr_eff0 wofd if id ==`i', lc(black gs10) ///
		, leg(off) xline(`=tw(2020w13)')
		
sum tr_eff0, d		

gen 	outlier = tr_eff0>1 
gegen 	outlier2 = total(outlier), by(id)

bysort id: gen cnt_id=_n==1
tab outlier2 cnt_id
	
carryforward pre_mn, replace 
carryforward pre_sd, replace