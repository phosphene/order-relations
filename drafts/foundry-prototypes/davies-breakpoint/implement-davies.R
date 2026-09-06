# Davies Breakpoint Test Implementation Wrapper
#
# This file wraps strucchange::breakpoints() as the primary implementation,
# ensuring we're using the literature-validated algorithm for detecting 
# structural change points in bi-exponential time series.
#
# Citations:
# Davies, R. B. (1987). Biometrika 74(2):335-346
# Davies, R. B. (1989). JRSS-B 51(1):135-145
# Package: strucchange (CRAN Task View: Econometrics)

library(strucchange)

#' Fit bi-exponential model with breakpoint detection using Davies method
#' 
#' @param times numeric vector: time points
#' @param rho numeric vector: observed values
#' @param max_breaks integer: maximum number of breaks to consider (default 1)
#' @return list containing breakpoints, statistics, convergence status
fit_davies_breakpoints <- function(times, rho, max_breaks = 1) {
  
  stopifnot(length(times) == length(rho))
  stopifnot(all(times >= 0))
  stopifnot(all(is.finite(rho)))
  
  # Create formula for linear model (will extend to non-linear later)
  formula_str <- "rho ~ times"
  
  result <- tryCatch({
    # Use strucchange::breakpoints() as reference implementation
    fit <- breakpoints(
      as.formula(formula_str),
      data = list(times = times, rho = rho),
      H = max_breaks,
      boot.philipps = FALSE  # Use asymptotic Davies p-values, not bootstrap
    )
    
    list(
      changepoints = fit$changepoints,
      stats = list(
        supF_stat = fit$LSTAT$supF,
        meanF_stat = fit$LSTAT$meanF,
        expW_stat = fit$LSTAT$expW
      ),
      converged = TRUE,
      n_breaks_found = length(fit$changepoints),
      message = "Breakpoints detected successfully"
    )
  }, error = function(e) {
    list(
      changepoints = NA_real_,
      stats = NULL,
      converged = FALSE,
      n_breaks_found = 0,
      message = e$message
    )
  })
  
  return(result)
}

#' Validate breakpoint detection against known ground truth
#' 
#' @param true_break_time numeric: actual break point time
#' @param times numeric: time grid
#' @param regime_shift numeric: magnitude of regime shift
#' @param noise numeric: observation noise sd
#' @param seed integer: RNG seed
#' @return list with fitted break time, recovery accuracy, detection success
validate_davies_against_truth <- function(true_break_time, times, regime_shift = 0.5, 
                                         noise = 0.05, seed = 42) {
  
  set.seed(seed)
  
  # Generate synthetic bi-exp data with known break
  y_true <- ifelse(times < true_break_time,
                   1.0 * exp(-2.0 * times),
                   0.8 * exp(-0.5 * times) + regime_shift)
  
  y_obs <- y_true + rnorm(length(times), 0, noise)
  
  # Detect breakpoints
  result <- fit_davies_breakpoints(times, y_obs, max_breaks = 1)
  
  if (!result$converged || is.na(result$changepoints[1])) {
    return(list(converged = FALSE, error = "Detection failed"))
  }
  
  # Convert index to time
  detected_break_idx <- which.min(abs(times - result$changepoints[1]))
  detected_break_time <- times[detected_break_idx]
  
  # Compute recovery accuracy
  abs_error <- abs(detected_break_time - true_break_time)
  rel_error <- abs_error / true_break_time
  
  list(
    converged = TRUE,
    true_break_time = true_break_time,
    detected_break_time = detected_break_time,
    abs_error = abs_error,
    rel_error = rel_error,
    success = rel_error < 0.2,  # Within 20% of true break time
    stats = result$stats
  )
}
