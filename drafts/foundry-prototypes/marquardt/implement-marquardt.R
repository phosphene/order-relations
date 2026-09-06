# MARQUARDT Implementation Wrapper
# 
# This file wraps minpack.lm::nls.lm() as the primary implementation,
# ensuring we're using the literature-validated algorithm rather than
# building our own from scratch (which would risk introducing errors).
#
# Citation: Levenberg, K. (1944). "A method for the solution of certain non-linear problems in least squares." Quarterly of Applied Mathematics, 2, 164-168.
#           Marquardt, D. W. (1963). "An algorithm for least-squares estimation of nonlinear parameters." SIAM Journal on Applied Mathematics, 11(2), 431-441.
#           MINPACK documentation: Argonne National Laboratory (1980). MINPACK User Guide.

library(minpack.lm)

#' Fit bi-exponential model using MARQUARDT algorithm (via minpack.lm)
#' 
#' @param times numeric vector: time points
#' @param rho numeric vector: observed values
#' @param init_par list: initial parameter guesses (k1, k2, A1, A2)
#' @param maxit integer: maximum iterations
#' @return list containing fitted parameters, convergence status, diagnostics
fit_marquardt_biexp <- function(times, rho, init_par = c(A1=1, k1=10, A2=1, k2=1), 
                               maxit = 500) {
  
  stopifnot(length(times) == length(rho))
  stopifnot(all(times >= 0))
  stopifnot(all(is.finite(rho)))
  
  n <- length(times)
  
  # Residuals function
  residuals_fn <- function(p) {
    A1 <- p[1]; k1 <- p[2]; A2 <- p[3]; k2 <- p[4]
    pred <- A1 * exp(-k1 * times) + A2 * exp(-k2 * times)
    rho - pred
  }
  
  # Run LM via minpack.lm
  result <- tryCatch({
    nls.lm(
      par = init_par,
      fn = residuals_fn,
      control = list(maxiter = maxit, factr = 1e7)
    )
  }, error = function(e) {
    list(par = NA_real_, value = Inf, convergence = -1, message = e$message)
  })
  
  # Post-fit processing: ensure parameter ordering (k1 > k2) and amplitude pairing
  if (all(is.finite(result$par))) {
    k1 <- result$par[2]; k2 <- result$par[4]
    A1 <- result$par[1]; A2 <- result$par[3]
    
    # Swap if needed to maintain convention
    if (k2 > k1) {
      tmp_k <- k1; k1 <- k2; k2 <- tmp_k
      tmp_A <- A1; A1 <- A2; A2 <- tmp_A
    }
    
    result$par <- c(A1, k1, A2, k2)
    names(result$par) <- c("A1", "k1", "A2", "k2")
    result$converged <- result$convergence == 0
  } else {
    result$par <- rep(NA, 4)
    result$converged <- FALSE
    result$ratio_fit <- NA_real_
    return(result)
  }
  
  # Compute fitted ratio
  result$ratio_fit <- result$par["k1"] / result$par["k2"]
  
  # Gradient norm for additional diagnostic
  grad_fn <- numDeriv::grad(function(p) sum(residuals_fn(p)^2), result$par)
  result$grad_norm <- sqrt(sum(grad_fn^2))
  
  result$sse <- result$value
  result$n <- n
  
  return(result)
}

#' Validate fit against known synthetic ground truth
#' 
#' @param true_params named list: TRUE parameters
#' @param times numeric: time grid
#' @param noise numeric: observation noise sd
#' @param seed integer: RNG seed
#' @return list with fitted params, errors, convergence status
validate_marquardt_against_truth <- function(true_params, times, noise = 0.01, seed = 42) {
  
  set.seed(seed)
  rho_true <- true_params$A1 * exp(-true_params$k1 * times) + 
              true_params$A2 * exp(-true_params$k2 * times)
  rho_obs <- rho_true + rnorm(length(times), 0, noise)
  
  init_par <- c(A1=true_params$A1*0.8, k1=true_params$k1*1.2, 
                A2=true_params$A2*0.8, k2=true_params$k2*1.2)  # biased start
  
  fit <- fit_marquardt_biexp(times, rho_obs, init_par)
  
  if (!fit$converged || any(is.na(fit$par))) {
    return(list(converged = FALSE, error = "Fit did not converge"))
  }
  
  # Compute relative errors
  rel_err_A1 <- abs(fit$par["A1"] - true_params$A1) / true_params$A1
  rel_err_k1 <- abs(fit$par["k1"] - true_params$k1) / true_params$k1
  rel_err_A2 <- abs(fit$par["A2"] - true_params$A2) / true_params$A2
  rel_err_k2 <- abs(fit$par["k2"] - true_params$k2) / true_params$k2
  
  list(
    converged = TRUE,
    fitted = fit$par,
    true = true_params,
    rel_errors = c(A1 = rel_err_A1, k1 = rel_err_k1, A2 = rel_err_A2, k2 = rel_err_k2),
    mean_rel_error = mean(c(rel_err_A1, rel_err_k1, rel_err_A2, rel_err_k2)),
    ratio_fitted = fit$ratio_fit,
    ratio_true = true_params$k1 / true_params$k2,
    ratio_error = abs(fit$ratio_fit - ratio_true) / ratio_true
  )
}
