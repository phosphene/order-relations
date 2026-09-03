# test-fit-numerics.R — numerical discipline regressions (M5 / calibration)
#
# Anti-pattern fixes under test:
#   1. fit_biexp swaps k1/k2 WITHOUT A1/A2 (amplitude mislabeling).
#   2. window_collapse_sweep computed dAIC unconditionally, even when the
#      fits did not converge (a stalled fit could still produce an AIC claim).
#   3. Single-start optim collapsed to a degenerate corner on the LTEE-like
#      regime (k1=k2 at the upper bound, amplitudes -> 0, ratio 1.0, but
#      optim reported converged=TRUE). Multi-start + off-boundary discipline
#      must recover the true basin (ratio ~ 37.7).
#   4. dAIC comparability: n must be reported per row (ΔAIC across different
#      n is incommensurable).

library(testthat)

# ---- 1. amplitude pairing after rate swap ----

test_that("fit_biexp pairs amplitudes with their rates after the swap", {
  # truth: slow component FIRST (A1=0.7, k1=0.05), fast component SECOND
  # (A2=0.3, k2=1.0). The fitter must return k1 >= k2 with A1 the fast
  # amplitude (0.3) and A2 the slow amplitude (0.7).
  set.seed(11)
  t <- seq(0, 40, length.out = 800)
  rho <- sample_process(t, A1 = 0.7, k1 = 0.05, A2 = 0.3, k2 = 1.0,
                        noise = 0.001, seed = 11)
  fit <- fit_biexp(t, rho)
  expect_true(fit$converged)
  expect_true(fit$k1 > fit$k2)                    # k1 labeled fast
  expect_equal(fit$A1, 0.3, tolerance = 0.05)     # fast amplitude with k1
  expect_equal(fit$A2, 0.7, tolerance = 0.05)     # slow amplitude with k2
  expect_equal(fit$k1, 1.0, tolerance = 0.05)
  expect_equal(fit$k2, 0.05, tolerance = 0.01)
})

# ---- 2. dAIC gating on convergence ----

test_that("window_collapse_sweep gates dAIC and ratio on BOTH fits converging", {
  # maxit = 1 cannot converge: dAIC/ratio must be NA, not a number.
  sweep <- window_collapse_sweep(1, 0.01, deltas = c(0.01, 1, 100),
                                 noise = 0.001, seed = 42, maxit = 1)
  expect_true(all(is.na(sweep$dAIC)))
  expect_true(all(is.na(sweep$ratio_fit)))
  expect_true(all(!sweep$converged_b | !sweep$converged_m))
})

test_that("converged fits produce a real dAIC (positive = bi-exp wins)", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = c(0.01, 1, 100),
                                 noise = 0.001, seed = 42)
  expect_true(all(sweep$converged_b))
  expect_true(all(sweep$converged_m))
  expect_true(all(!is.na(sweep$dAIC)))
  expect_true(sweep$dAIC[1] > 0)   # fine sampling: bi-exp clearly preferred
})

# ---- 3. LTEE-like calibration (degenerate-corner regression) ----

test_that("LTEE-like regime recovers the true ratio (no bound collapse)", {
  # k1=17.7, k2=0.47, A1=0.1, A2=0.6 — the simulacra-9-13 LTEE-like system.
  # Single-start optim collapsed to k1=k2=1e6, A->0, ratio 1.0 with
  # converged=TRUE. Multi-start must find the true basin (~37.7).
  set.seed(42)
  t <- seq(0, by = 0.01, length.out = 20000)
  rho <- sample_process(t, 0.1, 17.7, 0.6, 0.47, noise = 0.001, seed = 42)
  fit <- fit_biexp(t, rho)
  expect_true(fit$converged)
  expect_lt(fit$k1, 1e3)                # not at the upper bound
  expect_gt(fit$A1, 1e-3)               # fast amplitude not collapsed to 0
  expect_gt(fit$k1 / fit$k2, 20)        # ratio far from the degenerate 1.0
  expect_equal(fit$k1 / fit$k2, 37.7, tolerance = 0.25)
})

# ---- 4. n reported per row ----

test_that("sweep reports n per row (dAIC comparability)", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = c(0.01, 0.1, 1, 10),
                                 noise = 0.001, seed = 42)
  expect_true("n" %in% names(sweep))
  expect_true(all(sweep$n > 0))
  expect_true(all(diff(sweep$n) < 0))   # finer sampling -> more points
  expect_true(all(is.finite(sweep$n)))
})

# ---- 6. input validation (M2 recycling / M3 non-finite) ----

test_that("length-mismatched times/rho fails instead of recycling (M2)", {
  t <- seq(0, 10, length.out = 50)
  rho <- sample_process(t, 1, 1, 1, 0.01, noise = 0)
  # 25 vs 50 is a compatible multiple: R would silently recycle and fit
  # garbage with converged=TRUE. The precondition must refuse it.
  expect_error(fit_biexp(t[1:25], rho), "length")
  expect_error(fit_monoexp(t[1:25], rho), "length")
})

test_that("non-finite inputs fail informatively (M3)", {
  t <- seq(0, 10, length.out = 50)
  rho <- sample_process(t, 1, 1, 1, 0.01, noise = 0)
  rho_na <- rho; rho_na[10] <- NA
  rho_nan <- rho; rho_nan[10] <- NaN
  rho_inf <- rho; rho_inf[10] <- Inf
  expect_error(fit_biexp(t, rho_na))
  expect_error(fit_biexp(t, rho_nan))
  expect_error(fit_biexp(t, rho_inf))
  expect_error(fit_monoexp(t, rho_na))
  expect_error(fit_monoexp(t, rho_nan))
  expect_error(fit_monoexp(t, rho_inf))
})

test_that("valid inputs still fit after the preconditions", {
  t <- seq(0, 20, length.out = 200)
  rho <- sample_process(t, 1, 1, 1, 0.01, noise = 0.001, seed = 7)
  fb <- fit_biexp(t, rho)
  fm <- fit_monoexp(t, rho)
  expect_true(fb$converged)
  expect_true(fm$converged)
  expect_equal(fb$k1 / fb$k2, 100, tolerance = 0.1)
})

# ---- 7. diagnostics present ----

test_that("fit outputs carry grad_norm and n diagnostics", {
  set.seed(3)
  t <- seq(0, 20, length.out = 200)
  rho <- sample_process(t, 1, 1, 1, 0.01, noise = 0.001, seed = 3)
  fb <- fit_biexp(t, rho)
  fm <- fit_monoexp(t, rho)
  expect_true(is.finite(fb$grad_norm))
  expect_true(is.finite(fm$grad_norm))
  expect_equal(fb$n, 200)
  expect_equal(fm$n, 200)
  expect_true(all(is.finite(c(fb$k1, fb$k2, fb$A1, fb$A2, fb$sse))))
})
