# Example Client: Complete CARA Trial Workflow - Standalone API
# This script demonstrates how to use the standalone CARA API (pure R, no C++)

library(httr)
library(jsonlite)

BASE_URL <- "http://localhost:8000"

cat("========================================\n")
cat("CARA Standalone API - Example Trial Workflow\n")
cat("Pure R Implementation (No C++)\n")
cat("========================================\n\n")

# Helper function to make API calls
api_call <- function(method, endpoint, body = NULL) {
  url <- paste0(BASE_URL, endpoint)
  
  if (method == "GET") {
    response <- GET(url)
  } else if (method == "POST") {
    response <- POST(url, body = body, encode = "json")
  }
  
  if (status_code(response) != 200) {
    cat("ERROR: API call failed\n")
    print(content(response))
    return(NULL)
  }
  
  return(content(response))
}

# Step 1: Check API health
cat("Step 1: Checking API health...\n")
health <- api_call("GET", "/health")
cat("Status:", health$status, "\n")
cat("Implementation:", health$implementation, "\n\n")

# Step 2: Initialize trial
cat("Step 2: Initializing trial...\n")
init_response <- api_call("POST", "/trial/initialize", body = list(
  study_name = "Hypertension-CARA-Standalone",
  n0 = 10,
  gamma = 2,
  target = "Neyman",
  TB = 1,
  randomization_method = "CARA"
))
cat("Study:", init_response$config$study_name, "\n")
cat("Burn-in size:", init_response$config$n0, "\n\n")

# Step 3: Simulate patient enrollment
cat("Step 3: Enrolling patients...\n\n")

# Define patient strata (simulating patient characteristics)
# In real trial, these would come from patient screening data
set.seed(123)
patient_strata <- sample(1:3, 50, replace = TRUE, prob = c(0.3, 0.4, 0.3))

# Simulate true treatment effects by stratum (unknown in real trial)
true_effects <- c(3, 4, 5)  # Stratum 1, 2, 3

# Enroll patients
patients_enrolled <- list()

for (i in 1:50) {
  cat(sprintf("Enrolling Patient %d (Stratum %d)... ", i, patient_strata[i]))
  
  # Enroll patient
  enrollment <- api_call("POST", "/patient/enroll", body = list(
    patient_id = i,
    stratum = patient_strata[i]
  ))
  
  if (!is.null(enrollment) && enrollment$success) {
    cat(sprintf("%s (p=%.3f, %s)\n", 
                enrollment$treatment_label,
                enrollment$allocation_probability,
                enrollment$allocation_method))
    
    patients_enrolled[[i]] <- enrollment
    
    # Simulate outcome (in real trial, this comes from patient follow-up)
    # Outcome = baseline effect + treatment effect + random noise
    baseline <- 20  # Baseline blood pressure reduction
    treatment_effect <- ifelse(enrollment$treatment == 1, 
                               true_effects[patient_strata[i]], 
                               0)
    noise <- rnorm(1, 0, 3)
    outcome <- baseline + treatment_effect + noise
    
    # Record outcome (simulate delay for first 20 patients to show burn-in)
    if (i <= 20 || runif(1) < 0.8) {
      api_call("POST", "/patient/outcome", body = list(
        patient_id = i,
        outcome = outcome
      ))
    }
    
  } else {
    cat("FAILED\n")
  }
  
  # Show status every 10 patients
  if (i %% 10 == 0) {
    cat("\n")
    status <- api_call("GET", "/trial/status")
    cat(sprintf("Status: %d enrolled, %d with outcomes, %d Treatment A, %d Control B\n\n",
                status$patients_enrolled,
                status$patients_with_outcomes,
                status$treatment_allocated,
                status$control_allocated))
  }
}

# Step 4: Check allocation statistics
cat("\nStep 4: Checking allocation statistics...\n")
alloc_stats <- api_call("GET", "/analysis/allocation-stats")

cat("\nOverall Allocation:\n")
cat(sprintf("- Total patients: %d\n", alloc_stats$overall$total_patients))
cat(sprintf("- Treatment A: %d (%.1f%%)\n", 
            alloc_stats$overall$treatment_a,
            alloc_stats$overall$proportion_treatment * 100))
cat(sprintf("- Control B: %d (%.1f%%)\n", 
            alloc_stats$overall$control_b,
            alloc_stats$overall$proportion_control * 100))

cat("\nBy Stratum:\n")
for (stratum_name in names(alloc_stats$by_stratum)) {
  s <- alloc_stats$by_stratum[[stratum_name]]
  cat(sprintf("- %s: %d total, %d Treatment A (%.1f%%), %d Control B (%.1f%%)\n",
              stratum_name, s$total, s$treatment_a, 
              s$proportion_treatment * 100,
              s$control_b, s$proportion_control * 100))
}

# Step 5: Analyze treatment effect
cat("\nStep 5: Analyzing treatment effect...\n")
effect <- api_call("GET", "/analysis/treatment-effect")

if (!is.null(effect) && effect$success) {
  cat(sprintf("\nOverall Treatment Effect: %.2f\n", effect$overall_treatment_effect))
  cat(sprintf("Standard Error: %.2f\n", effect$standard_error))
  cat(sprintf("95%% CI: [%.2f, %.2f]\n", effect$ci_95_lower, effect$ci_95_upper))
  cat(sprintf("Mean Treatment A: %.2f (n=%d)\n", effect$mean_treated, effect$n_treated))
  cat(sprintf("Mean Control B: %.2f (n=%d)\n", effect$mean_control, effect$n_control))
  
  if (length(effect$stratified_results) > 0) {
    cat("\nStratified Results:\n")
    for (stratum_name in names(effect$stratified_results)) {
      s <- effect$stratified_results[[stratum_name]]
      cat(sprintf("- %s: Effect=%.2f (n_treat=%d, n_ctrl=%d)\n",
                  stratum_name, s$treatment_effect, s$n_treated, s$n_control))
    }
  }
}

# Step 6: Export data
cat("\nStep 6: Exporting trial data...\n")
export <- api_call("GET", "/data/export")

if (!is.null(export)) {
  # Save to file
  write_json(export, "trial_data_export_standalone.json", pretty = TRUE)
  cat("Data exported to: trial_data_export_standalone.json\n")
}

cat("\n========================================\n")
cat("Example workflow completed successfully!\n")
cat("Pure R implementation (no C++)\n")
cat("========================================\n")
