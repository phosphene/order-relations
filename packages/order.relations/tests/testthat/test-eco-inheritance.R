# Eco-inheritance primitives — Laland/Odling-Smee/Feldman 1999 verification
#
# Battery V1-V7 ported from the workspace verification
# (work/feelingflowingbot/nct-math-review/laland1999-verification/, green
# 2026-09-07). The 1999 Table 1 fitness matrix is an INSTANTIATION:
# biology enters here, not in eco_inheritance.R.

source_inc <- function() {
  # lightweight source of the primitives for standalone runs (package
  # tests will use namespace); harmless under test_local
  invisible(NULL)
}

# ---- the 1999 Table 1 fitness matrix (verified verbatim vs primary) ----
w1999 <- function(R, a1 = 1, a2 = 1, b1 = 1, b2 = 1, eps = 0.1) {
  rbind(
    c(a1 * a2 + eps * R,       a2 + eps * R,       b1 * a2 + eps * R),
    c(a1 + eps,                1 + eps,            b1 + eps),
    c(a1 * b2 + eps * (1 - R), b2 + eps * (1 - R), b1 * b2 + eps * (1 - R))
  )
}

test_that("resource_map: constraints and increment/decrement regimes", {
  # increment regime at p = 0: pure independent persistence + renewal
  expect_equal(resource_map(0.5, 0, l1 = 0.6, l2 = 0.3, l3 = 0.1), 0.4)
  # decrement regime
  # l1*R*(1-g*p) + l3 = 0.5*0.5*0.6 + 0.1 = 0.25
  expect_equal(resource_map(0.5, 1, l1 = 0.5, l2 = 0, l3 = 0.1, g = 0.4,
                            regime = "decrement"), 0.25)
  # constraint checking
  expect_error(resource_map(0.5, 0.5, l1 = 1.2, l2 = 0, l3 = 0), "l1")
  expect_error(resource_map(0.5, 0.5, l1 = 0.9, l2 = 0.2, l3 = 0.1), "l1")
})

test_that("V5: analytic resource equilibrium (Eq. 3a) matches iteration", {
  for (pp in c(0, 0.25, 0.5, 1)) {
    Wf <- function(R) w1999(R, eps = 0.3)  # a2 = b2 = 1: no external selection at recipient
    # LD=0 seed so p is invariant (hitchhiking absent by construction)
    x0 <- c(pp / 2, pp / 2, (1 - pp) / 2, (1 - pp) / 2)
    out <- two_locus_run(x0, 0, Wf, r = 0.5,
                         map_params = list(l1 = 0.6, l2 = 0.25, l3 = 0.1,
                                           g = 0, regime = "increment"),
                         T_max = 5000, tol = 1e-12)
    expect_equal(out$R, resource_equilibrium(pp, l1 = 0.6, l2 = 0.25, l3 = 0.1),
                 tolerance = 1e-6)
    expect_equal(out$p, pp, tolerance = 1e-9)  # V4a: p invariance under A-only selection
  }
})

test_that("V6: primacy weights reproduce the 1996 weighted-average model", {
  n <- 5
  w <- primacy_weights(n)
  # constant p: R converges to p (weighted average of a constant)
  Wf <- function(R) w1999(R, eps = 0.3)
  out <- two_locus_run(c(0.3, 0.3, 0.2, 0.2), 0, Wf,
                       map_params = c(w, list(g = 0, regime = "increment")),
                       T_max = 5000, tol = 1e-12)
  expect_equal(out$R, 0.6, tolerance = 1e-6)
})

test_that("V7: polymorphic equilibrium line q_hat = R (eps > 0)", {
  Wf <- function(R) w1999(R, eps = 0.3)  # neutral modifier, frequency-dependent recipient
  out <- two_locus_run(c(0.35, 0.15, 0.3, 0.2), 0.2, Wf,
                       map_params = list(l1 = 0.6, l2 = 0.25, l3 = 0.1,
                                         g = 0, regime = "increment"),
                       T_max = 30000, tol = 1e-14)
  expect_equal(out$q, out$R, tolerance = 1e-6)
})

test_that("V3: neutral LD decays as (1-r)^t", {
  W <- matrix(1, 3, 3)  # fully neutral
  x0 <- c(0.3, 0.2, 0.2, 0.3)
  D0 <- x0[1] * x0[4] - x0[2] * x0[3]
  x <- x0
  for (i in 1:5) x <- two_locus_step(x, 0.5, W, r = 0.3)$x
  expect_equal(x[1] * x[4] - x[2] * x[3], D0 * (1 - 0.3)^5, tolerance = 1e-12)
})

test_that("V2: eps = 0 reduces to single-locus viability selection", {
  a2 <- 1.1; b2 <- 0.9
  # E-neutral instantiation: a1 = b1 = 1, eps = 0 -> R is a spectator
  Wf <- function(R) w1999(R, a2 = 1.1, b2 = 0.9, eps = 0)
  out <- two_locus_run(c(0.7, 0.1, 0.1, 0.1), 0.5, Wf, T_max = 400, tol = 1e-16)
  # single-locus reference recursion on the recipient locus
  q <- out$q; q0 <- 0.8; qref <- c(q0); q <- q0
  for (i in 1:399) {
    Wq <- q^2 * a2 + 2 * q * (1 - q) + (1 - q)^2 * 0.9
    q <- (q^2 * a2 + q * (1 - q)) / Wq
    qref <- c(qref, q)
  }
  expect_equal(out$q, tail(qref, 1), tolerance = 1e-9)
})

test_that("V1: normalization and range invariants hold through runs", {
  Wf <- function(R) w1999(R, a1 = 1.05, b1 = 0.95, eps = 0.3)
  out <- two_locus_run(c(0.25, 0.25, 0.25, 0.25), 0.4, Wf, T_max = 300,
                       return_traj = TRUE)
  expect_true(all(abs(rowSums(out$traj) - 1) < 1e-12))
  expect_true(out$R > 0 && out$R < 1)
})

test_that("hitchhiking finding (V4b): p moves under LD != 0, not under LD = 0", {
  # LD = 0: p exactly invariant (covered above). LD != 0: E-locus allele
  # hitchhikes on the selected recipient background — documented finding.
  Wf <- function(R) w1999(R, a2 = 1.1, b2 = 0.9, eps = 0.25)
  out <- two_locus_run(c(0.4, 0.2, 0.3, 0.1), 0.3, Wf, T_max = 800)
  expect_false(abs(out$p - 0.6) < 1e-9)
  # magnitude stays tiny over 800 generations
  expect_lt(abs(out$p - 0.6), 0.01)
})
