# T-2: observation-window collapse — apparent rate vs sampling interval
#
# Claim under test: the observable two-rate ratio depends on the
# sampling window. k1/k2 -> 1 at deep-time sampling is a model-predicted
# resolution limit (the fast phase is unresolvable), not a contradiction.
# This is the formal address of the LTEE (37.7) vs C4 (~1.0) ratio gap.

test_that("T-2a: fine sampling recovers the true rate ratio (analytic)", {
  expect_gt(apparent_rate_ratio(0.01, k1 = 1, k2 = 0.01), 90)
})

test_that("T-2b: coarse sampling collapses the ratio to ~1 (analytic)", {
  expect_lt(apparent_rate_ratio(100, k1 = 1, k2 = 0.01), 1.5)
})

test_that("T-2c: apparent ratio monotone non-increasing in delta", {
  deltas <- 10^seq(-3, 3, by = 0.5)
  ratios <- sapply(deltas, function(d) apparent_rate_ratio(d, 1, 0.01))
  expect_true(all(diff(ratios) <= 0))
})

test_that("T-2d: resolution anchor — delta* is where the fast phase is tol-decayed", {
  dstar <- resolution_delta(k1 = 1, tol = 0.05)
  expect_equal(fast_surviving(dstar, 1), 0.05, tolerance = 1e-6)
  expect_equal(dstar, 3, tolerance = 1e-6)  # -ln(0.05)/1
})

test_that("T-2d2: ratio fully collapsed by 10/k1 (single observable rate)", {
  expect_lt(apparent_rate_ratio(10, k1 = 1, k2 = 0.01), 2)
})

test_that("T-2e: fit recovers the ratio at fine sampling", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = 10^seq(-2, 3, length.out = 13),
                                 noise = 0.001, seed = 42)
  sweep <- sweep[!is.na(sweep$ratio_fit), ]
  expect_gt(sweep$ratio_fit[1], 50)
})

test_that("T-2f: coarse-sampling fit fails to recover the true ratio (unidentifiable)", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = 10^seq(-2, 3, length.out = 13),
                                 noise = 0.001, seed = 42)
  sweep <- sweep[!is.na(sweep$ratio_fit), ]
  expect_lt(tail(sweep$ratio_fit, 1), 50)
})

test_that("T-2g: dAIC strongly supports bi-exp at fine sampling", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = 10^seq(-2, 3, length.out = 13),
                                 noise = 0.001, seed = 42)
  expect_gt(sweep$dAIC[1], 20)
})

test_that("T-2h: dAIC ~ 0 at coarse sampling (models indistinguishable)", {
  sweep <- window_collapse_sweep(1, 0.01, deltas = 10^seq(-2, 3, length.out = 13),
                                 noise = 0.001, seed = 42)
  expect_lt(abs(tail(sweep$dAIC, 1)), 10)
})

test_that("T-2i: deterministic under fixed seed (MPI blueprint)", {
  s1 <- window_collapse_sweep(1, 0.01, deltas = c(0.01, 0.1, 1, 10), noise = 0.001, seed = 5)
  s2 <- window_collapse_sweep(1, 0.01, deltas = c(0.01, 0.1, 1, 10), noise = 0.001, seed = 5)
  expect_identical(s1, s2)
})

test_that("T-2j/k/l: LTEE vs C4 reading — same process, different windows", {
  rd <- window_reading(1, 0.01)
  expect_gt(rd$fine, 90)     # LTEE ~ 37.7 style (physiological window)
  expect_lt(rd$deep, 1.5)    # C4 ~ 1.0 (geological window)
  expect_lt(rd$collapse, 1 / 60)
})
