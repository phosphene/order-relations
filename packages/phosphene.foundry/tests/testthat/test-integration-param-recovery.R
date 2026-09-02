# test-integration-param-recovery.R
# Tier 2: Parameter recovery with real model fitting.
# Validates that models recover known true parameters from synthetic data.
# Guarded — runs in nightly CI only (RUN_INTEGRATION=true).

test_that("lm recovers known linear parameters via STDD framework", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  result <- stdd_param_recovery(
    true_params = c(intercept = 3.0, slope = -0.8),
    generate_fn = function(params) {
      n <- 500
      x <- rnorm(n)
      y <- params["intercept"] + params["slope"] * x + rnorm(n, sd = 0.5)
      data.frame(x = x, y = y)
    },
    fit_fn = function(data) lm(y ~ x, data = data),
    extract_fn = function(fit) {
      ci <- confint(fit, level = 0.95)
      data.frame(
        parameter = c("intercept", "slope"),
        mean = unname(coef(fit)),
        lower = ci[, 1],
        upper = ci[, 2],
        stringsAsFactors = FALSE
      )
    },
    seed = 42
  )

  expect_true(result$all_recovered,
    info = paste("Failed to recover:",
      paste(result$summary$parameter[!result$recovered], collapse = ", ")))
  expect_equal(nrow(result$summary), 2)
})


test_that("lm recovers parameters with multiple predictors", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  result <- stdd_param_recovery(
    true_params = c(intercept = 1.0, x1 = 2.5, x2 = -1.3),
    generate_fn = function(params) {
      n <- 800
      x1 <- rnorm(n)
      x2 <- rnorm(n)
      y <- params["intercept"] + params["x1"] * x1 + params["x2"] * x2 +
           rnorm(n, sd = 0.4)
      data.frame(x1 = x1, x2 = x2, y = y)
    },
    fit_fn = function(data) lm(y ~ x1 + x2, data = data),
    extract_fn = function(fit) {
      ci <- confint(fit, level = 0.95)
      data.frame(
        parameter = c("intercept", "x1", "x2"),
        mean = unname(coef(fit)),
        lower = ci[, 1],
        upper = ci[, 2],
        stringsAsFactors = FALSE
      )
    },
    seed = 123
  )

  expect_true(result$all_recovered)
})


test_that("glm recovers logistic regression parameters", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  result <- stdd_param_recovery(
    true_params = c(intercept = -0.5, slope = 1.2),
    generate_fn = function(params) {
      n <- 1000
      x <- rnorm(n)
      logit_p <- params["intercept"] + params["slope"] * x
      y <- rbinom(n, 1, plogis(logit_p))
      data.frame(x = x, y = y)
    },
    fit_fn = function(data) glm(y ~ x, data = data, family = binomial()),
    extract_fn = function(fit) {
      ci <- confint(fit, level = 0.95)
      data.frame(
        parameter = c("intercept", "slope"),
        mean = unname(coef(fit)),
        lower = ci[, 1],
        upper = ci[, 2],
        stringsAsFactors = FALSE
      )
    },
    seed = 77
  )

  expect_true(result$all_recovered)
})


test_that("brms model compiles, fits, and recovers parameters", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")
  skip_if_not_installed("brms")

  true_intercept <- 2.0
  true_slope <- 0.5
  true_sigma <- 0.3

  synth <- stdd_seed_env(42, {
    n <- 200
    x <- rnorm(n)
    y <- true_intercept + true_slope * x + rnorm(n, sd = true_sigma)
    data.frame(x = x, y = y)
  })

  fit <- brms::brm(
    y ~ x,
    data = synth,
    family = gaussian(),
    seed = 42,
    chains = 4,
    cores = 1,
    iter = 1000,
    warmup = 500,
    silent = 2,
    refresh = 0
  )

  expect_s3_class(fit, "brmsfit")

  # Extract fixed effects with CIs
  fe <- brms::fixef(fit)
  intercept_ci <- fe["Intercept", c("Q2.5", "Q97.5")]
  slope_ci <- fe["x", c("Q2.5", "Q97.5")]

  # Parameter recovery
 expect_true(
    true_intercept >= intercept_ci[1] && true_intercept <= intercept_ci[2],
    info = sprintf("Intercept %.2f not in [%.2f, %.2f]",
                   true_intercept, intercept_ci[1], intercept_ci[2])
  )
  expect_true(
    true_slope >= slope_ci[1] && true_slope <= slope_ci[2],
    info = sprintf("Slope %.2f not in [%.2f, %.2f]",
                   true_slope, slope_ci[1], slope_ci[2])
  )
})
