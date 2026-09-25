*
* Tica, Arčabić, Viljevac
* Output gap and model uncertainty
*
* This file download employment, unemployment and inflation data from Eurostat 
*
* Eurostat has historical employment and unemployment until 2020, and new series afterward, which does not include the UK. We simply merge historical and new series
*
* Download employment
eurostatuse lfsi_emp_q , clear long noflags save geo(BE BG CZ DK DE EE IE EL ES FR HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE) keepdim(Y15-64; EMP_LFS; SA; T; PC_POP) start() end() 
* Download historical employment
eurostatuse lfsi_emp_q_h , clear long noflags save geo(BE BG CZ DK DE EE IE EL ES FR FX HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE UK) keepdim(Y15-64; EMP_LFS; SA; T; PC_POP) start() end() 
* Download unemployment
eurostatuse une_rt_q, clear long noflags save geo(BE BG CZ DK DE EE IE EL ES FR HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE) keepdim(Y15-74; SA; T; PC_POP) start() end() 
* Download historical unemployment
eurostatuse une_rt_q_h, clear long noflags save geo(BE BG CZ DK DE EE IE EL ES FR HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE UK) keepdim(Y15-74; SA; T; PC_POP) start() end() 
*
* Merge them all
*
use lfsi_emp_q_h, clear
encode geo, gen(country)
xtset country time
tsappend, add(9) 
drop geo
decode country, gen(geo)
*
merge 1:1 geo time using lfsi_emp_q, gen(_m_emp)
merge 1:1 geo time using une_rt_q, gen(_m_unemp)
merge 1:1 geo time using une_rt_q_h, gen(_m_unemp_h)

drop unit unit_label sex sex_label indic_em indic_em_label age age_label s_adj s_adj_label _m*

* append new series to historical
replace lfsi_emp_q_h = lfsi_emp_q if lfsi_emp_q_h ==.
replace une_rt_q_h   = une_rt_q   if une_rt_q_h   ==.
rename (lfsi_emp_q_h une_rt_q_h) (emp unemp)

drop lfsi_emp_q une_rt_q

save bus_cyc_databasev2_R1, replace
*
* Download OECD unemployment
sdmxuse data OECD, clear dataset(KEI) dimensions(LR+LRHUTTTT.AUT+BEL+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN+IRL+ITA+LVA+LTU+LUX+NLD+POL+PRT+SVK+SVN+ESP+SWE+GBR.ST.Q) start(1975) end(2023-01)
gen time2 = quarterly(time, "YQ")
format time2 %tq

kountry location, from(iso3c) to(iso2c) marker
rename _ISO2C_ geo
misstable summarize MARKER
drop subject location measure frequency time MARKER
rename time2 time
order geo time NAMES_STD value
sort geo time
replace geo="UK" if geo=="GB"
replace geo="EL" if geo=="GR"
save unemployment_oecd_R1, replace

use bus_cyc_databasev2_R1, clear
merge 1:1 geo time using unemployment_oecd_R1 , gen(_m)
drop _m
rename value unemp_oecd

gen unemployment_combined = unemp_oecd
replace unemployment_combined = unemp if unemployment_combined==.
replace unemployment_combined = unemp if geo=="EL" | geo=="LT" | geo=="LV" | geo=="SK"

rename unemp unemp_eurostat
rename unemployment_combined unemp_rate

xtline unemp_rate

save bus_cyc_databasev2_R1, replace


*
* INFLATION DOWNLOAD
*
* Eurostat only offers monthly data for CPI. 
*
*
clear all
* OECD inflation (just click cancel when asked for password)
getdata xt OECD_RESTR, ///
rest(PRICES_CPI/AUS+AUT+BEL+CAN+CHL+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN+ISL+IRL+ISR+ITA+JPN+KOR+LVA+LTU+LUX+MEX+NLD+NZL+NOR+POL+PRT+SVK+SVN+ESP+SWE+CHE+TUR+GBR+USA+ARG+BRA+CHN+COL+CRI+IND+IDN+RUS+SAU+ZAF.CPALTT01.GY.Q) ///
geo(LOCATION country) time(DATE quarter) frequency(q) datemask(YQ) varname(pi_oecd)  isocountrycodes(alpha2) merge(1:1)
*
save inf_R1.dta

* Harmonized CPI
eurostatuse prc_hicp_manr, clear long noflags save geo(BE BG CZ DK DE EE IE EL ES FR HR IT CY LV LT LU HU MT NL AT PL PT RO SI SK FI SE UK) keepdim(RCH_A; CP00) start() end() 

rename prc_hicp_manr pi_eurostat
*
gen quarterq = qofd(dofm(time))
format quarterq %tq
collapse (mean) pi_eurostat, by(geo quarterq)
rename geo country
merge 1:1 country quarterq using inf_R1.dta
sort country quarterq
*
keep if country=="EE" | country=="LV" | country=="IT" | country=="LU" | country=="LT" | country=="FR" | country=="RO" | country=="FI" | country=="GB" | country=="AT" ///
| country=="IE" | country=="MT" | country=="PT" | country=="DK" | country=="PL" | country=="SK" | country=="DE" | country=="SI" | country=="HU" | country=="ES" ///
| country=="HR" | country=="SE" | country=="GR" | country=="CZ" | country=="CY" | country=="NL" | country=="BG" | country=="BE"
replace country="UK" if country=="GB"
replace country="EL" if country=="GR"
*
* check countries with CPI data
graph bar (count) pi_eurostat, over(country, label(angle(vertical) labsize(small))) 
graph bar (count) pi_oecd, over(country, label(angle(vertical) labsize(small))) 
*
encode country, gen(Country)
xtset Country quarterq
*
tsfill, full
xtset Country quarterq
* This will simply copy country names to all xt observations
bysort Country: carryforward country, replace
gsort Country -quarterq
bysort Country: carryforward country, replace
sort Country quarterq
*
bysort country: egen eurostatcount = count(pi_eurostat)
bysort country: egen oecdcount = count(pi_oecd)
drop if eurostatcount == 0 & oecdcount == 0
*
by country: gen pi     = pi_oecd if oecdcount>=eurostatcount
by country: replace pi = pi_eurostat if eurostatcount>oecdcount
*
* generate GDP deflator inflation
*
xtline pi if quarterq>tq(1995q1), byopts(yrescale)
graph export "deflator_R1.png", as(png) replace
*
rename country geo
rename quarterq time
*
save inflation_R1, replace
*
use bus_cyc_databasev2_R1, clear
decode country, gen(Country)
drop geo
rename Country geo
merge 1:1 geo time using inflation_R1.dta, gen(merge_pi2)
sort geo time

drop country 
encode geo, gen(country)
order country time geo  
drop  quarter pi_eurostat pi_oecd eurostatcount oecdcount Country merge_pi merge_pi2 _merge

drop if time<tq(1975q1)
replace pi = . if geo=="LT" & time<tq(1997q1)
replace pi = . if geo=="LV" & time<tq(1997q1)
replace pi = . if geo=="PL" & time<tq(1997q1)
replace pi = . if geo=="SI" & time<tq(1997q1)

save bus_cyc_databasev2_R1, replace

