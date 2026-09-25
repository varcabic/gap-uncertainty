*
* Tica, Arčabić, Viljevac
* Output gap and model uncertainty
*
* This code downloads the most recent data on GDP from the Eurostat, combines it 
* with the OECD database, and reshapes the data into wide format in Excel
*
*
********************************************************************************
* Download the data
********************************************************************************

* Download GDP data from Eurostat
eurostatuse namq_10_gdp, clear long noflags save geo( EU28 EA19 BE BG CZ DK DE EE IE EL ES FR HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE UK) keepdim(CLV10_MEUR ; SCA ; B1GQ ) start() end()
rename namq_10_gdp gdp
save gdp_R1.dta, replace

* Import OECD data and save in .dta file
* Extended UK data from 1975q1 to 2023q1 is entirely taken from OECD
* Real GDP, 
* Gross domestic product - expenditure approach
* LNBQRSA: National currency, chained volume estimates, national reference year, quarterly levels, seasonally adjusted
* quarterly
import excel "Extended data import.xlsx", sheet("Sheet1") firstrow clear
gen time2 = quarterly(time, "YQ")
format time2 %tq
drop time
rename time2 time
save oecd_R1.dta, replace

* Merge all sources
use gdp_R1.dta, clear
merge 1:1 geo time using oecd_R1.dta, gen(mergeoecd)

* Add OECD data to extend the dataset
replace gdp=gdp_oecd if gdp==.
replace gdp=gdp_oecd if geo=="UK"
*
* Set the data as a panel
*
encode geo, gen(country)
xtset country time
tsfill, full
xtset country time

* Drop unnecessary variables
drop unit unit_label s_adj s_adj_label na_item na_item_label gdp_oecd mergeoecd 

save bus_cyc_database_R1.dta, replace
********************************************************************************
* Make graphs
********************************************************************************
use bus_cyc_database_R1.dta, clear

gen lgdp = log(gdp)
xtline lgdp,  byopts(yrescale title(GDP)  note("")) tline(`=tq(1995q1)') ytitle("") ttitle("") tlabel(#7, angle(90))  
graph export "data gdp_R1.png", replace

********************************************************************************
* Reshape the dataset to wide format and save in Excel
********************************************************************************
*
* GDP DATA
use bus_cyc_database_R1.dta, clear
keep geo time gdp
reshape wide gdp, i(time) j(geo) string
export excel using "Data - GDP_R1.xlsx", firstrow(variables) replace
*
* Unemployment data
use bus_cyc_databasev2_R1.dta, clear
keep unemp_rate time geo
reshape wide unemp_rate , i(time) j(geo) string
export excel using "Data - Unemployment_R1.xlsx", firstrow(variables) replace
*
* Employment data
use bus_cyc_databasev2_R1.dta, clear
keep geo time emp
reshape wide emp, i(time) j(geo) string
drop if time<=tq(1992q1)
export excel using "Data - Employment_R1.xlsx", firstrow(variables) replace
*
* Inflation data
use bus_cyc_databasev2_R1.dta, clear
xtline pi, byopts(yrescale)
keep geo time pi
drop if time==tq(2023q2)
reshape wide pi, i(time) j(geo) string
export excel using "Data - Inflation_R1.xlsx",  firstrow(variables) replace
*
* The End
*
