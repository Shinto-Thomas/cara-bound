# CARA Randomization Plumber API - Standalone R Version
# This API provides endpoints for adaptive randomization in clinical trials
# using Covariate-Adjusted Response-Adaptive (CARA) methods
# 
# This version uses pure R implementations without C++ dependencies

library(plumber)
library(jsonlite)

# Source the pure R implementations
source("randomization_r.R")

# Global variables to store trial state
trial_data <- new.env()
trial_data$patients <- data.frame(
  patient_id = integer(),
  stratum = integer(),
  treatment = integer(),
  outcome = numeric(),
  enrollment_time = character(),
  stringsAsFactors = FALSE
)
trial_data$config <- list(
  study_name = "CARA-Trial-Demo",
  n0 = 10,  # Burn-in size
  gamma = 2,  # Adaptation parameter
  target = "Neyman",  # Allocation strategy
  TB = 1,  # Threshold parameter
  randomization_method = "CARA"
)

#* @apiTitle CARA Randomization API (Standalone R Version)
#* @apiDescription API for Covariate-Adjusted Response-Adaptive Randomization in Clinical Trials - Pure R Implementation
#* @apiVersion 1.0.0

#* Health check endpoint
#* @get /health
#* @serializer json
function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    version = "1.0.0-standalone-r",
    implementation = "Pure R (no C++ dependencies)"
  )
}

#* Initialize or reset trial
#* @post /trial/initialize
#* @param study_name:character Study identifier
#* @param n0:int Burn-in period size (default: 10)
#* @param gamma:numeric Adaptation tuning parameter (default: 2)
#* @param target:character Allocation strategy: Neyman, RSIHR, BandBis, New (default: Neyman)
#* @param TB:numeric Threshold parameter for constrained methods (default: 1)
#* @param randomization_method:character Method: CR, CARA, CADBCD, RAR (default: CARA)
#* @serializer json
function(study_name = "CARA-Trial-Demo", 
         n0 = 10, 
         gamma = 2, 
         target = "Neyman", 
         TB = 1,
         randomization_method = "CARA") {
  
  # Reset trial data
  trial_data$patients <- data.frame(
    patient_id = integer(),
    stratum = integer(),
    treatment = integer(),
    outcome = numeric(),
    enrollment_time = character(),
    stringsAsFactors = FALSE
  )
  
  # Update configuration
  trial_data$config <- list(
    study_name = study_name,
    n0 = as.integer(n0),
    gamma = as.numeric(gamma),
    target = target,
    TB = as.numeric(TB),
    randomization_method = randomization_method
  )
  
  list(
    success = TRUE,
    message = "Trial initialized successfully",
    config = trial_data$config,
    timestamp = Sys.time()
  )
}

#* Get trial configuration and current status
#* @get /trial/status
#* @serializer json
function() {
  n_patients <- nrow(trial_data$patients)
  n_with_outcomes <- sum(!is.na(trial_data$patients$outcome))
  
  if (n_patients > 0) {
    n_treatment <- sum(trial_data$patients$treatment == 1, na.rm = TRUE)
    n_control <- sum(trial_data$patients$treatment == 0, na.rm = TRUE)
    
    strata_summary <- table(trial_data$patients$stratum)
  } else {
    n_treatment <- 0
    n_control <- 0
    strata_summary <- table()
  }
  
  list(
    config = trial_data$config,
    patients_enrolled = n_patients,
    patients_with_outcomes = n_with_outcomes,
    treatment_allocated = n_treatment,
    control_allocated = n_control,
    strata_distribution = as.list(strata_summary),
    timestamp = Sys.time()
  )
}

#* Enroll a new patient and get treatment assignment
#* @post /patient/enroll
#* @param patient_id:int Unique patient identifier
#* @param stratum:int Covariate stratum (1, 2, or 3)
#* @serializer json
function(patient_id, stratum) {
  
  patient_id <- as.integer(patient_id)
  stratum <- as.integer(stratum)
  
  # Validate inputs
  if (is.na(patient_id) || patient_id <= 0) {
    return(list(
      success = FALSE,
      error = "Invalid patient_id. Must be a positive integer."
    ))
  }
  
  if (is.na(stratum) || !(stratum %in% c(1, 2, 3))) {
    return(list(
      success = FALSE,
      error = "Invalid stratum. Must be 1, 2, or 3."
    ))
  }
  
  # Check if patient already enrolled
  if (patient_id %in% trial_data$patients$patient_id) {
    return(list(
      success = FALSE,
      error = paste("Patient", patient_id, "already enrolled")
    ))
  }
  
  # Get current patient count
  n_current <- nrow(trial_data$patients)
  n0 <- trial_data$config$n0
  
  # Determine treatment assignment
  if (n_current < 2 * n0) {
    # Burn-in period: balanced randomization
    n_treatment_so_far <- sum(trial_data$patients$treatment == 1, na.rm = TRUE)
    n_control_so_far <- sum(trial_data$patients$treatment == 0, na.rm = TRUE)
    
    if (n_treatment_so_far < n0 && n_control_so_far < n0) {
      # Random assignment
      treatment <- sample(c(0, 1), 1)
    } else if (n_treatment_so_far >= n0) {
      treatment <- 0
    } else {
      treatment <- 1
    }
    
    allocation_method <- "Burn-in (Balanced)"
    probability <- 0.5
    
  } else {
    # Adaptive randomization
    
    # Prepare data for randomization algorithm
    patients_with_outcomes <- trial_data$patients[!is.na(trial_data$patients$outcome), ]
    
    if (nrow(patients_with_outcomes) < 2 * n0) {
      # Not enough outcomes yet, use balanced randomization
      treatment <- sample(c(0, 1), 1)
      allocation_method <- "Balanced (Insufficient outcomes)"
      probability <- 0.5
    } else {
      # Use CARA algorithm
      # Get stratum-specific statistics from historical data
      stratum_data <- patients_with_outcomes[patients_with_outcomes$stratum == stratum, ]
      
      if (nrow(stratum_data) >= 4) {
        # Sufficient data in stratum
        treated <- stratum_data[stratum_data$treatment == 1, ]
        control <- stratum_data[stratum_data$treatment == 0, ]
        
        if (nrow(treated) > 0 && nrow(control) > 0) {
          mean_treated <- mean(treated$outcome, na.rm = TRUE)
          mean_control <- mean(control$outcome, na.rm = TRUE)
          sd_treated <- sd(treated$outcome, na.rm = TRUE)
          sd_control <- sd(control$outcome, na.rm = TRUE)
          
          # Handle edge cases
          if (is.na(sd_treated) || sd_treated < 1e-5) sd_treated <- 0.1
          if (is.na(sd_control) || sd_control < 1e-5) sd_control <- 0.1
          
          # Calculate target allocation
          target_prob <- target_alloc(
            mean_treated, sd_treated,
            mean_control, sd_control,
            trial_data$config$target,
            trial_data$config$TB
          )
          
          # Calculate current proportion in stratum
          stratum_all <- trial_data$patients[trial_data$patients$stratum == stratum, ]
          current_prop <- mean(stratum_all$treatment)
          
          # Calculate assignment probability using biased coin
          probability <- assigFun_g(current_prop, target_prob, trial_data$config$gamma)
          
          # Assign treatment
          treatment <- as.integer(runif(1) < probability)
          allocation_method <- paste0("CARA (", trial_data$config$target, ")")
          
        } else {
          # One group empty in stratum
          treatment <- sample(c(0, 1), 1)
          probability <- 0.5
          allocation_method <- "Balanced (Stratum data incomplete)"
        }
      } else {
        # Insufficient data in stratum
        treatment <- sample(c(0, 1), 1)
        probability <- 0.5
        allocation_method <- "Balanced (Insufficient stratum data)"
      }
    }
  }
  
  # Add patient to trial data
  new_patient <- data.frame(
    patient_id = patient_id,
    stratum = stratum,
    treatment = treatment,
    outcome = NA_real_,
    enrollment_time = as.character(Sys.time()),
    stringsAsFactors = FALSE
  )
  
  trial_data$patients <- rbind(trial_data$patients, new_patient)
  
  list(
    success = TRUE,
    patient_id = patient_id,
    stratum = stratum,
    treatment = treatment,
    treatment_label = ifelse(treatment == 1, "Treatment A", "Control B"),
    allocation_method = allocation_method,
    allocation_probability = round(probability, 4),
    patients_enrolled = nrow(trial_data$patients),
    timestamp = Sys.time()
  )
}

#* Record patient outcome
#* @post /patient/outcome
#* @param patient_id:int Patient identifier
#* @param outcome:numeric Patient outcome value
#* @serializer json
function(patient_id, outcome) {
  
  patient_id <- as.integer(patient_id)
  outcome <- as.numeric(outcome)
  
  # Validate inputs
  if (is.na(patient_id)) {
    return(list(
      success = FALSE,
      error = "Invalid patient_id"
    ))
  }
  
  if (is.na(outcome)) {
    return(list(
      success = FALSE,
      error = "Invalid outcome value"
    ))
  }
  
  # Find patient
  patient_idx <- which(trial_data$patients$patient_id == patient_id)
  
  if (length(patient_idx) == 0) {
    return(list(
      success = FALSE,
      error = paste("Patient", patient_id, "not found")
    ))
  }
  
  # Update outcome
  trial_data$patients$outcome[patient_idx] <- outcome
  
  list(
    success = TRUE,
    patient_id = patient_id,
    outcome = outcome,
    message = "Outcome recorded successfully",
    timestamp = Sys.time()
  )
}

#* Get all enrolled patients
#* @get /patients/list
#* @serializer json
function() {
  if (nrow(trial_data$patients) == 0) {
    return(list(
      patients = list(),
      total = 0
    ))
  }
  
  patients_list <- trial_data$patients
  patients_list$treatment_label <- ifelse(
    patients_list$treatment == 1, 
    "Treatment A", 
    "Control B"
  )
  
  list(
    patients = patients_list,
    total = nrow(patients_list)
  )
}

#* Get treatment effect estimate
#* @get /analysis/treatment-effect
#* @serializer json
function() {
  
  patients_with_outcomes <- trial_data$patients[!is.na(trial_data$patients$outcome), ]
  
  if (nrow(patients_with_outcomes) < 2) {
    return(list(
      success = FALSE,
      error = "Insufficient data for analysis (need at least 2 patients with outcomes)"
    ))
  }
  
  treated <- patients_with_outcomes[patients_with_outcomes$treatment == 1, ]
  control <- patients_with_outcomes[patients_with_outcomes$treatment == 0, ]
  
  if (nrow(treated) == 0 || nrow(control) == 0) {
    return(list(
      success = FALSE,
      error = "Need patients in both treatment groups"
    ))
  }
  
  # Calculate treatment effect
  mean_treated <- mean(treated$outcome)
  mean_control <- mean(control$outcome)
  treatment_effect <- mean_treated - mean_control
  
  # Calculate standard errors
  se_treated <- sd(treated$outcome) / sqrt(nrow(treated))
  se_control <- sd(control$outcome) / sqrt(nrow(control))
  se_effect <- sqrt(se_treated^2 + se_control^2)
  
  # Confidence interval
  ci_lower <- treatment_effect - 1.96 * se_effect
  ci_upper <- treatment_effect + 1.96 * se_effect
  
  # Stratified analysis if using CARA
  stratified_results <- list()
  if (trial_data$config$randomization_method == "CARA") {
    for (s in unique(patients_with_outcomes$stratum)) {
      stratum_data <- patients_with_outcomes[patients_with_outcomes$stratum == s, ]
      treated_s <- stratum_data[stratum_data$treatment == 1, ]
      control_s <- stratum_data[stratum_data$treatment == 0, ]
      
      if (nrow(treated_s) > 0 && nrow(control_s) > 0) {
        effect_s <- mean(treated_s$outcome) - mean(control_s$outcome)
        stratified_results[[paste0("stratum_", s)]] <- list(
          treatment_effect = round(effect_s, 4),
          n_treated = nrow(treated_s),
          n_control = nrow(control_s),
          mean_treated = round(mean(treated_s$outcome), 4),
          mean_control = round(mean(control_s$outcome), 4)
        )
      }
    }
  }
  
  list(
    success = TRUE,
    overall_treatment_effect = round(treatment_effect, 4),
    standard_error = round(se_effect, 4),
    ci_95_lower = round(ci_lower, 4),
    ci_95_upper = round(ci_upper, 4),
    mean_treated = round(mean_treated, 4),
    mean_control = round(mean_control, 4),
    n_treated = nrow(treated),
    n_control = nrow(control),
    stratified_results = stratified_results,
    timestamp = Sys.time()
  )
}

#* Get allocation statistics
#* @get /analysis/allocation-stats
#* @serializer json
function() {
  
  if (nrow(trial_data$patients) == 0) {
    return(list(
      success = FALSE,
      error = "No patients enrolled"
    ))
  }
  
  total <- nrow(trial_data$patients)
  n_treatment <- sum(trial_data$patients$treatment == 1)
  n_control <- sum(trial_data$patients$treatment == 0)
  
  # Overall statistics
  overall <- list(
    total_patients = total,
    treatment_a = n_treatment,
    control_b = n_control,
    proportion_treatment = round(n_treatment / total, 4),
    proportion_control = round(n_control / total, 4)
  )
  
  # Stratum-specific statistics
  stratum_stats <- list()
  for (s in unique(trial_data$patients$stratum)) {
    stratum_data <- trial_data$patients[trial_data$patients$stratum == s, ]
    n_s <- nrow(stratum_data)
    n_treat_s <- sum(stratum_data$treatment == 1)
    n_ctrl_s <- sum(stratum_data$treatment == 0)
    
    stratum_stats[[paste0("stratum_", s)]] <- list(
      total = n_s,
      treatment_a = n_treat_s,
      control_b = n_ctrl_s,
      proportion_treatment = round(n_treat_s / n_s, 4),
      proportion_control = round(n_ctrl_s / n_s, 4)
    )
  }
  
  list(
    success = TRUE,
    overall = overall,
    by_stratum = stratum_stats,
    timestamp = Sys.time()
  )
}

#* Export trial data
#* @get /data/export
#* @serializer json
function() {
  list(
    config = trial_data$config,
    patients = trial_data$patients,
    export_time = Sys.time()
  )
}
