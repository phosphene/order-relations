# test-unit-posterior.R
# Tier 1: Deterministic unit tests for Beta-Binomial posterior math.

source("../../R/posterior.R")

test_that("beta_binomial_posterior returns correct conjugate update", {
  result <- beta_binomial_posterior(2, 2, 8, 2)

  expect_equal(result$alpha_post, 10)
  expect_equal(result$beta_post, 4)
  expect_equal(result$mean, 10 / 14, tolerance = 1e-6)
})

test_that("posterior mean matches analytical formula", {
  result <- beta_binomial_posterior(1, 1, 5, 5)
  expected_mean <- 6 / 12
  expect_equal(result$mean, expected_mean, tolerance = 1e-10)
})

test_that("posterior variance matches analytical formula", {
  result <- beta_binomial_posterior(2, 2, 8, 2)
  a <- 10
  b <- 4
  expected_var <- (a * b) / ((a + b)^2 * (a + b + 1))
  expect_equal(result$variance, expected_var, tolerance = 1e-10)
})

test_that("95% credible interval contains the posterior mean", {
  result <- beta_binomial_posterior(2, 2, 8, 2)
  expect_true(result$mean >= result$lower_95)
  expect_true(result$mean <= result$upper_95)
})

test_that("uniform prior (1,1) with no data returns uniform", {
  result <- beta_binomial_posterior(1, 1, 0, 0)
  expect_equal(result$alpha_post, 1)
  expect_equal(result$beta_post, 1)
  expect_equal(result$mean, 0.5)
})

test_that("beta_binomial_posterior rejects invalid inputs", {
  expect_error(beta_binomial_posterior(-1, 2, 5, 5))
  expect_error(beta_binomial_posterior(2, 0, 5, 5))
  expect_error(beta_binomial_posterior(2, 2, -1, 5))
})

test_that("prepare_observations extracts correct counts", {
  df <- data.frame(id = 1:10, outcome = c(1, 1, 1, 0, 1, 1, 0, 1, 1, 1))
  obs <- prepare_observations(df, outcome_col = "outcome")

  expect_equal(obs$successes, 8)
  expect_equal(obs$failures, 2)
})

test_that("prepare_observations handles NA values", {
  df <- data.frame(outcome = c(1, 0, NA, 1))
  obs <- prepare_observations(df)

  expect_equal(obs$successes, 2)
  expect_equal(obs$failures, 1)
})

test_that("prepare_observations rejects non-binary values", {
  df <- data.frame(outcome = c(1, 2, 3))
  expect_error(prepare_observations(df), "only 0 and 1")
})

test_that("prepare_observations rejects missing outcome column", {
  df <- data.frame(x = 1:5)
  expect_error(prepare_observations(df), "Missing required column")
})

test_that("format_posterior produces a single-row data frame", {
  post <- beta_binomial_posterior(2, 2, 8, 2)
  result <- format_posterior(post, model_name = "test_model")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$model, "test_model")
  expect_true(all(c("mean", "variance", "lower_95", "upper_95") %in% names(result)))
})
