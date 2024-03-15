import excel "${raw}\sp_state_yields.xlsx", first clear 
local varlist Alabama Alaska Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada NewHampshire NewJersey NewMexico NewYork NorthCarolina NorthDakota Ohio Oklahoma Oregon Pennsylvania RhodeIsland SouthCarolina SouthDakota Tennessee Texas Utah Vermont Virginia Washington WestVirginia Wisconsin Wyoming
local i = 1 
foreach var of local varlist {
    rename `var' v`i'
	local name`i' = "`var'"
	local i = `i' + 1
}

reshape long v, i(Date) j(st)
gen name = ""

forvalues i=1(1)50{
replace name = "`name`i''" if st == `i'
}

gen yr = year(Date)
drop if yr < 2019
drop if yr == 2021
rename Date date 
rename v yield
rename st sec_id
preserve 
gcollapse (mean) sec_id, by(name)
save "${tem}\state_names.dta",replace 
restore 


keep date yield sec_id name 
save "${tem}\spyields.dta", replace 