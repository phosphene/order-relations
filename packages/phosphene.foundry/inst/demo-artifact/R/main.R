#' Demo Analysis Pipeline
#'
#' Orchestrator for the Beta-Binomial demo analysis.
#' Follows the MPI Handoff Blueprint guard pattern.
#'
#' @name main
NULL


#' Run the full demo analysis pipeline
#'
#' Loads observation data, computes the Bayesian posterior, and writes
#' results to the results/ directory.
#'
#' @param data_path Path to the observation CSV file.
#' @param results_dir Path to the results output directory.
#' @param alpha_prior Prior alpha parameter. Default 2.
#' @param beta_prior Prior beta parameter. Default 2.
#' @return Invisible list with posterior results.
#' @export
run_analysis <- function(data_path = "data/observations.csv",
                         results_dir = "results",
                         alpha_prior = 2,
                         beta_prior = 2) {
  # Step 1: Load data (impure — isolated here)
  df <- utils::read.csv(data_path, stringsAsFactors = FALSE)

  # Step 2: Prepare observations (pure)
  obs <- prepare_observations(df, outcome_col = "outcome")

  # Step 3: Compute posterior (pure)
  posterior <- beta_binomial_posterior(
    alpha_prior = alpha_prior,
    beta_prior = beta_prior,
    successes = obs$successes,
    failures = obs$failures
  )

  # Step 4: Format results (pure)
  results_df <- format_posterior(posterior)

  # Step 5: Write results (impure — isolated here)
  dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(results_df,
                    file.path(results_dir, "model_summary.csv"),
                    row.names = FALSE)

  message(sprintf(
    "Posterior: mean = %.3f, 95%% CI [%.3f, %.3f] (n = %d observations)",
    posterior$mean, posterior$lower_95, posterior$upper_95,
    obs$successes + obs$failures
  ))

  invisible(posterior)
}


# Guard: Rscript runs, source() loads
if (sys.nframe() == 0) {
  run_analysis()
}
