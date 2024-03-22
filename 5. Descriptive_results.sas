************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza, revised by B. Milne. 
IDI Refresh: IDI Refresh: IDI_Clean_202206

TASK:
Distribution of infections and dementia

INPUT DATASETS:
steph.totpop_24Sep22
steph.adrd_dx_13jul22
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
*************************************************************;

***ALWAYS RUN THESE LIBNAMES AT THE START***;
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data";

*get total population data (including infection data);
data totpop;
set steph.totpop_24Sep22;
run;


*load dementia data; 
data dementia; set steph.adrd_dx_13jul22; run;

*check dates; 
proc sort data=dementia; by adrd_date; run;
proc sort data=dementia; by descending adrd_date; run;

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

*left join with cohort;
proc sql;
	create table totpop_adrd as 
		select * from totpop a
		left join adrd_id b
			 on a.snz_uid = b.snz_uid;
quit;


*check that there's no duplicates; 
proc freq data=totpop_adrd noprint;
table snz_uid / out=check2;
proc means data=check2; run;

*sort out adrd flag & infection start date;
data totpop_infections2; set totpop_adrd;
if adrd_flag ne 1 then adrd_flag = 0;
*if any_infec ne 1 then any_infec = 0;
infection_date=infect_start;
format infection_date date9.;
run;


**get counts and % of those with infection and those with dementia;
proc freq data=totpop_infections2;
table adrd_flag any_infec;
run;

*repeat by age and sex;
proc sort data=totpop_infections2; by snz_sex_gender_code cohort; 
proc freq data=totpop_infections2; 
table adrd_flag any_infec;
by snz_sex_gender_code;
run;

proc freq data=totpop_infections2; 
table adrd_flag any_infec;
by snz_sex_gender_code cohort;
run;

proc freq data=totpop_infections2; 
table snz_sex_gender_code cohort;
run;

**counts of those with dementia, with and without an infection;
proc freq data=totpop_infections2;
table any_infec;
where adrd_flag = 1;
run;

proc sort data=totpop_infections2; by snz_sex_gender_code cohort; 
*by sex;
proc freq data=totpop_infections2; 
table any_infec;
where adrd_flag = 1;
by snz_sex_gender_code;
run;

*by age and sex;
proc freq data=totpop_infections2; 
table any_infec;
where adrd_flag = 1;
by snz_sex_gender_code cohort;
run;


**counts of those with infection, with and without dementia; 
proc freq data=totpop_infections2;
table adrd_flag;
where any_infec = 1;
run;

*by sex;
proc freq data=totpop_infections2; 
table adrd_flag;
where any_infec = 1;
by snz_sex_gender_code;
run;

*by age and sex;
proc freq data=totpop_infections2; 
table adrd_flag;
where any_infec = 1;
by snz_sex_gender_code cohort;
run;

 



*********************************************;
*********AGE AT INFECTION & DEMENTIA*********;
*********************************************;


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
*Create flags for infec/ADRD events. 
0 = no infection or ADRD, 1 = infection only, 2 = ADRD only, 3 = both;
data totpop_ph; set totpop_noprior;
if any_infec = 0 and adrd_flag = 0 then inf_ADRD = 0;
if any_infec = 1 and adrd_flag = 0 then inf_ADRD = 1; 
if any_infec = 0 and adrd_flag = 1 then inf_ADRD = 2;
if any_infec = 1 and adrd_flag = 1 then inf_ADRD = 3;
run;

proc freq data=totpop_ph; 
table any_infec adrd_flag inf_adrd;
run;


*********;
DATA ages; set totpop_ph;
DOB = mdy(dia_bir_birth_month_nbr,15,dia_bir_birth_year_nbr);
age_infec = (infect_start - DOB)/365.25;
age_adrd = (adrd_date - DOB)/365.25;
run;


proc freq data = ages;
table any_infec adrd_flag inf_adrd;
RUN;

proc means data=ages;
var dob age_infec age_adrd;
run;


*overall;
proc univariate data=ages (where=(inf_adrd=3));
var age_infec age_adrd;
run;

*by cohort;
proc sort data=ages; by cohort; run;
proc univariate data=ages (where=(inf_adrd=3));
var age_infec age_adrd;
by cohort;
run;


*by cohort & sex;
*Male;
proc univariate data=ages (where=(inf_adrd=3 & snz_sex_gender_code="1"));
var age_infec age_adrd;
run;

proc univariate data=ages (where=(inf_adrd=3 & snz_sex_gender_code="1"));
var age_infec age_adrd;
by cohort;
run;

*Female;
proc univariate data=ages (where=(inf_adrd=3 & snz_sex_gender_code="2"));
var age_infec age_adrd;
run;

proc univariate data=ages (where=(inf_adrd=3 & snz_sex_gender_code="2"));
var age_infec age_adrd;
by cohort;
run;




*********************************************;
**************TIME TO DEMENTIA***************;
*********************************************;

*unadjusted;
proc genmod data=steph.totpop_HR_16Nov23 (where=(adrd_date~=.)); 
class any_infec /REF=first ORDER=internal;
model time = any_infec ; lsmeans; run;

*adjusted;
proc genmod data=steph.totpop_HR_16Nov23 (where=(adrd_date~=.)); 
class any_infec snz_sex_gender_code /REF=first ORDER=internal;
model time = any_infec snz_sex_gender_code mh_flag ph_flag dia_bir_birth_year_nbr; lsmeans; run;


