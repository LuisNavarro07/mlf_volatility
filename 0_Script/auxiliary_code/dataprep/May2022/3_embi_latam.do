/// Import EMBI Data 
/// Source: https://www.invenomica.com.ar/riesgo-pais-embi-america-latina-serie-historica/
import excel "${raw}\Serie_Historica_Spread_del_EMBI.xlsx", sheet("Serie Histórica") cellrange(A2:V3586) firstrow case(lower) clear 
drop v
gen date = date(fecha, "DMY", 2050)
format date %td
drop fecha 
order date 
gen yr = year(date)
drop if yr < 2019 
drop if yr > 2020
drop if date == . 
destring _all, replace 
rename (méxico perú panamá) (mexico peru panama)
global embis global latino repdom argentina bolivia brasil chile colombia costarica ecuador elsalvador guatemala honduras mexico paraguay peru panama uruguay venezuela rdlatino

label variable global "EMBI Global"
label variable latino "EMBI Latino"
label variable repdom "EMBI Dominican Republic"
label variable argentina "EMBI Argentina"
label variable bolivia "EMBI Bolivia"
label variable brasil "EMBI Brazil"
label variable chile "EMBI Chile"
label variable colombia "EMBI Colombia"
label variable costarica "EMBI Costa Rica"
label variable ecuador "EMBI Ecuador"
label variable elsalvador "EMBI El Salvador"
label variable guatemala "EMBI Guatemela"
label variable honduras "EMBI Honduras"
label variable mexico "EMBI Mexico"
label variable paraguay "EMBI Paraguay"
label variable peru "EMBI Peru"
label variable panama "EMBI Panama"
label variable uruguay "EMBI Uruguay"
label variable venezuela "EMBI Venezuela"
label variable rdlatino "EMBI RD Latino"

local varlist $embis
foreach var of local varlist {
	rename `var' embi_`var'
}



save "${tem}\embi_latam.dta", replace 