# T-1: perturbation reversal — lambda-sweep ordering (test queue item 1)
#
# Claim under test: loss ordering matches integration depth in the
# relaxation regime; the R1/R7/lesion "reversed ordering" is a
# strong-perturbation regime boundary, not a refutation.

test_that("T-1a: relaxation regime ordering matches depth", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "depth", seed = 42)
  r0 <- sweep$rho_mean[sweep$lambda == 0]
  expect_gt(r0, 0.8)
})

test_that("T-1b: strong perturbation reverses ordering under depth exposure", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "depth", seed = 42)
  expect_lt(tail(sweep$rho_mean, 1), -0.8)
})

test_that("T-1c: reversal boundary exists at finite lambda", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "depth", seed = 42)
  bd <- reversal_boundary(sweep)
  expect_false(is.null(bd))
  expect_gt(bd$lambda_star, 0)
  expect_lt(bd$lambda_star, 5)
})

test_that("T-1d: rho descends monotonically under depth exposure", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "depth", seed = 42)
  expect_lt(max(diff(sweep$rho_mean)), 0.005)
})

test_that("T-1e: shallow exposure never reverses ordering", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "shallow", seed = 42)
  expect_gt(tail(sweep$rho_mean, 1), 0.8)
})

test_that("T-1f: uniform exposure preserves rank but collapses rate ratio", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  sweep <- lambda_sweep_ordering(depths, k1 = 1, k2 = 0.01,
                                 lambdas = seq(0, 5, by = 0.25),
                                 noise = 0.05, n_rep = 100,
                                 exposure = "uniform", seed = 42)
  expect_gt(tail(sweep$rho_mean, 1), 0.5)  # rank ordering survives
  r0 <- max(perturbation_rates(depths, 1, 0.01, 0, "uniform")) /
        min(perturbation_rates(depths, 1, 0.01, 0, "uniform"))
  r5 <- max(perturbation_rates(depths, 1, 0.01, 5, "uniform")) /
        min(perturbation_rates(depths, 1, 0.01, 5, "uniform"))
  expect_lt(r5, 2)    # relative separation collapses (T-2 window fact)
  expect_gt(r0, 10)   # separation present at baseline
})

test_that("T-1g: deterministic under fixed seed (MPI blueprint)", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  a1 <- lambda_sweep_ordering(depths, 1, 0.01, seq(0, 1, by = 0.25),
                              noise = 0.05, n_rep = 10, seed = 7)
  a2 <- lambda_sweep_ordering(depths, 1, 0.01, seq(0, 1, by = 0.25),
                              noise = 0.05, n_rep = 10, seed = 7)
  expect_identical(a1, a2)
})

test_that("T-1h: loss order matches depth order at relaxation (Kendall)", {
  set.seed(1)
  depths <- sort(runif(20, 0.02, 0.98))
  k_eff <- perturbation_rates(depths, 1, 0.01, 0, "depth")
  t_loss <- loss_times(k_eff, 0.5, 0.05)
  expect_gt(suppressWarnings(stats::cor(depths, t_loss, method = "kendall")), 0.9)
})
