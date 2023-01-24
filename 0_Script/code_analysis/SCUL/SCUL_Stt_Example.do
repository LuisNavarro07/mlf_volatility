u "http://fmwww.bc.edu/repec/bocode/s/scul_basque.dta", clear

xtset
local lbl: value label `r(panelvar)'
stop 
loc unit ="Basque Country (Pais Vasco)":`lbl'


loc int_time = 1975

qui xtset
cls

g treat = cond(`r(panelvar)'==`unit' & `r(timevar)' >= `int_time',1,0)

*scul gdpcap, ahead(3) treat(treat)
 stop 
scul gdpcap, ahead(3) treat(treat) 

///
obscol(black) cfcol("170 19 15") legpos(11)



scul depvar [if], treated(varname)     [ahead(#) lambda(string) cv(string)
placebos sqerror(#) covs(varlist) scheme(string) intname(string)
rellab(#) obscol(string) cfcol(string) conf(string) legpos(#)
transform(string) before(#) after(#) obscol(string) cfcol(string)]