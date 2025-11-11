# CARA Bound
Codes used to perform a simulation study in 

>
> Xin, J., & Ma, W. (2025). On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization. *Statistical Methods in Medical Research*, 09622802251327689.

The repository includes the R and C++ code used to produce the presented results in the manuscript and supplementary material.

## 📖 Complete Documentation

**For a comprehensive explanation of the complete working module, see [MODULE_DOCUMENTATION.md](MODULE_DOCUMENTATION.md)**

The documentation includes:
- Detailed explanation of all algorithms and functions
- Mathematical foundations of CARA randomization
- Usage examples and workflow diagrams
- Output interpretation guide
- Troubleshooting tips 

## File folder description

`base_randomization.cpp` contains C++ code to perform randomization methods. `simulatoin.R` contains R code to generate simulation models and results.

Replication code is contained in `codes.Rmd` and the output file is `codes.pdf`. 


## Dependencies

* R packages: 

parallel, Rcpp, RcppArmadillo, ggplot2, tidyr, dplyr, patchwork, latex2exp

For detailed installation and usage instructions, see [MODULE_DOCUMENTATION.md](MODULE_DOCUMENTATION.md).
