 
************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza
IDI Refresh: IDI Refresh: IDI_Clean_202206

TASK: 
Coding dementia diagnoses from health data

INPUT DATASETS:
moh.mortality_registrations
moh.mortality_diagnosis
moh.pub_fund_hosp_discharges_event
moh.pub_fund_hosp_discharges_diag
moh.pharmaceutical
metadata.moh_dim_form_pack_subsidy_code

OUTPUT DATASETS:
steph.ADRD_mort_13ul22
steph.ADRD_hosp_13Jul22
steph.adrd_pharms_13Jul22
steph.adrd_dx_13Jul22

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
libname moh ODBC dsn=idi_clean_202206_srvprd schema=moh_clean;
libname metadata ODBC dsn=idi_metadata_srvprd schema=clean_read_classifications;
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data";

*******MORTALITY*******
*load mortality registrations;
proc sql;
	create table mort_reg as 
		select *,MDY(moh_mor_death_month_nbr,1,moh_mor_death_year_nbr) as dod format = date9.
		from moh.mortality_registrations;
quit;

proc contents data=mort_reg; run;
*snz_dia_death_reg_uid;

*load mortality diagnoses;
proc sql;
	create table mort_dx as 
		select *
		from moh.mortality_diagnosis;
quit;

*left join diagnosis to registrations;
proc sql; 
	create table mort as 
	select a.snz_dia_death_reg_uid, a.snz_uid, a.dod, a.moh_mor_icd_d_code, 
			b.moh_mort_diag_clinical_code, b.moh_mort_diag_clinic_type_code, b.moh_mort_diag_clinic_sys_code,b.moh_mort_diag_diag_type_code
	from mort_reg a left join mort_dx b
	on a.snz_dia_death_reg_uid = b.snz_dia_death_reg_uid;
quit;

*removed deaths prior to start of obs period - 01 July 1989;
data mort1; set mort;
where '01JUL1989'd le dod;
run;

*create ADRD flags;
data mort2; set mort1;
if moh_mort_diag_clinic_sys_code = '06' then ICD = 9;
if moh_mort_diag_clinic_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if ICD = 10 then ICD10 = 1;	else ICD10 = 0;
if ICD = 9 then ICD9 = 1;	else ICD9 = 0;

code = moh_mort_diag_clinical_code;

if code in 
('F00', 'F000', 'F001', 'F002', 'F009', 'F01', 'F010', 'F011', 'F012', 'F013', 'F018',
'F019', 'F02', 'F020', 'F021', 'F022', 'F023', 'F024', 'F028', 'F03', 'F051', 'F107', 'F137',
'F187', 'F197', 'G30', 'G300', 'G301', 'G308', 'G309', 'G310', 'G311', 'G313','29010','2900',
'29040','2941','29011','2912','3310','3311','3312','2903','2908','2909','29012','29013',
'29020','29021','29041','29042','29043','29282')
then adrd_death = 1; else adrd_death = 0;
run;

* Retain ICD-9 diagnoses for July 1989 - June 1999 
  and ICD-10 diagnoses for July 1999 to June 2019;
data mort3; set mort2;
if (ICD = 10) and ('01JUL1989'd le dod le '30JUN1999'd) then delete;
run;

data mort4; set mort3; 
if (ICD = 9) and ('01JUL1999'd le dod le '30JUN2019'd) then delete;
run;

*remove duplicates;
proc sort data=mort4 nodupkey; by snz_uid descending adrd_death; run;

*check if there are dup snz_uids;
proc freq data=mort4 noprint;
table snz_uid / out=dup;
run;
proc means data=dup; run;

*some duplicates where adrd and non-adrd causes of death;
proc freq data=mort4; table adrd_death; run;

data mort_nodup; set mort4; 
by snz_uid descending adrd_death;
if first.snz_uid;
run;

*check;
proc freq data=mort_nodup; table adrd_death; run;

proc freq data=mort_nodup noprint;
table snz_uid / out=dup2;
run;
proc means data=dup2; run;

*save file, change names back and keep necessary variables;
data steph.ADRD_mort_13ul22; set mort_nodup; where adrd_death = 1; source = "mort"; run;

*******HOSPITALISATIONS*******
**NOTE THIS CODE IS ONLY FOR ADRD HOSPITALISATIONS, OTHER CONDITIONS WILL BE CODED IN SEPARATE FILES;
*load hospitalisation data;
* Limit to events between 1 July 1989 and 30 June 2019 (30-year period);
* NOTE: USE START DATES. Admission must occur in observation period, discharge may be after;
data hosp (keep = snz_uid event_id snz_moh_uid snz_moh_evt_uid moh_evt_end_type_code moh_evt_agency_code hosp_start hosp_end); 
set moh.pub_fund_hosp_discharges_event;
where '01JUL1989'd le moh_evt_evst_date le '30JUN2019'd;
hosp_start = moh_evt_evst_date;
hosp_end = moh_evt_even_date;
event_id = moh_evt_event_id_nbr;
format hosp_start hosp_end date9.;
run;
* NOTE: LONG FILE. Each hospitalization assigned a unique event number;

*check;
proc sort data=hosp; by descending hosp_start; run;

* Clinical codes dataset;
data clin_codes (keep = event_id moh_dia_clinical_code moh_dia_clinical_sys_code moh_dia_diagnosis_type_code);
set moh.pub_fund_hosp_discharges_diag;
event_id = moh_dia_event_id_nbr;
run;

*inner join using event id;
proc sql;
create table hosp_join as
select hosp.*, clin_codes.*
from hosp, clin_codes
where hosp.event_id = clin_codes.event_id;
quit;

*identify ADRD diagnoses;
data hosp_adrd; set hosp_join;
if moh_dia_clinical_sys_code = '06' then ICD = 9;
if moh_dia_clinical_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if ICD = 10 then ICD10 = 1;	else ICD10 = 0;
if ICD = 9 then ICD9 = 1;	else ICD9 = 0;

if moh_dia_clinical_code in 
('F00', 'F000', 'F001', 'F002', 'F009', 'F01', 'F010', 'F011', 'F012', 'F013', 'F018',
'F019', 'F02', 'F020', 'F021', 'F022', 'F023', 'F024', 'F028', 'F03', 'F051', 'F107', 'F137',
'F187', 'F197', 'G30', 'G300', 'G301', 'G308', 'G309', 'G310', 'G311', 'G313','29010','2900',
'29040','2941','29011','2912','3310','3311','3312','2903','2908','2909','29012','29013',
'29020','29021','29041','29042','29043','29282')
then adrd_hosp = 1; else adrd_hosp = 0;
run;

* Retain ICD-9 diagnoses for July 1989 - June 1999 
  and ICD-10 diagnoses for July 1999 to June 2019;
data hosp_adrd2; set hosp_adrd;
if (ICD = 10) and ('01JUL1989'd le hosp_start le '30JUN1999'd) then delete;
run;

data hosp_adrd3; set hosp_adrd2; 
if (ICD = 9) and ('01JUL1999'd le hosp_start le '30JUN2019'd) then delete;
run;

*save file - and only keep ADRD events;
data steph.ADRD_hosp_13Jul22; set hosp_adrd3;
where adrd_hosp = 1;
source = "hosp";
run;

proc freq data=steph.ADRD_hosp_13Jul22; table moh_dia_diagnosis_type_code; run;
*A, B and O codes;

*******PHARMACEUTICALS*******
*Get ADRD related data;
proc sql;
	create table adrd_pharms as
		select a.snz_uid
      ,a.moh_pha_dispensed_date
      ,a.moh_pha_dim_form_pack_code
      ,a.moh_pha_order_type_code
	  ,a.snz_moh_provider_uid
	  ,b.DIM_FORM_PACK_SUBSIDY_KEY
      ,b.CHEMICAL_ID
      ,b.CHEMICAL_NAME
      ,b.FORMULATION_ID
      ,b.FORMULATION_NAME
	  FROM moh.pharmaceutical a left join metadata.moh_dim_form_pack_subsidy_code b
	on input(a.moh_pha_dim_form_pack_code,8.)=b.DIM_FORM_PACK_SUBSIDY_KEY
	WHERE (a.moh_pha_dispensed_date < '30JUN2019'd) 
 AND b.FORMULATION_ID in (392326,392325,403725,403726); 
quit;

*check dates;
proc sort data=adrd_pharms; by moh_pha_dispensed_date; run;

proc sort data=adrd_pharms; by descending moh_pha_dispensed_date; run;

*check pharms;
proc freq data=adrd_pharms; table FORMULATION_ID; run;

*save dataset;
data steph.adrd_pharms_13Jul22; set adrd_pharms; 
adrd_pharms = 1;
source = "pharms";
run;

*******COMBINED FILE*******;
data steph.adrd_dx_13Jul22; 
set steph.ADRD_mort_13ul22(rename=(dod=adrd_date)) steph.ADRD_hosp_13Jul22(rename=(hosp_start = adrd_date)) steph.adrd_pharms_13Jul22(rename=(moh_pha_dispensed_date = adrd_date)); 
keep snz_uid adrd_date source adrd_flag;
adrd_flag = 1;
run;
