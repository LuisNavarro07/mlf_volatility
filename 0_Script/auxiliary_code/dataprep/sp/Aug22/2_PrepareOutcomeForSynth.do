********************************************************************************
********************************************************************************
*** Project: Volatility in the Municipal Bond Market and the MLF 
*** Authors: Felipe Lozano & Luis Navarro 
*** Code by: Luis Navarro 
*** Script: Prepare Data for Synthetic Control 
*** This Update: September 2022 
********************************************************************************
********************************************************************************

/// Merge the Data
use "${tem}\secondary_rating.dta", clear 
/// All Municipal Market 
merge 1:1 date using "${tem}\secondary_fullmkt.dta", keep(match master) nogen 
*merge 1:1 date using "${tem}\fred_clean.dta", keep(match master) nogen 
drop  parnr par3a par2a para par3b par_muni_market yr
global fred BAMLH0A0HYM2EY BAMLC0A4CBBBEY BAMLH0A3HYCEY BAMLH0A1HYBBEY BAMLH0A2HYBEY BAMLC0A1CAAAEY BAMLC0A2CAAEY BAMLC0A0CMEY BAMLC0A3CAEY BAMLC1A0C13YEY BAMLC4A0C710YEY BAMLC8A0C15PYEY BAMLC2A0C35YEY BAMLC3A0C57YEY BAMLC7A0C1015YEY BAMLEM2RBBBLCRPIUSEY BAMLEM1RAAA2ALCRPIUSEY BAMLEM3RBBLCRPIUSEY BAMLEMCLLCRPIUSEY BAMLEMALLCRPIASIAUSEY BAMLEMHGHGLCRPIUSEY BAMLEMHYHYLCRPIUSEY BAMLEMFLFLCRPIUSEY BAMLEMELLCRPIEMEAUSEY BAMLEMLLLCRPILAUSEY BAMLEMUBCRPIUSEY OBMMIUSDA30YF OBMMIC30YFNA DJIA WILLREITIND WILLSMLCAP WILLLRGCAP WILLMICROCAP WILLMIDCAP WILLSMLCAPVALPR WILLRESIND WILLMIDCAPVAL WILLMIDCAPGR OBMMIJUMBO30YF OBMMIC30YFLVLE80FGE740 OBMMIC30YF OBMMIFHA30YF OBMMIVA30YF OBMMIC30YFLVGT80FGE740 OBMMIC30YFLVGT80FB720A739 OBMMIC15YF OBMMIC30YFLVGT80FLT680 OBMMIC30YFLVLE80FB700A719 OBMMIC30YFLVLE80FB720A739 OBMMIC30YFLVGT80FB700A719 OBMMIC30YFLVLE80FLT680 OBMMIC30YFLVLE80FB680A699 OBMMIC30YFLVGT80FB680A699 VXVCLS VXOCLS VXNCLS yield_muni_market CBBTCUSD CBETHUSD CBLTCUSD CBBCHUSD 
global fred1 BAMLHE00EHYIEY BAMLEMHBHYCRPIEY BAMLEMPBPUBSICRPIEY BAMLEMCBPIEY BAMLEMRACRPIASIAEY BAMLEMRLCRPILAEY BAMLEM3BRRBBCRPIEY BAMLEM2BRRBBBCRPIEY BAMLEM4RBLLCRPIUSEY BAMLEM4BRRBLCRPIEY BAMLEMEBCRPIEEY BAMLEMRECRPIEMEAEY BAMLEM1BRRAAA2ACRPIEY BAMLEMFSFCRPIEY BAMLEM5BCOCRPIEY BAMLEMNSNFCRPIEY BAMLEMPTPRVICRPIEY VIXCLS GVZCLS VXFXICLS OVXCLS RVXCLS VXEEMCLS VXSLVCLS VXDCLS EVZCLS VXXLECLS VXAZNCLS VXEWZCLS VXAPLCLS VXGDXCLS VXGOGCLS VXGSCLS VXIBMCLS SP500 WILL5000INDFC NASDAQCOM NASDAQ100 WILL5000IND DJTA DJCA DJUA WILL2500INDGR WILL4500IND WILL2500INDVAL WILL2500IND DTWEXAFEGS DTWEXEMEGS
drop $fred $fred1
merge 1:1 date using "${tem}\embi_latam.dta", keep(match master) nogen 
merge 1:1 date using "${tem}\bloombergprices_clean.dta", keep(match master) nogen

/// Drop Aggregated Variables 
drop embi_rdlatino embi_global embi_latino

drop yr
label variable yieldnr "Not Rated"
label variable yield3a "AAA Bonds"
label variable yield2a "AA Bonds"
label variable yielda "A Bonds"
label variable yield3b "BBB Bonds"

global all_variables yieldnr yield3a yield2a yielda yield3b DEXUSEU DEXCHUS DEXJPUS DEXKOUS DEXUSUK DEXMXUS DEXCAUS DEXINUS DEXBZUS DEXUSAL DEXVZUS DEXTHUS DEXSFUS DEXSZUS DEXMAUS DEXHKUS DEXNOUS DEXSIUS DEXTAUS DEXSDUS DEXUSNZ DEXSLUS DEXDNUS DCOILWTICO DCOILBRENTEU DHHNGSP DPROPANEMBTX DDFUELUSGULF DHOILNYH DJFUELUSGULF DGASUSGULF DDFUELNYH DGASNYH DDFUELLA DRGASLA embi_repdom embi_argentina embi_bolivia embi_brasil embi_chile embi_colombia embi_costarica embi_ecuador embi_elsalvador embi_guatemala embi_honduras embi_mexico embi_paraguay embi_peru embi_panama embi_uruguay embi_venezuela ctjmd10ygovt ctmxn10ygovt ctchf10ygovt ctclp10ygovt spxindex ftsemibindex induindex mexbolindex ctsek10ygovt clacomdty coacomdty coalinequity xb1comdty ng1comdty gc1comdty si1comdty hg1comdty xptusdcurrncy cc1comdty lc1comdty ho1comdty qs1comdty rr1comdty sm1comdty bo1comdty rs1comdty kc1comdty jo1comdty lb1comdty or1comdty dl1comdty fc1comdty lh1comdty ctfrf9ygovt ctgrd20ygovt ctiep3ygovt ctnok3ygovt ctczk3ygovt ctdkk3ygovt ctdkk5ygovt ctbef3ygovt ctdemii5y ctbrl5ygovt ctbrlii30tgovt ctbrl3ygovt ctnzd5ygovt ctpln2ygovt cteurlt2ygvot ctzar10ygovt ctgbpii5ygovt ctgbp10ygovt ctlvl2ygovt cteurro6ygovt daxindex cacindex aexindex ibexindex omxindex smiindex bsxindex igpaindex buxindex rtsiindex saxindex kse100index nse200index hisindex kospiindex sensexindex as51index atxindex aseindex bel20index omxc25index hexindex icexiindex croxindex ctxeurindex rotxlindex utxeurindex

local varlist ${all_variables}
foreach i of local varlist {
local a : variable label `i'
local a: subinstr local a "U.S. Dollar " "USD "
label var `i' "`a'"

local a : variable label `i'
local a: subinstr local a "Spot Exchange Rate" ""
label var `i' "`a'"

}

/// Volatility Indices
global vix GVZCLS VXVCLS VXFXICLS OVXCLS RVXCLS VXEEMCLS VXSLVCLS VXDCLS EVZCLS VXXLECLS VXAZNCLS VXEWZCLS VXAPLCLS VXGDXCLS VXGOGCLS VXGSCLS VXIBMCLS

/// Save the Dataset in Levels - The Yields
save "${tem}\financial_market_yields.dta", replace 

/// Describe the Variables 
describe $all_variables
descsave $all_variables, saving("${tem}\varnames.dta", replace)

preserve 
use "${tem}\varnames.dta", clear
keep order name varlab 
gen sec_id = order + 1
drop order 
sum sec_id
save "${tem}\varnames.dta", replace 
restore 





********************************************************************************
/// To use the synth package the data needs to be in a panel structure where each unit is a financial instrument. Oh boy, we need to reshape this stuff carefully. 
/// First, lets rename the securities 
use "${tem}\financial_market_yields.dta", clear 
describe 


local varlist $all_variables
local i = 2
foreach var of local varlist {
	global name`i' =  "`var'"
	rename `var' var`i'
	local i = `i' + 1
}

reshape long var, i(date) j(sec_id)
tsset sec_id date 
label values sec_id
rename var yield 

sum sec_id
global max = r(max)


/// Drop missings 
drop if sec_id == 2
drop if date == td(06may2019)
sort sec_id date
/// Compute Min Max and Range Across Weeks
/// Gen week variable 
gen dow = dow(date)
gen wofd= wofd(date + 1)
format wofd %tw


/// Create Variance Variables 
gen min = yield 
gen max = yield 
gen sd = yield 

/// Collapse at the weekly levels 
gcollapse (mean) yield (min) min (max) max (sd) sd, by(wofd sec_id)
sort sec_id wofd 
/// Merge with varlabs 
merge m:1 sec_id using "${tem}\varnames.dta", keep(match master) nogen 
gen range = max - min 


save "${cln}\financial_market_volatility.dta", replace 

*********************************************************************************
/// Prepare Everything for the Synth 
/// Save The File for Regressions 
use "$cln/financial_market_volatility.dta", clear
*** Making sure the data are balanced on the outcomes
drop if wofd<=`=tw(2019,12)'
drop if wofd==`=tw(2021,1)' 
/*capture // we identified sec_id 3 (AA) & 4 (A) with missing values. 
	drop if sd==.
	bysort sec_id: gen cnt=_N
	tab cnt
restore*/
/// Donors recieve a sec_id > 1000 
tsset sec_id wofd
replace sec_id = 		sec_id-1 if sec_id<=6 
replace sec_id = 1000 +	sec_id-5 if sec_id>6  

/// Assumptions -- 
/// Drop stock indices 
drop if sec_id >= 1058 & sec_id <= 1061
drop if sec_id > 1106
/// Drop Venezuela 
drop if sec_id ==1012
drop if sec_id ==1053
/// Drop Oil 
drop if sec_id ==1029 | sec_id == 1033 | sec_id == 1035
drop if sec_id ==1025 | sec_id == 1026 |sec_id == 1063 

/// Reshape the data into a long format. Each row is a security-vol measure
rename (sd range)(v1 v2)
keep sec_id wofd v*
greshape long v, i(sec_id wofd) j(sertype)	
sort sec_id sertype wofd
/// Create Unique Ids. 
gegen id = group(sec_id sertype)
gen status = sec_id<1000
order id status sec_id sertype 

/// Store the Varnames 
preserve 
replace varlab = varlab + " (SD)" if sertype == 1 
replace varlab = varlab + " (Range)" if sertype == 2 
keep id varlab
duplicates drop id, force 
encode varlab, gen(des)
save "${tem}\varnames.dta", replace 
restore 

/// Assumption: Turn everything into monthly data 
gen td = dofw(wofd)
gen mofd = mofd(td)
format mofd %tmMon_CCYY
drop wofd td 
/// Collapse to Month  
gcollapse (mean) v , by(mofd id status sertype sec_id varlab)
/// Rename the variable month as week to make the code works 
/// DO NOT GET CONFUSED 


save "${tem}\TheFile.dta", replace 

exit 