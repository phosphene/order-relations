# test-integration-recovery.R
# Tier 2: Parameter recovery for the Beta-Binomial model.
# Validates the posterior recovers known true parameters.
# Guarded — runs in nightly CI only.

source("../../R/posterior.R")

test_that("posterior recovers true success probability", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  # Known true probability
  true_p <- 0.7

  # Generate synthetic data under controlled seed
  set.seed(42)
  n <- 200
  outcomes <- rbinom(n, 1, true_p)
  successes <- sum(outcomes)
  failures <- n - successes

  # Compute posterior with weakly informative prior
  posterior <- beta_binomial_posterior(1, 1, successes, failures)

  # True probability should fall within 95% CI
  expect_true(
    true_p >= posterior$lower_95 && true_p <= posterior$upper_95,
    info = sprintf("True p = %.2f not in [%.3f, %.3f]",
                   true_p, posterior$lower_95, posterior$upper_95)
  )

  # Posterior mean should be close to true value
  expect_equal(posterior$mean, true_p, tolerance = 0.1)
})


test_that("posterior recovers extreme probabilities", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  for (true_p in c(0.1, 0.3, 0.5, 0.7, 0.9)) {
    set.seed(42)
    n <- 500
    outcomes <- rbinom(n, 1, true_p)
    successes <- sum(outcomes)
    failures <- n - successes

    posterior <- beta_binomial_posterior(1, 1, successes, failures)

    expect_true(
      true_p >= posterior$lower_95 && true_p <= posterior$upper_95,
      info = sprintf("true_p = %.1f not in [%.3f, %.3f]",
                     true_p, posterior$lower_95, posterior$upper_95)
    )
  }
})


test_that("informative prior pulls posterior toward prior with little data", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  # Strong prior at 0.5, data suggests 0.9
  strong_prior <- beta_binomial_posterior(20, 20, 9, 1)
  weak_prior <- beta_binomial_posterior(1, 1, 9, 1)

  # Strong prior should pull mean closer to 0.5
  expect_lt(strong_prior$mean, weak_prior$mean)
  expect_gt(strong_prior$mean, 0.5)  # but still influenced by data
})
