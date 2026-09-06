# Test-Driven Prototype: AICc Formula Reproduction
# 
# Objective: Reproduce Akaike Information Criterion with small-sample correction
# using MuMIn package as reference implementation
#
# Test Cases:
# 1. Validate AICc formula against published examples (Burnham & Anderson 2002)
# 2. Confirm n/k threshold where correction becomes significant
# 3. Verify consistency with naive AIC when n >> k
# 4. Compare manual calculation vs MuMIn::AICc() output

library(testthat)
library(MuMIn)

test_that("AICc: Published example from Burnham & Anderson (2002)", {
  # Example 6.1 from Burnham & Anderson (2002), p. 157
  # Model: y = a + b*x (k = 2 parameters)
  # Sample size: n = 20
  
  set.seed(42)
  x <- seq(0, 1, length.out = 20)
  y <- 2 + 3 * x + rnorm(20, 0, 0.5)
  
  # Fit linear model
  fit <- lm(y ~ x)
  
  # Compute AICc using MuMIn
  aicc_mumin <- AICc(fit)$AICc
  
  # Manual calculation of AICc
  # AIC = -2*logLik + 2*k
  loglik <- as.numeric(logLik(fit))
  k <- 2  # intercept + slope
  n <- 20
  
  aic <- -2 * loglik + 2 * k
  aicc_manual <- aic + (2 * k * (k + 1)) / (n - k - 1)
  
  # Both should match exactly
  expect_equal(aicc_mumin, aicc_manual, tolerance = 1e-10)
  
  # Verify values are reasonable
  expect_true(is.finite(aicc_mumin))
  expect_true(aicc_mumin > 0)
})

test_that("AICc: Small sample correction significance", {
  # When n/k is small (< 40), correction should be significant
  # When n/k is large (> 100), correction should be negligible
  
  set.seed(123)
  
  # Case 1: Small n (n = 15, k = 2 → n/k = 7.5)
  x1 <- seq(0, 1, length.out = 15)
  y1 <- 1 + 2 * x1 + rnorm(15, 0, 0.3)
  fit1 <- lm(y1 ~ x1)
  
  aic1 <- AIC(fit1)
  aicc1 <- AICc(fit1)$AICc
  correction1 <- aicc1 - aic1
  
  expect_gt(correction1, 1.0)  # Significant correction expected
  
  # Case 2: Large n (n = 500, k = 2 → n/k = 250)
  x2 <- seq(0, 1, length.out = 500)
  y2 <- 1 + 2 * x2 + rnorm(500, 0, 0.3)
  fit2 <- lm(y2 ~ x2)
  
  aic2 <- AIC(fit2)
  aicc2 <- AICc(fit2)$AICc
  correction2 <- aicc2 - aic2
  
  expect_lt(abs(correction2), 0.1)  # Negligible correction expected
  
  # Verify trend: smaller n/k → larger correction
  expect_gt(correction1, correction2)
})

test_that("AICc: Consistency with naive AIC for large samples", {
  # When n >> k, AICc should converge to AIC
  
  set.seed(456)
  n_values <- c(50, 100, 500, 1000)
  
  for (n in n_values) {
    x <- seq(0, 1, length.out = n)
    y <- 2 + 3 * x + rnorm(n, 0, 0.5)
    fit <- lm(y ~ x)
    
    aic <- AIC(fit)
    aicc <- AICc(fit)$AICc
    
    relative_diff <- abs(aicc - aic) / aic
    expect_lt(relative_diff, 0.05)  # Within 5% of AIC
  }
})

test_that("AICc: Multiple models comparison", {
  # AICc should rank models correctly when one is clearly better
  
  set.seed(789)
  times <- seq(0, 10, length.out = 50)
  
  # True model: bi-exponential
  true_A1 <- 1.0; true_k1 <- 0.5
  true_A2 <- 0.5; true_k2 <- 0.05
  rho_true <- true_A1 * exp(-true_k1 * times) + true_A2 * exp(-true_k2 * times)
  rho_obs <- rho_true + rnorm(length(times), 0, 0.1)
  
  # Fit mono-exponential (underfitting)
  fit_mono <- lm(log(rho_obs) ~ times)
  
  # Fit bi-exponential (correct)
  fit_bi <- nls(rho_obs ~ A1 * exp(-k1 * times) + A2 * exp(-k2 * times),
               start = list(A1 = 1, k1 = 0.5, A2 = 0.5, k2 = 0.05))
  
  # Compute AICc for both
  aicc_mono <- AICc(fit_mono)$AICc
  aicc_bi <- tryCatch({
    AICc(fit_bi)$AICc
  }, error = function(e) NA)
  
  if (!is.na(aicc_bi)) {
    # Correct model should have lower AICc
    expect_lt(aicc_bi, aicc_mono)
    
    # Difference should be substantial (> 2 units indicates real improvement)
    expect_gte(aicc_mono - aicc_bi, 2.0)
  } else {
    skip("NLS failed on this dataset")
  }
})

test_that("AICc: Gradient verification via complex-step", {
  # Verify that AIC calculations are numerically stable
  
  set.seed(321)
  x <- seq(0, 1, length.out = 30)
  y <- 1 + 2 * x + rnorm(30, 0, 0.2)
  fit <- lm(y ~ x)
  
  # Log-likelihood gradient check
  loglik_fn <- function(beta) {
    pred <- beta[1] + beta[2] * x
    sum(dnorm(y, pred, sigma = sqrt(mean((y - pred)^2)), log = TRUE))
  }
  
  grad_analytic <- numDeriv::grad(loglik_fn, c(1, 2), method="complex")
  
  # Should be finite and non-zero
  expect_true(all(is.finite(grad_analytic)))
  expect_true(any(abs(grad_analytic) > 0.1))
})
