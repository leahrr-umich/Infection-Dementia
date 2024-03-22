*********************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza and B. Milne
IDI Refresh: IDI_Clean_202206

TASK:
Cohort derivation

INPUT DATASETS:
dia.births
dia.deaths
data.personal_detail
data.snz_res_pop
data.person_overseas_spell
steph.adrd_dx_13jul22
steph.phdx_27jul22
steph.mhdx_27jul22

OUTPUT DATASETS:
steph.coh5968_24Sep22
steph.coh4958_24Sep22
steph.coh3948_24Sep22
steph.coh2938_24Sep22
steph.totpop_24Sep22
steph.totpop_1Nov22
steph.totpop_HR_16Nov23

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
*********************************************************************;

***ALWAYS RUN THESE LIBNAMES AT THE START***;
libname data ODBC dsn=idi_clean_202206_srvprd schema=data;
libname dia ODBC dsn=idi_clean_202206_srvprd schema=dia_clean;
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data";

%macro sample(
  cohort,
  start_yr /* first year of birth cohort */, 
  end_yr /* final year of birth cohort */);

data &cohort.;
set dia.births;
if &start_yr. <= dia_bir_birth_year_nbr <= &end_yr.;
keep snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr;
run;

* remove duplicates;
proc sort data=&cohort. nodupkey;
by snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr;
run;

* CHECK AND MAKE NOTE OF INITIAL COUNTS;
proc means data=&cohort.; var snz_uid; run;

* exclude those not in spine (data.personal_detail is spine table);
proc sql;
	create table &cohort._1 as
	select * from &cohort. a
	left join data.personal_detail b 
		on a.snz_uid = b.snz_uid
		where b.snz_spine_ind = 1;
quit;

* CHECK AND MAKE NOTE OF COUNT OF THOSE ONLY IN SPINE;
proc means data= &cohort._1; var snz_uid; run;

* merge cohorts with deaths;
proc sql; 
	create table &cohort._2 as
		select * from &cohort._1 a
		left join dia.deaths b
			on a.snz_uid = b.snz_uid;
quit;

*remove duplicates;
proc sort data=&cohort._2 nodupkey;
by snz_uid;
run;

* creat dod; 
data &cohort._alive; set &cohort._2;
format death_date date10.;
death_date = mdy(dia_dth_death_month_nbr, 1, dia_dth_death_year_nbr);
label death_date = 'date of death';
run;

** Create indicator for dead vs. alive during exposure period;
data &cohort._death; set &cohort._alive;
if (death_date ne .) and (death_date < '01JUL1989'd) then died = 1;
else died = 0;

*MAKE NOTE OF THOSE WHERE DIED = 0, AS THIS WILL BE COHORT NUMBER EXCLUDING ALL THOSE WHO DIED PRIOR TO EXPOSURE PERIOD;
proc freq data=&cohort._death;
table died;
run;

** DROP individuals who died prior to observation period;
data &cohort._3; set &cohort._death;
if (death_date ne .) and (death_date < '01JUL1989'd) then delete;
run;

*** Bring in sex from personal details table;
*  1 = male, 2 = female;
proc sql;
	create table &cohort._sex as 
	select * from  &cohort._3 a
	left join data.personal_detail b
		on a.snz_uid = b.snz_uid;
quit;

proc sort data = &cohort._sex; by dia_bir_birth_year_nbr; run; 

%mend sample;

%sample(coh5968, 1959, 1968);
%sample(coh4958, 1949, 1958);
%sample(coh3948, 1939, 1948);
%sample(coh2938, 1929, 1938);

* create overseas flag and resident population flag;
*load resident population between study period; 
data res_pop; set data.snz_res_pop;
where srp_ref_date le '30JUN2019'd;
run;

proc freq data=res_pop; table srp_ref_date; run;

* resident population - remove duplicate snz_uids;
proc freq data=res_pop noprint;
table snz_uid /out=res_pop_ids;
run;

data res_pop_ids2; set res_pop_ids; 
res_pop_flag = 1; 
drop count percent; 
run;


%macro final(cohort);
* merge with res pop ids;
proc sql;
	create table &cohort._res as
	select distinct a.*, b.res_pop_flag from &cohort._sex a
	left join res_pop_ids2 b
		on a.snz_uid = b.snz_uid;
quit;

* res count without os restriction;
proc freq data=&cohort._res;
table res_pop_flag;
run; 

proc sort data = &cohort._res; by dia_bir_birth_year_nbr; run;

*save;
data steph.&cohort._7Jul22;
set &cohort._res;
keep snz_uid dia_bir_birth_month_nbr dia_bir_birth_year_nbr death_date snz_sex_gender_code res_pop_flag;  
run;
%mend final;

%final(coh5968); 
%final(coh4958); 
%final(coh3948);
%final(coh2938);



*testing;
proc sql;
	create table coh5968 as
		select * from steph.coh5968_7Jul22 a
		left join infections6 b on a.snz_uid=b.snz_uid;
quit;

proc sql;
	create table coh4958 as
		select * from steph.coh4958_7Jul22 a
		left join infections6 b on a.snz_uid=b.snz_uid;
quit;

proc sql;
	create table coh3948 as
		select * from steph.coh3948_7Jul22 a
		left join infections6 b on a.snz_uid=b.snz_uid;
quit;

proc sql;
	create table coh2938 as
		select * from steph.coh2938_7Jul22 a
		left join infections6 b on a.snz_uid=b.snz_uid;
quit;


data totpop_test; 
set coh2938 coh3948 coh4958 coh5968;
if any_infec=. then any_infec=0;
run;

*combine all into total population; 
data steph.totpop_24Sep22; 
set steph.coh2938_24Sep22 steph.coh3948_24Sep22 steph.coh4958_24Sep22 steph.coh5968_24Sep22;
if any_infec=. then any_infec=0;
run;

*check cohort counts; 
proc sort data= steph.totpop_24Sep22; by snz_sex_gender_code cohort;
proc freq data=steph.totpop_24Sep22; 
table cohort; by snz_sex_gender_code;
run;
proc freq data=steph.totpop_24Sep22; 
table any_infec; by snz_sex_gender_code cohort;
run;



******************************************************************************;
**************COHORT FOR MODELS WITHOUT TIME VARYING COVARIATES***************;
******************************************************************************;

*load total population; 
data totpop; set steph.totpop_24Sep22;
keep snz_uid snz_sex_gender_code any_infec infect_start start_date cohort 
dia_bir_birth_month_nbr dia_bir_birth_year_nbr 
moh_dia_diagnosis_type_code moh_dia_clinical_code
viral_infec bacterial_infec parasitic_infec other_infec;
if viral_infec=. then viral_infec=0;
if bacterial_infec=. then bacterial_infec=0;
if parasitic_infec=. then parasitic_infec=0;
if other_infec=. then other_infec=0;
run;

*load dementia data;
data dementia; set steph.adrd_dx_13jul22; run;

*select earliest dementia date; 
*restrict to snz_uids and adrd flag, remove duplicates by selecting first event;
proc sort data=dementia; 
by snz_uid adrd_date;
data adrd_id; set dementia;
by snz_uid;
if first.snz_uid;
run;

*check; 
proc freq data=adrd_id noprint;
table snz_uid / out=check;
proc means data=check; run;

*left join with totpop;
proc sql;
	create table totpop_adrd as 
		select * from totpop a
		left join adrd_id b
			 on a.snz_uid = b.snz_uid;
quit;

proc means data=totpop_adrd;
var infect_start start_date;
run;

**Exclude those with dementia dx prior to or at the same time as start date; 
data totpop_noprior; 
set totpop_adrd;
if (adrd_date ne .) and (start_date ne .) and (adrd_date le start_date) then delete;

*finalise flags for infection and subsequent dementia; 
if adrd_flag = . then adrd_flag = 0;
if any_infec = . then any_infec = 0;
run; 

*check; 
proc freq data=totpop_noprior; 
table adrd_flag any_infec;
run;

********************************************************;
**Code pre-existing physical health event; 
**Create ph flag;
*Create flags for infec/ADRD events. 
0 = no infection or ADRD, 1 = infection only, 2 = ADRD only, 3 = both;
data totpop_ph; set totpop_noprior;
if any_infec = 0 and adrd_flag = 0 then inf_ADRD = 0;
if any_infec = 1 and adrd_flag = 0 then inf_ADRD = 1; 
if any_infec = 0 and adrd_flag = 1 then inf_ADRD = 2;
if any_infec = 1 and adrd_flag = 1 then inf_ADRD = 3;
run;

proc freq data=totpop_ph; table inf_ADRD; run;

*NEITHER INF/ADRD;
* merge ph diagnostic information in and restrict to those with no infection or ADRD and a ph event;
proc sql;
	create table NOINFADRD as
		select a.*, b.hosp_start as ph_start, b.event_id, b.ph_diagnosis, b.AnyPH_dx from totpop_ph a
		left join steph.phdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 0 and b.AnyPH_dx = 1;
quit;

*select first event and create ph flag for this group;
proc sort data=NOINFADRD; 
by snz_uid ph_start event_id;
data NOINFADRD2; set NOINFADRD;
by snz_uid;
if first.snz_uid;
ph_flag = 1;
run; 

*check for duplicates; 
proc freq data=NOINFADRD2 noprint;
table snz_uid / out=check; 
proc means data=check;
run;
*all good; 

*************;
*INF ONLY;
* merge ph diagnostic information in and restrict to those with an infection and a ph event;
proc sql;
	create table INF_ONLY as
		select a.*, b.hosp_start as ph_start, b.event_id, b.ph_diagnosis, b.AnyPH_dx from totpop_ph a
		left join steph.phdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 1 and b.AnyPH_dx = 1;
quit;

*if ph_start is before infection date then give ph_flag and restrict to just these events;
data INF_ONLY2; set INF_ONLY;
if ph_start < infect_start then ph_flag = 1;
if ph_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=INF_ONLY2; 
by snz_uid ph_start event_id;
data INF_ONLY3; set INF_ONLY2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=INF_ONLY3 noprint;
table snz_uid / out=check2; 
proc means data=check2;
run;
*all good; 

*************;
*ADRD ONLY;
* merge ph diagnostic information in and restrict to those with a ADRD and a ph event;
proc sql;
	create table ADRD_ONLY as
		select a.*, b.hosp_start as ph_start, b.event_id, b.ph_diagnosis, b.AnyPH_dx from totpop_ph a
		left join steph.phdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 2 and b.AnyPH_dx = 1;
quit;

*if ph_start is before adrd date then give ph_flag and restrict to just these events;
data ADRD_ONLY2; set ADRD_ONLY;
if ph_start < adrd_date then ph_flag = 1;
if ph_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=ADRD_ONLY2; 
by snz_uid ph_start event_id;
data ADRD_ONLY3; set ADRD_ONLY2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=ADRD_ONLY3 noprint;
table snz_uid / out=check3; 
proc means data=check3;
run;
*all good; 

*************;

*INF and ADRD;
* merge ph diagnostic information in and restrict to those with a ADRD and infection and a ph event;
proc sql;
	create table INFADRD as
		select a.*, b.hosp_start as ph_start, b.event_id, b.ph_diagnosis, b.AnyPH_dx from totpop_ph a
		left join steph.phdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 3 and b.AnyPH_dx = 1;
quit;

*if ph_start is before infection date then give ph_flag and restrict to just these events;
data INFADRD2; set INFADRD;
if ph_start < infect_start then ph_flag = 1;
if ph_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=INFADRD2; 
by snz_uid ph_start event_id;
data INFADRD3; set INFADRD2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=INFADRD3 noprint;
table snz_uid / out=check4; 
proc means data=check4;
run;
*all good; 

*combine all into one file; 
data ph_flags_combined;
set NOINFADRD2 INF_ONLY3 ADRD_ONLY3 INFADRD3;
run;

*merge them all back in;
proc sql;
	create table totpop_ph2 as
	select a.*, b.ph_flag
		from totpop_ph a left join ph_flags_combined b on a.snz_uid = b.snz_uid;
quit;

proc means data=totpop_ph; 
proc means data=totpop_ph2;
proc means data=ph_flags_combined; var ph_flag; 
proc freq data=totpop_ph2; table ph_flag; 
run;


********************************************************;
**Code pre-existing mental health event; 
*NEITHER INF/ADRD;
* merge mh diagnostic information in and restrict to those with no infection or ADRD and a mh event;
proc sql;
	create table NOINFADRDmh as
		select a.*, b.hosp_start as mh_start, b.event_id, b.mh_diagnosis, b.AnyMH_dx from totpop_ph2 a
		left join steph.mhdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 0 and b.AnyMH_dx = 1;
quit;

*select first event and create mh flag for this group;
proc sort data=NOINFADRDmh; 
by snz_uid mh_start event_id;
data NOINFADRDmh2; set NOINFADRDmh;
by snz_uid;
if first.snz_uid;
mh_flag = 1;
run; 

*check for duplicates; 
proc freq data=NOINFADRDmh2 noprint;
table snz_uid / out=check; 
proc means data=check;
run;
*all good; 

*************;
*INF ONLY;
* merge mh diagnostic information in and restrict to those with an infection and a mh event;
proc sql;
	create table INF_ONLYmh as
		select a.*, b.hosp_start as mh_start, b.event_id, b.mh_diagnosis, b.AnyMH_dx from totpop_ph2 a
		left join steph.mhdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 1 and b.AnyMH_dx = 1;
quit;

*if ph_start is before infection date then give mh_flag and restrict to just these events;
data INF_ONLYmh2; set INF_ONLYmh;
if mh_start < infect_start then mh_flag = 1;
if mh_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=INF_ONLYmh2; 
by snz_uid mh_start event_id;
data INF_ONLYmh3; set INF_ONLYmh2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=INF_ONLYmh3 noprint;
table snz_uid / out=check2; 
proc means data=check2;
run;
*all good; 

*************;
*ADRD ONLY;
* merge mh diagnostic information in and restrict to those with a ADRD and a mh event;
proc sql;
	create table ADRD_ONLYmh as
		select a.*, b.hosp_start as mh_start, b.event_id, b.mh_diagnosis, b.AnyMH_dx from totpop_ph2 a
		left join steph.mhdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 2 and b.AnyMH_dx = 1;
quit;

*if mh_start is before adrd date then give mh_flag and restrict to just these events;
data ADRD_ONLYmh2; set ADRD_ONLYmh;
if mh_start < adrd_date then mh_flag = 1;
if mh_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=ADRD_ONLYmh2; 
by snz_uid mh_start event_id;
data ADRD_ONLYmh3; set ADRD_ONLYmh2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=ADRD_ONLYmh3 noprint;
table snz_uid / out=check3; 
proc means data=check3;
run;
*all good; 

*************;

*INF and ADRD;
* merge mh diagnostic information in and restrict to those with a ADRD and infection and a mh event;
proc sql;
	create table INFADRDmh as
		select a.*, b.hosp_start as mh_start, b.event_id, b.mh_diagnosis, b.AnyMH_dx from totpop_ph2 a
		left join steph.mhdx_27jul22 b
			on a.snz_uid = b.snz_uid
			where a.inf_ADRD = 3 and b.AnyMH_dx = 1;
quit;

*if mh_start is before infection date then give mh_flag and restrict to just these events;
data INFADRDmh2; set INFADRDmh;
if mh_start < infect_start then mh_flag = 1;
if mh_flag ne 1 then delete;
run;

*select first event to remove duplicates;
proc sort data=INFADRDmh2; 
by snz_uid mh_start event_id;
data INFADRDmh3; set INFADRDmh2;
by snz_uid;
if first.snz_uid;
run; 

*check for duplicates; 
proc freq data=INFADRDmh3 noprint;
table snz_uid / out=check4; 
proc means data=check4;
run;
*all good; 

*combine all into one file; 
data mh_flags_combined;
set NOINFADRDmh2 INF_ONLYmh3 ADRD_ONLYmh3 INFADRDmh3;
run;

proc means data=mh_flags_combined; var mh_flag; run;

*merge them all back in;
proc sql;
	create table totpop_ph3 as
	select a.*, b.mh_flag
		from totpop_ph2 a left join mh_flags_combined b on a.snz_uid = b.snz_uid;
quit;

proc means data=totpop_ph2; 
proc means data=totpop_ph3;
proc means data=mh_flags_combined; var mh_flag; 
proc freq data=totpop_ph3; table mh_flag ph_flag; 
proc freq data=totpop_ph2; table ph_flag; 
run;

********************************************************;
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
	select a.*, b.death_date from totpop_ph3 a 
	left join deaths2 b
		on a.snz_uid = b.snz_uid;
quit;

proc freq data=pop_death noprint; 
table snz_uid/out=check;
proc means data=check;
run;

proc sort data=check; by descending count; run;

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
	select a.snz_uid, a.start_date, b.* 
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

* Delete rows where travel ended prior to start date;
data totpop_os3; set totpop_os2;
if ceased lt start_date then delete;
run;

* Delete rows where travel started following end of study period;
data totpop_os4; set totpop_os3;
if applied gt '30JUN2019'd then delete;
run;

* get date when they left country;
data left; set totpop_os4;
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
	create table totpop_os5 as	
		select* from totpop_os4 a
		left join left2 b
			on a.snz_uid = b.snz_uid;
quit;

*restrict to those who have left the country - where left country date = applied date - and create left country flag;
data totpop_os6; set totpop_os5; 
where leftcountry_date = applied;
leftcountry = 1;
keep snz_uid leftcountry_date;
run;

* remove duplicates;
proc sort data=totpop_os6 nodupkey;
by snz_uid;
run;

proc freq data=totpop_os6 noprint; 
table snz_uid/out=check;
proc means data=check;
run;

* merge back in with original data;
proc sql;
	create table totpop_2 as 
		select * from tot_pop_1 a
		left join totpop_os6 b
			on a.snz_uid = b.snz_uid;
quit;

proc freq data=totpop_2 noprint; 
table snz_uid/out=check;
proc means data=check;
run;

* Finalise end dates;
* create additional variables;
data totpop_3; set totpop_2;

if death_date = . and leftcountry_date ne . then end_date = leftcountry_date;
else if death_date ne .  and leftcountry_date = . then end_date = death_date;
else if death_date ne . and leftcountry_date ne . and death_date > leftcountry_date then end_date = leftcountry_date;
else if death_date ne . and leftcountry_date ne . and death_date < leftcountry_date then end_date = death_date;
else end_date = '30JUN2019'd;

*some people died/left country after end date period - so make end date end of study period;
if end_date > '30JUN2019'd then end_date = '30JUN2019'd;

format end_date date9.;

*create full follow up and actual follow up variables;
fullfol = '30JUN2019'd - start_date;
actualfol = end_date - start_date;

if actualfol < 0 then wgt = 0;
else wgt = actualfol/fullfol;

*some people have actual and full follow up of 0 due to infections occuring on 30 June 2019 (end of study period)
This gives a missing weight, so assign a weight of 0 to these individuals;
if wgt = . then wgt = 0;

if ph_flag ne 1 then ph_flag = 0;
if mh_flag ne 1 then mh_flag = 0;

run;
**Note there's a small number with left country dates that occur after they've supposedly died. Going with death date for these people;

*check that everyone has a weight; 
proc means data=totpop_3; run;

*check flags; 
proc freq data=totpop_ph3;
table mh_flag ph_flag adrd_flag any_infec;
run;

proc freq data=totpop_3;
table mh_flag ph_flag adrd_flag any_infec;
run;


************************************;
*save file; 
data steph.totpop_1Nov22; 
set totpop_3;
run;
************************************;





******************************************************************************;
******************************************************************************;
******************************************************************************;


data temp; set steph.totpop_1Nov22;

if death_date = . and leftcountry_date ne . then date1 = leftcountry_date;
else if death_date ne .  and leftcountry_date = . then date1 = death_date;
else if death_date ne . and leftcountry_date ne . and death_date > leftcountry_date then date1 = leftcountry_date;
else if death_date ne . and leftcountry_date ne . and death_date le leftcountry_date then date1 = death_date;

if adrd_date = . and date1 ne . then end_date2 = date1;
else if adrd_date ne .  and date1 = . then end_date2 = adrd_date;
else if adrd_date ne . and date1 ne . and adrd_date > date1 then end_date2 = date1;
else if adrd_date ne . and date1 ne . and adrd_date le date1 then end_date2 = adrd_date;


*some people died/left country after end date period - so make end date end of study period;
if end_date2 > '30JUN2019'd then end_date2 = '30JUN2019'd;

*also for those who did not have an event, make end date end of study period;
if end_date2 = . then end_date2 = '30JUN2019'd;

format date1 end_date2 date9.;

run;


*create time and status variables;
data temp2; set temp;
status = 0; *left country or end of study period;
if death_date = end_date2 then status = 2; *death as censor;
if adrd_date = end_date2 then status = 1; *adrd event first;

time = end_date2 - start_date;

run;

proc sort data=temp2; by time; run;
proc freq data=temp2; table status; run;


************************************;
*save file;
data steph.totpop_HR_16Nov23; set temp2; run;
************************************;
