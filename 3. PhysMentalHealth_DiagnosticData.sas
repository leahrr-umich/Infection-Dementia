
*********************************************************************
PROJECT: Infections and dementia
AUTHOR: S. D'Souza (adapted from L. Richmond-Rakerd)
IDI Refresh: IDI_Clean_202206

TASK:
Data setup for mental disorders & physical diseases, with changes
made for the ADRD study

INPUT DATASETS:
moh_clean.pub_fund_hosp_discharges_event
moh_clean.pub_fund_hosp_discharges_diag

OUTPUT DATASETS:
steph.alldiag_89_19_07Jul22
steph.MHdx_27Jul22
steph.PHdx_27Jul22

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

* Hospitalizations dataset;
proc sql;
connect to odbc(dsn=idi_clean_202206_srvprd);
create table hospitalizations as
select * from connection to odbc
(select * from moh_clean.pub_fund_hosp_discharges_event);
disconnect from odbc;
quit;

* Limit to events between 1 July 1989 and 30 June 2019 (30-year period);
* NOTE: USE START DATES. Admission must occur in observation period, discharge may be after;
data hospitalizations_2; set hospitalizations;
where '01JUL1989'd le moh_evt_evst_date le '30JUN2019'd;
run;

data hospitalizations_2; set hospitalizations_2;
hosp_start = moh_evt_evst_date;
hosp_end = moh_evt_even_date;
event_id = moh_evt_event_id_nbr;
format hosp_start hosp_end date9.;
run;

data hospitalizations_3; set hospitalizations_2
(keep = snz_uid event_id snz_moh_uid snz_moh_evt_uid moh_evt_end_type_code moh_evt_agency_code hosp_start hosp_end);
run;

* NOTE: LONG FILE. Each hospitalization assigned a unique event number;

* Clinical codes dataset;
proc sql;
connect to odbc(dsn=idi_clean_202206_srvprd);
create table clin_codes as
select * from connection to odbc
(select * from moh_clean.pub_fund_hosp_discharges_diag);
disconnect from odbc;
quit;

* inner join using event ID;
data clin_codes_1; set clin_codes;
event_id = moh_dia_event_id_nbr;
run;

data clin_codes_2; set clin_codes_1
(keep = event_id moh_dia_clinical_code moh_dia_clinical_sys_code moh_dia_diagnosis_type_code);
run;

proc sql;
create table hosp_join as
select hospitalizations_3.*, clin_codes_2.*
from hospitalizations_3, clin_codes_2
where hospitalizations_3.event_id = clin_codes_2.event_id;
quit;

* Limit to PRIMARY diagnoses (diagnosis type 'A'), EXTERNAL CAUSES (diagnosis type 'E'), and PROCEDURES (diagnosis type 'O');
* Only 1 primary diagnosis per event, but there can be multiple E codes per event;
* Procedure codes needed for physical-health diagnoses;
data hosp_join_1; set hosp_join;
if moh_dia_diagnosis_type_code = 'B' then delete;
run;

** ICD CODES: 
*  1988 - JUN 1999: ICD-9-CM;
*  JUL 1999 - JUN 2001: ICD-10-AM v1
*  JUL 2001 - JUN 2004: ICD-10-AM v2
*  JUL 2004 - JUN 2008: ICD-10-AM v3
*  JUL 2008 - JUN 2014: ICD-10-AM v6
*  JUL 2014 ON:         ICD-10-AM v8;
proc freq data=hosp_join_1; table moh_dia_clinical_sys_code; run;

* Create ICD-9 v ICD-10 indicator;
data hosp_join_1; set hosp_join_1;
if moh_dia_clinical_sys_code = '06' then ICD = 9;
if moh_dia_clinical_sys_code in ('10','11','12','13','14','15') then ICD = 10;

if ICD = 10 then ICD10 = 1;	else ICD10 = 0;
if ICD = 9 then ICD9 = 1;	else ICD9 = 0;


*********************************** 
ASSIGN PHYSICAL-HEALTH DIAGNOSES

Use NMDS ICD codes AND procedure codes from chronic conditions data dictionary
***********************************;
data diag; set hosp_join_1;
code = moh_dia_clinical_code;
format ph_diagnosis $30.; 
label ph_diagnosis = 'Physical health diagnosis';

/********************************************
* Coronary heart disease: 
ICD-10: 
I20-I25, Z951, Z955

Procedures: 
3530400, 3530500, 3531000, 3531001, 3531002, 
3849700, 3849701, 3849702, 3849703, 3849704, 
3849705, 3849706, 3849707, 3850000, 3850001, 
3850002, 3850003, 3850004, 3850300, 3850301, 
3850302, 3850303, 3850304, 3863700, 9020100, 
9020101, 9020102, 9020103

ICD-9:
410-414, V4581, V4582

Procedures:
3601, 3602, 3603, 3604, 3605, 3606, 3607, 3610, 
3611, 3612, 3613, 3614, 3615, 3616
*********************************************/
if ('I20' le substr(code,1,3) le 'I25') 
or (code in ('Z951', 'Z955',
'3530400', '3530500', '3531000', '3531001', '3531002', '3849700', '3849701', '3849702', '3849703', 
'3849704', '3849705', '3849706', '3849707', '3850000', '3850001', '3850002', '3850003', '3850004', 
'3850300', '3850301', '3850302', '3850303', '3850304', '3863700', '9020100', '9020101', '9020102', '9020103'))
then do ph_diagnosis = 'CHD'; output; end;


if ('410' le substr(code,1,3) le '414') 
or (code in ('V4581', 'V4582',
'3601', '3602', '3603', '3604', '3605', '3606', '3607', 
'3610', '3611', '3612', '3613', '3614', '3615', '3616'))
then do ph_diagnosis = 'CHD'; output; end;

/********************************************
* Gout: 
ICD-10: M10
ICD-9: 274
*********************************************/
if substr(code,1,3) = 'M10' then do ph_diagnosis = 'Gout';	output; end;


if substr(code,1,3) = '274' then do ph_diagnosis = 'Gout';	output; end;

/********************************************
* Chronic obstructive pulmonary disease: 
ICD-10: 
J40, J410, J411, J418, J42, J430, J431, J432, 
J438, J439, J440, J441, J448, J449 

ICD-9:
490, 4910, 4911, 49120, 49121, 4918, 
4919, 4920, 4928, 496 
*********************************************/
if code in ('J40', 'J410', 'J411', 'J418','J42','J430', 'J431', 'J432', 
'J438', 'J439', 'J440', 'J441', 'J448', 'J449') then do ph_diagnosis = 'COPD';	output; end;


if code in ('490', '4910', '4911', '49120', '49121', '4918', '4919', '4920', '4928', '496')
then do ph_diagnosis = 'COPD';	output; end;

/********************************************
Diabetes:
ICD-10:
E10, E11, E13, E14, O240, O241, O242, O243

ICD-9 (from mapped codes):
25000, 25001, 25002, 25003, 25010, 25011, 25012,
25013, 25030, 25031, 25032, 25033, 25040, 25041,
25042, 25043, 25050, 25051, 25052, 25053, 25060,
25061, 25062, 25063, 25070, 25071, 25072, 25073,
25080, 25081, 25082, 25083, 25090, 25091, 25092,
25093, 5235,  64801, 64803, 64804, 71500, 7829
*********************************************/ 
if (substr(code,1,3) in ('E10', 'E11', 'E13', 'E14'))
or (substr(code,1,4) in ('O240', 'O241', 'O242', 'O243'))
then do ph_diagnosis = 'Diabetes';	output; end;  

if code in ('25000', '25001', '25002', '25003', '25010', '25011', '25012',
'25013', '25030', '25031', '25032', '25033', '25040', '25041',
'25042', '25043', '25050', '25051', '25052', '25053', '25060',
'25061', '25062', '25063', '25070', '25071', '25072', '25073',
'25080', '25081', '25082', '25083', '25090', '25091', '25092',
'25093', '64801', '64803', '64804', '71500', '5235', '7829') then do ph_diagnosis = 'Diabetes';	output; end;  

/********************************************
Cancer:
ICD-10:
C00 to C96 
D45 to D47 

ICD-9 (from mapped codes):
See previous version of code.
*********************************************/ 
if ('C00' le substr(code,1,3) le 'C96') or ('D45' le substr(code,1,3) le 'D47') then do ph_diagnosis = 'Cancer';	output; end;


if code in ('17001', '17002', '19881', '19882', '19889', '20000', '20010', '20020', '20080', '20100',
'20140', '20150', '20160', '20170', '20190', '20200', '20210', '20220', '20230', '20240', '20241', '20250', '20260',
'20280', '20290', '20300', '20301', '20310', '20311', '20380', '20400', '20401', '20410', '20411', '20420', '20480',
'20481', '20490', '20491', '20500', '20501', '20510', '20511', '20520', '20521', '20530', '20531', '20580', '20581',
'20590', '20591', '20600', '20601', '20610', '20611', '20680', '20690', '20691', '20700', '20701', '20710', '20720', 
'20721', '20780', '20781', '20800', '20801', '20810', '20880', '20890', '20891','1400','1401','1403','1404','1406','1408',
'1409','1410','1411','1412','1413','1414','1416','1418',
'1419','1420','1421','1422','1428','1429','1430','1431','1439','1440','1441','1448','1449','1450','1451','1452','1453','1454',
'1455','1456','1458','1459','1460','1461','1462','1463','1464','1466','1467','1468','1469','1470','1471','1472','1473','1478',
'1479','1480','1481','1482','1483','1488','1489','1490','1498','1500','1501','1502','1503','1504','1505','1508','1509','1510',
'1511','1512','1513','1514','1515','1516','1518','1519','1520','1521','1522','1523','1528','1529','1530','1531','1532','1533',
'1534','1535','1536','1537','1538','1539','1540','1541','1542','1543','1548','1550','1551','1560','1561','1562','1568','1569',
'1570','1571','1572','1573','1574','1578','1579','1580','1588','1589','1590','1591','1598','1599','1600','1601','1602','1603',
'1604','1605','1608','1609','1610','1611','1612','1613','1618','1619','1620','1622','1623','1624','1625','1628','1629','1639',
'1640','1641','1642','1643','1648','1649','1650','1658','1659','1701','1702','1703','1704','1705','1706','1707','1708','1709',
'1710','1712','1713','1714','1715','1716','1717','1718','1719','1720','1721','1722','1723','1724','1725','1726','1727','1728',
'1729','1730','1731','1732','1733','1734','1735','1736','1737','1738','1739','1740','1741','1742','1743','1744','1745','1746',
'1748','1749','1760','1761','1762','1765','1768','1769','1800','1801','1808','1809','1820','1821','1828','1830','1832','1833',
'1834','1835','1839','1840','1841','1842','1843','1844','1848','1849','1860','1869','1871','1872','1873','1874','1875','1876',
'1877','1878','1879','1880','1881','1882','1883','1884','1885','1886','1887','1888','1889','1890','1891','1892','1893','1898',
'1899','1900','1901','1902','1903','1904','1905','1906','1908','1909','1910','1911','1912','1913','1914','1915','1916','1917',
'1918','1919','1920','1921','1922','1923','1928','1929','1940','1941','1943','1944','1945','1946','1949','1950','1951','1952',
'1953','1954','1955','1958','1960','1961','1962','1963','1965','1966','1968','1969','1970','1971','1972','1973','1974','1975',
'1976','1977','1978','1980','1981','1982','1983','1984','1985','1986','1987','1991','2384','2385','2386','2387','2731','2732',
'2733','2898','179','181','185','193')
then do ph_diagnosis = 'Cancer';	output; end;

/********************************************
Traumatic brain injury:
ICD-10: S06 

ICD-9:
800-801.9, 803-804.9, 850-854 
*********************************************/ 
if substr(code,1,3) = 'S06' then do ph_diagnosis = 'TBI';	output; end;


if (substr(code,1,3) in ('800', '803', '850', '851', '852', '853', '854'))
or (code in ('801','8010','8011','8012','8013','8014','8015','8016','8017','8018','8019',
'804','8040','8041','8042','8043','8044','8045','8046','8047','8048','8049'))
then do ph_diagnosis = 'TBI';	output; end;

/*********************************************
Stroke:
ICD-10: 
I60 to 164 

ICD-9:
430-432, 433.01, 433.11, 433.21, 433.31, 
433.81, 433.91, 434.01, 434.11, 434.91, 436 
**********************************************/
if 'I60' le substr(code,1,3) le 'I64' then do ph_diagnosis = 'Stroke';	output; end;

if ('430' le substr(code,1,3) le '432') 
or (code in ('43301', '43311', '43321', '43331', '43381', '43391', '43401', '43411', '43491', '436')) 
then do ph_diagnosis = 'Stroke';	output; end;

/*********************************************
Myocardial infarction:
ICD-10: I21
ICD-9: 410  
**********************************************/
if substr(code,1,3) = 'I21' then do ph_diagnosis = 'MI';	output; end;

if substr(code,1,3) = '410' then do ph_diagnosis = 'MI';	output; end;

/*********************************************
No PH diagnosis
**********************************************/
if ph_diagnosis = '' then do ph_diagnosis = 'No PH dx';	output; end;
run;

*******;



*********************************** 
ASSIGN MENTAL-HEALTH DIAGNOSES

UTILIZE AN INCLUSIVE SCHEME
***********************************;

/********************************
* Self-harm: 
  ICD-10: X60 to X84 
  ICD-9:  E950 to E959 
  (coded as 950 and 959 in dataset), per MOH documentation
  ('masterb' back-conversion spreadsheet)
*********************************/
* NOTE: Exclude events with undetermined intent;
data diag_2; set diag;

format mh_diagnosis $30.;
label mh_diagnosis = 'Mental health diagnosis';

if 'X60' le substr(code,1,3) le 'X84'   then do mh_diagnosis = 'SelfHarm';	output;	end;

if '950' le substr(code,1,3) le '959' 	then do mh_diagnosis = 'SelfHarm';	output;	end;

/*************************************************
* Substance use disorders: 

ICD-10:
F10 to F19

ICD-9:
2910,2911,2912,2918,2919,2920,29283,29289,2929,
30390,30400,30410,30420,30430,30440,30450,30460,
30480,30500,3051,30520,30530,30540,30550,30560,
30570,30590
**************************************************/
* NOTE: This includes nicotine dependence (a very small # of cases with a primary diagnosis);
if 'F10' le substr(code,1,3) le 'F19' then do mh_diagnosis = 'SUD';	output; end;


if code in ('2910','2911','2912','2918','2919','2920','29283','29289','2929',
'30390','30400','30410','30420','30430','30440','30450','30460',
'30480','30500','3051','30520','30530','30540','30550','30560',
'30570','30590') then do mh_diagnosis = 'SUD';	output; end;

/*************************************************
* Psychotic disorders

ICD-10:
F20 to F25, F28, F29

ICD-9:
29500,29510,29520,29530,29540,29550,29560,29570,
29580,29590,2971,2973,2978,2979,2983,2988,2989,3004
**************************************************/

* NOTE: Psychotic disorders due to substance use are included in the SUD category;
if ('F20' le substr(code,1,3) le 'F25') or ('F28' le substr(code,1,3) le 'F29') then do mh_diagnosis = 'Psychosis'; output; end;


if code in ('29500','29510','29520','29530','29540','29550','29560','29570',
'29580','29590','2971','2973','2978','2979','2983','2988','2989','3004') then do mh_diagnosis = 'Psychosis'; output; end;

/*************************************************
* Mood disorders
ICD-10:
F30 to F34, F39

ICD-9:
29600,29621,29622,29623,29624,29630,29631,29632,29633,
29634,29636,29640,29651,29653,29654,29660,2967,29682,29690,
29699,3004,30113,311
**************************************************/
if ('F30' le substr(code,1,3) le 'F34') or (substr(code,1,3) = 'F39') then do mh_diagnosis = 'Mood';	output; end;


if code in ('29600','29621','29622','29623','29624','29630','29631','29632','29633',
'29634','29636','29640','29651','29653','29654','29660','2967','29682','29690',
'29699','3004','30113','311') then do mh_diagnosis = 'Mood';	output; end;

/*************************************************
* Anxiety disorders

ICD-10:
F40 to F45, F48

ICD-9:
30000,30001,30002,30009,30011,30012,30013,30014,30015,30016,
30019,30020,30021,30022,30023,30029,3003,3004,3005,3006,3007,
30081,30089,3009,3061,3062,3064,30650,3068,3069,30780,30789,3083,
3089,30929
**************************************************/
if ('F40' le substr(code,1,3) le 'F45') or (substr(code,1,3) = 'F48') then do mh_diagnosis = 'Anxiety';	output; end;

if code in ('30000','30001','30002','30009','30011','30012','30013','30014','30015','30016',
'30019','30020','30021','30022','30023','30029','3003','3004','3005','3006','3007',
'30081','30089','3009','3061','3062','3064','30650','3068','3069','30780','30789','3083',
'3089','30929') then do mh_diagnosis = 'Anxiety';	output; end;

/***********************************************************
* Physiological disturbance disorders (e.g., eating, sleep)

ICD-10:
F50 to F55, F59

ICD-9:
30270,30272,30279,30289,30580,30590,3069,3071,30740,30741,
30744,30745,30746,30747,30750,30751,30754,30759,316,64844
************************************************************/
if ('F50' le substr(code,1,3) le 'F55') or (substr(code,1,3) = 'F59') then do mh_diagnosis = 'Physiol_Disturb';	output; end;


if code in ('30270','30272','30279','30289','30580','30590','3069','3071','30740','30741',
'30744','30745','30746','30747','30750','30751','30754','30759','316','64844') then do mh_diagnosis = 'Physiol_Disturb';	output; end;

/*************************************************
* Personality disorders

ICD-10:
F60, F63 to F66, F68, F69

ICD-9:
30019,3010,30120,3013,3014,30150,30151,3016,3017,30182,
30183,30189,3019,3022,3023,3024,30250,3026,30281,30283,
30289,3029,31230,31231,31233,31239
**************************************************/
if (substr(code,1,3) in ('F60', 'F68', 'F69')) or ('F63' le substr(code,1,3) le 'F66') then do mh_diagnosis = 'Personality';	output; end;

if code in ('30019','3010','30120','3013','3014','30150','30151','3016','3017','30182',
'30183','30189','3019','3022','3023','3024','30250','3026','30281','30283',
'30289','3029','31230','31231','31233','31239') then do mh_diagnosis = 'Personality';	output; end;

/*************************************************
* Intellectual disability

* NOTE: EXCLUDE intellectual disability from MH conditions
  (per TEM & AC 18 July) ;
**************************************************/

/*
if (substr(code,1,3) in ('F78', 'F79')) or ('F70' le substr(code,1,3) le 'F73') then mh_diagnosis = 'Intellectual';
*/

/*************************************************
* Developmental disorders (e.g., autism)

ICD-10:
F80 to F82, F84, F88, F89

ICD-9:
29900,29910,29980,29990,31500,3151,3152,31531,31539,
3154,3158,3159,3308
**************************************************/
if (substr(code,1,3) in ('F84', 'F88', 'F89')) or ('F80' le substr(code,1,3) le 'F82') then do mh_diagnosis = 'Developmental';	output; end;


if code in ('29900','29910','29980','29990','31500','3151','3152','31531','31539','3154','3158','3159','3308') then do mh_diagnosis = 'Developmental';	output; end;

/*************************************************
* Childhood-onset disorders (e.g., ADHD, CD)

ICD-10:
F90, F91, F93 to F95, F98

ICD-9:
3070,30720,30721,30722,30723,3073,30752,30759,3076,
3077,3079,30921,30983,31200,31220,31289,3129,3130,
31322,31389,3139,31400,3142,3148,3149
**************************************************/
if substr(code,1,3) in ('F90', 'F91', 'F93', 'F94', 'F95', 'F98') then do mh_diagnosis = 'ChildOnset';	output; end;


if code in ('3070','30720','30721','30722','30723','3073','30752','30759','3076','3077','3079','30921','30983',
'31200','31220','31289','3129','3130','31322','31389','3139','31400','3142','3148','3149') then do mh_diagnosis = 'ChildOnset';	output; end;

/*
* NOTE: Create 3 versions: ADHD, CD, other;
if substr(code,1,3) = 'F90' then mh_diagnosis = 'ChildOnset_ADHD';
if substr(code,1,3) = 'F91' then mh_diagnosis = 'ChildOnset_CD';
if substr(code,1,3) in ('F93', 'F94', 'F95', 'F98') then mh_diagnosis = 'ChildOnset_OtherDx';
*/

/*************************************************
* Unspecified
ICD-10: F99
ICD-9: 3009
**************************************************/
if substr(code,1,3) = 'F99' then do mh_diagnosis = 'Unspecified';	output; end;


if code = '3009' then do mh_diagnosis = 'Unspecified';	output; end;

/*************************************************
* No MH diagnosis
**************************************************/
if mh_diagnosis = '' then do mh_diagnosis = 'No MH dx';	output; end;
run;

* Create psychiatric discharge var;
data diag_2; set diag_2; 
if moh_evt_end_type_code in ('DC', 'DL', 'DN', 'DP') then MH_discharge = 1;
else MH_discharge = 0;
label MH_discharge = 'Mental health-related hospital discharge';
run; 

* Drop E codes that are not self-harm;
data diag_3; set diag_2;
if (moh_dia_diagnosis_type_code = 'E') and (mh_diagnosis ne 'SelfHarm') then delete;
run;

* DROP O codes that are not coronary heart disease;
data diag_4; set diag_3;
if (moh_dia_diagnosis_type_code = 'O') and (ph_diagnosis ne 'CHD') then delete;
run;


* Retain ICD-9 diagnoses for July 1989 - June 1999 
  and ICD-10 diagnoses for July 1999 to June 2019;
data diag_5; set diag_4;
if (ICD = 10) and ('01JUL1989'd le hosp_start le '30JUN1999'd) then delete;
run;

data diag_6; set diag_5; 
if (ICD = 9) and ('01JUL1999'd le hosp_start le '30JUN2019'd) then delete;
run;

* Create global mental- and physical-health categories (per T & A 11 June):
  Mental health:
  1) Any condition
  2) Substance use
  3) Self-harm;
data diag_6; set diag_6;
if mh_diagnosis ne 'No MH dx' then AnyMH_dx = 1;
else AnyMH_dx = 0;

if mh_diagnosis = 'SUD' then SUD_dx = 1;
else SUD_dx = 0;

if mh_diagnosis = 'SelfHarm' then SelfHarm_dx = 1;
else SelfHarm_dx = 0;

if ph_diagnosis ne 'No PH dx' then AnyPH_dx = 1;
else AnyPH_dx = 0;
run;

* save this for later; 
libname steph "/nas/DataLab/MAA/MAA2022-15/Steph/Data" ;
data steph.alldiag_89_19_07Jul22;
set diag_6;
run;

*load data; 
data diag; set steph.alldiag_89_19_07Jul22;
run;

*save MH only dx file; 
data steph.MHdx_27Jul22; set steph.alldiag_89_19_07Jul22;
where AnyMH_dx = 1; 
run;

*save PH only dx file; 
data steph.PHdx_27Jul22; set steph.alldiag_89_19_07Jul22;
where AnyPH_dx = 1; 
run;

