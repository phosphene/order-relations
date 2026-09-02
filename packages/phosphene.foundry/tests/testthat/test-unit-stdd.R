# test-unit-stdd.R
# Unit tests for STDD utilities.
# Tier 1: deterministic under seed control, fast.

test_that("stdd_seed_env produces reproducible results", {
  r1 <- stdd_seed_env(42, rnorm(5))
  r2 <- stdd_seed_env(42, rnorm(5))
  expect_identical(r1, r2)
})

test_that("stdd_seed_env isolates seed state", {
  set.seed(99)
  before <- runif(1)

  # This should not affect the outer seed

  stdd_seed_env(42, rnorm(100))

  set.seed(99)
  after <- runif(1)
  expect_equal(before, after)
})

test_that("stdd_seed_env rejects non-numeric seed", {
  expect_error(stdd_seed_env("abc", 1 + 1))
})

test_that("stdd_convergence_check passes with good diagnostics", {
  result <- stdd_convergence_check(
    rhat_values = c(1.01, 1.00, 1.02),
    ess_values = c(1200, 800, 950),
    param_names = c("alpha", "beta", "sigma")
  )

  expect_true(result$all_converged)
  expect_equal(nrow(result$report), 3)
  expect_true(all(result$report$converged))
})

test_that("stdd_convergence_check fails on high R-hat", {
  result <- stdd_convergence_check(
    rhat_values = c(1.01, 1.15),
    ess_values = c(1200, 800)
  )

  expect_false(result$all_converged)
  expect_false(result$rhat_ok[2])
  expect_true(result$ess_ok[2])
})

test_that("stdd_convergence_check fails on low ESS", {
  result <- stdd_convergence_check(
    rhat_values = c(1.01, 1.02),
    ess_values = c(1200, 50)
  )

  expect_false(result$all_converged)
  expect_true(result$rhat_ok[2])
  expect_false(result$ess_ok[2])
})

test_that("stdd_convergence_check custom thresholds", {
  # Stricter thresholds
  result <- stdd_convergence_check(
    rhat_values = c(1.01, 1.04),
    ess_values = c(500, 500),
    rhat_threshold = 1.02,
    ess_threshold = 1000
  )

  expect_false(result$all_converged)
  expect_false(result$rhat_ok[2])
  expect_false(result$ess_ok[1])
})

test_that("stdd_param_recovery works with linear model", {
  result <- stdd_param_recovery(
    true_params = c(intercept = 2.0, slope = 0.5),
    generate_fn = function(params) {
      set.seed(123)  # internal reproducibility
      x <- rnorm(500)
      y <- params["intercept"] + params["slope"] * x + rnorm(500, sd = 0.3)
      data.frame(x = x, y = y)
    },
    fit_fn = function(data) lm(y ~ x, data = data),
    extract_fn = function(fit) {
      ci <- confint(fit, level = 0.95)
      data.frame(
        parameter = c("intercept", "slope"),
        mean = coef(fit),
        lower = ci[, 1],
        upper = ci[, 2],
        stringsAsFactors = FALSE
      )
    },
    seed = 42
  )

  expect_true(result$all_recovered)
  expect_equal(nrow(result$summary), 2)
})

test_that("stdd_param_recovery rejects missing column names", {
  expect_error(
    stdd_param_recovery(
      true_params = c(a = 1),
      generate_fn = function(p) data.frame(x = 1:10),
      fit_fn = function(d) lm(x ~ 1, data = d),
      extract_fn = function(f) data.frame(parameter = "a", mean = 1)
      # missing lower, upper columns
    ),
    "extract_fn must return columns"
  )
})

test_that("stdd_param_recovery rejects unnamed params", {
  expect_error(
    stdd_param_recovery(
      true_params = c(1, 2),
      generate_fn = identity,
      fit_fn = identity,
      extract_fn = identity
    )
  )
})
