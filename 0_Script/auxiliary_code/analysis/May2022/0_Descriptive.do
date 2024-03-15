/// Description of Short Term vs Long Term
use "${tem}\statebondsfull.dta",clear  
gen matdays = datediff(IssueDate,Maturity,"day")
gen longterm = (matdays/365) > 1
replace AmtIssued = AmtIssued/1000000
encode CUSIP, gen(cusid)
gen yr = year(IssueDate)
tab longterm
tab yr longterm
table longterm, content(sum AmtIssued count cusid) format(%12.0fc)

//// Volatility Graphs 
use "${cln}\financial_market_volatility.dta", clear 
drop if wofd < tw(2019w13)
format wofd %twMon_CCYY

global graph_options ytitle("", size(vsmall)) ylabel(#10, nogrid labsize(vsmall) angle(0)) xlabel(#11, nogrid labsize(vsmall) angle(0)) xtitle("", size(small)) xlabel(, labsize(vsmall) angle(0) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor(white)) plotregion(color(white)) graphregion(color(white) margin(4 4 4 4)) plotregion(lcolor(black)) ytitle("") legend(on size(tiny) rows(1) cols(4) pos(6) region(lcolor(black) fcolor(white)))

/// Graph 1. Yield At Trade By Credit Rating
local tr_dt =tw(2020w13) 
local title3 "AAA Bonds"
local title4 "AA Bonds"
local title5 "A Bonds"
local title6 "BBB Bonds"
forvalues i=3(1)6{
twoway (line yield wofd if sec_id == `i' , lcolor(black) lwidth(thin)) (line range wofd if sec_id == `i', lcolor(cranberry) lwidth(thin)) (line sd wofd if sec_id == `i', lcolor(navy) lwidth(thin)), $graph_options legend(on order(1 "Yield" 2 "Range" 3 "SD")) title("`title`i''") name(graph`i', replace) xline(`tr_dt', lcolor(maroon) lpattern(dash) lwidth(thin))
}

grc1leg graph3 graph4 graph5 graph6, legendfrom(graph3) rows(2) cols(2) xcommon plotregion(lcolor(white)) plotregion(color(white)) graphregion(color(white) margin(4 4 4 4)) plotregion(lcolor(black)) name(combined1,replace)
graph export "${oup}\Graph1_StatBonds.png", $export