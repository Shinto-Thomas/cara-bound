# CARA Bound - Complete Working Module Documentation

## Table of Contents
1. [Overview](#overview)
2. [Repository Purpose](#repository-purpose)
3. [Mathematical Foundation](#mathematical-foundation)
4. [Repository Structure](#repository-structure)
5. [Dependencies](#dependencies)
6. [Module Components](#module-components)
7. [Workflow](#workflow)
8. [Key Algorithms](#key-algorithms)
9. [Usage Examples](#usage-examples)
10. [Output Interpretation](#output-interpretation)

---

## Overview

This repository contains the implementation of **Covariate-Adjusted Response-Adaptive (CARA) Randomization** methods for clinical trials. The code supports the research paper:

> Xin, J., & Ma, W. (2025). On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization. *Statistical Methods in Medical Research*, 09622802251327689.

The system implements and compares various randomization strategies for allocating patients to treatment groups in clinical trials, with a focus on achieving statistical efficiency while maintaining balance across covariate strata.

---

## Repository Purpose

The primary goals of this repository are to:

1. **Implement randomization algorithms**: Various response-adaptive and covariate-adjusted randomization procedures
2. **Perform simulation studies**: Generate data under different models and evaluate randomization performance
3. **Compare methods**: Assess efficiency, bias, and variance across different allocation strategies
4. **Replicate research results**: Provide transparent, reproducible code for all results in the manuscript

---

## Mathematical Foundation

### Clinical Trial Randomization

In clinical trials, patients are randomly assigned to treatment groups. The key challenges are:
- **Efficiency**: Minimizing variance of treatment effect estimates
- **Balance**: Ensuring comparable groups across important covariates (strata)
- **Ethics**: Allocating more patients to better-performing treatments

### Target Allocation Strategies

The system implements several target allocation rules:

1. **Neyman Allocation**: Minimizes variance of treatment effect estimate
   - `ρ = σ₁/(σ₁ + σ₀)` where σ₁, σ₀ are standard deviations for treatments

2. **RSIHR (Rosenberger-Sverdlov-Ivanova-Hu-Rosenberger)**: Minimizes expected treatment failures
   - `ρ = σ₁√μ₀/(σ₁√μ₀ + σ₀√μ₁)` where μ₁, μ₀ are mean responses

3. **Biased Coin Design (BandBis)**: Uses normal CDF for treatment comparison
   - `ρ = Φ((μ₁ - μ₀)/TB)` where Φ is standard normal CDF

4. **New Constrained Method**: Combines Neyman allocation with constraint threshold TB
   - Optimizes variance while ensuring expected response meets threshold

5. **Bayesian**: Uses Bayesian posterior distributions for adaptive allocation

### Randomization Procedures

1. **Complete Randomization (CR)**: Fixed probability allocation
2. **Biased Coin Design (BCD)**: Balances treatment assignments
3. **Doubly-Adaptive Biased Coin Design (DBCD/RAR)**: Adapts to both target allocation and current imbalance
4. **Covariate-Adjusted (CARA)**: Performs DBCD within each stratum
5. **Covariate-Adjusted DBCD (CADBCD)**: Global adaptation with covariate adjustment

---

## Repository Structure

```
cara-bound/
├── README.md                    # Project overview and basic information
├── LICENSE                      # License information
├── base_randomization.cpp       # C++ implementation of randomization algorithms
├── simulation.R                 # R functions for simulation and analysis
├── codes.Rmd                    # R Markdown replication code
└── codes.pdf                    # Generated output from codes.Rmd
```

---

## Dependencies

### R Packages
- **parallel**: Parallel computing for Monte Carlo simulations
- **Rcpp**: Interface between R and C++ code
- **RcppArmadillo**: C++ linear algebra library interface
- **ggplot2**: Data visualization
- **tidyr**: Data manipulation (reshaping)
- **dplyr**: Data manipulation (filtering, summarizing)
- **patchwork**: Combining multiple plots
- **latex2exp**: LaTeX expressions in plots

### System Requirements
- R (≥ 3.5.0)
- C++ compiler with C++11 support
- Sufficient RAM for large simulations (recommended ≥ 8GB)

---

## Module Components

### 1. base_randomization.cpp

**Purpose**: High-performance C++ implementation of randomization procedures.

#### Key Functions:

##### `target_alloc()`
```cpp
double target_alloc(double muA, double sigmaA, 
                    double muB, double sigmaB, 
                    String target = "Neyman", 
                    double TB = 4)
```
- **Purpose**: Calculates target allocation probability for treatment A
- **Parameters**:
  - `muA, muB`: Mean responses for treatments A and B
  - `sigmaA, sigmaB`: Standard deviations for treatments
  - `target`: Allocation strategy ("Neyman", "RSIHR", "BandBis", "ZhangRosenberger", "New")
  - `TB`: Threshold parameter for constrained methods
- **Returns**: Target allocation probability ρ (constrained to [0.1, 0.9])

##### `assigFun_g()`
```cpp
double assigFun_g(double x, double y, double gamma = 2)
```
- **Purpose**: Doubly-adaptive biased coin function
- **Parameters**:
  - `x`: Current proportion of treatment A assignments
  - `y`: Target allocation probability
  - `gamma`: Tuning parameter (controls adaptation strength)
- **Returns**: Probability of assigning next patient to treatment A
- **Formula**: Uses ratio of powered terms to bias allocation toward target

##### `DBCD()`
```cpp
arma::vec DBCD(arma::mat Ymat, double gamma = 2, int n0 = 10, 
               String target = "BandBis", double TB = 4)
```
- **Purpose**: Implements doubly-adaptive biased coin design (Response-Adaptive Randomization)
- **Parameters**:
  - `Ymat`: n×2 matrix of potential outcomes [Y₀, Y₁]
  - `gamma`: Tuning parameter for adaptation
  - `n0`: Burn-in period (initial balanced randomization)
  - `target`: Target allocation rule
  - `TB`: Threshold parameter
- **Returns**: Vector of treatment assignments (0/1)
- **Algorithm**:
  1. Initial 2×n0 patients: balanced randomization
  2. For each subsequent patient:
     - Estimate target allocation from observed data
     - Calculate assignment probability using `assigFun_g()`
     - Randomly assign based on this probability

##### `CARA()`
```cpp
arma::vec CARA(List model_output, double gamma = 2, int n0 = 10, 
               std::string target = "Neyman", double TB = 1)
```
- **Purpose**: Covariate-Adjusted Response-Adaptive randomization
- **Parameters**:
  - `model_output`: List containing `Ymat` (outcomes) and `strata` (covariate strata)
  - Other parameters same as `DBCD()`
- **Returns**: Vector of treatment assignments
- **Algorithm**: Applies DBCD independently within each stratum

##### `CADBCD()`
```cpp
arma::vec CADBCD(List model_output, double gamma = 2, int n0 = 30, 
                 String target = "Neyman", double TB = 30)
```
- **Purpose**: Covariate-Adjusted DBCD with global balance
- **Key Difference from CARA**: Maintains global treatment balance while accounting for strata-specific targets
- **Algorithm**:
  1. Initial balanced randomization
  2. For each patient:
     - Calculate stratum-specific target allocations
     - Compute weighted average target across all strata
     - Assign using DBCD with global imbalance and stratum-specific target

##### `CRand()`
```cpp
arma::vec CRand(arma::mat Ymat, double delta = 0.5)
```
- **Purpose**: Complete randomization with fixed probability
- **Returns**: Treatment assignments with probability δ

##### `n0Rand()`
```cpp
arma::vec n0Rand(int n0)
```
- **Purpose**: Initial balanced randomization for burn-in period
- **Returns**: Vector of 2×n0 assignments with exactly n0 in each group

---

### 2. simulation.R

**Purpose**: R implementation of simulation framework, data generation, and analysis functions.

#### Data Generation Functions:

##### `model1(n)`
```r
model1 <- function(n)
```
- **Purpose**: Binary outcome model with 2 strata
- **Structure**:
  - 2 strata with 1/3 and 2/3 probabilities
  - Stratum 1: Y₀~Bernoulli(0.5), Y₁~Bernoulli(0.9)
  - Stratum 2: Y₀~Bernoulli(0.5), Y₁~Bernoulli(0.5)
- **Returns**: List with `Ymat` (outcomes) and `strata` (stratum indicators)

##### `model2(n)`
```r
model2 <- function(n)
```
- **Purpose**: Continuous outcome model with 3 strata (primary model in paper)
- **Structure**:
  - 3 equally likely strata
  - Complex t-distribution based outcomes
  - Stratum 2 has reversed treatment effects
  - Treatment B adds 20 to outcomes
- **Returns**: List with `Ymat` and `strata`

##### `model3(n)`
```r
model3 <- function(n)
```
- **Purpose**: Normal distribution model with 3 strata
- **Structure**:
  - Y₀~N(20, stratum)
  - Y₁~N(60-5×stratum, 2×(4-stratum))
- **Returns**: List with `Ymat` and `strata`

#### Randomization Wrapper Functions:

##### `MIN(model_output, lambda = 0.75)`
- **Purpose**: Minimization (stratified biased coin design)
- **Algorithm**: Applies BCD within each stratum independently

##### `BCD(n, lambda = 0.75)`
- **Purpose**: Biased Coin Design
- **Algorithm**: 
  - Tracks imbalance D
  - If D > 0, assign to control with probability 0.75
  - If D < 0, assign to treatment with probability 0.75

#### Estimation Functions:

##### `DID(Ymat, An)`
```r
DID <- function(Ymat, An)
```
- **Purpose**: Difference-in-Differences estimator
- **Formula**: `τ̂ = Ȳ₁ - Ȳ₀` where Ȳ₁ is mean outcome in treatment group
- **Returns**: Treatment effect estimate

##### `SDID(model_output, An)`
```r
SDID <- function(model_output, An)
```
- **Purpose**: Stratified Difference-in-Differences
- **Formula**: `τ̂ = Σₛ (nₛ/n) × τ̂ₛ` weighted average of stratum-specific effects
- **Returns**: Stratified treatment effect estimate

#### Oracle Functions:

##### `oracle(model_output, target, TB)`
```r
oracle <- function(model_output, target, TB = 1)
```
- **Purpose**: Computes true population parameters for each stratum
- **Returns**: List containing:
  - `prob_strata`: Proportion in each stratum
  - `tau_strata`: True treatment effects per stratum
  - `Y0bar_strata`, `Y1bar_strata`: Mean outcomes per stratum
  - `sigma0_strata`, `sigma1_strata`: Standard deviations per stratum
  - `target_alloc_strata`: Optimal allocation probabilities

##### `oracle2(model_output, target, TB)`
- **Purpose**: Computes population parameters without stratification
- **Returns**: Overall treatment effect, means, SDs, and target allocation

#### Simulation Experiment Functions:

##### `repli_func(model_func, n, rand, target, TB, n0, gamma)`
```r
repli_func <- function(model_func, n=500, rand="CARA", 
                      target="Neyman", TB=1, n0=10, gamma=2)
```
- **Purpose**: Single replication of randomization experiment
- **Process**:
  1. Generate data from `model_func`
  2. Apply randomization procedure `rand`
  3. Compute DID and SDID estimates
  4. Calculate stratum-specific mean outcomes
- **Returns**: Vector with estimates and means

##### `experiment(model_func, n, randomise, target, TB, n0, gamma, repli, seed)`
```r
experiment <- function(model_func=model2, n=500, randomise="CARA",
                      target="New", TB=1, n0=10, gamma=2, 
                      repli=1e4, seed=12345)
```
- **Purpose**: Run Monte Carlo simulation (for stratified methods)
- **Process**:
  1. Set random seed for reproducibility
  2. Run `repli` replications in parallel (8 cores)
  3. Collect results into data frame
- **Returns**: Data frame with columns: `sdid`, `did`, `Ymean` (per stratum)

##### `experiment2()`
- **Purpose**: Run Monte Carlo simulation (for non-stratified methods)
- **Similar structure** but uses `repli_func2()` which returns only `did` and overall `Ymean`

#### Analysis/Extraction Functions:

##### `extract(final_result, round_num = 3)`
```r
extract <- function(final_result, round_num = 3)
```
- **Purpose**: Extract summary statistics from experiment results (stratified)
- **Computes**:
  - Theoretical efficiency bound / n
  - Mean outcomes per stratum
  - Bias of DID and SDID estimators
  - Variance of DID and SDID estimators
- **Returns**: Vector of rounded summary statistics

##### `extract2(final_result, round_num = 3)`
- **Purpose**: Extract summary statistics (non-stratified version)

##### `true_values(model_func, rand, target, TB, n, seed)`
```r
true_values <- function(model_func, rand="RAR", target="New", 
                       TB=100, n=1e6, seed=12345)
```
- **Purpose**: Compute true treatment effect and theoretical efficiency bound
- **Process**:
  1. Generate large sample (n=1e6) for approximating population
  2. Calculate true treatment effect τ
  3. Compute theoretical variance bound based on optimal allocation
- **Returns**: Vector [true_tau, true_bound]

#### Diagnostic Functions:

##### `burn_in_test(model_output, n0, target, rand, TB)`
```r
burn_in_test <- function(model_output, n0=10, target="Neyman", 
                        rand="CARA", TB=30)
```
- **Purpose**: Compare target allocation estimates using all data vs. burn-in period only
- **Returns**: Vector of [true_pi, pi_hat] for comparison

##### `compare_alloc(model_output, n, n0, target, TB, repli, gamma)`
```r
compare_alloc <- function(model_output, n=500, n0=10, 
                         target="Neyman", TB=30, repli=1000, gamma=2)
```
- **Purpose**: Compare allocation ratios between CARA (stratified) and CADBCD (global)
- **Returns**: Vector of stratum-specific allocation ratios for both methods

---

### 3. codes.Rmd

**Purpose**: R Markdown document containing replication code for all tables and figures in the manuscript.

#### Structure:

1. **Dependency Loading**: Load all required packages and source C++/R code
2. **Main Text Results**: 
   - Table 1: RAR (non-stratified) results under different constraints
   - Table 2: CARA (stratified) results under different constraints
3. **Supplementary Material**:
   - Section S2.1: Binary outcome model (model1) results
   - Section S2.2: Comparison across multiple randomization methods
   - Section S2.3: Allocation probability comparison plots
   - Section S2.4: Burn-in period analysis plots
   - Section S2.5: Treatment effect estimate distributions

#### Key Code Patterns:

```r
# Set true values for comparison
true_tau = true_values(model2, "RAR")[1]
true_bound = true_values(model2, "RAR")[2]

# Run experiment
n = 500
repli_num = 1e4
results = experiment2(model2, n, "CR", repli = repli_num)

# Extract and display summary
extract2(results)
```

---

## Workflow

### Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CARA Bound Workflow                          │
└─────────────────────────────────────────────────────────────────┘

1. DATA GENERATION
   ├─ model1(n), model2(n), model3(n) [simulation.R]
   └─> Ymat [n×2], strata [n×1]

2. RANDOMIZATION
   ├─ C++ Functions [base_randomization.cpp]:
   │  ├─ CRand(): Complete Randomization
   │  ├─ DBCD(): Response-Adaptive (RAR)
   │  ├─ CARA(): Covariate-Adjusted RAR
   │  └─ CADBCD(): Global Covariate-Adjusted
   │
   └─ R Wrapper Functions [simulation.R]:
      ├─ BCD(): Biased Coin Design
      └─ MIN(): Minimization

3. ESTIMATION
   ├─ DID(Ymat, An): Overall effect
   └─ SDID(model_output, An): Stratified effect

4. SIMULATION FRAMEWORK
   ├─ repli_func(): Single replication
   ├─ experiment(): Multiple replications (parallel)
   └─> Results data frame

5. ANALYSIS
   ├─ extract(): Summary statistics
   ├─ true_values(): Theoretical benchmarks
   └─> Tables and figures

6. REPLICATION
   └─ codes.Rmd: Complete analysis pipeline
      └─> codes.pdf: Publication-ready output
```

### Typical Execution Flow

```r
# Step 1: Setup
Rcpp::sourceCpp("base_randomization.cpp")
source("simulation.R")

# Step 2: Define true parameters
true_tau = true_values(model2, "CARA")[1]
true_bound = true_values(model2, "CARA")[2]

# Step 3: Run simulation
n = 500
repli_num = 10000
results = experiment(model2, n, "CARA", 
                    target = "New", TB = 18, 
                    repli = repli_num)

# Step 4: Extract results
summary_stats = extract(results)
# Returns: [bound/n, Ymean1, Ymean2, Ymean3, 
#           bias_did, var_did, bias_sdid, var_sdid]

# Step 5: Visualize
library(ggplot2)
ggplot(data.frame(estimate = results$sdid), 
       aes(x = estimate)) +
  geom_histogram() +
  geom_vline(xintercept = true_tau, color = "red")
```

---

## Key Algorithms

### Algorithm 1: DBCD (Doubly-Adaptive Biased Coin Design)

**Input**: 
- Outcome matrix Ymat [n×2]
- Tuning parameter γ
- Burn-in size n₀
- Target allocation rule
- Threshold TB

**Output**: Treatment assignments A [n×1]

**Procedure**:
```
1. Initialize first 2n₀ patients with balanced randomization
2. For patient i = 2n₀+1 to n:
   a. Subset historical data: Y₁ (treated), Y₀ (control)
   b. Estimate parameters: Ȳ₁, Ȳ₀, σ̂₁, σ̂₀
   c. Compute target allocation: ρ̂ = target_alloc(Ȳ₁, σ̂₁, Ȳ₀, σ̂₀, target, TB)
   d. Calculate current proportion: x = (# treated) / (i-1)
   e. Compute assignment probability: 
      p = assigFun_g(x, ρ̂, γ)
   f. Assign treatment: Aᵢ ~ Bernoulli(p)
3. Return A
```

**Key Properties**:
- Adapts to observed treatment responses
- Biases allocation toward target proportion ρ̂
- γ controls adaptation speed (larger γ = faster adaptation)

### Algorithm 2: CARA (Covariate-Adjusted RAR)

**Input**:
- Model output (Ymat, strata)
- Parameters (γ, n₀, target, TB)

**Output**: Treatment assignments A [n×1]

**Procedure**:
```
1. Identify unique strata: S = {s₁, s₂, ..., sₖ}
2. For each stratum s in S:
   a. Extract stratum-specific outcomes: Ymatₛ
   b. Apply DBCD within stratum:
      Aₛ = DBCD(Ymatₛ, γ, n₀, target, TB)
3. Combine stratum-specific assignments into A
4. Return A
```

**Key Properties**:
- Independent adaptation within each stratum
- Maintains covariate balance automatically
- Each stratum has own target allocation

### Algorithm 3: CADBCD (Covariate-Adjusted DBCD)

**Input**: Same as CARA

**Output**: Treatment assignments A [n×1]

**Procedure**:
```
1. Initialize first 2n₀ patients with balanced randomization
2. For patient i = 2n₀+1 to n:
   a. For each stratum s:
      i. Identify patients in stratum s before time i
      ii. Subset treated and control in stratum s
      iii. Estimate parameters: Ȳ₁ₛ, Ȳ₀ₛ, σ̂₁ₛ, σ̂₀ₛ
      iv. Compute target: πₛ = target_alloc(Ȳ₁ₛ, σ̂₁ₛ, Ȳ₀ₛ, σ̂₀ₛ, target, TB)
   b. Compute weighted average target:
      ρ̂ = Σₛ pₛ × πₛ where pₛ = (# in stratum s) / (i-1)
   c. Identify current patient's stratum: j = stratum[i]
   d. Calculate assignment probability:
      p = πⱼ × (ρ̂/x̄)^γ / [πⱼ × (ρ̂/x̄)^γ + (1-πⱼ) × ((1-ρ̂)/(1-x̄))^γ]
      where x̄ = (# treated) / (i-1)
   e. Constrain: p ∈ [0.1, 0.9]
   f. Assign treatment: Aᵢ ~ Bernoulli(p)
3. Return A
```

**Key Properties**:
- Global treatment balance
- Stratum-specific targets
- More complex than CARA but potentially more efficient

---

## Usage Examples

### Example 1: Basic Simulation with CARA

```r
# Load dependencies
library(Rcpp)
library(RcppArmadillo)
Rcpp::sourceCpp("base_randomization.cpp")
source("simulation.R")

# Generate data
set.seed(123)
model_output = model2(500)

# Apply CARA randomization
assignments = CARA(model_output, 
                   gamma = 2,
                   n0 = 10,
                   target = "Neyman",
                   TB = 1)

# Estimate treatment effect
tau_hat = SDID(model_output, assignments)
print(paste("Estimated treatment effect:", round(tau_hat, 3)))
```

### Example 2: Comparing Multiple Methods

```r
# Setup
n = 500
repli = 1000

# Complete Randomization
cr_results = experiment(model2, n, "CR", repli = repli)

# CARA with Neyman allocation
cara_results = experiment(model2, n, "CARA", 
                         target = "Neyman", 
                         repli = repli)

# CARA with constrained allocation
cara_const_results = experiment(model2, n, "CARA",
                               target = "New",
                               TB = 18,
                               repli = repli)

# Compare
print("Complete Randomization:")
print(extract(cr_results))

print("CARA (Neyman):")
print(extract(cara_results))

print("CARA (Constrained):")
print(extract(cara_const_results))
```

### Example 3: Visualizing Allocation Probabilities

```r
library(ggplot2)

# Generate large sample for oracle values
oracle_val = oracle(model2(100000), "New", TB = 18)

# Run simulation replications
set.seed(123)
repli_num = 1000
alloc_data = replicate(repli_num, {
  compare_alloc(model2(500), n0 = 10, target = "New", TB = 18)
})

# Create data frame
df = data.frame(
  stratum = rep(paste0("Stratum ", 1:3), 2 * repli_num),
  method = rep(c("CARA", "CADBCD"), each = 3 * repli_num),
  allocation = c(alloc_data[1:3,], alloc_data[4:6,]),
  true_value = rep(oracle_val$target_alloc_strata, 2)
)

# Plot
ggplot(df, aes(x = stratum, y = allocation, fill = method)) +
  geom_boxplot(alpha = 0.6) +
  geom_point(aes(y = true_value), 
            shape = 17, color = "red", size = 3) +
  theme_minimal() +
  labs(title = "Allocation Probability Comparison",
       y = "Allocation Probability",
       x = "")
```

### Example 4: Efficiency Analysis

```r
# Compute theoretical bound
true_tau = true_values(model2, "CARA", target = "New", TB = 18)[1]
true_bound = true_values(model2, "CARA", target = "New", TB = 18)[2]

# Run experiment
n = 500
results = experiment(model2, n, "CARA", 
                    target = "New", TB = 18, 
                    repli = 10000)

# Extract metrics
stats = extract(results)
theoretical_var = stats[1]  # bound/n
empirical_var_sdid = stats[7]  # variance of SDID

# Efficiency
efficiency = theoretical_var / empirical_var_sdid
print(paste("Efficiency:", round(efficiency * 100, 2), "%"))

# Bias
bias_sdid = stats[6]
print(paste("Bias:", round(bias_sdid, 4)))
```

---

## Output Interpretation

### Understanding extract() Output

When you run `extract(results)`, you get a vector with 8 elements:

```r
[1] bound/n      # Theoretical efficiency bound divided by sample size
[2] Ymean1       # Mean outcome in stratum 1
[3] Ymean2       # Mean outcome in stratum 2  
[4] Ymean3       # Mean outcome in stratum 3
[5] bias_did     # Bias of difference-in-differences estimator
[6] bias_sdid    # Bias of stratified DID estimator
[7] var_did      # Variance of DID estimator
[8] var_sdid     # Variance of stratified DID estimator
```

**Interpretation**:
- **bound/n**: Lower values indicate better theoretical efficiency
- **bias**: Should be close to 0; large values suggest estimator bias
- **var_sdid**: Should be close to bound/n for optimal methods
- **var_sdid < var_did**: Indicates benefit of stratification

### Understanding extract2() Output (Non-stratified)

```r
[1] bound/n      # Theoretical efficiency bound divided by sample size
[2] Ymean        # Overall mean outcome
[3] bias         # Bias of DID estimator
[4] variance     # Variance of DID estimator
```

### Example Table Interpretation (Table 2 from codes.Rmd)

```
Method          bound/n  Ymean1  Ymean2  Ymean3  bias_did  var_did  bias_sdid  var_sdid
CR              0.082    17.5    18.2    19.1    0.003     0.083    0.002      0.082
CARA (Neyman)   0.070    17.6    18.0    19.3    0.001     0.072    0.001      0.071
CARA (New, 18)  0.072    17.8    17.9    19.0    0.002     0.073    0.001      0.072
```

**Reading this table**:
1. **Complete Randomization (CR)**: 
   - Theoretical bound: 0.082
   - Achieved variance: 0.082 (matching theory)
   - Unbiased estimates
   
2. **CARA with Neyman**:
   - Lower bound (0.070 vs 0.082) = 14.6% more efficient than CR
   - Achieved variance (0.071) close to bound
   - Maintains low bias
   
3. **CARA with Constraint (c=18)**:
   - Slightly higher bound than unconstrained Neyman
   - Trade-off: Ensure mean outcome ≥ 18 while maintaining good efficiency
   - Mean outcomes show constraint is effective (all close to 18-19)

### Diagnostic Plots

**Boxplots of Estimates**:
- Center line should align with true value (red marker)
- Narrow boxes indicate low variance
- Symmetric boxes suggest unbiased estimates

**Allocation Probability Plots**:
- Points show achieved allocation ratios across replications
- Red triangles show theoretical optimal values
- CARA shows more variability (independent per stratum)
- CADBCD shows less variability (global coordination)

---

## Advanced Topics

### Bayesian Target Allocation

The Bayesian method uses inverse-gamma priors for mean outcomes:

```r
target_alloc_bayesian <- function(n1, n0, sum1, sum0, N, alpha, beta, B) {
  # Posterior samples for mean outcomes
  mu0 = 1/rgamma(10000, shape = n0 + alpha, rate = sum0 + beta)
  mu1 = 1/rgamma(10000, shape = n1 + alpha, rate = sum1 + beta)
  
  # Probability treatment 1 is better
  p1 = mean(mu1 < mu0)  # Lower is better (e.g., toxicity)
  
  # Apply skewing function
  c = (n0 + n1) / (2 * N * 0.8)
  ps1 = p1^c / (p1^c + (1-p1)^c)
  
  # Constrain to [B, 1-B]
  pp1 = min(max(ps1, B), 1-B)
  return(pp1)
}
```

This is called from C++ via:
```cpp
double call_bayesian(double n1, double n0, double sum1, double sum0,
                    int N, double alpha=1, double beta=1, double B=0.1)
```

### Burn-in Period Analysis

The burn-in period (first 2n₀ patients) uses balanced randomization because:
1. **Insufficient data**: Initial estimates are unreliable
2. **Stability**: Prevents extreme allocations early on
3. **Ethical**: Ensures fair initial exposure to treatments

The `burn_in_test()` function compares:
- **All-sample estimate**: Target allocation using all outcome data
- **Burn-in estimate**: Target allocation using only first 2n₀ patients

Large differences indicate:
- High variability in early estimates
- Need for larger burn-in period
- Potential for early allocation bias

### Parallel Computing

The simulation uses parallel processing via `mclapply`:

```r
library(parallel)
RNGkind("L'Ecuyer-CMRG")  # Parallel-safe RNG
set.seed(12345)

results <- mclapply(
  1:repli, 
  function(x) {
    repli_func(model_func, n, randomise, target, TB, n0, gamma)
  },
  mc.cores = 8,  # Use 8 CPU cores
  mc.set.seed = TRUE  # Ensure reproducible parallel RNG
)
```

**Performance**: With 8 cores, 10,000 replications take ~5-10 minutes depending on n and complexity.

---

## Troubleshooting

### Common Issues

**Problem**: C++ compilation errors
```
Error in sourceCpp("base_randomization.cpp"): ...
```
**Solution**: Ensure RcppArmadillo is installed:
```r
install.packages("RcppArmadillo")
```

**Problem**: Parallel execution hangs
**Solution**: Reduce `mc.cores` or use sequential execution:
```r
results <- lapply(1:repli, function(x) { ... })
```

**Problem**: "object true_tau not found"
**Solution**: Run `true_values()` before calling `extract()`:
```r
true_tau = true_values(model2, "CARA")[1]
true_bound = true_values(model2, "CARA")[2]
```

**Problem**: Very high variance in results
**Solution**: 
1. Increase burn-in period `n0`
2. Reduce adaptation parameter `gamma`
3. Check data generation (are there outliers?)

---

## References

### Primary Paper
Xin, J., & Ma, W. (2025). On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization. *Statistical Methods in Medical Research*, 09622802251327689.

### Key Methodology Papers
- Hu, Y., & Hu, F. (2012). Asymptotic properties of covariate-adaptive randomization. *The Annals of Statistics*, 40(3), 1794-1815.
- Rosenberger, W. F., & Lachin, J. M. (2015). *Randomization in clinical trials: theory and practice*. John Wiley & Sons.
- Atkinson, A. C. (1982). Optimum biased coin designs for sequential clinical trials with prognostic factors. *Biometrika*, 69(1), 61-67.

---

## Conclusion

This repository provides a comprehensive framework for:
1. **Implementing** state-of-the-art adaptive randomization procedures
2. **Evaluating** their statistical properties through simulation
3. **Comparing** efficiency across methods and allocation strategies
4. **Reproducing** research results transparently

The modular design separates:
- **Core algorithms** (C++ for performance)
- **Simulation framework** (R for flexibility)
- **Analysis pipeline** (R Markdown for reproducibility)

This makes the code both efficient for large-scale simulations and accessible for understanding and extending the methodology.

---

## Contact and Citation

If using this code, please cite:

```bibtex
@article{xin2025achievability,
  title={On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization},
  author={Xin, J. and Ma, W.},
  journal={Statistical Methods in Medical Research},
  pages={09622802251327689},
  year={2025},
  publisher={SAGE Publications}
}
```

For questions or issues, please open an issue on the GitHub repository: https://github.com/Shinto-Thomas/cara-bound
