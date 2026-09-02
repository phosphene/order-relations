#' Stochastic Test-Driven Development (STDD) Utilities
#'
#' Tools for testing probabilistic and Bayesian code. Implements the STDD
#' framework: decoupling deterministic math from stochastic simulation,
#' controlled seed environments, and statistical hypothesis assertions.
#'
#' @name stdd
NULL


#' Execute code in a controlled seed environment
#'
#' Wraps `withr::with_seed()` with Foundry conventions: explicit seed,
#' automatic teardown, optional RNG kind specification for cross-platform
#' reproducibility.
#'
#' @param seed Integer seed value.
#' @param code Expression to evaluate under the seed.
#' @param .rng_kind Character; RNG algorithm. Default `"Mersenne-Twister"`.
#' @param .rng_normal_kind Character; normal generation method.
#'   Default `"Inversion"` for cross-platform stability.
#' @return The result of evaluating `code`.
#' @export
#' @examples
#' stdd_seed_env(42, rnorm(5))
stdd_seed_env <- function(seed,
                          code,
                          .rng_kind = "Mersenne-Twister",
                          .rng_normal_kind = "Inversion") {
  stopifnot(is.numeric(seed), length(seed) == 1L)
  withr::with_seed(
    seed,
    code,
    .rng_kind = .rng_kind,
    .rng_normal_kind = .rng_normal_kind
  )
}


#' Parameter recovery test
#'
#' Generates synthetic data from known true parameters, fits a model,
#' and checks whether the estimated parameters fall within Bayesian
#' credible intervals. Designed for use inside `testthat::test_that()`.
#'
#' @param true_params Named numeric vector of true parameter values.
#' @param generate_fn Function that takes `true_params` and returns
#'   a synthetic dataset (data.frame).
#' @param fit_fn Function that takes a dataset and returns a fitted
#'   model object with extractable posterior summaries.
#' @param extract_fn Function that takes a fitted model and returns a
#'   data.frame with columns: `parameter`, `mean`, `lower`, `upper`.
#' @param ci_level Credible interval level. Default `0.95`.
#' @param seed Integer seed for data generation reproducibility.
#' @return A list with components:
#'   \describe{
#'     \item{recovered}{Logical vector; TRUE if true value falls within CI.}
#'     \item{summary}{Data frame of parameter estimates with CIs.}
#'     \item{all_recovered}{Logical; TRUE if all parameters recovered.}
#'   }
#' @export
#' @examples
#' \dontrun{
#' result <- stdd_param_recovery(
#'   true_params = c(intercept = 2.0, slope = 0.5),
#'   generate_fn = function(params) {
#'     x <- rnorm(200)
#'     y <- params["intercept"] + params["slope"] * x + rnorm(200, sd = 0.5)
#'     data.frame(x = x, y = y)
#'   },
#'   fit_fn = function(data) lm(y ~ x, data = data),
#'   extract_fn = function(fit) {
#'     ci <- confint(fit)
#'     data.frame(
#'       parameter = c("intercept", "slope"),
#'       mean = coef(fit),
#'       lower = ci[, 1],
#'       upper = ci[, 2]
#'     )
#'   }
#' )
#' }
stdd_param_recovery <- function(true_params,
                                generate_fn,
                                fit_fn,
                                extract_fn,
                                ci_level = 0.95,
                                seed = 42L) {
  stopifnot(is.numeric(true_params), !is.null(names(true_params)))
  stopifnot(is.function(generate_fn), is.function(fit_fn), is.function(extract_fn))
  stopifnot(ci_level > 0, ci_level < 1)

  # Generate synthetic data under controlled seed
  synth_data <- stdd_seed_env(seed, generate_fn(true_params))

  # Fit model

  fit <- fit_fn(synth_data)

  # Extract summaries
  summary_df <- extract_fn(fit)

  # Check recovery
  required_cols <- c("parameter", "mean", "lower", "upper")
  missing <- setdiff(required_cols, names(summary_df))
  if (length(missing) > 0L) {
    stop("extract_fn must return columns: ", paste(required_cols, collapse = ", "),
         ". Missing: ", paste(missing, collapse = ", "))
  }

  recovered <- vapply(seq_len(nrow(summary_df)), function(i) {
    param_name <- summary_df$parameter[i]
    if (!param_name %in% names(true_params)) return(NA)
    true_val <- true_params[param_name]
    true_val >= summary_df$lower[i] && true_val <= summary_df$upper[i]
  }, logical(1))

  list(
    recovered = recovered,
    summary = summary_df,
    all_recovered = all(recovered, na.rm = TRUE)
  )
}


#' MCMC convergence diagnostics check
#'
#' Programmatic convergence assertions for Bayesian models. Checks
#' Gelman-Rubin R-hat and Effective Sample Size against configurable
#' thresholds.
#'
#' @param rhat_values Numeric vector of R-hat values per parameter.
#' @param ess_values Numeric vector of effective sample sizes per parameter.
#' @param rhat_threshold Maximum acceptable R-hat. Default `1.05`.
#' @param ess_threshold Minimum acceptable ESS. Default `400`.
#' @param param_names Optional character vector of parameter names.
#' @return A list with components:
#'   \describe{
#'     \item{rhat_ok}{Logical vector per parameter.}
#'     \item{ess_ok}{Logical vector per parameter.}
#'     \item{all_converged}{Logical; TRUE if all diagnostics pass.}
#'     \item{report}{Data frame with per-parameter diagnostics.}
#'   }
#' @export
#' @examples
#' stdd_convergence_check(
#'   rhat_values = c(1.01, 1.00, 1.02),
#'   ess_values = c(1200, 800, 950),
#'   param_names = c("alpha", "beta", "sigma")
#' )
stdd_convergence_check <- function(rhat_values,
                                   ess_values,
                                   rhat_threshold = 1.05,
                                   ess_threshold = 400,
                                   param_names = NULL) {
  stopifnot(is.numeric(rhat_values), is.numeric(ess_values))
  stopifnot(length(rhat_values) == length(ess_values))

  n <- length(rhat_values)
  if (is.null(param_names)) {
    param_names <- paste0("param_", seq_len(n))
  }

  rhat_ok <- rhat_values < rhat_threshold
  ess_ok <- ess_values >= ess_threshold

  report <- data.frame(
    parameter = param_names,
    rhat = rhat_values,
    rhat_ok = rhat_ok,
    ess = ess_values,
    ess_ok = ess_ok,
    converged = rhat_ok & ess_ok,
    stringsAsFactors = FALSE
  )

  list(
    rhat_ok = rhat_ok,
    ess_ok = ess_ok,
    all_converged = all(rhat_ok & ess_ok),
    report = report
  )
}
