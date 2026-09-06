# Gradient-Based Hessian Validation Implementation Wrapper
#
# This file validates second-order derivatives (Hessians) using complex-step
# differentiation via numDeriv package as reference implementation.
#
# Citations:
# - Griewank, A., & Walther, A. (2008). Evaluating Derivatives: Principles and Techniques of Algorithmic Differentiation (2nd ed.). SIAM.
# - numDeriv package documentation (R Core Team)
# - Implementation Reference: `numDeriv::hessian()` with complex-step method

library(numDeriv)

#' Compute Hessian matrix using complex-step differentiation
#' 
#' @param f function of two or more variables
#' @param p numeric vector: evaluation point
#' @param tol numeric: tolerance for validation checks
#' @return list containing Hessian matrix, validity status, and diagnostics
fit_hessian <- function(f, p, tol = 1e-10) {
  
  stopifnot(is.function(f))
  stopifnot(is.numeric(p) && length(p) >= 2)
  
  # Use numDeriv::hessian with complex-step method
  hessian_result <- tryCatch({
    hessian(f, p, method="complex")
  }, error = function(e) {
    return(NULL)
  })
  
  if (is.null(hessian_result)) {
    return(list(
      success = FALSE,
      message = "Hessian computation failed",
      hessian = NULL,
      valid = FALSE
    ))
  }
  
  # Basic validation checks
  is_symmetric <- all(abs(hessian_result - t(hessian_result)) < tol * max(abs(hessian_result)))
  has_finite_values <- all(is.finite(hessian_result))
  
  list(
    success = TRUE,
    hessian = hessian_result,
    is_symmetric = is_symmetric,
    has_finite_values = has_finite_values,
    condition_number <- tryCatch({
      cond <- kappa(hessian_result)
      list(cond_numeric = cond, warning = abs(log(cond)) > 10)
    }, error = function(e) list(cond_numeric = NA, warning = TRUE))
  )
}

#' Validate Hessian against known analytic example
#' 
#' @param example_id integer: which analytic function to validate (default 1 = quadratic)
#' @return list with validation results
validate_hessian_against_analytic <- function(example_id = 1) {
  
  if (example_id == 1) {
    # Quadratic form: f(x,y) = x^2 + xy + y^2, Hessian = [[2,1],[1,2]]
    f_quadratic <- function(p) {
      p[1]^2 + p[1]*p[2] + p[2]^2
    }
    
    p_test <- c(1, 2)
    h_true <- matrix(c(2, 1, 1, 2), nrow=2)
    
    fit_result <- fit_hessian(f_quadratic, p_test)
    
    if (!fit_result$success || !fit_result$has_finite_values) {
      return(list(error = "Computation failed"))
    }
    
    error_matrix <- abs(fit_result$hessian - h_true)
    max_error <- max(error_matrix)
    
    return(list(
      example = "Quadratic form (analytic Hessian known)",
      true_hessian = h_true,
      computed_hessian = fit_result$hessian,
      max_error = max_error,
      within_tolerance = max_error < 1e-10,
      validation_passed = max_error < 1e-10
    ))
  } else {
    return(list(error = "Example ID not found"))
  }
}

#' Compare complex-step vs finite-difference accuracy
#' 
#' @param f function to differentiate
#' @param p evaluation point
#' @param step_sizes numeric vector: step sizes to test
#' @return dataframe with errors for each method and step size
compare_hessian_methods <- function(f, p, step_sizes = 10^seq(-16, -2, by=2)) {
  
  h_true <- tryCatch({
    # Get analytic Hessian if available (for simple functions)
    # For now, use a proxy: just compare methods against each other
    NULL
  }, error = function(e) NULL)
  
  results <- data.frame(
    step = step_sizes,
    fd_error = numeric(length(step_sizes)),
    cs_error = numeric(length(step_sizes))
  )
  
  for (i in seq_along(step_sizes)) {
    h_fd <- tryCatch({
      hessian(f, p, method="central", eps=step_sizes[i])
    }, error = function(e) matrix(NA, nrow=2, ncol=2))
    
    h_cs <- tryCatch({
      hessian(f, p, method="complex", eps=step_sizes[i])
    }, error = function(e) matrix(NA, nrow=2, ncol=2))
    
    if (!all(is.na(h_fd)) && !all(is.na(h_cs))) {
      # Compare against each other if no ground truth
      diff_fd_cs <- max(abs(h_fd - h_cs))
      results$fd_error[i] <- diff_fd_cs
      results$cs_error[i] <- 0  # CS is reference; could compute against analytic if known
    }
  }
  
  return(results)
}
