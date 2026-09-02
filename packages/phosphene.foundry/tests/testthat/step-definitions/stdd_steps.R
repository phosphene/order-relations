# Step definitions for stdd_workflow.feature

library(cucumber)
library(testthat)

world <- new.env(parent = emptyenv())

# --- Given steps ---

given("a seed value of {int}", function(seed) {
  world$seed <- seed
})

given("seeds {int} and {int}", function(seed1, seed2) {
  world$seed1 <- seed1
  world$seed2 <- seed2
})

given("the outer RNG state is set to seed {int}", function(seed) {
  set.seed(seed)
  world$outer_seed <- seed
  world$before_val <- runif(1)
})

given("true parameters intercept {double} and slope {double}", function(intercept, slope) {
  world$true_params <- c(intercept = intercept, slope = slope)
})

given("R-hat values of {double} and {double} and {double}", function(r1, r2, r3) {
  world$rhat_values <- c(r1, r2, r3)
})

given("R-hat values of {double} and {double}", function(r1, r2) {
  world$rhat_values <- c(r1, r2)
})

given("ESS values of {int} and {int} and {int}", function(e1, e2, e3) {
  world$ess_values <- c(e1, e2, e3)
})

given("ESS values of {int} and {int}", function(e1, e2) {
  world$ess_values <- c(e1, e2)
})

# --- When steps ---

when("I generate {int} normal random draws under seed isolation", function(n) {
  world$draws1 <- stdd_seed_env(world$seed, rnorm(n))
})

when("I generate another {int} draws under the same seed", function(n) {
  world$draws2 <- stdd_seed_env(world$seed, rnorm(n))
})

when("I generate {int} draws under each seed", function(n) {
  world$draws_a <- stdd_seed_env(world$seed1, rnorm(n))
  world$draws_b <- stdd_seed_env(world$seed2, rnorm(n))
})

when("I run a computation under isolated seed {int}", function(seed) {
  stdd_seed_env(seed, rnorm(1000))
})

when("I generate {int} synthetic data points and fit a linear model", function(n) {
  world$recovery_result <- stdd_param_recovery(
    true_params = world$true_params,
    generate_fn = function(params) {
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
})

when("I run stdd_convergence_check", function() {
  n <- length(world$rhat_values)
  world$convergence_result <- stdd_convergence_check(
    rhat_values = world$rhat_values,
    ess_values = world$ess_values,
    param_names = paste0("param_", seq_len(n))
  )
})

# --- Then steps ---

then("both draw vectors should be identical", function() {
  expect_identical(world$draws1, world$draws2)
})

then("the two draw vectors should differ", function() {
  expect_false(identical(world$draws_a, world$draws_b))
})

then("the outer RNG state should be unchanged", function() {
  set.seed(world$outer_seed)
  after_val <- runif(1)
  expect_equal(world$before_val, after_val)
})

then("all parameters should fall within the {int} percent confidence interval", function(ci_pct) {
  expect_true(world$recovery_result$all_recovered,
    info = paste("Failed to recover:",
      paste(world$recovery_result$summary$parameter[!world$recovery_result$recovered],
            collapse = ", ")))
})

then("all parameters should be flagged as converged", function() {
  expect_true(world$convergence_result$all_converged)
})

then("the second parameter should be flagged as not converged", function() {
  expect_false(world$convergence_result$report$converged[2])
})
