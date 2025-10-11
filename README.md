# CARA Bound
Codes used to perform a simulation study in 

>
> Xin, J., & Ma, W. (2025). On the achievability of efficiency bounds for covariate-adjusted response-adaptive randomization. *Statistical Methods in Medical Research*, 09622802251327689.

The repository includes the R and C++ code used to produce the presented results in the manuscript and supplementary material. 

## File folder description

`base_randomization.cpp` contains C++ code to perform randomization methods. `simulatoin.R` contains R code to generate simulation models and results.

Replication code is contained in `codes.Rmd` and the output file is `codes.pdf`. 


## Dependency

* R packages: 

paralle, Rcpp, RcppAmardillo, ggplot2, tidyr, dplyr, patchwork, latex2exp
