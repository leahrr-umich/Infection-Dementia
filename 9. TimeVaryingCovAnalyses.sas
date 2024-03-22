************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza 
IDI Refresh: IDI Refresh: IDI_Clean_202206

TASK:
Time-varying covariate analyses

Update:
4 Aug 23 - cox ph analyses run by cohort and sex

17 Aug 23 - full set of analyses for paper

5 Nov 23 - update outcome specificity to include vascular dementia 

INPUT DATASETS:
steph.timevarcohort_4AUG23
steph.totpop_24Sep22
steph.adrd_hosp_13jul22
steph.adrd_mort_13ul22
steph.adrd_pharms_13jul22
steph.adrd_dx_13jul22
steph.totpop_HR_16Nov23
steph.cohort_nopharms_17Aug23
steph.cohort_nomort_17Aug23
IDI_Clean_202206.data.address_notification
IDI_Metadata.clean_read_CLASSIFICATIONS.DepIndex2013
IDI_Metadata.clean_read_CLASSIFICATIONS.meshblock_concordance

OUTPUT DATASETS:
steph.totpop_demtype_5Nov23

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

*load data;
data totpop; set steph.timevarcohort_4AUG23; run;



*adjusted cox ph models by cohort and sex; 
%macro adcoxph(sex,cohort);
proc phreg data=totpop (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
%mend adcoxph;

*males; 
%adcoxph (sex = 1, cohort = coh2938);
%adcoxph (sex = 1, cohort = coh3948);
%adcoxph (sex = 1, cohort = coh4958);
%adcoxph (sex = 1, cohort = coh5968);

*females; 
%adcoxph (sex = 2, cohort = coh2938);
%adcoxph (sex = 2, cohort = coh3948);
%adcoxph (sex = 2, cohort = coh4958);
%adcoxph (sex = 2, cohort = coh5968);

**Adjusted cox ph models by sex; 
*Male;
proc phreg data=totpop (where=(snz_sex_gender_code="1")); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

*Female;
proc phreg data=totpop (where=(snz_sex_gender_code="2")); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
***Does not run - 


**************************************;
**********splitting in four********** ;
**************************************;
data totpop2;
set totpop;
split=mod(snz_uid,4)+1;
run;

proc freq data=totpop2;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=totpop2;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;

**************************************;
*running analyses on each split by sex;
**************************************;

***MALE***;
proc phreg data=totpop2 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop2 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop2 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


***********************************;
*******PREDICTOR SPECIFICITY*******;
***********************************;

proc freq data=totpop;
table any_infec any_infec2 viral_infec viral_infec2 bacterial_infec bacterial_infec2 
parasitic_infec parasitic_infec2 other_infec other_infec2;
run;

**identifying snz_uids to drop for each infection type to create a clean comparison group;
proc freq data=steph.totpop_24Sep22 ;
table any_infec viral_infec bacterial_infec parasitic_infec other_infec;
run;
*0's on the infection type variables are those that should be set to missing;

data inftypemiss (keep=snz_uid VM BM PM OM);
set steph.totpop_24Sep22 ;
if viral_infec = 0 then VM = 1;
if bacterial_infec = 0 then BM = 1;
if parasitic_infec = 0 then PM = 1; 
if other_infec = 0 then OM = 1;
run;

*should be none with 1 for all (otherwise any_infec variable is incorrect);
proc means data=inftypemiss (where=(VM=1 & BM=1 & PM=1 & OM=1));
var snz_uid;
run;
*all good;

**merging in;
proc sort data=totpop;by snz_uid;run;
proc sort data=inftypemiss;by snz_uid;run;

data totpop3;
merge totpop inftypemiss;
by snz_uid;run;

**checking all 0s for infection typw variables that should be set to missing;
proc freq data=totpop3 (where=(VM=1)); table viral_infec viral_infec2; run;
proc freq data=totpop3 (where=(BM=1)); table bacterial_infec bacterial_infec2; run;
proc freq data=totpop3 (where=(PM=1)); table parasitic_infec parasitic_infec2 ; run;
proc freq data=totpop3 (where=(OM=1)); table other_infec other_infec2; run;
*all good;

**setting to missing;
data totpop4;
set totpop3;
if VM=1 then viral_infec=.;
if VM=1 then viral_infec2=.;
if BM=1 then bacterial_infec=.;
if BM=1 then bacterial_infec2=.;
if PM=1 then parasitic_infec=.;
if PM=1 then parasitic_infec2=.;
if OM=1 then other_infec=.;
if OM=1 then other_infec2=.;
run;

proc freq data=totpop4;
table any_infec any_infec2 viral_infec viral_infec2 bacterial_infec bacterial_infec2 
parasitic_infec parasitic_infec2 other_infec other_infec2;
run;

******************;
**running analyses;
******************;

*adjusted cox ph models by cohort and sex; 
%macro adcoxph_ps(sex,cohort);
proc phreg data=totpop4 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop4 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop4 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop4 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
%mend adcoxph_ps;

*males; 
%adcoxph_ps (sex = 1, cohort = coh2938);
%adcoxph_ps (sex = 1, cohort = coh3948);
%adcoxph_ps (sex = 1, cohort = coh4958);
%adcoxph_ps (sex = 1, cohort = coh5968);

*females; 
%adcoxph_ps (sex = 2, cohort = coh2938);
%adcoxph_ps (sex = 2, cohort = coh3948);
%adcoxph_ps (sex = 2, cohort = coh4958);
%adcoxph_ps (sex = 2, cohort = coh5968);


**Adjusted cox ph models by sex; 
**************************************;
**********splitting in four********** ;
**************************************;
data totpop5;
set totpop4;
split=mod(snz_uid,4)+1;
run;

proc freq data=totpop5;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=totpop5;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;



**************************************;
*running analyses on each split by sex;
**************************************;

**************************************;
**************VIRAL*******************;
**************************************;

***MALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = viral_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
************BACTERIAL*****************;
**************************************;

***MALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = bacterial_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
************PARASITIC*****************;
**************************************;

***MALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = parasitic_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
**************OTHER*******************;
**************************************;

***MALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop5 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = other_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;






****************************************;
**********OUTCOME SPECIFICITY***********;
****SEPARATING OUT VASCULAR DEMENTIA****;
****************************************;

*load adrd data;
data ADRDhosp; 
rename hosp_start = adrd_date;
set steph.adrd_hosp_13jul22;
source = "hosp"; 
code = moh_dia_clinical_code;
where adrd_hosp = 1;
run;

proc freq data=ADRDhosp;
table code;
run;

data ADRDmort;
rename dod=adrd_date;
set steph.adrd_mort_13ul22;
source = "mortality";
where adrd_death = 1;
run;

proc freq data=ADRDmort;
table code adrd_date;
run;

data ADRDpharms;
set Steph.adrd_pharms_13jul22;
where adrd_pharms=1;
run;

proc freq data=ADRDpharms;
table moh_pha_dispensed_date;
run;


data ADRD_nopharms; set ADRDhosp ADRDmort; 
keep snz_uid adrd_date source adrd_flag code AD_flag other_dem Unspec_dem Vasc_dem otherNV_dem;
adrd_flag = 1;
AD_flag = 0;
if code in ('F00', 'F000', 'F001', 'F002', 'F009', 'G30', 'G300', 'G301', 'G308', 'G309', '3310')
then AD_flag = 1; 
Unspec_dem = 0;
if code in ('29021', '2908', '2909', 'F03') then Unspec_dem = 1; 
other_dem = 0;
if (AD_flag = 0 & Unspec_dem = 0) then other_dem = 1; 
**ADDING CODES FOR VASCULAR DEMENTIA & OTHER NON-VASCULAR DEMENTIA;
Vasc_dem = 0;
if code in ('29040', '29041', '29042', '29043', 'F012', 'F013', 'F018', 'F019') 
then Vasc_dem = 1; 
otherNV_dem = 0;
if (AD_flag = 0 & Unspec_dem = 0 & Vasc_dem = 0) then otherNV_dem = 1;
run;

proc freq data=ADRD_nopharms;
table code adrd_flag AD_flag other_dem Unspec_dem Vasc_dem otherNV_dem;
run;
**ALL OK;


*********************;
***loading totpop without dementia prior to infection removed, and add dementia data;
*********************;
data outcomes; set steph.totpop_24Sep22;
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
		select * from outcomes a
		left join adrd_id b
			 on a.snz_uid = b.snz_uid;
quit;

data outcomes2; set totpop_adrd;
keep snz_uid dia_bir_birth_year_nbr snz_sex_gender_code
start_date cohort adrd_start death_date adrd_flag;
if adrd_flag=. then adrd_flag=0;
adrd_start=adrd_date;
format adrd_start date9.;
run;

proc freq data=outcomes2;
table adrd_flag;
run;



**do for ad first;
* merge diagnostic information in;
proc sql;
	create table outcomes_ad as
		select * from outcomes2 a
		left join ADRD_nopharms b
			on a.snz_uid = b.snz_uid
			where AD_flag = 1;
quit;

*flag cases where adrd_date = adrd_start;
data ad; set outcomes_ad;
where adrd_start = adrd_date;
run;

*remove duplicates;
proc sort data=ad nodupkey; by snz_uid; run;

*merge ad flag in to total population;
proc sql;
	create table outcomes_ad2 as
		select a.*, b.ad_flag from outcomes2 a
		left join ad b
			on a.snz_uid = b.snz_uid;
quit;

*check;
proc freq data=outcomes_ad2; table AD_flag;
run;
proc freq data=ad; table AD_flag;
run;


***do for other dementia;
* merge diagnostic information in;
proc sql;
	create table outcomes_od as
		select * from outcomes2 a
		left join ADRD_nopharms b
			on a.snz_uid = b.snz_uid
			where other_dem = 1;
quit;

*flag cases where adrd_date = adrd_start;
data od; set outcomes_od;
where adrd_start = adrd_date;
run;

*remove duplicates;
proc sort data=od nodupkey; by snz_uid; run;

*merge od flag in to total population;
proc sql;
	create table outcomes_od2 as
		select a.*, b.other_dem from outcomes_ad2 a
		left join od b
			on a.snz_uid = b.snz_uid;
quit;


*check;
proc freq data=outcomes_od2; table other_dem;
run;
proc freq data=od; table other_dem;
run;



***do for unspecified dementia;
* merge diagnostic information in;
proc sql;
	create table outcomes_un as
		select * from outcomes2 a
		left join ADRD_nopharms b
			on a.snz_uid = b.snz_uid
			where Unspec_dem = 1;
quit;

*flag cases where adrd_date = adrd_start;
data un; set outcomes_un;
where adrd_start = adrd_date;
run;

*remove duplicates;
proc sort data=un nodupkey; by snz_uid; run;

*merge un flag in to total population;
proc sql;
	create table outcomes_un2 as
		select a.*, b.unspec_dem from outcomes_od2 a
		left join un b
			on a.snz_uid = b.snz_uid;
quit;

*check;
proc freq data=outcomes_un2; table Unspec_dem;
run;
proc freq data=un; table Unspec_dem;
run;



***do for vascular dementia;
* merge diagnostic information in;
proc sql;
	create table outcomes_vas as
		select * from outcomes2 a
		left join ADRD_nopharms b
			on a.snz_uid = b.snz_uid
			where Vasc_dem = 1;
quit;

*flag cases where adrd_date = adrd_start;
data vas; set outcomes_vas;
where adrd_start = adrd_date;
run;

*remove duplicates;
proc sort data=vas nodupkey; by snz_uid; run;

*merge un flag in to total population;
proc sql;
	create table outcomes_vas2 as
		select a.*, b.Vasc_dem from outcomes_un2 a
		left join vas b
			on a.snz_uid = b.snz_uid;
quit;

*check;
proc freq data=outcomes_vas2; table Vasc_dem;
run;
proc freq data=vas; table Vasc_dem;
run;



***do for other dementia EXCLUDING VASCULAR DEMENTIA;
* merge diagnostic information in;
proc sql;
	create table outcomes_onvd as
		select * from outcomes2 a
		left join ADRD_nopharms b
			on a.snz_uid = b.snz_uid
			where otherNV_dem = 1;
quit;

*flag cases where adrd_date = adrd_start;
data onvd; set outcomes_onvd;
where adrd_start = adrd_date;
run;

*remove duplicates;
proc sort data=onvd nodupkey; by snz_uid; run;

*merge un flag in to total population;
proc sql;
	create table outcomes3 as
		select a.*, b.otherNV_dem from outcomes_vas2 a
		left join onvd b
			on a.snz_uid = b.snz_uid;
quit;

*check;
proc freq data=outcomes3; table otherNV_dem;
run;
proc freq data=onvd; table otherNV_dem;
run;





proc freq data=outcomes3;
table adrd_flag AD_flag other_dem Unspec_dem Vasc_dem otherNV_dem;
*table AD_flag*other_dem AD_flag*Unspec_dem other_dem*Unspec_dem;
table AD_flag*Vasc_dem other_dem*Vasc_dem Unspec_dem*Vasc_dem otherNV_dem*Vasc_dem;
run;
*some overlap;



*create appropriate flags and do checks;
data outcomes4; set outcomes3;
if adrd_flag = 0 then ad_flag = 0;
if adrd_flag = 0 then other_dem = 0;
if adrd_flag = 0 then unspec_dem = 0;
if adrd_flag = 0 then Vasc_dem = 0;
if adrd_flag = 0 then otherNV_dem = 0;
*if ad_flag = 1 then other_dem = .;
*if ad_flag = 1 then unspec_dem = .;
*if other_dem = 1 then unspec_dem = .;
if (adrd_flag = 1 & ad_flag~=1 & other_dem ~=1 & Vasc_dem ~=1 & otherNV_dem ~=1) 
then unspec_dem = 1;
run;

proc freq data=outcomes4;
table adrd_flag AD_flag other_dem Unspec_dem Vasc_dem otherNV_dem;
table AD_flag*other_dem AD_flag*Unspec_dem other_dem*Unspec_dem;
table AD_flag*Vasc_dem other_dem*Vasc_dem Unspec_dem*Vasc_dem otherNV_dem*Vasc_dem;
run;



***********SAVING FILE**********;
data steph.totpop_demtype_5Nov23;
set outcomes4;
run;




*****Getting snz_uids for missing cases;
data outcomemiss (keep=snz_uid ADM ODM UNM VDM ONVDM);
set steph.totpop_demtype_5Nov23;
if AD_flag = . then ADM = 1;
if other_dem = . then ODM = 1; 
if Unspec_dem = . then UNM = 1;
if Vasc_dem = . then VDM = 1;
if otherNV_dem = . then ONVDM = 1; 
run;

*checking;
proc freq data=outcomes4; table adrd_flag AD_flag other_dem Unspec_dem Vasc_dem otherNV_dem; run;
proc freq data=outcomemiss; table ADM ODM UNM VDM ONVDM; run;

*all good;

**merging in;
proc sort data=totpop;by snz_uid;run;
proc sort data=outcomemiss;by snz_uid;run;

data totpop6;
merge totpop outcomemiss;
by snz_uid;run;

**checking all 1s for adrd_flag variables that should be set to missing;
proc freq data=totpop6 (where=(ADM=1)); table adrd_flag; run;
proc freq data=totpop6 (where=(ODM=1)); table adrd_flag; run;
proc freq data=totpop6 (where=(UNM=1)); table adrd_flag ; run;
proc freq data=totpop6 (where=(VDM=1)); table adrd_flag; run;
proc freq data=totpop6 (where=(ONVDM=1)); table adrd_flag ; run;
*all good;


**setting outcome status vars to missing;
data totpop7;
set totpop6;
ad_status=status;
if ADM=1 then ad_status=.;
od_status=status;
if ODM=1 then od_status=.;
un_status=status;
if UNM=1 then un_status=.;
vd_status=status;
if VDM=1 then vd_status=.;
onvd_status=status;
if ONVDM=1 then onvd_status=.;
run;

proc freq data=totpop7;
table adrd_flag status adrd_flag*status;
table ad_status od_status un_status vd_status onvd_status;
table adrd_flag*(ad_status od_status un_status vd_status onvd_status);
run;



******************;
**running analyses;
******************;

*adjusted cox ph models by cohort and sex; 
%macro outcoxph(sex,cohort);
proc phreg data=totpop7 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop7 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop7 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop7 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop7 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
%mend outcoxph;

*males; 
%outcoxph (sex = 1, cohort = coh2938);
%outcoxph (sex = 1, cohort = coh3948);
%outcoxph (sex = 1, cohort = coh4958);
%outcoxph (sex = 1, cohort = coh5968);

*females; 
%outcoxph (sex = 2, cohort = coh2938);
%outcoxph (sex = 2, cohort = coh3948);
%outcoxph (sex = 2, cohort = coh4958);
%outcoxph (sex = 2, cohort = coh5968);

**Adjusted cox ph models by sex; 



**************************************;
**********splitting in four********** ;
**************************************;
data totpop8;
set totpop7;
split=mod(snz_uid,4)+1;
run;

proc freq data=totpop8;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=totpop8;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;

**************************************;
*running analyses on each split by sex;
**************************************;

**************************************;
*************ALZHEIMERS***************;
**************************************;

***MALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*ad_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
***********OTHER DEMENTIA*************;
**************************************;

***MALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*od_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
*********UNSPECIFIED DEMENTIA*********;
**************************************;

***MALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*un_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
**************VASCULAR****************;
**************************************;

***MALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*vd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
*****OTHER NON-VASCULAR DEMENTIA******;
**************************************;

***MALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=totpop8 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*onvd_status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;






********************************************************************;
*************************COMPETING RISKS****************************;
********************************************************************;

*Updating time covariate file to create separate indicator for death;
data totpop_comprisk; set totpop;
status2 = 0; *left country or end of study period;
if death_date = stop_date then status2 = 2; *death as censor;
if adrd_date = stop_date then status2 = 1; *adrd event first;
run;

proc freq data=totpop_comprisk;
table status status2 status*status2;
run;


**MODELS BY COHORT & SEX;

%macro comprisk(sex,cohort);
proc phreg data=totpop_comprisk (where=(snz_sex_gender_code="&sex." and cohort="&cohort."));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm; 
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag;
run;
proc phreg data=totpop_comprisk (where=(snz_sex_gender_code="&sex." and cohort="&cohort."));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm; 
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;
%mend comprisk;

*males; 
%comprisk (sex = 1, cohort = coh2938);
%comprisk (sex = 1, cohort = coh3948);
%comprisk (sex = 1, cohort = coh4958);
%comprisk (sex = 1, cohort = coh5968);

*females; 
%comprisk (sex = 2, cohort = coh2938);
%comprisk (sex = 2, cohort = coh3948);
%comprisk (sex = 2, cohort = coh4958);
%comprisk (sex = 2, cohort = coh5968);


**************************************;
**********splitting in four********** ;
**************************************;

data totpop_comprisk_2;
set totpop_comprisk;
split=mod(snz_uid,4)+1;
run;

proc freq data=totpop_comprisk_2;
table snz_sex_gender_code*split;
run;


**************************************;
*running analyses on each split by sex;
**************************************;

***MALE***;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split = 1)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split=1));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split = 2)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split=2));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split = 3)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split=3));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split = 4)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='1' and split=4));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;



***FEMALE***;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split = 1)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split=1));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split = 2)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split=2));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split = 3)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split=3));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;

proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split = 4)); 
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0,2) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag ;
run;
proc phreg data=totpop_comprisk_2 (where=(snz_sex_gender_code='2' and split=4));
class any_infec2(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model (starttime,stoptime)*status2(0) = 
any_infec2 dia_bir_birth_year_nbr mh_flag ph_flag  /eventcode(cox) = 1;
run;





********************************************************************;
***************TIME VARYING INTERVALS***************;
********************************************************************;

data cohort_diff_followup; set steph.totpop_HR_16Nov23; 
time1=time; if time>365 then time1=365;
adrd1=status; if time>365 then adrd1=.;

time5=time; if time>1826 then time5=1826;
adrd5=status; if time>1826 then adrd5=.; if time<=365 then adrd5=.; 

time10=time; if time>3652 then time10=3652;
adrd10=status; if time>3652 then adrd10=.; if time<=1826 then adrd10=.; 

time15=time; if time>5479 then time15=5479;
adrd15=status; if time>5479 then adrd15=.; if time<=3652 then adrd15=.;

time20=time; if time>7305 then time20=7305;
adrd20=status; if time>7305 then adrd20=.; if time<=5479 then adrd20=.;

time25=time; if time>9131 then time25=9131;
adrd25=status; if time>9131 then adrd25=.; if time<=7305 then adrd25=.;

time30=time; 
adrd30=status; if time<=9131 then adrd30=.;
run;


proc freq data=cohort_diff_followup;
table status adrd1 adrd5 adrd10 adrd15 adrd20 adrd25 adrd30;
table ph_flag*(status adrd1 adrd5 adrd10 adrd15 adrd20 adrd25 adrd30);
run;
proc means data=cohort_diff_followup; var wgt; run;

*HR models;
proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time1*adrd1(0,2) = 
any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time5*adrd5(0,2) = 
any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time10*adrd10(0,2) = any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time15*adrd15(0,2) = any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time20*adrd20(0,2) = any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time25*adrd25(0,2) = any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;
***;

proc phreg data=cohort_diff_followup; 
class snz_sex_gender_code any_infec(ref=first) mh_flag(ref=first) ph_flag(ref=first) /param=glm;
model time30*adrd30(0,2) = any_infec snz_sex_gender_code dia_bir_birth_year_nbr mh_flag ph_flag / rl;
run;







**************************************;
************DEPRIVATION***************;
**************************************;


*****getting IDs*****;
data cohort; set steph.timevarcohort_4AUG23; 
keep snz_uid cohort; run;
proc sort data=cohort nodup; by snz_uid; run;


***getting addresses;
proc sql;
connect to odbc(dsn=idi_clean_202206_srvprd);
create table address as
select * from connection to odbc
(select snz_uid,ant_notification_date,ant_replacement_date,ant_meshblock_code 
FROM IDI_Clean_202206.data.address_notification);
disconnect from odbc;
quit;

data address2; set address; if ant_meshblock_code ~=""; run;

proc sort data=COHORT; by snz_uid; run;
proc sort data=address2; by snz_uid; run;

data cohort_address; merge cohort address2; by snz_uid; if cohort ~=""; run;

data temp; set cohort_address; if ant_meshblock_code =""; run;
proc sort data=temp nodup; by snz_uid; run;


proc freq data=COHORT; table cohort; run;
proc freq data=temp; table cohort; run;



***getting nzdep;
proc sql;
connect to odbc(dsn=IDI_Metadata_srvprd);
create table nzdep as
select * from connection to odbc
(select Meshblock2013,DepIndex2013 FROM IDI_Metadata.clean_read_CLASSIFICATIONS.DepIndex2013);
disconnect from odbc;
quit;
proc freq data=nzdep; table DepIndex2013; run;



***getting Meshblock2013;
proc sql;
connect to odbc(dsn=IDI_Metadata_srvprd);
create table concordance as
select * from connection to odbc
(select meshblock_code,MB2018_code,MB2017_code,MB2016_code,MB2015_code,MB2014_code,MB2013_code,census_meshblock_code 
FROM IDI_Metadata.clean_read_CLASSIFICATIONS.meshblock_concordance);
disconnect from odbc;
quit;

data cohort_address2; set cohort_address; meshblock_code=ant_meshblock_code; run;





***adding Meshblock2013 to cohort file;
proc sort data=concordance; by meshblock_code; run;
proc sort data=cohort_address2; by meshblock_code; run;
data cohort_address3; merge cohort_address2 concordance; by meshblock_code; if cohort ~=""; run;

proc means data=cohort_address3 (where=(meshblock_code ~="")); var snz_uid; run;
proc means data=cohort_address3 (where=(MB2013_code ~="")); var snz_uid; run;
proc means data=cohort_address3 (where=(meshblock_code ~="" & MB2013_code="")); 
var snz_uid; run;

proc freq data=cohort_address3 (where=(meshblock_code ~="" & MB2013_code="")); 
table meshblock_code;
run;


data cohort_address4 
(drop= ant_meshblock_code MB2018_code MB2017_code MB2016_code MB2015_code MB2014_code MB2013_code census_meshblock_code); 
set cohort_address3; Meshblock2013 = MB2013_code;
run;
proc means data=cohort_address4 (where=(meshblock_code ~="")); var snz_uid; run;
proc means data=cohort_address4 (where=(Meshblock2013 ~="")); var snz_uid; run;


***adding in NZDep;
proc sort data=cohort_address4; by Meshblock2013; run;
proc sort data=nzdep; by Meshblock2013; run;
data cohort_address5; merge cohort_address4 nzdep; by Meshblock2013; if cohort ~=""; run;

proc freq data=cohort_address5; table DepIndex2013; run;


data temp; set cohort_address5; if DepIndex2013 ~= .; run;
proc sort data=temp nodupkey; by snz_uid; run;
proc freq data=temp; table cohort; run;




***checking number of address changes, and keeping first address with NZDep;
data cohort_address6; set cohort_address5; if DepIndex2013 ~= .; run;
proc freq data=cohort_address6 noprint; table snz_uid /out=temp2; run;
proc freq data=temp2; table count; run;

proc freq data=cohort_address6; table ant_notification_date; run;

proc sort data=cohort_address6; by snz_uid ant_notification_date; run;




data cohort_address7; set cohort_address6;
count + 1;
by snz_uid;
if first.snz_uid then count = 1;
run;

proc freq data=cohort_address7; table count; run;


data dep1 (keep=snz_uid dep1 ); set cohort_address7; if count=1 ; dep1  = DepIndex2013; run;
data dep2 (keep=snz_uid dep2 ); set cohort_address7; if count=2 ; dep2  = DepIndex2013; run;
data dep3 (keep=snz_uid dep3 ); set cohort_address7; if count=3 ; dep3  = DepIndex2013; run;
data dep4 (keep=snz_uid dep4 ); set cohort_address7; if count=4 ; dep4  = DepIndex2013; run;
data dep5 (keep=snz_uid dep5 ); set cohort_address7; if count=5 ; dep5  = DepIndex2013; run;
data dep6 (keep=snz_uid dep6 ); set cohort_address7; if count=6 ; dep6  = DepIndex2013; run;
data dep7 (keep=snz_uid dep7 ); set cohort_address7; if count=7 ; dep7  = DepIndex2013; run;
data dep8 (keep=snz_uid dep8 ); set cohort_address7; if count=8 ; dep8  = DepIndex2013; run;
data dep9 (keep=snz_uid dep9 ); set cohort_address7; if count=9 ; dep9  = DepIndex2013; run;
data dep10 (keep=snz_uid dep10 ); set cohort_address7; if count=10 ; dep10  = DepIndex2013; run;
data dep11 (keep=snz_uid dep11 ); set cohort_address7; if count=11 ; dep11  = DepIndex2013; run;
data dep12 (keep=snz_uid dep12 ); set cohort_address7; if count=12 ; dep12  = DepIndex2013; run;
data dep13 (keep=snz_uid dep13 ); set cohort_address7; if count=13 ; dep13  = DepIndex2013; run;
data dep14 (keep=snz_uid dep14 ); set cohort_address7; if count=14 ; dep14  = DepIndex2013; run;
data dep15 (keep=snz_uid dep15 ); set cohort_address7; if count=15 ; dep15  = DepIndex2013; run;
data dep16 (keep=snz_uid dep16 ); set cohort_address7; if count=16 ; dep16  = DepIndex2013; run;
data dep17 (keep=snz_uid dep17 ); set cohort_address7; if count=17 ; dep17  = DepIndex2013; run;
data dep18 (keep=snz_uid dep18 ); set cohort_address7; if count=18 ; dep18  = DepIndex2013; run;
data dep19 (keep=snz_uid dep19 ); set cohort_address7; if count=19 ; dep19  = DepIndex2013; run;
data dep20 (keep=snz_uid dep20 ); set cohort_address7; if count=20 ; dep20  = DepIndex2013; run;

data dep; merge dep1 dep2 dep3 dep4 dep5 dep6 dep7 dep8 dep9 dep10 dep11 dep12 dep13 dep14 dep15 dep16 dep17 dep18 dep19 dep20; by snz_uid; 
meandep = mean(dep1,dep2,dep3,dep4,dep5,dep6,dep7,dep8,dep9,dep10,dep11,dep12,dep13,dep14,dep15,dep16,dep17,dep18,dep19,dep20);
run;

proc means data=dep; var dep1 meandep; run;


*****adding dep1 and meandep into analysis file;
proc sort data=steph.timevarcohort_4AUG23; by snz_uid; run;
proc sort data=dep; by snz_uid; run;
data totpop_dep (drop=dep2 dep3 dep4 dep5 dep6 dep7 dep8 dep9 dep10 dep11 dep12 dep13 dep14 dep15 dep16 dep17 dep18 dep19 dep20); 
merge steph.timevarcohort_4AUG23 dep; by snz_uid; 
	if dep1=. then dep1cat='missing';
	else if dep1 le 2 then dep1cat='Q1';
	else if dep1 le 4 then dep1cat='Q2';
	else if dep1 le 6 then dep1cat='Q3';
	else if dep1 le 8 then dep1cat='Q4';
	else if dep1 ge 9 then dep1cat='Q5';
run;
proc means data=totpop_dep; var dep1 meandep; run;
proc freq data=totpop_dep; table dep1cat; run;

******************;
**running analyses;
******************;

*adjusted cox ph models by cohort and sex; 
%macro depcoxph(sex,cohort);
proc phreg data=totpop_dep (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat / rl;
run;
%mend depcoxph;

*males; 
%depcoxph (sex = 1, cohort = coh2938);
%depcoxph (sex = 1, cohort = coh3948);
%depcoxph (sex = 1, cohort = coh4958);
%depcoxph (sex = 1, cohort = coh5968);

*females; 
%depcoxph (sex = 2, cohort = coh2938);
%depcoxph (sex = 2, cohort = coh3948);
%depcoxph (sex = 2, cohort = coh4958);
%depcoxph (sex = 2, cohort = coh5968);



**************************************;
**********splitting in four********** ;
**************************************;
data totpop_dep2;
set totpop_dep;
split=mod(snz_uid,4)+1;
run;

proc freq data=totpop_dep2;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=totpop_dep2;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;

**************************************;
*running analyses on each split by sex;
**************************************;

***MALE***;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="1" & split=1)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="1" & split=2)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="1" & split=3));  
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="1" & split=4)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;

***FEMALE***;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="2" & split=1)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="2" & split=2)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="2" & split=3)); 
class dep1cat / ref=first order=internal; 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;
proc phreg data=totpop_dep2 (where=(snz_sex_gender_code="2" & split=4)); 
class dep1cat / ref=first order=internal;
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr dep1cat/ rl;
run;






**************************************;
**************************************;
*************SENSITIVITY**************;
**************ANALYSES****************;
**************************************;
**************************************;

**************************************;
*************NO PHARMS****************;
**************************************;

data nopharms;
set steph.cohort_nopharms_17Aug23; 
run;

**need to add my & ph vars;
data mhph;
set totpop;
keep snz_uid mh_flag ph_flag;
run;

proc freq data=mhph;
table mh_flag ph_flag;
run;

proc sort data=nopharms; by snz_uid; run;
proc sort data=mhph nodupkey; by snz_uid; run;

data nopharms2;
merge nopharms mhph;
by snz_uid;
run;

proc freq data=nopharms2;
table adrd_flag status mh_flag ph_flag;
run;
*all good;


*adjusted cox ph models by cohort and sex; 
%macro npcoxph(sex,cohort);
proc phreg data=nopharms2 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
%mend npcoxph;

*males; 
%npcoxph (sex = 1, cohort = coh2938);
%npcoxph (sex = 1, cohort = coh3948);
%npcoxph (sex = 1, cohort = coh4958);
%npcoxph (sex = 1, cohort = coh5968);

*females; 
%npcoxph (sex = 2, cohort = coh2938);
%npcoxph (sex = 2, cohort = coh3948);
%npcoxph (sex = 2, cohort = coh4958);
%npcoxph (sex = 2, cohort = coh5968);


**************************************;
**********splitting in four********** ;
**************************************;
data nopharms3;
set nopharms2;
split=mod(snz_uid,4)+1;
run;

proc freq data=nopharms3;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=nopharms3;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;

**************************************;
*running analyses on each split by sex;
**************************************;

***MALE***;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nopharms3 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;


**************************************;
**************NO MORT*****************;
**************************************;

data nomort;
set steph.cohort_nomort_17Aug23; 
run;

proc sort data=nomort; by snz_uid; run;

data nomort2;
merge nomort mhph;
by snz_uid;
run;

proc freq data=nomort2;
table adrd_flag status mh_flag ph_flag;
run;
*all good;


*adjusted cox ph models by cohort and sex; 
%macro nmcoxph(sex,cohort);
proc phreg data=nomort2 (where=(snz_sex_gender_code="&sex." and cohort="&cohort.")); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
%mend nmcoxph;

*males; 
%nmcoxph (sex = 1, cohort = coh2938);
%nmcoxph (sex = 1, cohort = coh3948);
%nmcoxph (sex = 1, cohort = coh4958);
%nmcoxph (sex = 1, cohort = coh5968);

*females; 
%nmcoxph (sex = 2, cohort = coh2938);
%nmcoxph (sex = 2, cohort = coh3948);
%nmcoxph (sex = 2, cohort = coh4958);
%nmcoxph (sex = 2, cohort = coh5968);


**************************************;
**********splitting in four********** ;
**************************************;
data nomort3;
set nomort2;
split=mod(snz_uid,4)+1;
run;

proc freq data=nomort3;
table snz_sex_gender_code*split;
run;
*very equal splits;

*checking dementia and infection cases by splits;
proc freq data=nomort3;
table snz_sex_gender_code*split*status;
table snz_sex_gender_code*split*any_infec2;
run;
*very similar;

**************************************;
*running analyses on each split by sex;
**************************************;

***MALE***;
proc phreg data=nomort3 (where=(snz_sex_gender_code="1" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="1" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="1" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="1" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;

***FEMALE***;
proc phreg data=nomort3 (where=(snz_sex_gender_code="2" & split=1)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="2" & split=2)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="2" & split=3));  
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
proc phreg data=nomort3 (where=(snz_sex_gender_code="2" & split=4)); 
model(starttime,stoptime)*status(0) = any_infec2 mh_flag ph_flag dia_bir_birth_year_nbr / rl;
run;
