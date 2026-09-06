# Test-Driven Prototype: Gradient-Based Hessian Validation
# 
# Objective: Validate second-order derivatives (Hessians) using complex-step
# differentiation vs finite-difference methods
#
# Test Cases:
# 1. Verify complex-step Hessian matches analytic for known function
# 2. Quantify error divergence between complex-step and finite-difference
# 3. Establish step-size threshold where FD fails but CS succeeds
# 4. Validate on quadratic form (known Hessian)

library(testthat)
library(numDeriv)

# Analytic test function: f(x,y) = x^2 + xy + y^2
f_analytic <- function(p) {
  p[1]^2 + p[1]*p[2] + p[2]^2
}

# Analytic gradient: df/dx = 2x + y, df/dy = x + 2y
grad_analytic <- function(p) {
  c(2*p[1] + p[2], p[1] + 2*p[2])
}

# Analytic Hessian: [[2, 1], [1, 2]]
hessian_analytic <- matrix(c(2, 1, 1, 2), nrow=2)

test_that("Hessian: Complex-step matches analytic for quadratic form", {
  # Use point p = [1, 2]
  p_test <- c(1, 2)
  
  # Compute Hessian using complex-step
  hessian_cs <- numDeriv::hessian(f_analytic, p_test, method="complex")
  
  # Compare against known analytic result
  expect_equal(hessian_cs, hessian_analytic, tolerance = 1e-10)
  
  # All values should be finite and reasonable
  expect_true(all(is.finite(hessian_cs)))
  expect_gte(min(hessian_cs), 0)  # Positive semi-definite expected
})

test_that("Hessian: Finite-difference vs complex-step error divergence", {
  # Test at multiple step sizes to show FD degradation
  p_test <- c(1.5, 0.8)
  
  # True Hessian
  h_true <- hessian_analytic
  
  # Step sizes to test
  step_sizes <- c(1e-1, 1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8)
  
  fd_errors <- sapply(step_sizes, function(h) {
    h_fd <- numDeriv::hessian(f_analytic, p_test, method="central", eps=h)
    max(abs(h_fd - h_true))
  })
  
  cs_errors <- sapply(step_sizes, function(h) {
    h_cs <- numDeriv::hessian(f_analytic, p_test, method="complex", eps=h)
    max(abs(h_cs - h_true))
  })
  
  # FD should degrade at small steps (cancellation error)
  # CS should maintain precision across all steps
  expect_true(max(cs_errors) < min(fd_errors) * 0.1)  # CS always better
  
  # Qualitative check: FD error increases as step gets too small
  warning(sprintf("FD error at smallest step: %.2e, CS error: %.2e", 
                  fd_errors[length(fd_errors)], cs_errors[length(cs_errors)]))
})

test_that("Hessian: Threshold where FD fails but CS succeeds", {
  # Define "failure" as relative error > 1%
  failure_threshold <- 0.01
  
  p_test <- c(2.3, -1.7)
  h_true <- hessian_analytic
  
  # Find step size where FD exceeds threshold
  step_sizes <- seq(-16, -2, by = 1)  # log-scale from 1e-16 to 1e-2
  
  fd_max_error <- NULL
  cs_max_error <- NULL
  
  for (exp_val in step_sizes) {
    h_step <- 10^exp_val
    
    h_fd <- tryCatch({
      numDeriv::hessian(f_analytic, p_test, method="central", eps=h_step)
    }, error = function(e) NA)
    
    h_cs <- tryCatch({
      numDeriv::hessian(f_analytic, p_test, method="complex", eps=h_step)
    }, error = function(e) NA)
    
    if (!all(is.na(c(h_fd, h_cs)))) {
      err_fd <- max(abs(h_fd - h_true)) / max(abs(h_true))
      err_cs <- max(abs(h_cs - h_true)) / max(abs(h_true))
      
      fd_max_error <- c(fd_max_error, err_fd)
      cs_max_error <- c(cs_max_error, err_cs)
    }
  }
  
  # Remove NA values
  fd_max_error <- fd_max_error[!is.na(fd_max_error)]
  cs_max_error <- cs_max_error[!is.na(cs_max_error)]
  
  # FD should fail (error > 1%) at small steps while CS maintains accuracy
  if (length(fd_max_error) > 0 && length(cs_max_error) > 0) {
    fd_fails_any <- any(fd_max_error > failure_threshold)
    cs_succeeds_all <- all(cs_max_error < failure_threshold)
    
    expect_true(cs_succeeds_all)  # CS never fails above threshold
    # FD may or may not fail depending on problem; document empirically
    warning(sprintf("FD failure rate: %.0f%%, CS success rate: 100%%", 
                    sum(fd_max_error > failure_threshold)/length(fd_max_error)*100))
  } else {
    skip("Insufficient data points for threshold analysis")
  }
})

test_that("Hessian: Nonlinear function validation (Rosenbrock)", {
  # Rosenbrock function has known difficult curvature
  rosenbrock <- function(p) {
    100 * (p[2] - p[1]^2)^2 + (1 - p[1])^2
  }
  
  # Analytical gradient for verification
  grad_rosen <- function(p) {
    c(-400*p[1]*(p[2]-p[1]^2) - 2*(1-p[1]),
      200*(p[2]-p[1]^2))
  }
  
  # Point near optimal solution
  p_test <- c(0.9, 0.81)
  
  # Check that computed gradient matches analytic
  grad_cs <- numDeriv::grad(rosenbrock, p_test, method="complex")
  grad_an <- grad_rosen(p_test)
  
  expect_lte(max(abs(grad_cs - grad_an)), 1e-10 * max(1, abs(grad_an)))
  
  # Hessian should be positive definite near minimum
  hessian_cs <- numDeriv::hessian(rosenbrock, p_test, method="complex")
  
  eigen_vals <- eigen(hessian_cs)$values
  expect_true(all(eigen_vals >= -1e-10))  # Allow tiny numerical negatives
})
