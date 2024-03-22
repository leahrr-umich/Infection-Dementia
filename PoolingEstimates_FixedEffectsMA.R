# PROJECT: Infections and dementia
# AUTHOR: L. Khalifeh (using metafor package: https://cran.r-project.org/web/packages/metafor/index.html)
# TASK: Derive total-population hazard-ratio estimates by pooling associations from randomly-selected 25% subsets of males and females 
# NOTE: The code shown below was used to calculated pooled hazard ratios for vascular and non-vascular dementia. This same code was 
# adapted to calculated pooled estimates for other outcomes reported in the manuscript. 

# Load the metafor library
library(metafor)

# Function to perform fixed-effects meta-analysis and print results
  run_meta_analysis <- function(log_HRs, SEs, sample_sizes, title) {
  # Calculate the variances
  variances <- (SEs * sqrt(sample_sizes))^2
  
  # Create a data frame with log hazard ratios, standard errors, and variances
  dat <- data.frame(yi = log_HRs, sei = SEs, vi = variances)
  
  # Perform fixed-effects meta-analysis using log hazard ratios and standard errors
  res <- rma(yi = yi, sei = sei, data = dat, method = "FE")
  
  # Calculate pooled hazard ratios
  pooled_hr <- exp(res$beta)
  
  # Calculate confidence intervals for pooled hazard ratios
  conf_interval <- cbind(
    lower = exp(res$ci.lb),
    upper = exp(res$ci.ub)
  )
  
  # Print results
  cat(paste("Results for", title, ":\n"))
  cat("Pooled Hazard Ratio:\n")
  print(pooled_hr)
  cat("\nConfidence Intervals:\n")
  print(conf_interval)
  cat("\n\n")
}


# VASCULAR DEMENTIA
# Analysis for Vascular-Men
log_HRs_vascular_men <- c(log(4.256), log(3.627), log(4.189), log(4.474))
SEs_vascular_men <- c(0.09, 0.09, 0.09, 0.09)
sample_sizes_vascular_men <- c(273771, 274197, 273732, 274254)
run_meta_analysis(log_HRs_vascular_men, SEs_vascular_men, sample_sizes_vascular_men, "Vascular- Men")

# Analysis for Vascular-Women
log_HRs_vascular_women <- c(log(4.71), log(4.876), log(5.728), log(5.94)) 
SEs_vascular_women <- c(0.10253, 0.09839, 0.10314, 0.10257)
sample_sizes_vascular_women <- c(263217, 263643, 263304, 264690) 
run_meta_analysis(log_HRs_vascular_women, SEs_vascular_women, sample_sizes_vascular_women, "Vascular- Women")

# Analysis for Vascular- Both Men and Women
log_HRs_vascular_both <- c(log(4.256), log(3.627), log(4.189), log(4.474), log(4.71), log(4.876), log(5.728), log(5.94))
SEs_vascular_both <- c(0.09, 0.09, 0.09, 0.09, 0.10253, 0.09839, 0.10314, 0.10257)
sample_sizes_vascular_both <- c(273771, 274197, 273732, 274254, 263217, 263643, 263304, 264690)
run_meta_analysis(log_HRs_vascular_both, SEs_vascular_both, sample_sizes_vascular_both, "Vascular- Both Men and Women")



# NON-VASCULAR DEMENTIA 
# Analysis for Non-Vascular-Men
log_HRs_non_vascular_men <- c(log(3.503), log(3.619), log(3.479), log(3.512))
SEs_non_vascular_men <- c(0.06298, 0.06161, 0.06265, 0.06189)
sample_sizes_non_vascular_men <- c(274605, 275148, 274620, 275142)
run_meta_analysis(log_HRs_non_vascular_men, SEs_non_vascular_men, sample_sizes_non_vascular_men, "Non-Vascular- Men")

# Analysis for Non-Vascular-Women
log_HRs_non_vascular_women <- c(log(4.786), log(5.538), log(6.001), log(4.966))
SEs_non_vascular_women <- c(0.07237, 0.07372, 0.07513, 0.07374)
sample_sizes_non_vascular_women <- c(263853, 264237, 263910, 265281)
run_meta_analysis(log_HRs_non_vascular_women, SEs_non_vascular_women, sample_sizes_non_vascular_women, "Non-Vascular- Women")

# Analysis for Non-Vascular- Both Men and Women
log_HRs_non_vascular_both <- c(log(3.503), log(3.619), log(3.479), log(3.512), log(4.786), log(5.538), log(6.001), log(4.966))
SEs_non_vascular_both <- c(0.06298, 0.06161, 0.06265, 0.06189, 0.07237, 0.07372, 0.07513, 0.07374)
sample_sizes_non_vascular_both <- c(274605, 275148, 274620, 275142, 263853, 264237, 263910, 265281)
run_meta_analysis(log_HRs_non_vascular_both, SEs_non_vascular_both, sample_sizes_non_vascular_both, "Non-Vascular- Both Men and Women")

