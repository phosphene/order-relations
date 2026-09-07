# Eco-inheritance primitives (genealogy tier 2 — Laland, Odling-Smee &
# Feldman 1999, PNAS 96:10242-10247, DOI 10.1073/pnas.96.18.10242)
#
# Design law compliance: every object here is stateable with zero
# biological nouns. The two-locus machinery is stated as a coupled
# recursion between a MODIFIER frequency p and an ENVIRONMENTAL STATE R,
# with a CALLER-SUPPLIED 3x3 fitness matrix. The niche-construction
# instantiation (loci E/A, resource R, the 1999 Table 1) enters only in
# tests, the literate genealogy unit (docs/genealogy/G-10.md), and the
# battery script (scripts/genealogy/g10_laland1999.R).
#
# Verified 2026-09-07, topic 65385: V1-V7 battery green (analytic
# equilibria to 4.4e-16). Findings log in workspace
# work/feelingflowingbot/nct-math-review/laland1999-verification/.

#' Environmental-state recursion (coupled feedback map)
#'
#' Discrete-generation map for an environmental state R modified by a
#' population-level modifier frequency p, with independent decay,
#' independent renewal, and modifier-driven increment/decrement
#' (Laland et al. 1999, Eq. 1, four cases collapsed to two):
#'
#'   increment regime: R_t = l1*R_{t-1} + l2*p_t + l3
#'   decrement regime: R_t = l1*R_{t-1}*(1 - g*p_t) + l3
#'
#' Constraints (as published): 0 < l1, l2, l3, g < 1; l1 + l2 + l3 <= 1.
#'
#' @param R numeric: current environmental state in (0,1)
#' @param p numeric: modifier frequency in [0,1]
#' @param l1 numeric: independent persistence (1 = no depletion)
#' @param l2 numeric: modifier increment coefficient (0 = none)
#' @param l3 numeric: independent renewal
#' @param g numeric: modifier decrement coefficient (ignored when regime = "increment")
#' @param regime character: "increment" or "decrement"
#' @return numeric: next environmental state (clipped to (0,1) tolerance)
#' @export
resource_map <- function(R, p, l1, l2, l3, g = 0, regime = c("increment", "decrement")) {
  regime <- match.arg(regime)
  stopifnot(R >= 0, R <= 1, p >= 0, p <= 1)
  stopifnot(l1 > 0, l1 < 1, l2 >= 0, l3 >= 0, l1 + l2 + l3 <= 1 + 1e-12)
  out <- if (regime == "increment") l1 * R + l2 * p + l3
         else                       l1 * R * (1 - g * p) + l3
  min(max(out, 0), 1)
}

#' Analytic equilibrium of the environmental state at fixed p
#'
#' Laland et al. 1999, Eqs. 3a/3b. Verified against iteration to 1e-6+.
#'
#' @inheritParams resource_map
#' @return numeric: equilibrium environmental state
#' @export
resource_equilibrium <- function(p, l1, l2, l3, g = 0,
                                 regime = c("increment", "decrement")) {
  regime <- match.arg(regime)
  if (regime == "increment") (l2 * p + l3) / (1 - l1)
  else                       l3 / (1 - l1 * (1 - g * p))
}

#' Geometric (primacy) weighting identity check parameters
#'
#' The 1996 founding model computes R as a weighted average of the
#' previous n generations of modifier action. The 1999 map reproduces
#' exactly that weighting under l1 = 1 - 1/n, l2 = 1/n, l3 = 0
#' (primacy: older generations decay geometrically). Returns the
#' parameter set for a given memory length n.
#'
#' @param n integer >= 1: memory length in generations
#' @return list(l1, l2, l3) for use with resource_map(regime="increment")
#' @export
primacy_weights <- function(n) {
  stopifnot(is.numeric(n), length(n) == 1, n >= 1)
  list(l1 = 1 - 1 / n, l2 = 1 / n, l3 = 0)
}

#' One generation of the coupled two-locus recursion
#'
#' Four haplotypes x = (x1..x4) at frequencies summing to 1; a 3x3
#' fitness matrix W (rows: state at the modifier-coupled site in the
#' caller's mapping; cols: modifier-locus genotype) supplied by the
#' caller. Random mating, viability selection, recombination rate r.
#'
#' Standard gametic recursions: the caller supplies W indexed so that
#' haplotype-pair -> (W row, W col) is resolved by `pair_map()`.
#'
#' @param x numeric(4): haplotype frequencies (sum = 1)
#' @param R numeric: environmental state for this generation's selection
#' @param W numeric 3x3 matrix: genotype fitnesses (see pair_map)
#' @param r numeric: recombination rate in [0, 0.5]
#' @return list(x = next haplotype freqs, W_bar = mean fitness,
#'              p = modifier frequency, D = linkage disequilibrium)
#' @export
pair_map <- function() {
  # rows = recipient-locus genotype (1..3), cols = modifier-locus genotype
  # haplotypes: 1 = coupling-A, 2 = coupling-a, 3 = repulsion-A, 4 = repulsion-a
  list(
    "11" = c(1, 1), "12" = c(2, 1), "13" = c(1, 2), "14" = c(2, 2),
    "22" = c(3, 1), "23" = c(2, 2), "24" = c(3, 2),
    "33" = c(1, 3), "34" = c(2, 3), "44" = c(3, 3)
  )
}

#' @rdname two_locus_step
#' @export
two_locus_step <- function(x, R, W, r = 0.5) {
  stopifnot(length(x) == 4, abs(sum(x) - 1) < 1e-12, all(x >= 0))
  stopifnot(all(dim(W) == c(3, 3)), r >= 0, r <= 0.5)
  pm <- pair_map()
  pairs <- c("11","12","13","14","22","23","24","33","34","44")
  # zygote frequencies (unordered diploid pairs from gametes)
  gfreq <- c(x[1]^2, 2 * x[1] * x[2], 2 * x[1] * x[3], 2 * x[1] * x[4],
             x[2]^2, 2 * x[2] * x[3], 2 * x[2] * x[4],
             x[3]^2, 2 * x[3] * x[4], x[4]^2)
  wvec <- vapply(pairs, function(pp) {
    g <- pm[[pp]]; W[g[1], g[2]]
  }, numeric(1))
  Wbar <- sum(gfreq * wvec)
  stopifnot(Wbar > 0)
  surv <- gfreq * wvec / Wbar
  # gametogenesis with recombination
  split <- function(pair) {
    switch(pair,
      "11" = c(1, 0, 0, 0), "22" = c(0, 1, 0, 0),
      "33" = c(0, 0, 1, 0), "44" = c(0, 0, 0, 1),
      "12" = c(0.5, 0.5, 0, 0), "34" = c(0, 0, 0.5, 0.5),
      "13" = c(0.5, 0, 0.5, 0), "24" = c(0, 0.5, 0, 0.5),
      # double heterozygotes: coupling vs repulsion phase
      "14" = c((1 - r) / 2, r / 2, r / 2, (1 - r) / 2),
      "23" = c(r / 2, (1 - r) / 2, (1 - r) / 2, r / 2))
  }
  xp <- rep(0, 4)
  for (k in seq_along(pairs)) xp <- xp + surv[k] * split(pairs[k])
  xp <- xp / sum(xp)
  list(x = xp, W_bar = Wbar,
       p = xp[1] + xp[2], D = xp[1] * xp[4] - xp[2] * xp[3])
}

#' Run the coupled recursion to convergence or horizon
#'
#' @param x0 numeric(4): initial haplotype frequencies
#' @param R0 numeric: initial environmental state
#' @param W function(R) -> 3x3 matrix, or static 3x3 matrix. Niche
#'   construction is a FEEDBACK: fitness depends on the state. Pass a
#'   function unless the regime truly has no state dependence.
#' @param map_params list(l1, l2, l3, g, regime): resource map parameters
#' @param T_max integer: iteration horizon
#' @param tol numeric: convergence tolerance on max |dx|
#' @param return_traj logical: return full trajectory
#' @return list with x, R, p, q, D, converged, iterations, and optional traj
#' @export
two_locus_run <- function(x0, R0, W, r = 0.5,
                          map_params = list(l1 = 0.6, l2 = 0.25, l3 = 0.1,
                                            g = 0, regime = "increment"),
                          T_max = 2000, tol = 1e-10, return_traj = FALSE) {
  x <- x0 / sum(x0); R <- R0
  Wstat <- if (is.matrix(W)) W else NULL
  if (return_traj) traj <- matrix(NA_real_, T_max, 4)
  conv <- NA_integer_
  for (t in seq_len(T_max)) {
    Wt <- if (is.null(Wstat)) W(R) else Wstat   # fitness tracks the state
    stopifnot(all(dim(Wt) == c(3, 3)))
    s <- two_locus_step(x, R, Wt, r)
    R <- resource_map(R, s$p, l1 = map_params$l1, l2 = map_params$l2,
                      l3 = map_params$l3, g = map_params$g,
                      regime = map_params$regime)
    dx <- max(abs(s$x - x))
    x <- s$x
    if (return_traj) traj[t, ] <- x
    if (!is.na(dx) && dx < tol && is.na(conv)) conv <- t  # record, keep running
  }
  out <- list(x = x, R = R, p = x[1] + x[2], q = x[1] + x[3], D = x[1]*x[4] - x[2]*x[3],
              converged = !is.na(conv), iterations = ifelse(is.na(conv), T_max, conv))
  if (return_traj) out$traj <- traj[seq_len(out$iterations), , drop = FALSE]
  out
}
