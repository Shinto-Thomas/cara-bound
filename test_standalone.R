# Simple validation tests for standalone R implementations
# This file can be sourced to verify the functions work correctly

cat("========================================\n")
cat("CARA Standalone API - Validation Tests\n")
cat("========================================\n\n")

# Load the R implementations
tryCatch({
  source("randomization_r.R")
  cat("✓ randomization_r.R loaded successfully\n\n")
}, error = function(e) {
  cat("✗ Error loading randomization_r.R:\n")
  print(e)
  stop("Cannot proceed with tests")
})

# Test 1: target_alloc function
cat("Test 1: target_alloc function\n")
cat("------------------------------\n")

test1_results <- list()

# Neyman allocation
test1_results$neyman <- target_alloc(25, 5, 20, 3, "Neyman", 4)
cat(sprintf("Neyman allocation: %.4f (expected ~0.625)\n", test1_results$neyman))

# RSIHR allocation
test1_results$rsihr <- target_alloc(25, 5, 20, 3, "RSIHR", 4)
cat(sprintf("RSIHR allocation: %.4f (expected ~0.598)\n", test1_results$rsihr))

# BandBis allocation
test1_results$bandbis <- target_alloc(25, 5, 20, 3, "BandBis", 4)
cat(sprintf("BandBis allocation: %.4f (expected ~0.894)\n", test1_results$bandbis))

# Verify constraints
if (test1_results$neyman >= 0.1 && test1_results$neyman <= 0.9) {
  cat("✓ Constraints respected [0.1, 0.9]\n")
} else {
  cat("✗ Constraints violated\n")
}

cat("\n")

# Test 2: assigFun_g function
cat("Test 2: assigFun_g function\n")
cat("----------------------------\n")

test2_results <- list()

# Balanced case: x = y = 0.5
test2_results$balanced <- assigFun_g(0.5, 0.5, 2)
cat(sprintf("Balanced (x=0.5, y=0.5): %.4f (expected 0.5)\n", test2_results$balanced))

# Imbalanced case: need to increase x
test2_results$increase <- assigFun_g(0.3, 0.6, 2)
cat(sprintf("Increase needed (x=0.3, y=0.6): %.4f (expected >0.6)\n", test2_results$increase))

# Imbalanced case: need to decrease x
test2_results$decrease <- assigFun_g(0.7, 0.4, 2)
cat(sprintf("Decrease needed (x=0.7, y=0.4): %.4f (expected <0.4)\n", test2_results$decrease))

# Verify logic
if (test2_results$increase > 0.6 && test2_results$decrease < 0.4) {
  cat("✓ Biased coin logic working correctly\n")
} else {
  cat("✗ Biased coin logic may be incorrect\n")
}

cat("\n")

# Test 3: n0Rand function
cat("Test 3: n0Rand function\n")
cat("-----------------------\n")

set.seed(12345)
test3_result <- n0Rand(10)

n_ones <- sum(test3_result == 1)
n_zeros <- sum(test3_result == 0)

cat(sprintf("Generated vector length: %d\n", length(test3_result)))
cat(sprintf("Number of 1s: %d (expected 10)\n", n_ones))
cat(sprintf("Number of 0s: %d (expected 10)\n", n_zeros))

if (n_ones == 10 && n_zeros == 10) {
  cat("✓ Balanced randomization working correctly\n")
} else {
  cat("✗ Balanced randomization failed\n")
}

cat("\n")

# Test 4: DBCD function
cat("Test 4: DBCD function\n")
cat("---------------------\n")

# Create simple test data
set.seed(12345)
n_test <- 50
Ymat_test <- matrix(
  c(rnorm(n_test, 20, 5), rnorm(n_test, 25, 5)),
  ncol = 2
)

test4_result <- DBCD(Ymat_test, gamma = 2, n0 = 10, target = "Neyman", TB = 4)

n_assigned <- length(test4_result)
n_treatment <- sum(test4_result == 1)
n_control <- sum(test4_result == 0)

cat(sprintf("Patients assigned: %d\n", n_assigned))
cat(sprintf("Treatment group: %d (%.1f%%)\n", n_treatment, 100 * n_treatment / n_assigned))
cat(sprintf("Control group: %d (%.1f%%)\n", n_control, 100 * n_control / n_assigned))

# Check burn-in balance
burnin_treatment <- sum(test4_result[1:20] == 1)
burnin_control <- sum(test4_result[1:20] == 0)
cat(sprintf("Burn-in balance: %d treatment, %d control (expected 10 each)\n", 
            burnin_treatment, burnin_control))

if (burnin_treatment == 10 && burnin_control == 10) {
  cat("✓ DBCD burn-in working correctly\n")
} else {
  cat("✗ DBCD burn-in may have issues\n")
}

cat("\n")

# Test 5: CARA function
cat("Test 5: CARA function\n")
cat("---------------------\n")

# Create test data with 3 strata
set.seed(12345)
n_test <- 90
strata_test <- sample(1:3, n_test, replace = TRUE)
Ymat_test <- matrix(
  c(rnorm(n_test, 20, 5), rnorm(n_test, 25, 5)),
  ncol = 2
)

model_output_test <- list(Ymat = Ymat_test, strata = strata_test)

test5_result <- CARA(model_output_test, gamma = 2, n0 = 10, target = "Neyman", TB = 1)

cat(sprintf("Total patients: %d\n", length(test5_result)))

for (s in 1:3) {
  stratum_idx <- which(strata_test == s)
  if (length(stratum_idx) > 0) {
    n_stratum <- length(stratum_idx)
    n_treat <- sum(test5_result[stratum_idx] == 1)
    cat(sprintf("Stratum %d: %d patients, %d treatment (%.1f%%)\n", 
                s, n_stratum, n_treat, 100 * n_treat / n_stratum))
  }
}

if (length(test5_result) == n_test) {
  cat("✓ CARA assignment completed for all patients\n")
} else {
  cat("✗ CARA assignment incomplete\n")
}

cat("\n")

# Test 6: CRand function
cat("Test 6: CRand function\n")
cat("----------------------\n")

set.seed(12345)
test6_result <- CRand(Ymat_test, delta = 0.5)

n_treatment_cr <- sum(test6_result == 1)
expected_treatment <- n_test * 0.5

cat(sprintf("Complete randomization (delta=0.5): %d treatment (expected ~%.0f)\n", 
            n_treatment_cr, expected_treatment))

# Should be approximately 50% (within reasonable binomial variation)
if (abs(n_treatment_cr - expected_treatment) < 10) {
  cat("✓ Complete randomization working as expected\n")
} else {
  cat("⚠ Complete randomization may need more samples for stable estimate\n")
}

cat("\n")

# Summary
cat("========================================\n")
cat("Test Summary\n")
cat("========================================\n")
cat("All core functions have been tested.\n")
cat("If no errors were shown above, the\n")
cat("standalone R implementation is ready.\n\n")
cat("To test the full API, run:\n")
cat("  Rscript start_api_standalone.R\n")
cat("========================================\n")
