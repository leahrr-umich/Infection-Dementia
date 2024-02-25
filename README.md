# Associations of hospital-treated infections with subsequent dementia: Nationwide 30-year analysis

**Statistical code currently under preparation for posting:** Statistical code related to the manuscript will be made available once the files have been reviewed by Statistics New Zealand for adherence to Statistics New Zealands's confidentiality rules and output from the NZIDI secure data-lab.
For inquiries or further information, please contact Leah Richmond-Rakerd, PhD, at leahrr@umich.edu 

# Project Abstract 
Infections, which can prompt neuroinflammation, may be a risk factor for dementia. More information is needed concerning associations across different infections and different dementias, and from longitudinal studies with long follow-ups. This New Zealand-based population-register study tested whether infections antedate dementia across three decades. We identified individuals born between 1929-1968 and followed them from 1989-2019 (N=1,742,406, baseline age=21-60y). Infection diagnoses were ascertained from public-hospital records. Dementia diagnoses were ascertained from public-hospital, mortality, and pharmaceutical records. Relative to individuals without an infection, those with an infection were at increased risk of dementia (HR=2.93 [95% CI: 2.68-3.20]). Associations were evident for dementia diagnoses made up to 25-30y after infection diagnoses. Associations held after accounting for pre-existing physical diseases, mental disorders, and socioeconomic deprivation. Associations were evident for viral, bacterial, parasitic, and other infections; and for Alzheimer’s disease and other dementias, including vascular dementia. Preventing infections might reduce the burden of neurodegenerative conditions.

## Statistical Analyses 
This study utilized Cox proportional hazards models to test the association between individuals' first diagnosed infection during the observation period (index infection) and subsequent dementia diagnosis. Infection diagnoses were treated as time-varying covariates, and analyses controlled for pre-existing mental disorders and physical diseases. Individuals who died of causes other than dementia, out-migrated, or reached the study's end without a dementia diagnosis were censored in analyses. Generalized linear models were used to obtain both unadjusted and covariate-adjusted estimates of mean time to dementia diagnosis, among those with vs. without an infection.
To mitigate ascertainment bias and reverse-causation due to the lengthy pre-diagnosis phase of dementia, the study excluded individuals diagnosed with dementia within one month following their infection. We tested associations over the entire 30-year observation period, and across specific follow-up intervals (0-1, 1-5, 5-10, 10-15, 15-20, 20-25, and 25-30 years), with dementia cases that occurred prior to the interval modeled as censored. Analyses were conducted for all infections and dementias grouped together, as well as separately by infection and dementia type.
Sensitivity analyses evaluated the impact of excluding pharmaceutical and mortality records from dementia ascertainment, and the impact of adjusting for neighborhood deprivation. 
Due to computational constraints, hazard models were estimated in four randomly-selected 25% subsets of the male and female populations, with results pooled using fixed-effects meta-analysis to derive total-population estimates (via the "metafor" package in R) . 
Per the confidentiality rules of Statistics NZ, reported frequencies/counts were randomly rounded to a base of three. 

# Table of contents 
To be provided when statistical code is posted. 

# Acknowledgements and Authors
**Acknowledgements:** 

This research was supported by grant P30AG066582 from the National Institute on Aging (NIA) through the Center to Accelerate Population Research in Alzheimer’s and grant P30AG066589 from the NIA through the Center for Advancing Sociodemographic and Economic Study of Alzheimer’s Disease and Related Dementias. Additional support was provided by grants R01AG032282 and R01AG049789 from the NIA and grant MR/P005918 from the UK Medical Research Council. We thank Statistics New Zealand and their staff for access to the IDI data and timely ethics review of output data. We thank the Public Policy Institute at the University of Auckland for access to their Statistics New Zealand data lab. We also thank Hamish Jamieson, Amanda Kvalsvig, and Alzheimers New Zealand for helpful comments on earlier drafts of this manuscript.

**Manuscript authors:** 
- Leah S. Richmond-Rakerd, PhD
- Monica T. Iyer, BS
- Stephanie D’Souza, PhD
- Lara Khalifeh, MS
- Avshalom Caspi, PhD
- Terrie E. Moffitt, PhD
- Barry J. Milne, PhD
  
**Code authors:** 
- Leah S. Richmond-Rakerd, PhD
- Monica T. Iyer, BS
- Stephanie D’Souza, PhD
- Lara Khalifeh, MS
- Barry J. Milne, PhD



