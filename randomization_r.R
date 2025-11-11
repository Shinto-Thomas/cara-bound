# Pure R Implementation of CARA Randomization Functions
# This file provides R-only implementations of all randomization algorithms
# previously implemented in C++ (base_randomization.cpp)

# Target allocation probability calculation
# Implements various allocation strategies for adaptive randomization
target_alloc <- function(muA, sigmaA, muB, sigmaB, target = "Neyman", TB = 4) {
  # Handle edge cases for standard deviations
  if (sigmaA < 1e-5) sigmaA <- 0.1
  if (sigmaB < 1e-5) sigmaB <- 0.1
  
  rho <- 0.5  # Default
  
  if (target == "Neyman") {
    # Neyman allocation: minimizes variance of treatment effect estimate
    rho <- sigmaA / (sigmaA + sigmaB)
    
  } else if (target == "RSIHR") {
    # RSIHR allocation: minimizes expected treatment failures
    if (muB <= 0) muB <- 1e-5
    if (muA <= 0) muA <- 1e-5
    rho <- sigmaA * sqrt(muB) / (sigmaA * sqrt(muB) + sigmaB * sqrt(muA))
    
  } else if (target == "BandBis") {
    # Biased Coin Design based on normal CDF
    rho <- pnorm((muA - muB) / TB)
    
  } else if (target == "ZhangRosenberger") {
    # Zhang-Rosenberger allocation
    Rstar <- sigmaA * sqrt(muB) / (sigmaB * sqrt(muA))
    s <- if ((muA < muB && Rstar > 1) || (muA > muB && Rstar < 1)) 1 else 0
    
    if (s == 1) {
      rho <- sigmaA * sqrt(muB) / (sigmaA * sqrt(muB) + sigmaB * sqrt(muA))
    } else {
      rho <- 0.5
    }
    
  } else if (target == "New") {
    # Constrained allocation: Neyman with threshold constraint
    rho_Neyman <- sigmaA / (sigmaA + sigmaB)
    rho_TB <- (TB - muB) / (muA - muB)
    
    if (rho_Neyman * muA + (1 - rho_Neyman) * muB <= TB) {
      rho <- rho_Neyman
    } else if (rho_TB > 0) {
      rho <- rho_TB
    } else {
      rho <- rho_Neyman
    }
  }
  
  # Threshold: constrain to [0.1, 0.9]
  if (rho > 0.9) rho <- 0.9
  if (rho < 0.1) rho <- 0.1
  
  return(rho)
}

# Doubly-adaptive biased coin assignment function
# Calculates probability of assigning to treatment A based on current proportion
# and target allocation
assigFun_g <- function(x, y, gamma = 2) {
  # Handle edge cases
  if (x < 0.000001 && x > -0.000001) {
    return(1)
  }
  if (x < 1.000001 && x > 0.999999) {
    return(0)
  }
  
  # Calculate biased coin probability
  t1 <- y * (y / x)^gamma
  t2 <- (1 - y) * ((1 - y) / (1 - x))^gamma
  p <- t1 / (t1 + t2)
  
  return(p)
}

# Initial balanced randomization for burn-in period
# Returns a vector of 2*n0 assignments with exactly n0 in each group
n0Rand <- function(n0) {
  Tvec <- rep(c(0, 1), each = n0)
  Tvec <- sample(Tvec)  # Randomly permute
  return(Tvec)
}

# Doubly-Adaptive Biased Coin Design (DBCD) / Response-Adaptive Randomization (RAR)
# Implements adaptive allocation based on observed outcomes
DBCD <- function(Ymat, gamma = 2, n0 = 10, target = "Neyman", TB = 4) {
  n <- nrow(Ymat)
  Tvec <- rep(NA, n)
  
  # Burn-in period: balanced randomization
  Tvec[1:(2 * n0)] <- n0Rand(n0)
  
  rhohat <- 0.5
  
  # Adaptive allocation
  for (i in (2 * n0 + 1):n) {
    Tvec_t <- Tvec[1:(i - 1)]
    
    # Current proportion assigned to treatment
    x <- mean(Tvec_t)
    
    # Get outcomes for each treatment group
    ind1 <- which(Tvec_t > 0.99)
    ind0 <- which(Tvec_t < 0.01)
    
    Y1 <- Ymat[1:(i - 1), 2]
    Y0 <- Ymat[1:(i - 1), 1]
    
    if (target == "Bayesian") {
      # Update every 10 patients for Bayesian
      if ((i - 2 * n0) %% 10 == 0) {
        sum1 <- sum(Y1[ind1])
        sum0 <- sum(Y0[ind0])
        rhohat <- target_alloc_bayesian(length(ind1), length(ind0), sum1, sum0, n)
      }
    } else {
      # Calculate target allocation based on observed data
      Y1bar <- mean(Y1[ind1])
      Y0bar <- mean(Y0[ind0])
      
      sigma1 <- sd(Y1[ind1])
      sigma0 <- sd(Y0[ind0])
      
      rhohat <- target_alloc(Y1bar, sigma1, Y0bar, sigma0, target, TB)
    }
    
    # Calculate assignment probability
    g <- assigFun_g(x, rhohat, gamma)
    
    # Assign treatment
    Tvec[i] <- as.integer(runif(1) < g)
  }
  
  return(Tvec)
}

# Covariate-Adjusted Response-Adaptive Randomization (CARA)
# Performs DBCD independently within each stratum
CARA <- function(model_output, gamma = 2, n0 = 10, target = "Neyman", TB = 1) {
  Ymat <- model_output$Ymat
  strata <- model_output$strata
  
  n <- nrow(Ymat)
  An <- rep(NA, n)
  
  strata_set <- unique(strata)
  
  # Apply DBCD within each stratum
  for (s in strata_set) {
    strata_ind <- which(strata == s)
    Ymat_strata <- Ymat[strata_ind, , drop = FALSE]
    
    An[strata_ind] <- DBCD(Ymat_strata, gamma, n0, target, TB)
  }
  
  return(An)
}

# Covariate-Adjusted DBCD (CADBCD)
# Global adaptation with covariate adjustment
CADBCD <- function(model_output, gamma = 2, n0 = 30, target = "Neyman", TB = 30) {
  Ymat <- model_output$Ymat
  strata <- model_output$strata
  
  n <- nrow(Ymat)
  An <- rep(0, n)
  max_strata <- max(strata)
  pi <- rep(0, max_strata)
  
  # Initialize with balanced randomization
  An[1:(2 * n0)] <- n0Rand(n0)
  
  # Main loop
  for (i in (2 * n0 + 1):n) {
    rho <- 0.0
    
    if (target == "Bayesian") {
      if ((i - 2 * n0) %% 10 != 0) next
    }
    
    # Calculate stratum-specific target allocations
    for (s in 1:max_strata) {
      pre_seq <- 1:(i - 1)
      ind <- which(strata[pre_seq] == s)
      ind1 <- which(An[pre_seq] == 1 & strata[pre_seq] == s)
      ind0 <- which(An[pre_seq] == 0 & strata[pre_seq] == s)
      
      Y1 <- Ymat[, 2]
      Y0 <- Ymat[, 1]
      
      if (target == "Bayesian") {
        sum1 <- sum(Y1[ind1])
        sum0 <- sum(Y0[ind0])
        pi[s] <- target_alloc_bayesian(length(ind1), length(ind0), sum1, sum0, n)
      } else {
        if (length(ind1) == 0 || length(ind0) == 0) {
          # Skip if no data in one group
          next
        } else {
          Y1bar <- mean(Y1[ind1])
          Y0bar <- mean(Y0[ind0])
          
          sigma1 <- sd(Y1[ind1])
          sigma0 <- sd(Y0[ind0])
          
          pi[s] <- target_alloc(Y1bar, sigma1, Y0bar, sigma0, target, TB)
        }
      }
      
      # Weighted average target allocation
      rho <- rho + length(ind) * 1.0 / (i - 1) * pi[s]
    }
    
    N1 <- sum(An[1:(i - 1)])
    j <- strata[i]  # Current patient's stratum
    
    # Calculate assignment probability
    if (N1 == 0) {
      prob <- 0.5
    } else {
      x <- N1 / (i - 1)
      prob <- pi[j] * (rho / x)^gamma / 
              (pi[j] * (rho / x)^gamma + 
               (1 - pi[j]) * ((1 - rho) / (1 - x))^gamma)
    }
    
    # Constrain probability to [0.1, 0.9]
    prob <- min(max(prob, 0.1), 0.9)
    
    # Assign treatment
    An[i] <- as.integer(runif(1) < prob)
  }
  
  return(An)
}

# Complete Randomization with fixed probability
CRand <- function(Ymat, delta = 0.5) {
  n <- nrow(Ymat)
  Tvec <- rep(NA, n)
  
  for (i in 1:n) {
    Tvec[i] <- as.integer(runif(1) < delta)
  }
  
  return(Tvec)
}

# Bayesian target allocation (if needed)
# This function uses Bayesian posterior distributions for allocation
target_alloc_bayesian <- function(n1, n0, sum1, sum0, N, alpha = 1, beta = 1, B = 0.1) {
  mu0 <- 1 / rgamma(10000, shape = n0 + alpha, rate = sum0 + beta)
  mu1 <- 1 / rgamma(10000, shape = n1 + alpha, rate = sum1 + beta)
  c <- (n0 + n1) / (2 * N * 0.8)
  p1 <- mean(mu1 < mu0)
  ps1 <- p1^c / (p1^c + (1 - p1)^c)
  pp1 <- min(max(ps1, B), 1 - B)
  return(pp1)
}
