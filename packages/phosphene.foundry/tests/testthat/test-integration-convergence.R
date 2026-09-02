# test-integration-convergence.R
# Tier 2: MCMC convergence diagnostics on fitted models.
# Validates R-hat, ESS, and LOO diagnostics using stdd_convergence_check().
# Guarded — runs in nightly CI only (RUN_INTEGRATION=true).

test_that("brms model achieves convergence on simple regression", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")
  skip_if_not_installed("brms")

  synth <- stdd_seed_env(42, {
    n <- 200
    x <- rnorm(n)
    y <- 1.5 + 0.8 * x + rnorm(n, sd = 0.5)
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

  # Extract diagnostics
  rhat_vals <- brms::rhat(fit)
  # neff_ratio returns proportion; multiply by total draws for ESS
  total_draws <- 4 * 500  # chains * (iter - warmup)
  ess_vals <- brms::neff_ratio(fit) * total_draws

  # Remove any NA entries (can happen for derived quantities)
  valid <- !is.na(rhat_vals) & !is.na(ess_vals)
  rhat_vals <- rhat_vals[valid]
  ess_vals <- ess_vals[valid]

  check <- stdd_convergence_check(
    rhat_values = rhat_vals,
    ess_values = ess_vals,
    param_names = names(rhat_vals),
    rhat_threshold = 1.05,
    ess_threshold = 400
  )

  expect_true(check$all_converged,
    info = paste("Non-converged params:",
      paste(check$report$parameter[!check$report$converged], collapse = ", ")))
})


test_that("brms model achieves convergence on grouped regression", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")
  skip_if_not_installed("brms")

  synth <- stdd_seed_env(99, {
    n_groups <- 5
    n_per <- 60
    group <- rep(paste0("g", seq_len(n_groups)), each = n_per)
    group_effects <- rep(rnorm(n_groups, sd = 0.5), each = n_per)
    x <- rnorm(n_groups * n_per)
    y <- 2.0 + 0.5 * x + group_effects + rnorm(n_groups * n_per, sd = 0.4)
    data.frame(x = x, y = y, group = group)
  })

  fit <- brms::brm(
    y ~ x + (1 | group),
    data = synth,
    family = gaussian(),
    seed = 99,
    chains = 4,
    cores = 1,
    iter = 1000,
    warmup = 500,
    silent = 2,
    refresh = 0
  )

  rhat_vals <- brms::rhat(fit)
  total_draws <- 4 * 500
  ess_vals <- brms::neff_ratio(fit) * total_draws

  valid <- !is.na(rhat_vals) & !is.na(ess_vals)

  check <- stdd_convergence_check(
    rhat_values = rhat_vals[valid],
    ess_values = ess_vals[valid],
    param_names = names(rhat_vals[valid])
  )

  expect_true(check$all_converged)
})


test_that("stdd_convergence_check correctly flags bad diagnostics", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  # Simulate what bad convergence looks like
  bad_rhat <- c(1.01, 1.02, 1.15, 1.01)  # param 3 fails
  bad_ess <- c(800, 900, 50, 1000)         # param 3 also fails ESS

  check <- stdd_convergence_check(
    rhat_values = bad_rhat,
    ess_values = bad_ess,
    param_names = c("alpha", "beta", "sigma", "tau")
  )

  expect_false(check$all_converged)
  expect_false(check$report$converged[3])
  expect_true(check$report$converged[1])
  expect_true(check$report$converged[4])
})
