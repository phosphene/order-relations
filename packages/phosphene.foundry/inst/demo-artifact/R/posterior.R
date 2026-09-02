#' Beta-Binomial Posterior Computation
#'
#' Pure functional library for conjugate Beta-Binomial Bayesian updating.
#' Demonstrates the MPI Handoff Blueprint: data in, data out, no side effects.
#'
#' @name posterior
NULL


#' Compute Beta-Binomial posterior parameters
#'
#' Given a Beta prior and observed binomial data, computes the conjugate
#' posterior Beta distribution parameters analytically.
#'
#' @param alpha_prior Numeric; prior alpha parameter (> 0).
#' @param beta_prior Numeric; prior beta parameter (> 0).
#' @param successes Integer; observed number of successes (>= 0).
#' @param failures Integer; observed number of failures (>= 0).
#' @return A list with components:
#'   \describe{
#'     \item{alpha_post}{Posterior alpha parameter.}
#'     \item{beta_post}{Posterior beta parameter.}
#'     \item{mean}{Posterior mean.}
#'     \item{variance}{Posterior variance.}
#'     \item{lower_95}{Lower bound of 95\% credible interval.}
#'     \item{upper_95}{Upper bound of 95\% credible interval.}
#'   }
#' @export
#' @examples
#' beta_binomial_posterior(2, 2, 8, 2)
beta_binomial_posterior <- function(alpha_prior, beta_prior, successes, failures) {
  # Input validation
  stopifnot(is.numeric(alpha_prior), length(alpha_prior) == 1, alpha_prior > 0)
  stopifnot(is.numeric(beta_prior), length(beta_prior) == 1, beta_prior > 0)
  stopifnot(is.numeric(successes), length(successes) == 1, successes >= 0)
  stopifnot(is.numeric(failures), length(failures) == 1, failures >= 0)

  # Conjugate update
  alpha_post <- alpha_prior + successes
  beta_post <- beta_prior + failures

  # Posterior summaries
  mean_post <- alpha_post / (alpha_post + beta_post)
  var_post <- (alpha_post * beta_post) /
    ((alpha_post + beta_post)^2 * (alpha_post + beta_post + 1))

  # 95% credible interval
  lower_95 <- qbeta(0.025, alpha_post, beta_post)
  upper_95 <- qbeta(0.975, alpha_post, beta_post)

  list(
    alpha_post = alpha_post,
    beta_post = beta_post,
    mean = mean_post,
    variance = var_post,
    lower_95 = lower_95,
    upper_95 = upper_95
  )
}


#' Prepare observation data from a data frame
#'
#' Extracts success/failure counts from a data frame with a binary outcome
#' column. Pure function with contract validation.
#'
#' @param df Data frame with at least an outcome column.
#' @param outcome_col Character; name of the binary (0/1) outcome column.
#' @return A list with `successes` and `failures` counts.
#' @export
prepare_observations <- function(df, outcome_col = "outcome") {
  if (!is.data.frame(df)) stop("Expected a data.frame")
  if (!outcome_col %in% names(df)) {
    stop(sprintf("Missing required column: %s", outcome_col))
  }

  outcomes <- df[[outcome_col]]
  if (!all(outcomes %in% c(0L, 1L, 0, 1), na.rm = TRUE)) {
    stop("Outcome column must contain only 0 and 1 values")
  }

  outcomes <- outcomes[!is.na(outcomes)]

  list(
    successes = sum(outcomes == 1),
    failures = sum(outcomes == 0)
  )
}


#' Format posterior results as a tidy data frame
#'
#' Converts posterior list output into a structured data frame suitable
#' for export, reporting, or downstream analysis.
#'
#' @param posterior List as returned by [beta_binomial_posterior()].
#' @param model_name Character; optional label for the model.
#' @return A single-row data frame with posterior summaries.
#' @export
format_posterior <- function(posterior, model_name = "beta_binomial") {
  data.frame(
    model = model_name,
    alpha_post = posterior$alpha_post,
    beta_post = posterior$beta_post,
    mean = posterior$mean,
    variance = posterior$variance,
    lower_95 = posterior$lower_95,
    upper_95 = posterior$upper_95,
    stringsAsFactors = FALSE
  )
}
