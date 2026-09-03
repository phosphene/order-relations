# Abstraction inventory: substrate-stripping + instantiation tests.
# Design law: an abstraction must be stateable with zero biological nouns.
# These tests exercise the math directly (substrate-free), then the
# flytrap instantiation as the first mapping.

test_that("two-variable system: timescale ratio and slaving fact", {
  sys <- tv_system(
    f = function(x, y) -x,
    g = function(x, y) -y,
    tau1 = 1, tau2 = 1000
  )
  expect_equal(timescale_ratio(sys), 1e-3)
  expect_true(slaving_holds(sys))
  expect_false(slaving_holds(tv_system(function(x, y) -x, function(x, y) -y, 1, 2)))
})

test_that("slaving is direction-free: relation holds, drive read per-instance", {
  # fast -> slow: slow eq driven by fast variable, fast eq ignores y
  sys_fs <- tv_system(
    f = function(x, y) -x + 1,          # dg/dx != 0, df/dy == 0
    g = function(x, y) x - y,
    tau1 = 1, tau2 = 1000
  )
  d <- drive_direction(sys_fs, x0 = 1, y0 = 0.5)
  expect_equal(d$class, "fast_drives_slow")
  expect_true(slaving_holds(sys_fs))   # slaving holds regardless of direction

  # slow -> fast: fast eq driven by slow variable, slow eq ignores x
  sys_sf <- tv_system(
    f = function(x, y) y - x,
    g = function(x, y) -y,
    tau1 = 1, tau2 = 1000
  )
  d2 <- drive_direction(sys_sf, x0 = 0.5, y0 = 1)
  expect_equal(d2$class, "slow_drives_fast")

  # mutual coupling -> mutual (equal normalized rates: tau1 = tau2)
  sys_m <- tv_system(
    f = function(x, y) y - x,
    g = function(x, y) x - y,
    tau1 = 1, tau2 = 1
  )
  expect_equal(drive_direction(sys_m, 1, 1)$class, "mutual")
})

test_that("coupling matrix is numerically correct", {
  sys <- tv_system(
    f = function(x, y) 3 * x + 5 * y,
    g = function(x, y) 7 * x + 11 * y,
    tau1 = 1, tau2 = 2
  )
  jac <- coupling_matrix(sys, x0 = 0, y0 = 0)
  expect_equal(jac["f", "x"], 3, tolerance = 1e-4)
  expect_equal(jac["f", "y"], 5, tolerance = 1e-4)
  expect_equal(jac["g", "x"], 7, tolerance = 1e-4)
  expect_equal(jac["g", "y"], 11, tolerance = 1e-4)
})

test_that("adiabatic elimination: slow manifold and effective dynamics", {
  # f = -x + y  ->  x*(y) = y ;  g = x - y^2  ->  G(y) = y - y^2
  sys <- tv_system(
    f = function(x, y) -x + y,
    g = function(x, y) x - y^2,
    tau1 = 0.01, tau2 = 1
  )
  ys <- seq(-1, 1, length.out = 101)
  xstar <- slow_manifold(sys, ys)
  expect_equal(xstar, ys, tolerance = 1e-6)
  G <- effective_dynamics(sys, ys)
  expect_equal(G, ys - ys^2, tolerance = 1e-6)
})

test_that("landscape curvature gives k2 = kappa / tau2", {
  # L(y) = (y - 0.5)^2  ->  kappa = 2 at y* = 0.5
  ys <- seq(-1, 2, length.out = 1001)
  L <- (ys - 0.5)^2
  kappa <- curvature(ys, L, ystar = 0.5)
  expect_equal(kappa, 2, tolerance = 1e-3)
  k2 <- k2_from_curvature(kappa, tau2 = 100)
  expect_equal(k2, 0.02, tolerance = 1e-3)
})

test_that("bi-exponential relaxation matches the two-channel rate law", {
  k1 <- 1; k2 <- 0.01; rho1 <- 0; rho2 <- 1
  rho_inf <- rate_law_equilibrium(k1, k2, rho1, rho2)
  # amplitudes: start at rho(0) = rho1 + rho2 style split
  A1 <- 0.5; A2 <- 0.5
  # anti-pattern fix: horizon must reach the SLOW rate (1/k2 = 100 here).
  # t = 1000 leaves e^{-10} ~ 4.5e-5 above the asymptote, which fails the
  # relative tolerance when rho_inf is small. Same lesson as hedgehog P9.
  ts <- seq(0, 50 / min(k1, k2), by = 1)
  rho <- biexp_relaxation(ts, rho_inf, A1, A2, k1, k2)
  expect_true(all(diff(rho) <= 0))          # monotone relaxation
  expect_equal(rho[length(rho)], rho_inf, tolerance = 1e-6)  # asymptote
  # rate law consistency at a point
  drho <- rate_law(rho[1], k1, k2, rho1, rho2)
  expect_lt(drho, 0)
})

test_that("integration window: flytrap two-channel 29.5 s, one-channel 24 s", {
  tau1 <- 8; a <- 0.952; theta <- 1
  w2 <- integration_window(tau1, a, theta, n = 2)
  w1 <- integration_window(tau1, a, theta, n = 1)
  expect_equal(w2, 29.5, tolerance = 0.6)   # pipeline code read-point
  expect_equal(w1, 24.0, tolerance = 1.0)   # stated derivation read-point
  # both inside the published bracket — the honest consistency statement
  expect_true(w2 >= 20 && w2 <= 30)
  expect_true(w1 >= 20 && w1 <= 30)
})

test_that("window narrows monotonically under control-parameter sweep", {
  sweep <- window_sweep(tau1 = 8, a0 = 0.952, theta = 1, lambdas = seq(0, 0.45, by = 0.05))
  expect_true(all(diff(sweep$window) <= 0))
  # anti-pattern fix: strict inequality vs the first element compared index 1
  # to itself (w[1] < w[1] is always FALSE) — the assertion could never pass.
  # Use a fuzzy strict bound on the diffs instead.
  expect_true(all(diff(sweep$window) < -1e-12 * pmax(1, abs(sweep$window[-1]))))
})

test_that("critical slowing: slow rate vanishes at lambda_c", {
  expect_equal(critical_slowing_rate(k2 = 0.01, lambda = 0.5, lambda_c = 1), 0.005)
  expect_equal(critical_slowing_rate(k2 = 0.01, lambda = 0.99, lambda_c = 1), 1e-4)
  ratio <- critical_ratio(k1 = 1, k2 = 0.01, lambda = 0.99, lambda_c = 1)
  expect_equal(ratio, 1 / 1e-4, tolerance = 1e-9)
})

test_that("flytrap instantiation: all derived values land on published anchors", {
  ft <- flytrap_instantiation()
  expect_true(ft$slaving)
  # anti-pattern fix: 3.08e-5 is a rounded golden constant; the derived value
  # is exactly tau1/tau2 = 8/(3*86400) = 3.08642e-5. Assert the analytic
  # identity (relative tolerance now has honest meaning), keep the published
  # anchor as a bracket check.
  expect_equal(ft$epsilon, 8 / (3 * 86400), tolerance = 1e-7)
  expect_true(ft$epsilon < 3.1e-5 && ft$epsilon > 3.0e-5)  # published anchor bracket
  expect_equal(ft$k1, 0.125, tolerance = 1e-6)
  expect_true(ft$window_in_bracket)
  expect_true(ft$window_two_channel > ft$window_one_channel)
})
