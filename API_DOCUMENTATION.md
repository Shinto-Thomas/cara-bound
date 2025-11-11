# CARA Randomization API Documentation

## Overview

This Plumber API provides a RESTful interface for implementing Covariate-Adjusted Response-Adaptive (CARA) randomization in clinical trials. The API manages patient enrollment, treatment assignment, outcome recording, and real-time treatment effect analysis.

## Table of Contents

1. [Quick Start](#quick-start)
2. [API Endpoints](#api-endpoints)
3. [Example Study Scenario](#example-study-scenario)
4. [Operational Workflow](#operational-workflow)
5. [Step-by-Step Operations Table](#step-by-step-operations-table)
6. [Integration Examples](#integration-examples)
7. [Error Handling](#error-handling)

---

## Quick Start

### Installation

Ensure you have the required R packages:

```r
install.packages(c("plumber", "Rcpp", "RcppArmadillo", "jsonlite"))
```

### Running the API

```r
library(plumber)

# Start the API server
pr <- plumb("plumber_api.R")
pr$run(port = 8000, host = "0.0.0.0")
```

The API will be available at `http://localhost:8000`

### Interactive Documentation

Access the Swagger UI at: `http://localhost:8000/__docs__/`

---

## API Endpoints

### 1. Health Check

**Endpoint:** `GET /health`

**Description:** Check if the API is running

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-11T09:00:00Z",
  "version": "1.0.0"
}
```

---

### 2. Initialize Trial

**Endpoint:** `POST /trial/initialize`

**Description:** Initialize or reset a clinical trial with specific parameters

**Parameters:**
- `study_name` (string): Study identifier (default: "CARA-Trial-Demo")
- `n0` (integer): Burn-in period size (default: 10)
- `gamma` (numeric): Adaptation tuning parameter (default: 2)
- `target` (string): Allocation strategy - "Neyman", "RSIHR", "BandBis", "New" (default: "Neyman")
- `TB` (numeric): Threshold parameter for constrained methods (default: 1)
- `randomization_method` (string): Method - "CR", "CARA", "CADBCD", "RAR" (default: "CARA")

**Request Example:**
```bash
curl -X POST "http://localhost:8000/trial/initialize" \
  -H "Content-Type: application/json" \
  -d '{
    "study_name": "Hypertension-CARA-2025",
    "n0": 10,
    "gamma": 2,
    "target": "Neyman",
    "TB": 1,
    "randomization_method": "CARA"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Trial initialized successfully",
  "config": {
    "study_name": "Hypertension-CARA-2025",
    "n0": 10,
    "gamma": 2,
    "target": "Neyman",
    "TB": 1,
    "randomization_method": "CARA"
  },
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 3. Get Trial Status

**Endpoint:** `GET /trial/status`

**Description:** Get current trial configuration and enrollment statistics

**Response:**
```json
{
  "config": {
    "study_name": "Hypertension-CARA-2025",
    "n0": 10,
    "gamma": 2,
    "target": "Neyman",
    "TB": 1,
    "randomization_method": "CARA"
  },
  "patients_enrolled": 25,
  "patients_with_outcomes": 20,
  "treatment_allocated": 13,
  "control_allocated": 12,
  "strata_distribution": {
    "1": 8,
    "2": 10,
    "3": 7
  },
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 4. Enroll Patient

**Endpoint:** `POST /patient/enroll`

**Description:** Enroll a new patient and receive treatment assignment

**Parameters:**
- `patient_id` (integer): Unique patient identifier
- `stratum` (integer): Covariate stratum (1, 2, or 3)

**Request Example:**
```bash
curl -X POST "http://localhost:8000/patient/enroll" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "stratum": 2
  }'
```

**Response:**
```json
{
  "success": true,
  "patient_id": 1,
  "stratum": 2,
  "treatment": 1,
  "treatment_label": "Treatment A",
  "allocation_method": "Burn-in (Balanced)",
  "allocation_probability": 0.5,
  "patients_enrolled": 1,
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 5. Record Patient Outcome

**Endpoint:** `POST /patient/outcome`

**Description:** Record the outcome for an enrolled patient

**Parameters:**
- `patient_id` (integer): Patient identifier
- `outcome` (numeric): Outcome value (e.g., blood pressure reduction, survival time)

**Request Example:**
```bash
curl -X POST "http://localhost:8000/patient/outcome" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "outcome": 22.5
  }'
```

**Response:**
```json
{
  "success": true,
  "patient_id": 1,
  "outcome": 22.5,
  "message": "Outcome recorded successfully",
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 6. List All Patients

**Endpoint:** `GET /patients/list`

**Description:** Retrieve all enrolled patients and their data

**Response:**
```json
{
  "patients": [
    {
      "patient_id": 1,
      "stratum": 2,
      "treatment": 1,
      "outcome": 22.5,
      "enrollment_time": "2025-11-11 09:00:00",
      "treatment_label": "Treatment A"
    }
  ],
  "total": 1
}
```

---

### 7. Get Treatment Effect

**Endpoint:** `GET /analysis/treatment-effect`

**Description:** Calculate the current treatment effect estimate with confidence intervals

**Response:**
```json
{
  "success": true,
  "overall_treatment_effect": 3.2,
  "standard_error": 1.1,
  "ci_95_lower": 1.04,
  "ci_95_upper": 5.36,
  "mean_treated": 24.5,
  "mean_control": 21.3,
  "n_treated": 13,
  "n_control": 12,
  "stratified_results": {
    "stratum_1": {
      "treatment_effect": 2.8,
      "n_treated": 4,
      "n_control": 4,
      "mean_treated": 23.2,
      "mean_control": 20.4
    },
    "stratum_2": {
      "treatment_effect": 3.5,
      "n_treated": 5,
      "n_control": 5,
      "mean_treated": 25.1,
      "mean_control": 21.6
    }
  },
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 8. Get Allocation Statistics

**Endpoint:** `GET /analysis/allocation-stats`

**Description:** Get statistics on treatment allocation by stratum

**Response:**
```json
{
  "success": true,
  "overall": {
    "total_patients": 25,
    "treatment_a": 13,
    "control_b": 12,
    "proportion_treatment": 0.52,
    "proportion_control": 0.48
  },
  "by_stratum": {
    "stratum_1": {
      "total": 8,
      "treatment_a": 4,
      "control_b": 4,
      "proportion_treatment": 0.5,
      "proportion_control": 0.5
    },
    "stratum_2": {
      "total": 10,
      "treatment_a": 5,
      "control_b": 5,
      "proportion_treatment": 0.5,
      "proportion_control": 0.5
    }
  },
  "timestamp": "2025-11-11T09:00:00Z"
}
```

---

### 9. Export Trial Data

**Endpoint:** `GET /data/export`

**Description:** Export complete trial data for analysis

**Response:**
```json
{
  "config": {
    "study_name": "Hypertension-CARA-2025",
    "n0": 10,
    "gamma": 2,
    "target": "Neyman"
  },
  "patients": [
    {
      "patient_id": 1,
      "stratum": 2,
      "treatment": 1,
      "outcome": 22.5,
      "enrollment_time": "2025-11-11 09:00:00"
    }
  ],
  "export_time": "2025-11-11T09:00:00Z"
}
```

---

## Example Study Scenario

### Study Design: Hypertension Treatment Trial

**Objective:** Compare a new antihypertensive drug (Treatment A) vs. standard care (Control B)

**Primary Endpoint:** Reduction in systolic blood pressure (mmHg) at 12 weeks

**Covariate Strata:**
- **Stratum 1:** Mild hypertension (SBP 140-159 mmHg)
- **Stratum 2:** Moderate hypertension (SBP 160-179 mmHg)
- **Stratum 3:** Severe hypertension (SBP ≥180 mmHg)

**Sample Size:** 120 patients (40 per stratum planned)

**Randomization:**
- Method: CARA (Covariate-Adjusted Response-Adaptive)
- Burn-in: First 20 patients (10 per arm) balanced randomization
- Target: Neyman allocation (minimizes variance of treatment effect estimate)
- Gamma: 2 (moderate adaptation speed)

---

## Operational Workflow

### Phase 1: Trial Setup

1. **Initialize API Server**
   ```r
   library(plumber)
   pr <- plumb("plumber_api.R")
   pr$run(port = 8000)
   ```

2. **Initialize Trial**
   ```bash
   curl -X POST "http://localhost:8000/trial/initialize" \
     -d '{"study_name": "HTN-CARA-2025", "n0": 10, "target": "Neyman"}'
   ```

### Phase 2: Patient Enrollment (Burn-in Period)

**Patients 1-20:** Balanced randomization

```bash
# Patient 1
curl -X POST "http://localhost:8000/patient/enroll" \
  -d '{"patient_id": 1, "stratum": 2}'
# Response: treatment = 1 (Treatment A)

# Patient 2
curl -X POST "http://localhost:8000/patient/enroll" \
  -d '{"patient_id": 2, "stratum": 1}'
# Response: treatment = 0 (Control B)
```

### Phase 3: Outcome Recording

```bash
# Record outcome for Patient 1
curl -X POST "http://localhost:8000/patient/outcome" \
  -d '{"patient_id": 1, "outcome": 18.5}'
```

### Phase 4: Adaptive Randomization

**Patients 21+:** CARA adaptive allocation based on accumulated outcomes

```bash
# Patient 21
curl -X POST "http://localhost:8000/patient/enroll" \
  -d '{"patient_id": 21, "stratum": 2}'
# Response: treatment assigned based on stratum-specific data
# allocation_method: "CARA (Neyman)"
# allocation_probability: 0.58 (favors higher variance group)
```

### Phase 5: Interim Analysis

```bash
# Get treatment effect
curl -X GET "http://localhost:8000/analysis/treatment-effect"

# Get allocation statistics
curl -X GET "http://localhost:8000/analysis/allocation-stats"
```

### Phase 6: Data Export

```bash
# Export all data
curl -X GET "http://localhost:8000/data/export" > trial_data.json
```

---

## Step-by-Step Operations Table

| STEP | Action | Input Data | Expected Output / Result | Operational Notes |
|------|--------|------------|--------------------------|-------------------|
| **1** | **Initialize API Server** | - plumber_api.R file<br>- Port number (8000) | API server running at http://localhost:8000<br>Swagger UI available at /__docs__/ | Requires all dependencies installed (Rcpp, RcppArmadillo, plumber). Source files base_randomization.cpp and simulation.R must be in same directory. |
| **2** | **Initialize Trial** | POST /trial/initialize<br>- study_name: "HTN-CARA-2025"<br>- n0: 10<br>- gamma: 2<br>- target: "Neyman"<br>- TB: 1<br>- randomization_method: "CARA" | Success response with config<br>Trial data reset<br>Patient count: 0 | Sets trial parameters. Can be called multiple times to reset trial. Burn-in size (n0) determines when adaptive allocation begins (after 2×n0 patients). |
| **3** | **Check Trial Status** | GET /trial/status | Current configuration<br>Enrollment statistics<br>Allocation counts<br>Strata distribution | Use before starting enrollment to verify configuration. Check periodically during trial. |
| **4** | **Enroll Patient 1** | POST /patient/enroll<br>- patient_id: 1<br>- stratum: 2 | treatment: 1 (Treatment A)<br>allocation_method: "Burn-in (Balanced)"<br>allocation_probability: 0.5 | During burn-in (patients 1-20), allocation is balanced 1:1 regardless of outcomes. System ensures 10 per arm. |
| **5** | **Enroll Patient 2** | POST /patient/enroll<br>- patient_id: 2<br>- stratum: 1 | treatment: 0 (Control B)<br>allocation_method: "Burn-in (Balanced)"<br>allocation_probability: 0.5 | Continues burn-in period. Each patient_id must be unique. |
| **6-19** | **Enroll Patients 3-20** | POST /patient/enroll<br>(Various patient_id and stratum) | Balanced allocation<br>10 to Treatment A<br>10 to Control B | Complete burn-in period. May not be exactly balanced mid-way but will reach 10:10 by patient 20. |
| **20** | **Record Outcome - Patient 1** | POST /patient/outcome<br>- patient_id: 1<br>- outcome: 18.5 | Success: true<br>Outcome stored in database | Outcomes can be recorded any time after enrollment. Early outcomes enable earlier adaptive allocation. Outcome = BP reduction in mmHg. |
| **21** | **Record Outcomes - Patients 2-20** | POST /patient/outcome<br>(For each patient) | Outcomes stored<br>Ready for adaptive allocation | Need outcomes from burn-in patients before adaptive allocation can begin. Missing outcomes will delay adaptation. |
| **22** | **Enroll Patient 21** | POST /patient/enroll<br>- patient_id: 21<br>- stratum: 2 | treatment: 1 or 0<br>allocation_method: "CARA (Neyman)"<br>allocation_probability: 0.58 | **First adaptive allocation**. System analyzes stratum 2 data:<br>- Calculates mean/SD for each treatment<br>- Computes Neyman optimal allocation<br>- Uses biased coin with current imbalance<br>Probability ≠ 0.5 indicates adaptation. |
| **23** | **Check Allocation Stats** | GET /analysis/allocation-stats | Overall allocation ratio<br>Stratum-specific ratios | Monitor allocation balance. Neyman tends toward 50:50 if variances equal. Will diverge if one treatment has higher variance. |
| **24** | **Record Outcome - Patient 21** | POST /patient/outcome<br>- patient_id: 21<br>- outcome: 22.3 | Success: true<br>Updated patient record | Each new outcome updates the database and will influence future allocations. |
| **25** | **Enroll Patient 22** | POST /patient/enroll<br>- patient_id: 22<br>- stratum: 2 | treatment: assigned adaptively<br>Updated allocation_probability | Uses Patient 21's outcome in calculation. Adaptation becomes more stable as sample size increases. |
| **26-50** | **Continue Enrollment & Outcomes** | Alternate between:<br>POST /patient/enroll<br>POST /patient/outcome | Adaptive assignments<br>Growing outcome database | Typical pattern: Enroll patient → Record outcome within days/weeks → Enroll next patient. Outcomes don't need to be immediate. |
| **27** | **Interim Analysis - Treatment Effect** | GET /analysis/treatment-effect | Treatment effect estimate: 3.2<br>95% CI: [1.04, 5.36]<br>Stratified estimates | Can be called anytime with ≥2 patients per arm with outcomes. Shows overall and stratum-specific effects. SE decreases as N increases. |
| **28** | **Check if Stopping Rule Met** | External analysis of treatment effect | Decision: Continue or Stop | API doesn't implement stopping rules. Investigators use treatment effect endpoint to decide. Could stop early for efficacy or futility. |
| **29** | **Enroll Patients 51-120** | Continue enrollment process | Final allocation ratios<br>Complete outcome data | Complete planned enrollment. Final allocation may be 55:65 or 58:62 rather than exactly 60:60, depending on variance patterns. |
| **30** | **Record Final Outcomes** | POST /patient/outcome<br>(All remaining patients) | Complete dataset<br>All patients have outcomes | Ensure all enrolled patients have recorded outcomes before final analysis. |
| **31** | **Final Analysis** | GET /analysis/treatment-effect | Final treatment effect<br>Final CI<br>Statistical significance | Primary efficacy analysis. Compare CI to null hypothesis (effect = 0). |
| **32** | **Export Trial Data** | GET /data/export | JSON file with:<br>- Configuration<br>- All patient data<br>- Timestamps | Save for regulatory submission, publications, secondary analyses. Includes complete audit trail. |
| **33** | **Validate Data Export** | Review exported JSON | Verify:<br>- All 120 patients present<br>- All outcomes recorded<br>- No missing data | Quality check before database lock. |
| **34** | **Secondary Analyses** | Use exported data in R | Stratum-specific effects<br>Allocation efficiency<br>Variance ratios | Analyze whether CARA achieved efficiency gains vs. balanced allocation. Compare actual variance to theoretical bound. |
| **35** | **Generate Final Report** | Compile analyses | Clinical study report<br>Publications<br>Regulatory submissions | Include allocation methodology, interim analyses performed, final results. |

---

## Integration Examples

### Example 1: Python Client

```python
import requests
import json

BASE_URL = "http://localhost:8000"

# Initialize trial
response = requests.post(
    f"{BASE_URL}/trial/initialize",
    json={
        "study_name": "HTN-CARA-2025",
        "n0": 10,
        "target": "Neyman"
    }
)
print(response.json())

# Enroll patient
response = requests.post(
    f"{BASE_URL}/patient/enroll",
    json={
        "patient_id": 1,
        "stratum": 2
    }
)
assignment = response.json()
print(f"Patient 1 assigned to: {assignment['treatment_label']}")

# Record outcome
response = requests.post(
    f"{BASE_URL}/patient/outcome",
    json={
        "patient_id": 1,
        "outcome": 18.5
    }
)
print(response.json())

# Get treatment effect
response = requests.get(f"{BASE_URL}/analysis/treatment-effect")
print(response.json())
```

### Example 2: R Client

```r
library(httr)
library(jsonlite)

base_url <- "http://localhost:8000"

# Initialize trial
response <- POST(
  paste0(base_url, "/trial/initialize"),
  body = list(
    study_name = "HTN-CARA-2025",
    n0 = 10,
    target = "Neyman"
  ),
  encode = "json"
)
content(response)

# Enroll patient
response <- POST(
  paste0(base_url, "/patient/enroll"),
  body = list(patient_id = 1, stratum = 2),
  encode = "json"
)
assignment <- content(response)
print(paste("Treatment:", assignment$treatment_label))

# Record outcome
response <- POST(
  paste0(base_url, "/patient/outcome"),
  body = list(patient_id = 1, outcome = 18.5),
  encode = "json"
)

# Get treatment effect
response <- GET(paste0(base_url, "/analysis/treatment-effect"))
content(response)
```

### Example 3: JavaScript/Node.js Client

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:8000';

async function runTrial() {
  // Initialize trial
  let response = await axios.post(`${BASE_URL}/trial/initialize`, {
    study_name: 'HTN-CARA-2025',
    n0: 10,
    target: 'Neyman'
  });
  console.log(response.data);
  
  // Enroll patient
  response = await axios.post(`${BASE_URL}/patient/enroll`, {
    patient_id: 1,
    stratum: 2
  });
  console.log(`Assigned to: ${response.data.treatment_label}`);
  
  // Record outcome
  response = await axios.post(`${BASE_URL}/patient/outcome`, {
    patient_id: 1,
    outcome: 18.5
  });
  
  // Get treatment effect
  response = await axios.get(`${BASE_URL}/analysis/treatment-effect`);
  console.log(response.data);
}

runTrial();
```

---

## Error Handling

### Common Error Responses

**Invalid Patient ID:**
```json
{
  "success": false,
  "error": "Invalid patient_id. Must be a positive integer."
}
```

**Duplicate Enrollment:**
```json
{
  "success": false,
  "error": "Patient 1 already enrolled"
}
```

**Invalid Stratum:**
```json
{
  "success": false,
  "error": "Invalid stratum. Must be 1, 2, or 3."
}
```

**Patient Not Found:**
```json
{
  "success": false,
  "error": "Patient 5 not found"
}
```

**Insufficient Data:**
```json
{
  "success": false,
  "error": "Insufficient data for analysis (need at least 2 patients with outcomes)"
}
```

### Best Practices

1. **Always check trial status** before enrolling first patient
2. **Record outcomes promptly** to enable adaptive allocation
3. **Monitor allocation statistics** regularly to ensure proper adaptation
4. **Export data frequently** as backup
5. **Validate patient_id uniqueness** before enrollment
6. **Check stratum validity** (1, 2, or 3)
7. **Handle network errors** with retries in your client
8. **Log all API calls** for audit trail

---

## Advanced Configuration

### Allocation Strategies

**Neyman:** Minimizes variance of treatment effect estimate
```json
{"target": "Neyman"}
```

**RSIHR:** Minimizes expected treatment failures
```json
{"target": "RSIHR"}
```

**BandBis:** Uses normal CDF for allocation
```json
{"target": "BandBis", "TB": 4}
```

**New (Constrained):** Balances efficiency with safety threshold
```json
{"target": "New", "TB": 15}
```

### Tuning Parameters

**Gamma (Adaptation Speed):**
- `gamma = 1`: Slow adaptation
- `gamma = 2`: Moderate adaptation (recommended)
- `gamma = 3`: Fast adaptation

**Burn-in Size:**
- Small trials (N < 100): `n0 = 10`
- Medium trials (N = 100-300): `n0 = 15`
- Large trials (N > 300): `n0 = 20`

---

## Conclusion

This API provides a complete, production-ready implementation of CARA randomization for clinical trials. It handles patient enrollment, adaptive treatment assignment, outcome recording, and real-time analysis, all through a simple REST interface that can be integrated with any Electronic Data Capture (EDC) system or clinical trial management software.

For questions or issues, please refer to the main repository documentation or open an issue on GitHub.
