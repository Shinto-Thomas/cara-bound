# CARA Bound
Codes used to perform a simulation study in 

>
> Xin, J., & Ma, W. (2025). On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization. *Statistical Methods in Medical Research*, 09622802251327689.

The repository includes the R and C++ code used to produce the presented results in the manuscript and supplementary material.

## 🚀 Standalone Plumber API (NEW!)

**A pure R implementation of the CARA API is now available!**

The standalone API provides all CARA functionality **without C++ dependencies**, making it easy to deploy in any environment. Perfect for:
- Production clinical trials
- Cloud deployment (AWS, Azure, Google Cloud)
- Docker containers
- Environments without C++ compilers

**Quick Start:**
```r
# Install only 2 R packages - no C++ needed!
install.packages(c("plumber", "jsonlite"))

# Start the API server
Rscript start_api_standalone.R
```

**See [README_STANDALONE.md](README_STANDALONE.md) for complete documentation.**

## 📖 Complete Documentation

**For a comprehensive explanation of the complete working module, see [MODULE_DOCUMENTATION.md](MODULE_DOCUMENTATION.md)**

The documentation includes:
- Detailed explanation of all algorithms and functions
- Mathematical foundations of CARA randomization
- Usage examples and workflow diagrams
- Output interpretation guide
- Troubleshooting tips 

## File folder description

### Core Research Files
- `base_randomization.cpp` - C++ code for high-performance randomization methods
- `simulation.R` - R code to generate simulation models and results
- `codes.Rmd` - Replication code for manuscript results
- `codes.pdf` - Output file with all results

### Standalone API Files (Pure R)
- `randomization_r.R` - Pure R implementations of all algorithms (no C++)
- `plumber_api_standalone.R` - Standalone REST API endpoints
- `start_api_standalone.R` - Server startup script
- `example_client_standalone.R` - Complete usage example
- `README_STANDALONE.md` - Standalone API documentation

### Original API Files (R + C++)
- `plumber_api.R` - Original REST API (requires C++)
- `start_api.R` - Original server startup script
- `example_client.R` - Original usage example

## Dependencies

### For Standalone API (Recommended for Production)
* R packages: **plumber, jsonlite**

### For Research/Simulations (Original)
* R packages: parallel, Rcpp, RcppArmadillo, ggplot2, tidyr, dplyr, patchwork, latex2exp

For detailed installation and usage instructions, see [MODULE_DOCUMENTATION.md](MODULE_DOCUMENTATION.md).
