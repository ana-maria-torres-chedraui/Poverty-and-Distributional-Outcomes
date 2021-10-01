*Dofile elaborated by:

Clarissa Bruns, i6238772
Bram van Heteren, i6136380
Mohamed Sheikh,
Ana Maria Torres Chedraui, i6256049


***2011-2012 Data***
pwd 
cd "C:\Users\kurar\Documents\MPP\MPP4504 - PUBLIC POLICY ANALYSIS\Final Group Assignment"
use GSEC1_2011

*Drop unrelevant variables
drop day month result_code reason wave HHS_hh_shftd_dsntgrtd HH_2005 comm

isid HHID
save GSEC1_2011_merge, replace
clear
********GSEC2: HHSIZE, GENDER AND AGE********************

use GSEC2_2011
*Keep only relevant variables
keep h2q4 h2q1 h2q3 HHID h2q8 PID
isid HHID

*Edit variable h2q1 (household size)
destring h2q1, gen(hhsize)
egen hhsizes=max(hhsize), by(HHID)
gen hhsize2_2011=hhsizes if h2q4==1
lab var hhsize2_2011 "hhsize"

* Edit variable h2q3 (sex)
gen sex = h2q3 if h2q4==1
replace sex=0 if sex==2
lab var sex "Sex 1 male 0 women"


* Edit variable h2q8 (age)
gen age_2011=h2q8 if h2q4==1
lab var age_2011 "age hh"

* Remove duplicates heads of household
destring PID, gen(PID_numeric_2011)
drop if PID_numeric_2011==10130002130201 
drop if PID_numeric_2011==104100020901
drop if PID_numeric_2011==105300040701
drop if PID_numeric_2011==105300230901
drop if PID_numeric_2011==107100011101
drop if PID_numeric_2011==113300160402
drop if PID_numeric_2011==112100011001
drop if PID_numeric_2011==202300070401
drop if PID_numeric_2011==204100020201
drop if PID_numeric_2011==223300180701
drop if PID_numeric_2011==304100040101
drop if PID_numeric_2011==403300060301
drop if PID_numeric_2011==404300061001
drop if PID_numeric_2011==415300090201
collapse age_2011 sex hhsize2_2011 PID_numeric_2011,by(HHID)
duplicates tag HHID, g(dup)
drop dup

recode sex (1=1 "Male") (0=0 "Female"), gen(sex_2011)
lab var sex_2011 "Sex 1 male 0 women"
drop sex
lab var age_2011 "age hh" 
lab var hhsize2_2011 "hhsize 2011"
lab var PID_numeric_2011 "Personal ID 2011"

tab sex_2011
tab hhsize2_2011
save GSEC2_2011_merge, replace
clear



**********GSEC3= ETHNICITY AND REASON_FOR_MOVING
use GSEC3_2011
describe
keep HHID h2q1 h3q9 h3q18
gen ethnicity=h3q9 if h2q1==1
lab var ethnicity "HH Ethnicity"
gen reason_moving=h3q18 if h2q1==1
lab var reason_moving "HH reason to move to actual household"
collapse ethnicity reason_moving,by(HHID)
recode reason_moving (1=1 "Look for work") (2=2 "Income reasons") (3=3 "Weather") (4=4 "Eviction") (5=5 "Land problems")(6=6 "Illness/injury") (7=7 "Dissability") (8=8 "Education") (9=9 "Marriage") (10=10 "Divorce") (11=11 "Insecurity") (12=12 "return home") (13=13 "abduction") (14=14 "Follow/Join family") (96=96 "Other"),gen(HH_reason_moving)
lab var HH_reason_moving "HH reason to move to actual place"
drop reason_moving
lab var ethnicity "ethnicity"


save GSEC3_2011_merge, replace
clear

******** MAIN HOUSEHOLD INCOME SOURCE
use GSEC11_2011
describe
keep HHID h11q1
rename h11q1 main_income_source
collapse main_income_source,by(HHID)
recode main_income_source (1=1 "Subsistence farming") (2=2 "Commercial Farming") (3=3 "Wage employment") (4=4 "Non-agricultural enterprises") (5=5 "Property income")(6=6 "Transfers(pensions, allowances, social)") (7=7 "Remitances") (8=8 "Organizational support (e.g. food aid)") (9=9 "Other (specify)"),gen(HH_main_income_source)
lab var HH_main_income_source "Main income source HH"
drop main_income_source

save GSEC11_2011_merge, replace
clear


********************************************************************************
*The merging process
use GSEC1_2011_merge
merge 1:1 HHID using "GSEC2_2011_merge"
drop _merge
merge 1:1 HHID using "GSEC3_2011_merge"
drop _merge
merge 1:1 HHID using "GSEC11_2011_merge"
drop _merge
merge 1:1 HHID using "UNPS_Consumption_Aggregate_2011"
drop _merge
save dataset_Uganda_2011, replace

********************************************************************************
*Cleaning process  

*clean so that each string var names only appear in one format (all uppercase)
tab h1aq1
foreach var of varlist (h1aq1 h1aq2 h1aq3 h1aq4) {
	gen `var'_clean_2011=`var'
replace `var'_clean_2011 = upper(`var'_clean_2011)
}

tab h1aq1_clean_2011

*encode string variables
encode h1aq1_clean_2011, gen(District_clean_2011)
lab var District_clean_2011 "h1aq1_clean_code"
drop h1aq1 h1aq1_clean_2011
encode h1aq2_clean_2011, gen(County_clean_2011)
lab var County_clean_2011 "h1aq2_clean_code"
drop h1aq2_clean_2011 h1aq2
encode h1aq3_clean_2011, gen(SubCounty_clean_2011)
lab var SubCounty_clean_2011 "h1aq3_clean_code"
drop h1aq3_clean_2011 h1aq3
encode h1aq4_clean_2011, gen(Parish_clean_2011)
lab var Parish_clean_2011 "h1aq4_clean_code"
drop h1aq4_clean_2011 h1aq4

****Do not remove outliers because dealing with expenditures***

save dataset_Uganda_2011_cleaned.dta, replace

********************************************************************************
****Poverty Measures****

sum cpexp30

*generate anual and daily per capita consumption
gen pcc_2011_USD=((cpexp30*12)/hhsize2_2011)*0.00038633 //2011-2012 UGX average exchange rate = 1/2588.47=0.00038633 from the End Period values for 2011 and 2012 as published by the Bank of Uganda. 
lab var pcc_2011_USD "annual per capita consumption USD"
gen pcc_day_2011_USD=pcc_2011_USD/365
label var pcc_day_2011_USD "daily per capita consumption USD"

********************************************************************************



*generate absolute poverty line = US$1.25
gen pov_line_abs=1.25

* From 2008 to October 2015, the absolute poverty line was US$1.25 https://www.worldbank.org/en/topic/poverty/brief/global-poverty-line-faq

*absolute poverty line
gen headcount_abs_2011=0
replace headcount_abs_2011=1 if pcc_day_2011_USD<pov_line_abs
lab var headcount_abs_2011 "absolute poverty headcount"
recode headcount_abs_2011 (1=1 "Poor") (0=0 "Non-poor"), gen (Headcount_abs_2011)


asdoc tab Headcount_abs_2011 [aweight=mult], title(Headcount absolute poverty 2011(weighted)) save(headcount_abs_2011_weighted.doc), replace

/*some part of the population was oversampled, therefore the application of the weights is necessary for an accurate representation of the actual population https://microdata.worldbank.org/index.php/catalog/2059/download/31320 [last visited 15 November 2020]*/

* Absolute Poverty gap
gen pov_gap_abs_2011=0
replace pov_gap_abs_2011=pov_line_abs-pcc_day_2011_USD if pcc_day_2011_USD<pov_line_abs
lab var pov_gap_abs_2011 "absolute poverty gap"
sum pov_gap_abs_2011 

* Absolute Poverty index
gen pov_gapindex_abs_2011=0
replace pov_gapindex_abs_2011=pov_gap_abs_2011/pov_line_abs if pcc_day_2011_USD<pov_line_abs
lab var pov_gapindex_abs_2011 "absolute poverty gap index"
sum pov_gapindex_abs_2011

asdoc sum pov_gapindex_abs_2011 [aweight=mult], title(Poverty Gap Index Absolute Poverty 2011(weighted)) save(poverty_gapindex_abs_2011_weighted.doc), replace

* Absolute Poverty severity 
gen pov_sev_abs_2011=(pov_gapindex_abs_2011)^2
lab var pov_sev_abs_2011 "absolute poverty severity"

**************************************************************
********************* Share of poor by sex

* By weighted headcount
mean Headcount_abs_2011[pweight=mult], over(sex_2011)
graph bar (mean) Headcount_abs_2011 [pweight=mult], over(sex_2011) bargap(10) asyvars subtitle(Absolute Poverty Headcount by gender (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Headcount Absolute Poverty by Gender.gph"

* By poverty gap
mean pov_gap_abs_2011[pweight=mult], over(sex_2011)
graph bar (mean) pov_gap_abs_2011 [pweight=mult],over(sex_2011) bargap(10) asyvars subtitle(Absolute Poverty Gap by gender (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Poverty Gap Absolute Poverty by Gender.gph", replace

* By poverty gap index
mean pov_gapindex_abs_2011[pweight=mult], over(sex_2011)
graph bar (mean) pov_gapindex_abs_2011 [pweight=mult],over(sex_2011) bargap(10) asyvars subtitle(Absolute Poverty Gap Index by gender (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Poverty Gap Index Absolute Poverty by Gender.gph", replace

* By poverty severity
mean pov_sev_abs_2011[pweight=mult], over(sex_2011)
graph bar (mean) pov_sev_abs_2011 [pweight=mult],over(sex_2011) bargap(10) asyvars subtitle(Absolute Poverty Severity by gender (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Poverty Severity Absolute Poverty by Gender.gph", replace

****************** Share of poor by urban/rural
* By weighted headcount
mean Headcount_abs_2011[pweight=mult], over(urban)
graph bar (mean) Headcount_abs_2011 [pweight=mult],over(urban) bargap(10) asyvars subtitle(Absolute Headcount Poverty: Urban/Rural (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Headcount:Urban-Rural.gph", replace

* By poverty gap
mean pov_gap_abs_2011[pweight=mult], over(urban)
graph bar (mean) pov_gap_abs_2011 [pweight=mult],over(urban) bargap(10) asyvars subtitle(Absolute Poverty Gap: Urban/Rural (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap:Urban-Rural.gph", replace

* By poverty gap index
mean pov_gapindex_abs_2011[pweight=mult], over(urban)
graph bar (mean) pov_gapindex_abs_2011 [pweight=mult],over(urban) bargap(10) asyvars subtitle(Absolute Poverty Gap index: urban/rural (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap Index:Urban-Rural.gph", replace

* By poverty severity
mean pov_sev_abs_2011[pweight=mult], over(urban)
graph bar (mean) pov_sev_abs_2011 [pweight=mult],over(urban) bargap(10) asyvars subtitle(Absolute Poverty Severity: Urban/Rural (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Severity:Urban-Rural.gph", replace


********************** Share of poor by region
* By weighted headcount
mean Headcount_abs_2011 [pweight=mult], over(region)
graph bar (mean) Headcount_abs_2011 [pweight=mult],over(region) bargap(10) asyvars subtitle(Absolute Poverty Headcounty by Region (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Headcount:Region.gph", replace

* By poverty gap
mean pov_gap_abs_2011[pweight=mult], over(region)
graph bar (mean) pov_gap_abs_2011 [pweight=mult],over(region) bargap(10) asyvars subtitle(Absolute Poverty Gap by Region (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap:Region.gph", replace

* By poverty gap index
mean pov_gapindex_abs_2011[pweight=mult], over(region)
graph bar (mean) pov_gapindex_abs_2011 [pweight=mult],over(region) bargap(10) asyvars subtitle(Absolute Poverty Gap Index by Region (weighted)) blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap Index:Region.gph", replace

* By poverty severity
mean pov_sev_abs_2011[pweight=mult], over(region)
graph bar (mean) pov_sev_abs_2011 [pweight=mult],over(region) bargap(10) asyvars subtitle(Absolute Poverty Severity by region (weighted)) blabel(bar, position(upper) format(%5.4f)) 
save "Graphs/Absolute Poverty Severity:Region.gph", replace

asdoc mean Headcount_abs_2011 pov_gapindex_abs_2011 pov_sev_abs_2011[pweight=mult], over(region) title(Weighted Poverty measures by regions) save(poverty_measures_regions.doc), replace

************************** share of poor by main income 


* By weighted headcount
mean Headcount_abs_2011[pweight=mult], over(HH_main_income_source)
graph bar (mean) Headcount_abs_2011 [pweight=mult],over(HH_main_income_source) bargap(10) subtitle(Headcount absolute poverty by main income source) asyvars blabel(bar, position(upper) format(%5.4f)) 
save "Graphs/Absolute Poverty Headcount (weighted):Main Income.gph", replace

* By poverty gap
mean pov_gap_abs_2011[pweight=mult], over(HH_main_income_source)
graph bar (mean) pov_gap_abs_2011 [pweight=mult],over(HH_main_income_source) bargap(10) subtitle(Absolute Poverty Gap by Main Income Source (weighted)) asyvars  blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap (weighted):Main Income.gph", replace

* By poverty gap index
mean pov_gapindex_abs_2011[pweight=mult], over(HH_main_income_source)
graph bar (mean) pov_gapindex_abs_2011 [pweight=mult],over(HH_main_income_source) bargap(10) subtitle(Absolute Poverty Gap Index by Main Income Source (weighted)) asyvars  blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Gap Index (weighted):Main Income.gph", replace

* By poverty severity
mean pov_sev_abs_2011[pweight=mult], over(HH_main_income_source)
graph bar (mean) pov_sev_abs_2011 [pweight=mult],over(HH_main_income_source) bargap(10) subtitle(Poverty Severity by Main Income Source (weighted)) asyvars  blabel(bar, position(upper) format(%5.4f))
save "Graphs/Absolute Poverty Severity (weighted):Main Income.gph", replace

save dataset_Uganda_2011_calculations.dta, replace



********************************************************************************  INEQUALITY
* Basic summary statistics
sum pcc_2011_USD, detail
codebook pcc_2011_USD


***Charting distributions (and save graphs)***
* generate histograms 
histogram pcc_2011_USD, title("2011 Histogram in USD")
graph save "Graphs/2011 Histogram.gph", replace

* This distribution is not very representative due to outliers. From the basic summary statistics we learned that the 90% percentile of incomes boundary is 291.7 USD. As such we can attempt a histogram with an upper bound of 500 dollars income. 
histogram pcc_2011_USD if (pcc_2011_USD<=500), title ("2011 Histogram under 500 USD")
graph save "Graphs/2011 Histogram under 500 USD.gph", replace

histogram pcc_2011_USD if (pcc_2011_USD<=1000), title ("2011 Histogram under 1000 USD")
graph save "Graphs/2011 Histogram under 1000.gph", replace

histogram pcc_2011_USD if (pcc_2011_USD>=1000), title ("2011 Histogram above 1000 USD") width(100) barwidth(200)
graph save "Graphs/2011 Histogram above 1000", replace

graph combine "Graphs/2011 Histogram.gph" "Graphs/2011 Histogram under 500 USD.gph" "Graphs/2011 Histogram under 1000.gph" "Graphs/2011 Histogram above 1000", title("2011 Annual PCC Histograms") scale(0.7)
graph save "Graphs/2011 Combined Histograms.gph", replace
graph export "Graphs/2011 Combined Histograms.emf", replace


*Graph fitted with kernal density plot
graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=1000), title("2011 PCC Histogram & Kernel Density Plot under 1000 USD") legend(label(1 "Histogram") label(2 "Kernel Density Plot"))
graph save "Graphs/2011 Histogram-Kdensity under 1000.gph", replace

graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=500), title("2011 PCC Histogram & Kernel Density Plot under 500 USD") legend(label(1 "Histogram") label(2 "Kernel Density Plot"))
graph save "Graphs/2011 Histogram-Kdensity under 500.gph", replace

graph combine "Graphs/2011 Histogram-Kdensity under 500.gph" "Graphs/2011 Histogram-Kdensity under 1000.gph", title("2011 PCC Histogram-Kernel Density Plots") scale(0.6)
graph save "Graphs/2011 Histogram-Kdensity Combined.gph", replace
graph export "Graphs/2011 Histogram-Kdensity Combined.emf", replace

* Pen Parade (quantile function)
// Pen's Parade orders people in a population by level of income - lowest to highest
cumul pcc_2011_USD, gen(cdf_pcc_2011_USD)
lab var cdf_pcc_2011_USD "Cumulative Population Share"
sort cdf_pcc_2011_USD

* Pen Parade
graph twoway (line pcc_2011_USD cdf_pcc_2011_USD) ///
	, title("2011 PCC Pen's Parade") legend(label(1 "2011")) 
graph save "Graphs/pen_y11.gph", replace
* This first graph does not show us much, so we run it again at (y<500)

* Check if the pen parades cross at low values (y<500)	
graph twoway (line pcc_2011_USD cdf_pcc_2011_USD if pcc_2011_USD<500) ///
	, title("Pen's Parade (pcc_2011_USD<500)") legend(label(1 "2011"))
graph save "Graphs/penunder500_y11.gph", replace

* Check if the pen parades cross (y<1000)	
graph twoway (line pcc_2011_USD cdf_pcc_2011_USD if pcc_2011_USD<1000) ///
	, title("Pen's Parade (pcc_2011_USD<1000)") legend(label(1 "2011"))
graph save "Graphs/penunder1000_y11.gph", replace


 * Check if the pen parades cross above (y>1000)
graph twoway (line pcc_2011_USD cdf_pcc_2011_USD if pcc_2011_USD>1000) ///
	, title("Pen's Parade (pcc_2011_USD>1000)") legend(label(1 "2011"))
graph save "Graphs/penover1000_y11.gph"

graph combine "Graphs/pen_y11.gph" "Graphs/penunder500_y11.gph" "Graphs/penunder1000_y11.gph" "Graphs/penover1000_y11.gph", title(2011 PCC Pen's Parade Distributions) scale(0.75)
graph save "Graphs/Pen Parade Combined.gph", replace
graph export "Graphs/Pen Parade Combined.emf", replace


* Relative Lorenz curves and generalized Lorenz curves

glcurve pcc_2011_USD [aweight=mult], pvar(py) glvar(rly) lorenz 

sort py
graph twoway (line rly py, yaxis(1 2)) ///
	(function y = x, range(0 1) yaxis(1 2) ), ///
	aspect(1) xtitle("Cumulative population share") ///
	ytitle("Lorenz ordinate", axis(1)) ytitle(" ", axis(2)) legend(label(1 "2011") label(2 "line of equality")) title("Relative Lorenz Curve") 
graph save "Graphs/rlc_y11.gph", replace


* Generalized Lorenz curves // lorenz curve scaled up at each point by population mean income 
cap drop py 
cap drop gly*
glcurve pcc_2011_USD [aweight=mult], pvar(py) glvar(gly) 

sort py
graph twoway (line gly py, yaxis(1 2)),aspect(1) xtitle("Cumulative population share") ///
	ytitle("Generalized Lorenz ordinate", axis(1)) ytitle(" ", axis(2)) ///
    legend(label(1 "2011")) title("Generalized Lorenz Curve") 
graph save "Graphs/glc_y11.gph", replace

graph combine "Graphs/rlc_y11.gph" "Graphs/glc_y11.gph", title("Generalized and Relative Lorenz Curves") scale(0.9)
graph save "Graphs/Combined Lorenz Curves_11.gph", replace
graph export "Graphs/Combined Lorenz Curves_11.emf", replace

***Inequality Measures - parametric indices of inequality***

*report the gini index, theil index and mean log deviation 

ssc install ainequal
asdoc ainequal pcc_2011_USD [aweight=mult], all

//mean log deviation 2011 = 1.04171

//gini coefficient 2011 = 0.72977

//theil index 2011 = 2.86356

//theil vs. MLD for 2011 = -> MLD < Theil so inequality is concentrated in people with higher income

* compute the Palma ratio - using the pshare command // Palma ratio = ratio of income share of richest 10% of population to share of poorest 40%
ssc install pshare, replace
pshare estimate pcc_2011_USD [pweight=mult], n(5) percent
pshare estimate pcc_2011_USD [pweight=mult], percentiles(50 90 99) percent
*note: you can change the percentiles in the bracket 
pshare stack, plabels("bottom 50%" "50%-90%" "90%-99%" "top 1%") 
graph save "Graphs/Palma Ratio 50-90-99.gph", replace

pshare estimate pcc_2011_USD [pweight=mult], percentiles (40 90) percent
pshare stack, plabels("bottom 40%" "40%-90%" "90%-100%") 
graph save "Graphs/Palma Ratio 40-90.gph", replace
graph export "Graphs/Palma Ratio 40-90.emf", replace
di 68.14385/7.11763 // 9.5739523 (2011)
 
* compute the 90/10 ratio 
// 90/10 Ratio = Ratio of income eaned by individuals at 90th %ile compared to income of individuals at 10th %ile
asdoc sum pcc_2011_USD [aweight=mult], detail

di  496.3022/47.35991  // 10.479374 - income of someone at the 90th percentile is 10.479 times higher than the income of someone at the 10th percentile of income

//median value = 50th percentile is 111.5679 

save dataset_Uganda_2011_calculations.dta, replace

********************************************************************************
***********************INEQUALITY MEASURES BY REGION****************************

codebook region
*Central = 1
*Eastern = 2
*Northern = 3
*Western = 4

**************************Central inequality************************************
asdoc ainequal pcc_2011_USD if region==1 [aweight=mult], all
pshare estimate pcc_2011_USD if region==1 [pweight=mult], percentiles (40 90) percent 
di  70.53449/6.146328 // 11.475875 Palma ratio Central
sum pcc_2011_USD if region==1 [aweight=mult], detail
di  609.8896/67.10724 // 9.0882832 90/10 ratio Central

graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=1000 & region==1), title("2011 PCC Histogram & Kernel Density Plot by Central Region") legend(label(1 "Histogram") label(2 "Kernel Density Plot")) // kernel density/histogram Central
graph save "Graphs/2011 Histogram-Kdensity under 1000_Central.gph", replace


*************************Eastern inequality*************************************
asdoc ainequal pcc_2011_USD if region==2 [aweight=mult], all
pshare estimate pcc_2011_USD if region==2 [pweight=mult], percentiles (40 90) percent 
di   80.97945/  4.830343 // 16.764741 Palma ratio Eastern
sum pcc_2011_USD if region==2 [aweight=mult], detail
di 247.6746 / 43.61313 //5.6788999 90/10 ratio Eastern

graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=1000 & region==2), title("2011 PCC Histogram & Kernel Density Plot by Eastern Region") legend(label(1 "Histogram") label(2 "Kernel Density Plot")) // kernel density/histogram Eastern
graph save "Graphs/2011 Histogram-Kdensity under 1000_Eastern.gph", replace


*************************Northern inequality************************************
asdoc ainequal pcc_2011_USD if region==3 [aweight=mult], all
pshare estimate pcc_2011_USD if region==3 [pweight=mult], percentiles (40 90) percent
di   34.29053 / 14.69622 //2.3332891 Palma ratio 
sum pcc_2011_USD if region==3 [aweight=mult], detail
di  254.1686 /33.36533 // 7.6177457 90/10 ratio Northern

graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=1000 & region==3), title("2011 PCC Histogram & Kernel Density Plot by Northern Region") legend(label(1 "Histogram") label(2 "Kernel Density Plot")) // kernel density/histogram Northern
graph save "Graphs/2011 Histogram-Kdensity under 1000_Northern.gph", replace


*************************Western inequality*************************************
asdoc ainequal pcc_2011_USD if region==4 [aweight=mult], all
pshare estimate pcc_2011_USD if region==4 [pweight=mult], percentiles (40 90) percent 
di  31.92134 /  17.79891 // 1.7934435 Palma ratio Western
sum pcc_2011_USD if region==4 [aweight=mult], detail
di 292.9167/  57.21073 // 5.1199609 90/10 ratio Western

graph twoway (histogram pcc_2011_USD) (kdensity pcc_2011_USD) if (pcc_2011_USD <=1000 & region==4), title("2011 PCC Histogram & Kernel Density Plot by Western Region") legend(label(1 "Histogram") label(2 "Kernel Density Plot")) // kernel density/histogram Western
graph save "Graphs/2011 Histogram-Kdensity under 1000_Western.gph", replace

***********Combine histograms for all regions
graph combine "Graphs/2011 Histogram-Kdensity under 1000_Central.gph" "Graphs/2011 Histogram-Kdensity under 1000_Eastern.gph" "Graphs/2011 Histogram-Kdensity under 1000_Northern.gph" "Graphs/2011 Histogram-Kdensity under 1000_Western.gph", title("2011 Histogram-Kdensity under 1000 USD By Region") scale(0.6)
graph save "Graphs/2011 Histogram-Kdensity under 1000 USD By Region.gph", replace
graph export "Graphs/2011 Histogram-Kdensity under 1000 USD By Region.emf", replace

***********Combine kdenisty for all regions

graph twoway (kdensity pcc_2011_USD if pcc_2011_USD <=1000 & region==1) (kdensity pcc_2011_USD if pcc_2011_USD <=1000 & region==2) (kdensity pcc_2011_USD if pcc_2011_USD <=1000 & region==3) (kdensity pcc_2011_USD if pcc_2011_USD <=1000 & region==4), title("2011 PCC Kernel Density Plot by Region") xtitle("Annual Per Capita Consumption under 1000 USD") ytitle("Kernel Density") legend(label(1 "Central") label(2 "Eastern") label(3 "Northern") label(4 "Western"))
graph save "Graphs/2011 PCC Kernel Density Plot by Region.gph", replace
graph export "Graphs/2011 PCC Kernel Density Plot by Region.emf", replace

**************************Pen's Parade by Region********************************

bysort region: cumul pcc_2011_USD, gen(cdf_pcc_2011_USD_region) // Pen's Parade Calculations 
lab var cdf_pcc_2011_USD "Cumulative population share_region"
sort cdf_pcc_2011_USD_region

graph twoway ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==1 & pcc_2011_USD<500) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==2 & pcc_2011_USD<500) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==3 & pcc_2011_USD<500) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==4 & pcc_2011_USD<500) ///
	, title("Pen's Parade by Region (pcc_2011_USD<500)") legend(label(1 "Central") label(2 "Eastern") label(3 "Northern") label(4 "Western")) // Pen's Parade by Region
graph save "Graphs/penunder500_y11_Region.gph", replace

graph twoway ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==1 & pcc_2011_USD>1000) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==2 & pcc_2011_USD>1000) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==3 & pcc_2011_USD>1000) ///
	(line pcc_2011_USD cdf_pcc_2011_USD_region if region==4 & pcc_2011_USD>1000) ///
	, title("Pen's Parade by Region (pcc_2011_USD>1000)") legend(label(1 "Central") label(2 "Eastern") label(3 "Northern") label(4 "Western")) // Pen's Parade by Region
graph save "Graphs/penover1000_y11_Region.gph"

graph combine "Graphs/penunder500_y11_Region.gph" "Graphs/penover1000_y11_Region.gph", title("Pen's Parade Distributions by Region") scale(0.6)
graph export "Graphs/Pen's Parade Combined_Region.emf", replace


******************************Lorenz Curves by Region***************************

glcurve pcc_2011_USD [aweight=mult], by(region) split pvar(py) glvar(rly) lorenz // Relative Lorenz curves

sort py
graph twoway (line rly_1 py, yaxis(1 2)) ///
	(line rly_2 py, yaxis(1 2)) /// 
	(line rly_3 py, yaxis(1 2)) /// 
	(line rly_4 py, yaxis(1 2)) ///
	(function y = x, range(0 1) yaxis(1 2) ), ///
	aspect(1) xtitle("Cumulative population share by region") ///
	ytitle("Lorenz ordinate", axis(1)) ytitle(" ", axis(2)) legend(label(1 "Central") label(2 "Eastern") label(3 "Northern") label(4 "Western") label(5 "line of equality")) title("Relative Lorenz Curves By Region")
graph save "Graphs/Relative Lorenz Curves By Region.gph", replace
graph export "Graphs/Relative Lorenz Curves By Region.emf", replace

cap drop py 
cap drop gly*
glcurve pcc_2011_USD [aweight=mult], by(region) split pvar(py) glvar(gly) 

sort py
graph twoway (line gly_1 py, yaxis(1 2)) ///
	(line gly_2 py, yaxis(1 2)) /// 
	(line gly_3 py, yaxis(1 2)) /// 
	(line gly_4 py, yaxis(1 2)) ///
	,aspect(1) xtitle("Cumulative population share") ///
	ytitle("Generalized Lorenz ordinate", axis(1)) ytitle(" ", axis(2)) ///
     legend(label(1 "Central") label(2 "Eastern") label(3 "Northern") label(4 "Western") label(5 "line of equality")) title("Generalized Lorenz Curves By Region")
graph save "Graphs/Generalized Lorenz Curves By Region.gph", replace
graph combine "Graphs/Relative Lorenz Curves By Region.gph" "Graphs/Generalized Lorenz Curves By Region.gph", title("Relative and Generalized Lorenz Curves by Region") scale(0.8)
graph save "Graphs/Generalized & Relative Lorenz Curves By Region.gph", replace
graph export "Graphs/Generalized & Relative Lorenz Curves By Region.emf", replace

********************************************************************************
save dataset_Uganda_2011_Regions.dta, replace

********************************************************************************
**********************POLICY RECOMMENDATIONS*******************

**********************POOR PEOPLE AND LAND PROBLEMS 
asdoc tab HH_reason_moving Headcount_abs_2011 [aweight=mult], row format(%12.2f) title(The Poor: reasons for moving) save(poor_reason_moving.doc)   


* 98.95% of the persons that have experienced land problems are poor

clear

********** ACCESS AND CONDITIONS OF HEALTH FACILITIES
* We are interested in getting information based on regions, that is why we created a variable region that grouped the districts into a region category following the codes provided in: https://microdata.worldbank.org/index.php/catalog/2059/download/31321
use CSEC2b_2011
gen regions=. 
replace regions=1 if c1aq1==101 | c1aq1==102 | c1aq1==103 | c1aq1==104 | c1aq1==105 | c1aq1==106 | c1aq1==107 | c1aq1==108 | c1aq1==109 | c1aq1==110 | c1aq1==111 | c1aq1==112 | c1aq1==113 | c1aq1==114 | c1aq1==115 | c1aq1==116 | c1aq1==117| c1aq1==118| c1aq1==119| c1aq1==120| c1aq1==121| c1aq1==122| c1aq1==123| c1aq1==124
replace regions=2 if c1aq1==201 | c1aq1==202 | c1aq1==203 | c1aq1==204 | c1aq1==205 | c1aq1==206 | c1aq1==207 | c1aq1==208 | c1aq1==209 | c1aq1==210 | c1aq1==211 | c1aq1==212 | c1aq1==213 | c1aq1==214 | c1aq1==215 | c1aq1==216 | c1aq1==217  | c1aq1==218 | c1aq1==219 | c1aq1==220 | c1aq1==221 | c1aq1==222 | c1aq1==223 | c1aq1==224 | c1aq1==225 | c1aq1==226 | c1aq1==227| c1aq1==228| c1aq1==229| c1aq1==230| c1aq1==231| c1aq1==232
replace regions=3 if c1aq1==301 | c1aq1==302 | c1aq1==303 | c1aq1==304 | c1aq1==305 | c1aq1==306 | c1aq1==307 | c1aq1==308 | c1aq1==309 | c1aq1==310 | c1aq1==311 | c1aq1==312 | c1aq1==313 | c1aq1==314 | c1aq1==315 | c1aq1==316 | c1aq1==317  | c1aq1==318 | c1aq1==319 | c1aq1==320 | c1aq1==321 | c1aq1==322 | c1aq1==323 | c1aq1==324 | c1aq1==325 | c1aq1==326 | c1aq1==327 | c1aq1==328 | c1aq1==329 | c1aq1==330 
replace regions=4 if c1aq1==401 | c1aq1==402 | c1aq1==403 | c1aq1==404 | c1aq1==405 | c1aq1==406 | c1aq1==407 | c1aq1==408 | c1aq1==409 | c1aq1==410 | c1aq1==411 | c1aq1==412 | c1aq1==413 | c1aq1==414 | c1aq1==415 | c1aq1==416 | c1aq1==417  | c1aq1==418 | c1aq1==419 | c1aq1==420 | c1aq1==421 | c1aq1==422 | c1aq1==423 | c1aq1==424 | c1aq1==425 | c1aq1==426 
recode regions (1=1 "Central") (2=2 "Eastern") (3=3 "Northern") (4=4 "Western"), gen(region)
keep region c1aq1 c2bq10 c2bq13_a c2bq13_b 

foreach var of varlist (c2bq10 c2bq13_a c2bq13_b) {
	encode `var', gen (`var'_code)
	}
drop c2bq10 c2bq13_a c2bq13_b


asdoc tab region c2bq10, row title(Patient's satisfaction with health facility per region) save(patient_satisfaction.doc), replace

asdoc tab region c2bq13_b_code, row title(Means of transport to get to health facility) save(transport_facility.doc), replace

asdoc tab region c2bq13_a_code, row title(The distance to health facility was long) save(distance_facility.doc), replace

save CSEC2b_2011_statistics, replace
clear


********** ACCESS AND CONDITIONS OF EDUCATION FACILITIES
* We are interested in getting information based on regions, that is why we created a variable region that grouped the districts into a region category following the codes provided in: https://microdata.worldbank.org/index.php/catalog/2059/download/31321

use CSEC3a_2011

gen regions=. 
replace regions=1 if c1aq1==101 | c1aq1==102 | c1aq1==103 | c1aq1==104 | c1aq1==105 | c1aq1==106 | c1aq1==107 | c1aq1==108 | c1aq1==109 | c1aq1==110 | c1aq1==111 | c1aq1==112 | c1aq1==113 | c1aq1==114 | c1aq1==115 | c1aq1==116 | c1aq1==117| c1aq1==118| c1aq1==119| c1aq1==120| c1aq1==121| c1aq1==122| c1aq1==123| c1aq1==124
replace regions=2 if c1aq1==201 | c1aq1==202 | c1aq1==203 | c1aq1==204 | c1aq1==205 | c1aq1==206 | c1aq1==207 | c1aq1==208 | c1aq1==209 | c1aq1==210 | c1aq1==211 | c1aq1==212 | c1aq1==213 | c1aq1==214 | c1aq1==215 | c1aq1==216 | c1aq1==217  | c1aq1==218 | c1aq1==219 | c1aq1==220 | c1aq1==221 | c1aq1==222 | c1aq1==223 | c1aq1==224 | c1aq1==225 | c1aq1==226 | c1aq1==227| c1aq1==228| c1aq1==229| c1aq1==230| c1aq1==231| c1aq1==232
replace regions=3 if c1aq1==301 | c1aq1==302 | c1aq1==303 | c1aq1==304 | c1aq1==305 | c1aq1==306 | c1aq1==307 | c1aq1==308 | c1aq1==309 | c1aq1==310 | c1aq1==311 | c1aq1==312 | c1aq1==313 | c1aq1==314 | c1aq1==315 | c1aq1==316 | c1aq1==317  | c1aq1==318 | c1aq1==319 | c1aq1==320 | c1aq1==321 | c1aq1==322 | c1aq1==323 | c1aq1==324 | c1aq1==325 | c1aq1==326 | c1aq1==327 | c1aq1==328 | c1aq1==329 | c1aq1==330 
replace regions=4 if c1aq1==401 | c1aq1==402 | c1aq1==403 | c1aq1==404 | c1aq1==405 | c1aq1==406 | c1aq1==407 | c1aq1==408 | c1aq1==409 | c1aq1==410 | c1aq1==411 | c1aq1==412 | c1aq1==413 | c1aq1==414 | c1aq1==415 | c1aq1==416 | c1aq1==417  | c1aq1==418 | c1aq1==419 | c1aq1==420 | c1aq1==421 | c1aq1==422 | c1aq1==423 | c1aq1==424 | c1aq1==425 | c1aq1==426 
recode regions (1=1 "Central") (2=2 "Eastern") (3=3 "Northern") (4=4 "Western"), gen(region)
keep region c1aq1 c3aq8 c3aq9 c3aq10 c3aq12

*** Existence of facilities at school per region
asdoc tab c3aq8 c3aq9 if region==1, row title(Existence of facilities at school in Central region) save(existence_facilities_central.doc), replace

asdoc tab c3aq8 c3aq9 if region==2, row title(Existence of facilities at school in Eastern region) save(existence_facilities_eastern.doc), replace

asdoc tab c3aq8 c3aq9 if region==3, row title(Existence of facilities at school in Northern region) save(existence_facilities_northern.doc), replace

asdoc tab c3aq8 c3aq9 if region==4, row title(Existence of facilities at school in Western region) save(existence_facilities_western.doc), replace


**** Adequacy of facilities at school per region

asdoc tab c3aq8 c3aq10 if region==1, row title(Adequacy of facilities at school in Central region) save(adequacy_facilities_central.doc), replace

asdoc tab c3aq8 c3aq10 if region==2, row title(Adequacy of facilities at school in Eastern region) save(adequacy_facilities_eastern.doc), replace

asdoc tab c3aq8 c3aq10 if region==3, row title(Adequacy of facilities at school in Northern region) save(adequacy_facilities_northern.doc), replace

asdoc tab c3aq8 c3aq10 if region==4, row title(Adequacy of facilities at school in Western region) save(adequacy_facilities_western.doc), replace


**** Conditions of facilities at school per region

asdoc tab c3aq8 c3aq12 if region==1, row title(Conditions of facilities at school in Central region) save(conditions_facilities_central.doc), replace

asdoc tab c3aq8 c3aq12 if region==2, row title(Conditions of facilities at school in Eastern region) save(conditions_facilities_eastern.doc), replace

asdoc tab c3aq8 c3aq12 if region==3, row title(Conditions of facilities at school in Northern region) save(conditions_facilities_northern.doc), replace

asdoc tab c3aq8 c3aq12 if region==4, row title(Conditions of facilities at school in Western region) save(conditions_facilities_western.doc), replace

save CSEC3a_2011_statistics, replace
clear




