#!/usr/bin/env Rscript

# CARA Randomization API Server Launcher
# This script starts the Plumber API server for CARA randomization

cat("========================================\n")
cat("CARA Randomization API Server\n")
cat("========================================\n\n")

# Check if required packages are installed
required_packages <- c("plumber", "Rcpp", "RcppArmadillo", "jsonlite")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) > 0) {
  cat("ERROR: Missing required packages:\n")
  cat(paste("-", missing_packages, collapse = "\n"), "\n\n")
  cat("Please install them using:\n")
  cat("install.packages(c(", paste0('"', missing_packages, '"', collapse = ", "), "))\n\n")
  quit(status = 1)
}

# Load required libraries
suppressPackageStartupMessages({
  library(plumber)
  library(Rcpp)
  library(RcppArmadillo)
})

cat("Loading C++ randomization code...\n")
tryCatch({
  sourceCpp("base_randomization.cpp")
  cat("✓ C++ code loaded successfully\n")
}, error = function(e) {
  cat("✗ Error loading base_randomization.cpp:\n")
  cat(e$message, "\n")
  quit(status = 1)
})

cat("Loading R simulation functions...\n")
tryCatch({
  source("simulation.R")
  cat("✓ R functions loaded successfully\n")
}, error = function(e) {
  cat("✗ Error loading simulation.R:\n")
  cat(e$message, "\n")
  quit(status = 1)
})

cat("\nStarting API server...\n")

# Create plumber instance
pr <- plumb("plumber_api.R")

# Configure port (default 8000, can be overridden by environment variable)
port <- as.integer(Sys.getenv("PORT", "8000"))
host <- Sys.getenv("HOST", "0.0.0.0")

cat("\n========================================\n")
cat("Server Configuration:\n")
cat(paste("- Host:", host, "\n"))
cat(paste("- Port:", port, "\n"))
cat("========================================\n\n")

cat("API Endpoints:\n")
cat(paste0("- Health Check:      http://localhost:", port, "/health\n"))
cat(paste0("- API Documentation: http://localhost:", port, "/__docs__/\n"))
cat(paste0("- Swagger UI:        http://localhost:", port, "/__swagger__/\n\n"))

cat("Press Ctrl+C to stop the server\n\n")

# Run the API
pr$run(port = port, host = host)
