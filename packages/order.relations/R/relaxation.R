#' Bi-exponential relaxation (abstraction inventory row 8)
#'
#' The generic two-timescale result: after displacement, the order parameter
#' relaxes as a sum of two exponentials:
#'
#'   rho(t) = rho_inf + A1*exp(-k1*t) + A2*exp(-k2*t)
#'
#' with k1 = 1/tau1 (fast) and k2 = 1/tau2 (slow) when the system is
#' instantiated from a tv_system. Substrate-free: rho is any order
#' parameter, k1/k2 are any two rate constants.
#'
#' @param t numeric vector of times
#' @param rho_inf numeric: asymptote
#' @param A1 numeric: fast amplitude
#' @param A2 numeric: slow amplitude
#' @param k1 numeric > 0: fast rate
#' @param k2 numeric > 0: slow rate
#' @return numeric vector rho(t)
#' @export
biexp_relaxation <- function(t, rho_inf, A1, A2, k1, k2) {
  stopifnot(is.numeric(t))
  stopifnot(k1 > 0, k2 > 0)
  rho_inf + A1 * exp(-k1 * t) + A2 * exp(-k2 * t)
}

#' Rate-law form: drho/dt = -k1*(rho - rho_1) - k2*(rho - rho_2)
#'
#' The two-channel rate law from the exploration document. Each channel
#' pulls rho toward its own level (rho_1 fast, rho_2 slow) at its own
#' rate. Equivalent to biexp_relaxation with rho_inf = (k1*rho_1 +
#' k2*rho_2)/(k1+k2).
#'
#' @param rho numeric
#' @param k1 numeric > 0
#' @param k2 numeric > 0
#' @param rho1 numeric: fast-channel level
#' @param rho2 numeric: slow-channel level
#' @return numeric drho/dt
#' @export
rate_law <- function(rho, k1, k2, rho1, rho2) {
  -k1 * (rho - rho1) - k2 * (rho - rho2)
}

#' Equilibrium of the two-channel rate law
#' @return numeric rho* where drho/dt = 0
#' @export
rate_law_equilibrium <- function(k1, k2, rho1, rho2) {
  (k1 * rho1 + k2 * rho2) / (k1 + k2)
}

#' Integration window W: time for a summed two-channel signal to cross theta
#'
#' The flytrap derivation family. Premise: two channels each deliver
#' amplitude a (decaying with tau1) and the trap fires when the sum
#' reaches threshold theta:
#'
#'   n*a*exp(-t/tau1) >= theta   (n = number of channels)
#'
#' solving to  W = tau1 * ln(n*a / (theta - a)).
#'
#' NOTE (flagged bench discrepancy, 2026-09-02): the tier-2 pipeline's
#' *stated* derivation uses the one-channel premise (n=1), which solves
#' to ~24 s for the flytrap anchors; the code computes the two-channel
#' form (n=2), giving ~29.5 s. Both sit inside the published 20-30 s
#' bracket (Di Palma). This function implements both transparently so the
#' read-point can be re-verified at the bench; the default is the
#' two-channel form used by the pipeline code.
#'
#' @param tau1 numeric > 0: fast timescale
#' @param a numeric > 0: per-channel amplitude (a < theta required)
#' @param theta numeric > 0: threshold
#' @param n numeric: number of channels (1 = stated derivation, 2 = pipeline code)
#' @return numeric W in the same time units as tau1
#' @export
integration_window <- function(tau1, a, theta, n = 2) {
  stopifnot(tau1 > 0, a > 0, theta > 0, n >= 1)
  if (a >= theta) return(Inf) # threshold unreachable
  tau1 * log(n * a / (theta - a))
}

#' Window narrowing under control-parameter sweep (prediction P3)
#'
#' As the control parameter lambda rises (e.g. anesthetic dose), the
#' effective per-channel amplitude drops: a(lambda) = a0 * (1 - lambda).
#' The window narrows monotonically until the threshold becomes
#' unreachable.
#'
#' @param tau1 numeric > 0
#' @param a0 numeric > 0: zero-dose amplitude
#' @param theta numeric > 0
#' @param lambdas numeric vector in [0, 1)
#' @param n numeric channels
#' @return data.frame(lambda, a, window)
#' @export
window_sweep <- function(tau1, a0, theta, lambdas, n = 2) {
  a <- a0 * (1 - lambdas)
  w <- vapply(a, function(ai) integration_window(tau1, ai, theta, n), numeric(1))
  data.frame(lambda = lambdas, a = a, window = w)
}
