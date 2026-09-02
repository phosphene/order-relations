# Order-parameter formation — the inbound half of g (inventory row 11)
#
# Claim under test: "inbound" events (C4 convergence, Cambrian radiation,
# exaptation) are not fits to the relaxation law — they are the alpha > 0
# regime of the same amplitude equation. The asymmetry is a regime fact,
# not a missing law.

test_that("formation: growth coefficient crosses zero at lambda_c", {
  expect_equal(growth_coefficient(0.01, 0.5, 1), -0.005)   # relaxation regime
  expect_equal(growth_coefficient(0.01, 1, 1), 0)           # critical point
  expect_equal(growth_coefficient(0.01, 2, 1), 0.01)        # formation regime
})

test_that("formation: equilibria — one stable point below, two above", {
  expect_equal(order_parameter_equilibria(-1, 1), 0)
  eq <- order_parameter_equilibria(4, 1)
  expect_equal(sort(eq), c(-2, 2))
})

test_that("formation: growth is logistic-shaped, saturates at sqrt(alpha/beta)", {
  y <- order_parameter_growth(seq(0, 200, by = 0.5), y0 = 0.01, alpha = 0.1, beta = 1)
  expect_true(all(diff(y) > 0))                       # monotone gain
  expect_lt(abs(tail(y, 1) - sqrt(0.1)), 1e-3)        # saturates at y_inf
  # inflection: fastest growth near the middle of the S, not at start/end
  d <- diff(y)
  expect_gt(max(d), d[1])                             # accelerating at first
  expect_gt(max(d), tail(d, 1))                       # decelerating at end
})

test_that("formation: critical fluctuations diverge at lambda_c", {
  f_far <- critical_fluctuations(1, 0.01, 0.5, 1)     # lambda half of critical
  f_near <- critical_fluctuations(1, 0.01, 0.99, 1)   # 50x closer
  expect_gt(f_near, f_far * 20)                       # variance blows up
  expect_equal(critical_fluctuations(1, 0.01, 1, 1), Inf)
})

test_that("formation: regime classification", {
  expect_equal(g_regime(0.5, 1), "relaxation")
  expect_equal(g_regime(1.2, 1), "formation")
  expect_equal(g_regime(1.0, 1), "critical")
})

test_that("formation: inbound-as-relaxation — approach to new attractor is exponential", {
  # the same law as loss, read toward the other fixed point:
  # log(distance to the new attractor) decays linearly in time
  t_all <- seq(0, 200, by = 1)
  y <- order_parameter_growth(t_all, y0 = 0.05, alpha = 0.2, beta = 1)
  y_inf <- sqrt(0.2)
  dist <- y_inf - y
  # fit in the tail where the linearization holds (u = C*exp(-2*alpha*t) << 1)
  tail_idx <- which(dist < 0.05 * y_inf & dist > 1e-9)
  logdist <- log(dist[tail_idx])
  tt <- t_all[tail_idx]
  fit <- stats::lm(logdist ~ tt)
  expect_gt(stats::coef(fit)[2], -0.45)  # slope = -2*alpha = -0.4
  expect_lt(stats::coef(fit)[2], -0.35)
})
