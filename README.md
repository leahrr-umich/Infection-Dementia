# Associations of hospital-treated infections with subsequent dementia: Nationwide 30-year analysis

**Code currently under preparation for release:** Code related to the manuscript will be made available once we get release permission from Statistics New Zealand.
For inquiries or further information, please contact Leah Richmond-Rakerd, PhD, at leahrr@umich.edu 

# Project Abstract 
Infections, which can prompt neuroinflammation, may be a risk factor for dementia. More information is needed concerning associations across different infections and different dementias, and from longitudinal studies with long follow-ups. This New Zealand-based population-register study tested whether infections antedate dementia across three decades. We identified individuals born between 1929-1968 and followed them from 1989-2019 (N=1,742,406, baseline age=21-60y). Infection diagnoses were ascertained from public-hospital records. Dementia diagnoses were ascertained from public-hospital, mortality, and pharmaceutical records. Relative to individuals without an infection, those with an infection were at increased risk of dementia (HR=2.93 [95% CI: 2.68-3.20]). Associations were evident for dementia diagnoses made up to 25-30y after infection diagnoses. Associations held after accounting for pre-existing physical diseases, mental disorders, and socioeconomic deprivation. Associations were evident for viral, bacterial, parasitic, and other infections; and for Alzheimer’s disease and other dementias, including vascular dementia. Preventing infections might reduce the burden of neurodegenerative conditions.

## Statistical Analyses 
This study utilized Cox proportional hazards models to assess the relationship between individuals' first diagnosed infection during the observation period (index infection) and the subsequent development of dementia. Infections were treated as time-varying covariates, and analyses controlled for pre-existing mental disorders and physical diseases. Censoring occurred for individuals who died of non-dementia causes, out-migrated, or reached the study's end without a dementia diagnosis. Generalized linear models provided both unadjusted and adjusted estimates of the mean time to dementia diagnosis, comparing those with and without an infection.
To mitigate ascertainment bias and reverse-causation due to the lengthy pre-diagnosis phase of dementia, the study excluded individuals diagnosed with dementia within one month following their infection. We examined associations over the entire 30-year period and across specific follow-up intervals (0-1, 1-5, 5-10, 10-15, 15-20, 20-25, and 25-30 years), with dementia cases censored before each interval to ensure non-overlapping risk assessment. Analyses were conducted for all infections and dementias, as well as separately by type.
Sensitivity analyses explored the impact of excluding pharmaceutical and mortality records from dementia ascertainment and accounted for neighborhood deprivation. 
Due to computational limits, hazard models were estimated in four randomly-selected 25% subsets of the male and female populations, with results pooled using fixed-effects meta-analysis (via the "metafor" package in R) to derive total-population estimates. 

# Table of contents 
TODO 

# Acknowledgements and Authors
**Acknowledgements:** 

This research was supported by grant P30AG066582 from the National Institute on Aging (NIA) through the Center to Accelerate Population Research in Alzheimer’s and grant P30AG066589 from the NIA through the Center for Advancing Sociodemographic and Economic Study of Alzheimer’s Disease and Related Dementias. Additional support was provided by grants R01AG032282 and R01AG049789 from the NIA and grant MR/P005918 from the UK Medical Research Council. We thank Statistics New Zealand and their staff for access to the IDI data and timely ethics review of output data. We thank the Public Policy Institute at the University of Auckland for access to their Statistics New Zealand data lab. We also thank Hamish Jamieson, Amanda Kvalsvig, and Alzheimers New Zealand for helpful comments on earlier drafts of this manuscript.

**Code authors:** 
- Barry J. Milne, PhD
- Stephanie D’Souza, PhD
- Leah S. Richmond-Rakerd, PhD
- Lara Khalifeh, MS 


