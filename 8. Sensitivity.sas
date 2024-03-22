************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza 
IDI Refresh: IDI Refresh: IDI_Clean_202206

TASK:
data set up and sensitivity analyses

Update:
17 Aug 23 - Study pop data set up with dementia excluding 
mort and excluding pharms complete

INPUT DATASETS:
dia_clean.deaths
data.person_overseas_spell
steph.totpop_24Sep22
steph.adrd_hosp_13jul22
steph.adrd_mort_13ul22
steph.adrd_pharms_13jul22

OUTPUT DATASETS:
steph.cohort_nopharms_17Aug23
steph.cohort_nomort_17Aug23

Disclaimer: The results in this report are not official statistics. 
They have been created for research purposes from the Integrated Data 
Infrastructure (IDI), managed by Statistics New Zealand.
The opinions, findings, recommendations, and conclusions expressed in 
this report are those of the author, not Statistics NZ.
Access to the anonymised data used in this study was provided by 
Statistics NZ under the security and confidentiality provisions of 
the Statistics Act 1975. Only people authorised by the Statistics Act 
1975 are allowed to see data about a particular person, household, 
business, or organisation, and the results in this report have been 
confidentialised to protect these groups from identification and to 
keep their data safe.
Careful consideration has been given to the privacy, security, and 
confidentiality issues associated with using administrative and 
survey data in the IDI. Further detail can be found in the Privacy 
impact assessment for the Integrated Data Infrastructure available 
from www.stats.govt.nz.
*************************************************************;

***ALWAYS RUN THESE LIBNAMES AT THE START***;
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data";
libname data ODBC dsn=idi_clean_202206_srvprd schema=data;

*load dataset prior to exclusions;
data totpop; set steph.totpop_24Sep22;
keep snz_uid snz_sex_gender_code any_infec infect_start cohort 
dia_bir_birth_month_nbr dia_bir_birth_year_nbr 
moh_dia_diagnosis_type_code moh_dia_clinical_code;
run;

* check frequencies;
proc freq data=totpop;
table any_infec;
run;

*create event and censoring dates; 
**sort out end dates;
*get deaths;
proc sql;
connect to odbc(dsn=idi_clean_202206_srvprd);
	create table deaths as 
	select * from connection to odbc
		(select distinct snz_uid, dia_dth_death_month_nbr, dia_dth_death_year_nbr 
			from dia_clean.deaths)
 ;
disconnect from odbc;
quit;

* create dod; 
data deaths2; set deaths;
format death_date date10.;
death_date = mdy(dia_dth_death_month_nbr, 1, dia_dth_death_year_nbr);
run;

**sort out end dates;
*merge death date in with cohort; 
proc sql; 
	create table pop_death as 
	select a.*, b.death_date from totpop a 
	left join deaths2 b
		on a.snz_uid = b.snz_uid;
quit;

*remove duplicates;
proc sort data=pop_death nodupkey; by snz_uid; run;

*make dod end of month;
data tot_pop_1; 
set pop_death; 
death_date = intnx('month',death_date,1)-1; *make death date end of month;
run;

* merge in overseas information;
proc sql;
create table totpop_os as	
	select a.snz_uid, b.* 
		from tot_pop_1 a
		left join data.person_overseas_spell b
			on a.snz_uid = b.snz_uid;
quit;

* extract date from datetime;
data totpop_os2; set totpop_os;
applied = datepart(pos_applied_date);
ceased = datepart(pos_ceased_date);
format applied ceased date9.;
run;

* Delete rows where travel ended prior to start of study period and travel started following end of study period;
data left; set totpop_os2;
if ceased lt '01JUL1989'd then delete;
if applied gt '30JUN2019'd then delete;

* get date when they left country;
* if ceased has 31DEC9999 - means they have not returned to country. Therefore create leftcountry date;
if ceased = '31DEC9999'd then leftcountry_date = applied;
format leftcountry_date date9.;
run;

proc sort data=left; by descending leftcountry_date; run;

*remove other rows;
data left2; set left;
where leftcountry_date ne .;
keep snz_uid leftcountry_date;
run;

* merge back in;
proc sql;
	create table totpop_os3 as	
		select * from totpop_os2 a
		left join left2 b
			on a.snz_uid = b.snz_uid;
quit;

*restrict to those who have left the country - where left country date = applied date - and create left country flag;
data totpop_os4; set totpop_os3; 
where leftcountry_date = applied;
leftcountry = 1;
keep snz_uid leftcountry_date;
run;

* remove duplicates;
proc sort data=totpop_os4 nodupkey;
by snz_uid;
run;

* merge back in with original data;
proc sql;
	create table totpop_2 as 
		select * from tot_pop_1 a
		left join totpop_os4 b
			on a.snz_uid = b.snz_uid;
quit;

*************************************
	add dementia date - no pharms
*************************************;
*hospitalisation;
data ADRDhosp; 
rename hosp_start = adrd_date;
set steph.adrd_hosp_13jul22;
source = "hosp"; 
code = moh_dia_clinical_code;
where adrd_hosp = 1;
run;

*mortality;
data ADRDmort;
rename dod=adrd_date;
set steph.adrd_mort_13ul22;
source = "mortality";
where adrd_death = 1;
run;

data ADRD_nopharms; set ADRDhosp ADRDmort; 
keep snz_uid adrd_date source adrd_flag;
adrd_flag = 1;
run;

proc freq data=ADRD_nopharms;
table adrd_flag;
run;

*select earliest dementia date; 
*restrict to snz_uids and adrd flag, remove duplicates by selecting first event;
proc sort data=ADRD_nopharms; 
by snz_uid adrd_date;
data adrd_id; set ADRD_nopharms;
by snz_uid;
if first.snz_uid;
run;

*left join with totpop;
proc sql;
	create table totpop_3 as 
		select * from totpop_2 a
		left join adrd_id b
			 on a.snz_uid = b.snz_uid;
quit;

proc freq data=totpop_3; table adrd_flag; run;

* Finalise end dates;
* create additional variables;
data totpop_4; set totpop_3;

if death_date = . and leftcountry_date ne . then date1 = leftcountry_date;
else if death_date ne .  and leftcountry_date = . then date1 = death_date;
else if death_date ne . and leftcountry_date ne . and death_date > leftcountry_date then date1 = leftcountry_date;
else if death_date ne . and leftcountry_date ne . and death_date le leftcountry_date then date1 = death_date;

if adrd_date = . and date1 ne . then end_date = date1;
else if adrd_date ne .  and date1 = . then end_date = adrd_date;
else if adrd_date ne . and date1 ne . and adrd_date > date1 then end_date = date1;
else if adrd_date ne . and date1 ne . and adrd_date le date1 then end_date = adrd_date;


*some people died/left country after end date period - so make end date end of study period;
if end_date > '30JUN2019'd then end_date = '30JUN2019'd;

*also for those who did not have an event, amke end date end of study period;
if end_date = . then end_date = '30JUN2019'd;

format date1 end_date date9.;

run;

*checking everyone has an end date;
proc means data=totpop_4; var end_date; run;

*create infection only group with relevant date variables; 
data infection_only; set totpop_4; 
where any_infec = 1;
Start_date1 = '01JUL1989'd;

if end_date < infect_start then Stop_date1 = end_date;
else Stop_date1 = infect_start; 

if end_date < infect_start then check = 1; 

Start_date2 = infect_start;
Stop_date2 = end_date;
FORMAT Start_date1 Stop_date1 Start_date2 Stop_date2 date10.;
run;

*transpose; 
proc sort data=infection_only2; by snz_uid;
run;

proc transpose data=infection_only2 out=start prefix=start_date;
by snz_uid; 
var Start_date1 Start_date2;
run;

proc transpose data=infection_only2 out=stop prefix=stop_date;
by snz_uid; 
var Stop_date1 Stop_date2;
run;

*merge; 
data infection_long; 
	merge start(rename=(start_date1=start_date) drop=_name_) stop(rename=(stop_date1=stop_date));
	by snz_uid; 
	date_order=input(substr(_name_,10), 5.);
	any_infec2 = date_order-1;
	drop _name_;
run;

*left join back into datafile; 
proc sql;
create table tot_pop_long as	
	select * 
		from totpop_4 a
		left join infection_long b
			on a.snz_uid = b.snz_uid;
quit;

*check;
proc means data=totpop; var snz_uid;
proc means data=infection_only2; var snz_uid;
proc means data=tot_pop_long; var snz_uid;
*all good; 

*fill in start_date and date_order variables for non-infections group; 
data tot_pop_long2; set tot_pop_long; 
if start_date = . then start_date = '01JUL1989'd;
if date_order = . then date_order = 1;

*also make stop date the event or censor date for those without an infection;
if stop_date = . then stop_date = end_date;

*time variables;
starttime = start_date - '01JUL1989'd;
stoptime = stop_date - '01JUL1989'd;
run;

proc sort data=tot_pop_long2; by snz_uid date_order;
run;

*update relevant variables; 
*create time and status variables;
data tot_pop_long3; set tot_pop_long2;
	if adrd_date = stop_date then status = 1; *adrd event first;
	else status = 0; *died, left country or end of study period;

	if any_infec2 ne 1 then any_infec2 = 0; 
run;

*save file;
data steph.cohort_nopharms_17Aug23; set tot_pop_long3; run;


*************************************
	add dementia date - no mort
*************************************;
*hospitalisation;
data ADRDhosp; 
rename hosp_start = adrd_date;
set steph.adrd_hosp_13jul22;
source = "hosp"; 
code = moh_dia_clinical_code;
where adrd_hosp = 1;
run;

*pharms;
data ADRDpharms;
rename moh_pha_dispensed_date = adrd_date;
set steph.adrd_pharms_13jul22;
source = "pharms";
where adrd_pharms = 1;
run;

proc sort data=adrdpharms; by adrd_date; run;

data ADRD_nomort; set ADRDhosp ADRDpharms; 
keep snz_uid adrd_date source adrd_flag;
adrd_flag = 1;
run;

proc freq data=ADRD_nomort;
table adrd_flag;
run;

*select earliest dementia date; 
*restrict to snz_uids and adrd flag, remove duplicates by selecting first event;
proc sort data=ADRD_nomort; 
by snz_uid adrd_date;
data adrd_id; set ADRD_nomort;
by snz_uid;
if first.snz_uid;
run;

*left join with totpop;
proc sql;
	create table totpop_3 as 
		select * from totpop_2 a
		left join adrd_id b
			 on a.snz_uid = b.snz_uid;
quit;

proc freq data=totpop_3; table adrd_flag; run;

* Finalise end dates;
* create additional variables;
data totpop_4; set totpop_3;

if death_date = . and leftcountry_date ne . then date1 = leftcountry_date;
else if death_date ne .  and leftcountry_date = . then date1 = death_date;
else if death_date ne . and leftcountry_date ne . and death_date > leftcountry_date then date1 = leftcountry_date;
else if death_date ne . and leftcountry_date ne . and death_date le leftcountry_date then date1 = death_date;

if adrd_date = . and date1 ne . then end_date = date1;
else if adrd_date ne .  and date1 = . then end_date = adrd_date;
else if adrd_date ne . and date1 ne . and adrd_date > date1 then end_date = date1;
else if adrd_date ne . and date1 ne . and adrd_date le date1 then end_date = adrd_date;


*some people died/left country after end date period - so make end date end of study period;
if end_date > '30JUN2019'd then end_date = '30JUN2019'd;

*also for those who did not have an event, amke end date end of study period;
if end_date = . then end_date = '30JUN2019'd;

format date1 end_date date9.;

run;

*checking everyone has an end date;
proc means data=totpop_4; var end_date; run;

*create infection only group with relevant date variables; 
data infection_only; set totpop_4; 
where any_infec = 1;
Start_date1 = '01JUL1989'd;

if end_date < infect_start then Stop_date1 = end_date;
else Stop_date1 = infect_start; 

if end_date < infect_start then check = 1; 

Start_date2 = infect_start;
Stop_date2 = end_date;
FORMAT Start_date1 Stop_date1 Start_date2 Stop_date2 date10.;
run;

*transpose; 
proc sort data=infection_only2; by snz_uid;
run;

proc transpose data=infection_only2 out=start prefix=start_date;
by snz_uid; 
var Start_date1 Start_date2;
run;

proc transpose data=infection_only2 out=stop prefix=stop_date;
by snz_uid; 
var Stop_date1 Stop_date2;
run;

*merge; 
data infection_long; 
	merge start(rename=(start_date1=start_date) drop=_name_) stop(rename=(stop_date1=stop_date));
	by snz_uid; 
	date_order=input(substr(_name_,10), 5.);
	any_infec2 = date_order-1;
	drop _name_;
run;

*left join back into datafile; 
proc sql;
create table tot_pop_long as	
	select * 
		from totpop_4 a
		left join infection_long b
			on a.snz_uid = b.snz_uid;
quit;

*fill in start_date and date_order variables for non-infections group; 
data tot_pop_long2; set tot_pop_long; 
if start_date = . then start_date = '01JUL1989'd;
if date_order = . then date_order = 1;

*also make stop date the event or censor date for those without an infection;
if stop_date = . then stop_date = end_date;

*time variables;
starttime = start_date - '01JUL1989'd;
stoptime = stop_date - '01JUL1989'd;
run;

proc sort data=tot_pop_long2; by snz_uid date_order;
run;

*update relevant variables; 
*create time and status variables;
data tot_pop_long3; set tot_pop_long2;
	if adrd_date = stop_date then status = 1; *adrd event first;
	else status = 0; *died, left country or end of study period;

	if any_infec2 ne 1 then any_infec2 = 0; 
run;

*save file;
data steph.cohort_nomort_17Aug23; set tot_pop_long3; run;
