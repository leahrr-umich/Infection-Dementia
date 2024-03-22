************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza and B. Milne
(adapted from M. Iyer & L. Richmond-Rakerd)
IDI Refresh: IDI Refresh: IDI_Clean_202206

TASK:
Coding infections from hospitalisation data

INPUT DATASETS:
moh.pub_fund_hosp_discharges_event
moh.pub_fund_hosp_discharges_diag

OUTPUT DATASETS:
steph.primdiag
steph.infections_dx_BARRY_19Sep22
steph.infections_only_dx_BARRY_19Sep22

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
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data";

*load hospitalisation data;
* Limit to events between 1 July 1989 and 30 June 2019 (30-year period);
* NOTE: USE START DATES. Admission must occur in observation period, discharge may be after;

* hosp events data;
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

* Clinical codes dataset - hosp diagnoses;
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

*check dx type codes;
proc freq data=hosp_join;
table moh_dia_diagnosis_type_code;
run;

*creating primary diagnosis dataset;
data primdiag (keep=event_id primdiag); set hosp_join;
if moh_dia_diagnosis_type_code='A';
* Create ICD-9 v ICD-10 indicator;
if moh_dia_clinical_sys_code = '06' then ICD = 9;
if moh_dia_clinical_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if (ICD = 10) and ('01JUL1989'd le hosp_start le '30JUN1999'd) then delete;

if (ICD = 9) and ('01JUL1999'd le hosp_start le '30JUN2019'd) then delete;
primdiag=moh_dia_clinical_code;
run;

proc sort data=primdiag; by event_id; run;

*save;
data steph.primdiag; set primdiag; run;

*code infections;
data hosp_infections; set hosp_join;
if moh_dia_diagnosis_type_code='A' or moh_dia_diagnosis_type_code='B';
* Create ICD-9 v ICD-10 indicator;
if moh_dia_clinical_sys_code = '06' then ICD = 9;
if moh_dia_clinical_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if ICD = 10 then ICD10 = 1;	else ICD10 = 0;
if ICD = 9 then ICD9 = 1;	else ICD9 = 0;

if (ICD = 10) and ('01JUL1989'd le hosp_start le '30JUN1999'd) then delete;

if (ICD = 9) and ('01JUL1999'd le hosp_start le '30JUN2019'd) then delete;
run;

*code infection types;
data hosp_infections2; set hosp_infections;
*Viral;
if icd=9 & ((substr(moh_dia_clinical_code,1,3) in ('042','045','046','047','048','049','050','051','052','053','054','055','056','057','058','059','060',
'061','062','063','064','065','066','070','071','072','074','075','137','460','480','487','488'))
or (moh_dia_clinical_code in ('0771','0772','0773','0774','0778','07799','0780','0781','0784','0785','0786','0787','07889','0790','0791','0792',
'0793','0794','0795','0796','07981','07982','07983','07989','07999','7710','7711'))) then viral_infec = 1;

if icd=10 & (moh_dia_clinical_code in ('A600','A630','A748','A803','A804','A809','A810','A811','A812','A818','A819','A829','A830','A831','A832','A833',
'A834','A835','A838','A839','A840','A841','A848','A849','A852','A870','A871','A872','A888','A89','A90','A922','A928','A931','A932','A938','A94',
'A950','A951','A959','A968','A980','A981','A982','A985','B000','B002','B003','B004','B005','B007','B008','B009','B011','B012','B018','B019','B021',
'B022','B023','B028','B029','B03','B050','B052','B053','B058','B059','B060','B068','B069','B07','B080','B081','B083','B084','B085','B088','B09',
'B150','B159','B160','B161','B162','B169','B170','B171','B172','B178','B180','B181','B182','B190','B199','B24','B259','B260','B261','B262','B263',
'B268','B269','B279','B300','B301','B302','B303','B308','B330','B332','B333','B338','B340','B341','B344','B348','B349','B900','B901','B902','B908',
'B909','G630','H192','H621','J00','J100','J101','J108','J120','J121','J122','J128','J129','K770','L998','M0149','N512','N770','N771','P350','P351'))
then viral_infec = 1;
	

*Bacterial;
if icd=9 & ((substr(moh_dia_clinical_code,1,3) in ('001','002','003','004','005','010','011','012','013','014','015','016','017','018','020','021','022','023',
'024','025','026','027','030','031','032','033','034','035','036','037','038','039','040','041','073','076','080','081','082','083','087','090','091','092',
'093','094','095','096','097','098','100','101','102','103','104','137','320','324','383','475','481','482','513','566','670','680','681','682','684'))
or (substr(moh_dia_clinical_code,1,4) in ('5233', '6466'))
or (moh_dia_clinical_code in ('07798', '0783', '07888', '07988', '07998', '0990', '0991','0992', '09941', '0995', '5227', '5272', '5273', '5283', '5695', 
'7713', '7714', '77183'))) then bacterial_infec = 1;

if icd=10 & (moh_dia_clinical_code in ('A000','A001','A009','A010','A011','A012','A013','A014','A020','A021','A022','A028','A029','A030','A031','A032','A033','A038',
'A039','A050','A051','A052','A053','A058','A059','A150','A151','A152','A153','A154','A155','A156','A157','A158','A160','A161','A162','A163','A164','A165',
'A167','A168','A170','A171','A178','A179','A180','A181','A182','A183','A184','A185','A186','A187','A188','A192','A198','A199','A200','A201','A202','A207',
'A208','A209','A210','A211','A212','A213','A218','A219','A220','A221','A222','A227','A228','A229','A230','A231','A232','A233','A238','A239','A240','A244',
'A250','A251','A259','A269','A270','A278','A279','A280','A281','A288','A289','A300','A301','A303','A305','A308','A309','A310','A311','A318','A319','A329',
'A33','A35','A360','A361','A362','A363','A368','A369','A370','A371','A378','A379','A38','A390','A391','A394','A395','A398','A399','A403','A409','A412','A413',
'A414','A4151','A4152','A4158','A418','A419','A420','A421','A422','A428','A429','A46','A480','A488','A500','A501','A502','A503','A504','A505','A506','A507',
'A509','A510','A511','A512','A513','A514','A515','A520','A521','A522','A527','A528','A529','A530','A539','A540','A542','A543','A544','A545','A546','A548',
'A55','A560','A561','A562','A563','A564','A568','A57','A58','A65','A660','A661','A662','A663','A664','A665','A666','A667','A668','A669','A670','A671','A672',
'A673','A679','A680','A681','A689','A691','A698','A699','A70','A710','A711','A719','A740','A748','A749','A750','A751','A752','A753','A759','A770','A771',
'A772','A773','A778','A779','A78','A790','A791','A798','A799','B479','B900','B901','B902','B908','B909','B950','B951','B952','B953','B9541','B9542','B9548',
'B956','B957','B958','B962','B963','B964','B965','B966','B967','B9681','B9688','D77','E350','G000','G001','G002','G003','G008','G009','G01','G050','G060',
'G061','G062','H131','H190','H192','H220','H320','H480','H481','H700','H701','H702','H708','H709','H750','H940','H950','H951','I320','I390','I391','I392',
'I393','I398','I410','I520','I607','I790','I791','J020','J13','J14','J150','J151','J152','J153','J154','J155','J156','J158','J159','J170','J178','J36','J387',
'J852','J853','J998','K046','K052','K112','K113','K122','K230','K610','K630','K670','K671','K672','K678','K770','K908','K930','L010','L020','L021','L022',
'L023','L024','L028','L029','L0301','L0302','L0310','L0311','L032','L033','L038','L039','L998','M0109','M0139','M6009','M6309','M6809','M9019','M9029','N290',
'N302','N338','N390','N510','N511','N518','N72','N740','N741','N743','O239','O753','O85','O861','P38','R591'))
then bacterial_infec = 1;


*Parasitic;
if icd=9 & (substr(moh_dia_clinical_code,1,3) in ('006','007','008','084','085','086','120','121','122','123','124','125','126','127','128','129','130','131','132',
'133','134'))	then parasitic_infec = 1;
	
if icd=10 & (moh_dia_clinical_code in ('A020','A040','A041','A042','A043','A044','A045','A046','A047','A048','A049','A060','A061','A062','A064','A065','A066','A067',
'A068','A069','A070','A071','A072','A073','A078','A079','A080','A081','A082','A083','A085','A590','A598','A599','B508','B509','B519','B529','B530','B538',
'B54','B550','B551','B552','B559','B560','B561','B569','B571','B572','B575','B580','B581','B582','B583','B588','B589','B650','B651','B652','B653','B658',
'B659','B660','B661','B663','B664','B665','B668','B669','B670','B671','B673','B674','B675','B676','B677','B678','B679','B680','B681','B689','B699','B700',
'B701','B710','B718','B719','B72','B73','B740','B741','B743','B744','B748','B749','B75','B760','B761','B779','B789','B79','B80','B810','B811','B812','B814',
'B818','B820','B829','B830','B831','B838','B839','B850','B851','B852','B853','B854','B86','B879','B880','B882','B883','B889','E350','I412','N510','N771'))
then parasitic_infec = 1;	

*All other infections; 
if icd=9 & ((substr(moh_dia_clinical_code,1,3) in ('009','088','110','111','112','113','114','115','116','117','118','135','136','139','245','321','322','323','363',
'370','371','381','382','420','421','422','461','462','463','464','465','466','471','472','473','474','476','483','484','485','486','490','491','494','510',
'511','531','532','533','535','538','540','541','542','543','567','580','582','583','590','595','597','601','604','614','615','616','647','675','683','686',
'711','730'))
or (substr(moh_dia_clinical_code,1,4) in ('6593','9966','9985','9993'))
or (moh_dia_clinical_code in ('0770','0782','07881','0993','09940','09949','0998','0999','6031','72081','7712','7715','7716','7717','77181','77182','77189',
'99762'))) then other_infec=1;

if icd=10 & (moh_dia_clinical_code in ('A068','A09','A449','A638','A64','A692','A740','A881','A938','A94','B348','B350','B351','B352','B353','B354','B356','B358',
'B359','B360','B361','B362','B363','B368','B369','B370','B371','B372','B373','B374','B375','B376','B3781','B3788','B379','B380','B381','B382','B383','B384',
'B388','B389','B394','B395','B399','B409','B419','B420','B439','B449','B459','B469','B470','B480','B481','B482','B487','B488','B59','B600','B888','B89',
'B940','B941','B948','D869','E060','E061','E063','E064','E065','E069','G020','G021','G028','G030','G031','G039','G040','G048','G049','G051','G052','G92',
'H160','H161','H162','H163','H164','H168','H169','H170','H171','H178','H179','H180','H181','H182','H183','H184','H185','H186','H187','H188','H189','H192',
'H193','H300','H301','H302','H308','H309','H310','H311','H312','H313','H314','H318','H319','H353','H368','H609','H650','H651','H652','H653','H654','H659',
'H660','H661','H662','H663','H664','H669','H678','H680','H681','H690','H698','H699','I300','I308','I309','I321','I328','I330','I339','I398','I400','I401',
'I408','I409','I418','J010','J011','J012','J013','J018','J019','J029','J039','J040','J041','J042','J051','J060','J068','J069','J157','J168','J170','J171',
'J172','J178','J180','J188','J209','J219','J310','J311','J312','J320','J321','J322','J323','J328','J329','J330','J331','J338','J339','J350','J351','J352',
'J353','J358','J359','J370','J371','J40','J410','J411','J42','J441','J448','J47','J860','J869','J90','J998','K250','K251','K252','K253','K254','K255','K256',
'K257','K259','K260','K261','K262','K263','K264','K265','K266','K267','K269','K270','K271','K272','K273','K274','K275','K276','K277','K279','K290','K291',
'K292','K294','K296','K298','K299','K350','K351','K359','K36','K37','K380','K388','K650','K658','K659','K678','L049','L080','L088','L089','L946','L980',
'M0090','M0091','M0092','M0093','M0094','M0095','M0096','M0097','M0098','M0099','M0130','M0131','M0132','M0133','M0134','M0135','M0136','M0137','M0138',
'M0139','M0150','M0151','M0152','M0153','M0154','M0155','M0156','M0157','M0158','M0159','M0160','M0161','M0162','M0163','M0164','M0165','M0166','M0167',
'M0168','M0169','M0180','M0181','M0182','M0183','M0184','M0185','M0186','M0187','M0188','M0189','M0211','M0212','M0213','M0214','M0215','M0216','M0217',
'M0218','M0219','M0230','M0231','M0232','M0233','M0234','M0235','M0236','M0237','M0238','M0239','M352','M4909','M8610','M8611','M8612','M8613','M8614',
'M8615','M8616','M8617','M8618','M8619','M8660','M8667','M8668','M8669','M8690','M8691','M8692','M8693','M8694','M8695','M8696','M8697','M8698','M8699',
'M8960','M8961','M8962','M8963','M8964','M8965','M8966','M8967','M8968','M8969','M9020','M9021','M9022','M9023','M9024','M9025','M9026','M9027','M9028',
'M9029','N008','N009','N019','N031','N035','N038','N039','N052','N055','N058','N059','N088','N10','N118','N119','N12','N151','N300','N301','N302','N303',
'N304','N308','N309','N338','N340','N341','N342','N343','N410','N411','N412','N413','N418','N419','N431','N450','N459','N510','N511','N700','N701','N709',
'N710','N711','N719','N72','N730','N731','N733','N734','N736','N738','N739','N750','N751','N760','N764','N766','N768','N771','N778','O235','O2688','O269',
'O753','O754','O758','O908','O9100','O9110','O9120','O980','O981','O982','O983','O985','O986','O988','O989','P378','P390','P391','R091','T802','T814','T826',
'T827','T835','T845','T846','T8571','T8578','T874'))
then other_infec = 1;	


if (bacterial_infec = 1) or (viral_infec = 1) or (parasitic_infec = 1) or (other_infec = 1) then any_infec = 1;
else any_infec = 0;

* Recode missing infection codes to zeroes;
if bacterial_infec = . then bacterial_infec = 0;
if viral_infec = . then viral_infec = 0;
if parasitic_infec = . then parasitic_infec = 0;
if other_infec = . then other_infec = 0;
run;

*check counts;
proc freq data=hosp_infections2;
table bacterial_infec viral_infec parasitic_infec other_infec any_infec;
run;

*save file;
data steph.infections_dx_BARRY_19Sep22; set hosp_infections2; run;

*create separate file retaining just those with infections; 
data steph.infections_only_dx_BARRY_19Sep22; set hosp_infections2; 
where any_infec = 1;
run;

* get earliest infection admission date;
proc sql;
	create table infections2 as
	select *, min(hosp_start) as infect_start format = date9.
	from hosp_infections2
	group by snz_uid;
quit;

*some people have multiple infection diagnoses on the same date - so select only first record; 
proc sort data=infections2; 
by snz_uid hosp_start;

data infections3 (drop=viral_infec bacterial_infec parasitic_infec other_infec); set infections2;
by snz_uid;
if first.snz_uid;
run;


**adding in primary diagnosis;
proc sort data=infections3; by event_id; run;
proc sort data=primdiag; by event_id; run;
data infections4;
merge infections3 primdiag;
by event_id;
if snz_uid~=.;
run;

*checking if unique by snz_uid and event_id;
proc sort data= infections4 nodupkey; by snz_uid; run;*yep;
proc sort data= infections4 nodupkey; by event_id; run;*yep;


**creating files for different infection types for the first infection event;
*creating event file;
data event_id (keep=event_id xxx); set infections4;
xxx=1; run;


proc sort data=infections2; by event_id; run;
data infections5;
merge infections2 event_id;
by event_id;
if xxx=1;
run;


proc freq data=infections5;
*table viral_infec bacterial_infec parasitic_infec other_infec;
*table viral_infec*(bacterial_infec parasitic_infec other_infec);
*table bacterial_infec*(parasitic_infec other_infec);
*table parasitic_infec*other_infec;
table moh_dia_clinical_code;
run;
**lots of double ups - checking double-up codes;
proc freq data=infections5 (where=(viral_infec=1 & bacterial_infec=1)); table moh_dia_clinical_code; run;
proc freq data=infections5 (where=(viral_infec=1 & parasitic_infec=1)); table moh_dia_clinical_code; run;
proc freq data=infections5 (where=(viral_infec=1 & other_infec=1)); table moh_dia_clinical_code; run;
proc freq data=infections5 (where=(bacterial_infec=1 & parasitic_infec=1)); table moh_dia_clinical_code; run;
proc freq data=infections5 (where=(bacterial_infec=1 & other_infec=1)); table moh_dia_clinical_code; run;
proc freq data=infections5 (where=(parasitic_infec=1 & other_infec=1)); table moh_dia_clinical_code; run;
*all seem to be listed in the infection code list - ignoring;


*viral;
data V (keep=event_id viral_infec moh_dia_clinical_code VN); 
set infections5 (where=(viral_infec=1)); 
VN + 1; by event_id; if first.event_id then VN = 1;
run;
proc freq data=V; table VN; run; *up to 5;
data V1 (keep=event_id viral_infec V1); set V; if VN=1; V1=moh_dia_clinical_code; run;
data V2 (keep=event_id viral_infec V2); set V; if VN=2; V2=moh_dia_clinical_code; run;
data V3 (keep=event_id viral_infec V3); set V; if VN=3; V3=moh_dia_clinical_code; run;
data V4 (keep=event_id viral_infec V4); set V; if VN=4; V4=moh_dia_clinical_code; run;
data V5 (keep=event_id viral_infec V5); set V; if VN=5; V5=moh_dia_clinical_code; run;
data VW; merge V1 V2 V3 V4 V5; by event_id; 
VN=1; if V2~="" then VN=2; if V3~="" then VN=3; if V4~="" then VN=4; if V5~="" then VN=5; run;
proc freq data=VW; table VN; run;


*bacterial;
data B (keep=event_id bacterial_infec moh_dia_clinical_code BN); 
set infections5 (where=(bacterial_infec=1)); 
BN + 1; by event_id; if first.event_id then BN = 1;
run;
proc freq data=B; table BN; run; *up to 11;
data B1 (keep=event_id bacterial_infec B1); set B; if BN=1; B1=moh_dia_clinical_code; run;
data B2 (keep=event_id bacterial_infec B2); set B; if BN=2; B2=moh_dia_clinical_code; run;
data B3 (keep=event_id bacterial_infec B3); set B; if BN=3; B3=moh_dia_clinical_code; run;
data B4 (keep=event_id bacterial_infec B4); set B; if BN=4; B4=moh_dia_clinical_code; run;
data B5 (keep=event_id bacterial_infec B5); set B; if BN=5; B5=moh_dia_clinical_code; run;
data B6 (keep=event_id bacterial_infec B6); set B; if BN=6; B6=moh_dia_clinical_code; run;
data B7 (keep=event_id bacterial_infec B7); set B; if BN=7; B7=moh_dia_clinical_code; run;
data B8 (keep=event_id bacterial_infec B8); set B; if BN=8; B8=moh_dia_clinical_code; run;
data B9 (keep=event_id bacterial_infec B9); set B; if BN=9; B9=moh_dia_clinical_code; run;
data B10 (keep=event_id bacterial_infec B10); set B; if BN=10; B10=moh_dia_clinical_code; run;
data B11 (keep=event_id bacterial_infec B11); set B; if BN=11; B11=moh_dia_clinical_code; run;
data BW; merge B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11; by event_id; 
BN=1; if B2~="" then BN=2; if B3~="" then BN=3; if B4~="" then BN=4; if B5~="" then BN=5; if B6~="" then BN=6; 
if B7~="" then BN=7; if B8~="" then BN=8; if B9~="" then BN=9; if B10~="" then BN=10; if B11~="" then BN=11; run;
proc freq data=BW; table BN; run;


*parasitic;
data P (keep=event_id parasitic_infec moh_dia_clinical_code PN); 
set infections5 (where=(parasitic_infec=1)); 
PN + 1; by event_id; if first.event_id then PN = 1;
run;
proc freq data=P; table PN; run; *up to 4;
data P1 (keep=event_id parasitic_infec P1); set P; if PN=1; P1=moh_dia_clinical_code; run;
data P2 (keep=event_id parasitic_infec P2); set P; if PN=2; P2=moh_dia_clinical_code; run;
data P3 (keep=event_id parasitic_infec P3); set P; if PN=3; P3=moh_dia_clinical_code; run;
data P4 (keep=event_id parasitic_infec P4); set P; if PN=4; P4=moh_dia_clinical_code; run;
data PW; merge P1 P2 P3 P4; by event_id; 
PN=1; if P2~="" then PN=2; if P3~="" then PN=3; if P4~="" then PN=4; run;
proc freq data=PW; table PN; run;


*OTHER;
data O (keep=event_id other_infec moh_dia_clinical_code ON); 
set infections5 (where=(other_infec=1)); 
ON + 1; by event_id; if first.event_id then ON = 1;
run;
proc freq data=O; table ON; run; *up to 10;
data O1 (keep=event_id other_infec O1); set O; if ON=1; O1=moh_dia_clinical_code; run;
data O2 (keep=event_id other_infec O2); set O; if ON=2; O2=moh_dia_clinical_code; run;
data O3 (keep=event_id other_infec O3); set O; if ON=3; O3=moh_dia_clinical_code; run;
data O4 (keep=event_id other_infec O4); set O; if ON=4; O4=moh_dia_clinical_code; run;
data O5 (keep=event_id other_infec O5); set O; if ON=5; O5=moh_dia_clinical_code; run;
data O6 (keep=event_id other_infec O6); set O; if ON=6; O6=moh_dia_clinical_code; run;
data O7 (keep=event_id other_infec O7); set O; if ON=7; O7=moh_dia_clinical_code; run;
data O8 (keep=event_id other_infec O8); set O; if ON=8; O8=moh_dia_clinical_code; run;
data O9 (keep=event_id other_infec O9); set O; if ON=9; O9=moh_dia_clinical_code; run;
data O10 (keep=event_id other_infec O10); set O; if ON=10; O10=moh_dia_clinical_code; run;
data OW; merge O1 O2 O3 O4 O5 O6 O7 O8 O9 O10; by event_id; 
ON=1; if O2~="" then ON=2; if O3~="" then ON=3; if O4~="" then ON=4; if O5~="" then ON=5; if O6~="" then ON=6; 
if O7~="" then ON=7; if O8~="" then ON=8; if O9~="" then ON=9; if B10~="" then ON=10; run;
proc freq data=OW; table ON; run;


*merge files;
data infections6;
merge infections4 VW BW PW OW;
by event_id;
if viral_infec=. then viral_infec=0; IF VN=. THEN VN = 0;
if bacterial_infec=. then bacterial_infec=0; IF BN=. THEN BN = 0;
if parasitic_infec=. then parasitic_infec=0; IF PN=. THEN PN = 0;
if other_infec=. then other_infec=0; IF ON=. THEN ON = 0;
run;
