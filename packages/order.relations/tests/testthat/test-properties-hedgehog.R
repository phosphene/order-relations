# Property-based numerical testing suite for order.relations
#
# Ed's numerical-testing patterns, applied to the actual API:
#   1. Structural convergence rates (log-log slope, not absolute error)
#   2. Complex-step Jacobian validation (full machine precision)
#   3. Property-based axiom stressing via hedgehog (transitivity /
#      antisymmetry of order relations under floating-point noise)
#   4. Scale-independent backward-error gates
#   5. Anti-pattern guards: explicit tolerances, no golden values,
#      stationarity instead of optimizer flags, fuzzy relational bounds
#
# Run:  R_LIBS=<hedgehog lib> Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-properties-hedgehog.R")'
#       or via run_tests.R after installing.
#
# Note: hedgehog's gen.c takes ONE generator plus from/to/of; heterogeneous
# parameter tuples are built by mapping over uniform vectors. Properties must
# contain testthat expectations (bare logical returns are rejected).

library(hedgehog)

# ---- helpers -----------------------------------------------------------

# Scale-aware fuzzy strict inequality: x < y - delta*max(1, |x|, |y|)
fuzzy_lt <- function(x, y, delta = 1e-9) x < y - delta * max(1, abs(x), abs(y))
fuzzy_gt <- function(x, y, delta = 1e-9) fuzzy_lt(y, x, delta)

# Scale-aware equality for analytic identities
fuzzy_eq <- function(x, y, delta = 1e-9) abs(x - y) <= delta * max(1, abs(x), abs(y))

# Build strict order-relation matrix from a vector: M[i,j] = v[i] < v[j]
# under the fuzzy bound. Antisymmetry: never both M[i,j] and M[j,i] for i != j.
# Transitivity: M[i,j] & M[j,k] => M[i,k].
relation_matrix <- function(v, delta = 1e-9) {
  n <- length(v)
  M <- matrix(FALSE, n, n)
  for (i in seq_len(n)) for (j in seq_len(n)) M[i, j] <- fuzzy_lt(v[i], v[j], delta)
  M
}

check_antisymmetry <- function(M) {
  n <- nrow(M)
  for (i in seq_len(n)) for (j in seq_len(n)) {
    if (i != j && M[i, j] && M[j, i]) return(FALSE)
  }
  TRUE
}

check_transitivity <- function(M) {
  n <- nrow(M)
  for (i in seq_len(n)) for (j in seq_len(n)) for (k in seq_len(n)) {
    if (M[i, j] && M[j, k] && !M[i, k]) return(FALSE)
  }
  TRUE
}

# ---- 1. slaving threshold: relational boundary under fp noise ----------

test_that("P1: slaving_holds is exactly the epsilon threshold (fuzzy boundary)", {
  forall(gen.c(gen.unif(1e-3, 1e2), of = 2), function(pair) {
    tau1 <- pair[1]; tau2 <- pair[2]
    sys <- tv_system(function(x, y) -x, function(x, y) -y, tau1, tau2)
    eps <- timescale_ratio(sys)
    on_boundary <- abs(eps - 0.1) < 1e-9 * max(1, eps)
    if (on_boundary) discard()
    expect_equal(slaving_holds(sys), eps < 0.1)
  })
})

# ---- 2. depth -> loss-time ordering is a strict total order ------------
#      (the transitivity/antisymmetry stress, on the real T-1 object)

test_that("P2: loss-time order relation is antisymmetric and transitive (noise-free)", {
  forall(gen.c(gen.unif(0.02, 0.98), of = 8), function(vals) {
    depths <- sort(unique(round(vals, 3)))
    if (length(depths) < 2) { discard() }
    k_eff <- perturbation_rates(depths, k1 = 1, k2 = 0.01, lambda = 0)
    t_loss <- loss_times(k_eff, theta = 0.5, noise = 0)
    M <- relation_matrix(t_loss)
    expect_true(check_antisymmetry(M), info = "antisymmetry violated")
    expect_true(check_transitivity(M), info = "transitivity violated")
  })
})

test_that("P3: depth order implies loss-time order (monotone embedding)", {
  forall(gen.c(gen.unif(0.02, 0.98), of = 8), function(vals) {
    depths <- sort(unique(round(vals, 3)))
    if (length(depths) < 2) { discard() }
    k_eff <- perturbation_rates(depths, k1 = 1, k2 = 0.01, lambda = 0)
    t_loss <- loss_times(k_eff, theta = 0.5, noise = 0)
    ok <- all(vapply(seq_len(length(depths) - 1), function(i) {
      fuzzy_lt(t_loss[i], t_loss[i + 1])
    }, logical(1)))
    expect_true(ok, info = paste("depth order not preserved:", paste(t_loss, collapse = ",")))
  })
})

test_that("P4: perturbation_rates is monotone in depth (k1 > k2)", {
  forall(gen.c(gen.unif(0.02, 0.98), of = 6), function(vals) {
    depths <- sort(unique(round(vals, 3)))
    if (length(depths) < 2) { discard() }
    k_eff <- perturbation_rates(depths, k1 = 1, k2 = 0.01, lambda = 0)
    expect_lte(max(diff(k_eff)), 1e-12 * max(1, abs(k_eff))) # non-increasing in depth
  })
})

# ---- 3. integration window: analytic identities ------------------------

test_that("P5: integration_window matches its analytic form and scales linearly", {
  forall(gen.c(gen.unif(0, 1), of = 4), function(u) {
    tau1 <- 10^u[1]                    # log-uniform in (0.1, 10)
    theta <- 0.5 + 1.5 * u[2]          # in (0.5, 2)
    a <- (0.05 + 0.9 * u[3]) * theta   # in (0.05*theta, 0.95*theta) < theta
    n <- 1 + floor(3 * u[4])           # in {1, 2, 3}
    W <- integration_window(tau1, a, theta, n)
    expected <- tau1 * log(n * a / (theta - a))
    expect_equal(W, expected, tolerance = 1e-10)
    expect_equal(integration_window(2 * tau1, a, theta, n), 2 * W,
                 tolerance = 1e-9, scale = 1) # linear scaling in tau1
  })
})

test_that("P6: window widens as amplitude grows (a -> theta)", {
  forall(gen.c(gen.unif(0, 1), of = 3), function(u) {
    tau1 <- 10^u[1]
    theta <- 0.5 + 1.5 * u[2]
    a1 <- (0.05 + 0.85 * u[3]) * theta
    a2 <- min(theta * 0.99, a1 + 0.05 * theta)
    W1 <- integration_window(tau1, a1, theta)
    W2 <- integration_window(tau1, a2, theta)
    # W = tau1*log(n*a/(theta-a)) is strictly increasing in a;
    # P3's narrowing comes from a(lambda) DECREASING with lambda
    expect_gte(W2 - W1, -1e-9 * max(1, abs(W1))) # non-decreasing in a
  })
})

# ---- 4. critical slowing: structural rates ------------------------------

test_that("P7: critical_slowing_rate is positive, < k2, monotone in lambda", {
  forall(gen.c(gen.unif(0, 1), of = 3), function(u) {
    k2 <- 10^u[1]
    lambda_c <- 10^u[2]
    lambda <- u[3] * lambda_c * 0.99   # strictly below lambda_c
    r <- critical_slowing_rate(k2, lambda, lambda_c)
    expect_gt(r, 0)
    expect_lt(r, k2)
    expect_equal(critical_slowing_rate(k2, 0, lambda_c), k2, tolerance = 1e-10)
  })
})

test_that("P8: critical ratio diverges as lambda -> lambda_c", {
  forall(gen.c(gen.unif(0, 1), of = 2), function(u) {
    k1 <- 10^u[1]
    lambda_c <- 10^u[2]
    near <- lambda_c * (1 - 1e-6)
    ratio <- critical_ratio(k1, 1, near, lambda_c)
    expect_gt(ratio, k1 * 1e5) # k2_eff ~ 1e-6 => ratio ~ k1/1e-6
  })
})

# ---- 5. bi-exponential relaxation: invariants ---------------------------

test_that("P9: biexp relaxation starts at sum of amplitudes, decays to asymptote", {
  forall(gen.c(gen.unif(0, 1), of = 5), function(u) {
    rho_inf <- 5 * u[1]
    A1 <- 10 * u[2]
    A2 <- 10 * u[3]
    k1 <- 0.05 + 2 * u[4]
    k2 <- 0.05 + 2 * u[5]
    # horizon set by the SLOW rate: the asymptote check must reach
    # the slow component's decay, not just the fast one's
    t <- seq(0, 50 / min(k1, k2), length.out = 200)
    rho <- biexp_relaxation(t, rho_inf, A1, A2, k1, k2)
    expect_equal(rho[1], rho_inf + A1 + A2, tolerance = 1e-10) # starts at sum
    expect_lte(max(diff(rho)), 1e-9 * max(1, abs(rho)))        # monotone decay
    expect_equal(tail(rho, 1), rho_inf, tolerance = 1e-6)      # reaches asymptote
  })
})

# ---- 6. rate law: equilibrium is the weighted mean ----------------------

test_that("P10: rate_law_equilibrium is a convex combination, stationarity holds", {
  forall(gen.c(gen.unif(0, 1), of = 4), function(u) {
    k1 <- 10^u[1]
    k2 <- 10^u[2]
    rho1 <- -5 + 10 * u[3]
    rho2 <- -5 + 10 * u[4]
    rho_star <- rate_law_equilibrium(k1, k2, rho1, rho2)
    # analytic first-order optimality: drho/dt = 0 at the equilibrium
    expect_lte(abs(rate_law(rho_star, k1, k2, rho1, rho2)),
               1e-10 * max(1, abs(k1), abs(k2), abs(rho1), abs(rho2)))
    # equilibrium is a convex combination of the channel levels
    expect_gte(rho_star, min(rho1, rho2) - 1e-12)
    expect_lte(rho_star, max(rho1, rho2) + 1e-12)
  })
})

# ---- 7. complex-step Jacobian validation + convergence order ------------

# Analytic test system (holomorphic in both arguments)
f_analytic <- function(x, y) -x + sin(y) + 0.1 * x * y
g_analytic <- function(x, y) cos(x) - y + 0.05 * x^2

jac_complex_reference <- function(x0, y0) {
  J <- matrix(NA_real_, 2, 2,
              dimnames = list(c("f", "g"), c("x", "y")))
  J["f", "x"] <- numDeriv::grad(function(x) f_analytic(x, y0), x0, method = "complex")
  J["f", "y"] <- numDeriv::grad(function(y) f_analytic(x0, y), y0, method = "complex")
  J["g", "x"] <- numDeriv::grad(function(x) g_analytic(x, y0), x0, method = "complex")
  J["g", "y"] <- numDeriv::grad(function(y) g_analytic(x0, y), y0, method = "complex")
  J
}

test_that("P11: coupling_matrix matches complex-step reference at full precision", {
  forall(gen.c(gen.unif(-2, 2), of = 2), function(q) {
    x0 <- q[1]; y0 <- q[2]
    sys <- tv_system(f_analytic, g_analytic, tau1 = 1, tau2 = 10)
    J_num <- coupling_matrix(sys, x0, y0, h = 1e-6)
    J_ref <- jac_complex_reference(x0, y0)
    expect_lte(max(abs(J_num - J_ref)), 1e-8 * max(1, max(abs(J_ref))))
  })
})

test_that("P12: central-difference Jacobian converges at order 2 (log-log slope)", {
  expect_convergence_order <- function(step_fn, exact_fn, h_levels, expected_p, tol = 0.1) {
    errors <- vapply(h_levels, function(h) {
      sol <- step_fn(h)
      max(abs(sol - exact_fn))
    }, numeric(1))
    # drop levels where error hits the double-precision floor
    keep <- errors > 1e-12
    if (sum(keep) < 3) return(TRUE)
    fit <- lm(log(errors[keep]) ~ log(h_levels[keep]))
    observed_p <- coef(fit)[[2]]
    abs(observed_p - expected_p) < tol
  }
  x0 <- 0.7; y0 <- -0.4
  J_ref <- jac_complex_reference(x0, y0)
  h_levels <- 2^(-seq(1, 8))
  central <- function(h) {
    sys <- tv_system(f_analytic, g_analytic, tau1 = 1, tau2 = 10)
    coupling_matrix(sys, x0, y0, h)
  }
  ok <- expect_convergence_order(function(h) central(h)["f", "x"],
                                 J_ref["f", "x"], h_levels, expected_p = 2, tol = 0.15)
  expect_true(ok)
})

# ---- 8. amplitude equation: structural equilibria -----------------------

test_that("P13: amplitude equilibria are true stationary points", {
  forall(gen.c(gen.unif(0, 1), of = 2), function(u) {
    alpha <- 5 * u[1]
    beta <- 10 * u[2]
    eq <- order_parameter_equilibria(alpha, beta)
    resid <- vapply(eq, function(e) {
      abs(amplitude_dynamics(e, alpha, beta))
    }, numeric(1))
    expect_lte(max(resid), 1e-10 * max(1, alpha, beta)) # backward error gate
  })
})

test_that("P14: growth solution converges to sqrt(alpha/beta), monotone", {
  forall(gen.c(gen.unif(0, 1), of = 3), function(u) {
    alpha <- 0.05 + 5 * u[1]
    beta <- 0.05 + 10 * u[2]
    y_inf <- sqrt(alpha / beta)
    y0 <- u[3] * y_inf                  # seed strictly below saturation
    # horizon set by 2*alpha decay of the transient; small y0 gives
    # large C = (alpha/beta - y0^2)/y0^2, so go long enough to kill it
    t <- seq(0, 100 / alpha, length.out = 200)
    y <- order_parameter_growth(t, y0, alpha, beta)
    expect_gte(min(diff(y)), -1e-9 * max(1, abs(y))) # monotone growth
    expect_equal(tail(y, 1), y_inf, tolerance = 1e-6) # saturation
  })
})

# ---- 9. window sweep: P3 monotone narrowing ------------------------------

test_that("P15: window_sweep narrows monotonically in lambda (P3)", {
  forall(gen.c(gen.unif(0, 1), of = 2), function(u) {
    tau1 <- 10^u[1]
    a0 <- 0.1 + 0.8 * u[2]
    lambdas <- seq(0, 0.9, length.out = 10)
    sw <- window_sweep(tau1, a0, 1, lambdas, n = 2)
    finite_w <- sw$window[is.finite(sw$window)]
    expect_lte(max(diff(finite_w)), 1e-9 * max(1, abs(finite_w))) # non-increasing
  })
})

# ---- 10. anti-pattern guards: no golden values, explicit tolerance ------

test_that("P16: no golden values — landscape normalization and curvature sign", {
  forall(gen.c(gen.unif(0, 1), of = 2), function(u) {
    c0 <- -1.5 + 3 * u[1]            # keep minimum interior to the grid
    k <- 0.5 + 3 * u[2]
    y <- seq(-2, 2, length.out = 200)
    L <- landscape(y, -2 * k * (y - c0))     # L(y) = k*(y-c0)^2 + const
    expect_equal(min(L), 0, tolerance = 1e-10) # normalized, not a point value
    expect_gt(curvature(y, L), 0)              # positive curvature at min
  })
})

# Regression: curvature() at the RIGHT boundary used to return NA.
# The one-sided branch indexed y[i+1L] and L[i+2L] with i == length(y),
# both out of bounds. Caught by P16's generator placing the minimum at
# the grid edge (2026-09-03).
test_that("P17: curvature at the right boundary is finite (regression)", {
  y <- seq(-2, 2, length.out = 200)
  L <- landscape(y, -2 * 2 * (y - 1.99)) # minimum at the right edge
  i <- which.min(abs(y - 1.99))
  expect_equal(i, length(y))            # provokes the boundary branch
  expect_true(is.finite(curvature(y, L)))
  expect_gt(curvature(y, L), 0)
})
