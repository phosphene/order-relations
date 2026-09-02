#' Order-parameter formation: the amplitude equation (abstraction inventory row 11)
#'
#' The other half of g. Slaving has two faces: relaxation (row 8, the
#' bi-exponential — loss-shaped) and FORMATION (this row — gain-shaped).
#' In synergetics the order parameter is not a given: it is born at the
#' instability, growing from fluctuations via the amplitude equation
#'
#'   tau2 * dy/dt = alpha(lambda) * y - beta * y^3
#'
#' with alpha(lambda) = k2 * (lambda/lambda_c - 1). For lambda < lambda_c
#' (alpha < 0): single stable fixed point y* = 0 — no order parameter,
#' relaxation only. For lambda > lambda_c (alpha > 0): the zero state is
#' destabilized, two stable branches appear at y* = ±sqrt(alpha/beta) —
#' the order parameter FORMS. The growth is a gain process, and it is
#' the same g, other regime.
#'
#' This is the formal address of the inbound/outbound asymmetry
#' (exploration §2.4 "the deepest tension"): "inbound" events (C4
#' convergence, Cambrian radiation, exaptation) are not fits to the
#' relaxation law — they are the alpha > 0 regime of the same coupling.
#' The hinge is critical slowing (row 7 / T-2): same lambda sweep,
#' other side of lambda_c.
#'
#' Substrate-free: lambda is any control parameter, y any order parameter.
#' @name formation
NULL

#' Instantaneous amplitude dynamics: alpha*y - beta*y^3
#' @param y numeric: order parameter value
#' @param alpha numeric: growth coefficient (k2*(lambda/lambda_c - 1))
#' @param beta numeric > 0: nonlinear saturation
#' @return numeric tau2*dy/dt
#' @export
amplitude_dynamics <- function(y, alpha, beta) {
  stopifnot(is.numeric(y), is.numeric(alpha), beta > 0)
  alpha * y - beta * y^3
}

#' Growth coefficient from control parameter (linearization at the instability)
#' @param k2 numeric > 0: baseline slow rate
#' @param lambda numeric: control parameter value
#' @param lambda_c numeric > 0: critical value
#' @return numeric alpha(lambda)
#' @export
growth_coefficient <- function(k2, lambda, lambda_c) {
  stopifnot(k2 > 0, lambda_c > 0)
  k2 * (lambda / lambda_c - 1)
}

#' Stable equilibria of the amplitude equation
#'
#' @param alpha numeric
#' @param beta numeric > 0
#' @return numeric vector: stable fixed points (length 1 below, 2 above)
#' @export
order_parameter_equilibria <- function(alpha, beta) {
  stopifnot(beta > 0)
  if (alpha <= 0) return(0)
  s <- sqrt(alpha / beta)
  c(-s, s)
}

#' Exact growth solution of the amplitude equation from initial amplitude y0
#'
#'   y(t) = sqrt(alpha/beta) / sqrt(1 + C*exp(-2*alpha*t)),
#'   C = (alpha/beta - y0^2)/y0^2
#'
#' Logistic-shaped: slow departure from y0, fastest growth at the
#' inflection, saturation at sqrt(alpha/beta). This is inbound-as-
#' relaxation: approach to the NEW attractor is exponential — the same
#' law as loss, read toward the other fixed point.
#'
#' @param t numeric vector >= 0
#' @param y0 numeric > 0: initial amplitude (fluctuation seed)
#' @param alpha numeric > 0: growth coefficient
#' @param beta numeric > 0
#' @return numeric vector y(t)
#' @export
order_parameter_growth <- function(t, y0, alpha, beta) {
  stopifnot(all(t >= 0), y0 > 0, alpha > 0, beta > 0)
  y_inf <- sqrt(alpha / beta)
  C <- (alpha / beta - y0^2) / y0^2
  y_inf / sqrt(1 + C * exp(-2 * alpha * t))
}

#' Variance enhancement of the order parameter near criticality
#'
#' Fluctuation signature (the C4-P1 tag): as lambda -> lambda_c the
#' restoring force vanishes (critical slowing), so fluctuations of y
#' about the (unstable) zero state grow as
#'
#'   Var(y) ~ sigma0^2 / |alpha|  =  sigma0^2 / (k2*|lambda/lambda_c - 1|)
#'
#' The variance diverges at lambda_c. Prediction: BEFORE failure of a
#' commitment system (trap, anesthesia, reversion), response variance
#' should blow up — a measurable precursor. This is the observable that
#' makes the dissociation band (flytrap lambda* in (0.475, 0.58)) a
#' variance peak, not just a threshold.
#'
#' @param sigma0 numeric > 0: baseline fluctuation scale
#' @param k2 numeric > 0: baseline slow rate
#' @param lambda numeric
#' @param lambda_c numeric > 0
#' @return numeric variance enhancement (>= sigma0^2)
#' @export
critical_fluctuations <- function(sigma0, k2, lambda, lambda_c) {
  stopifnot(sigma0 > 0, k2 > 0, lambda_c > 0)
  alpha_abs <- abs(k2 * (lambda / lambda_c - 1))
  if (alpha_abs < 1e-12) return(Inf)
  sigma0^2 / alpha_abs
}

#' Regime classification: which face of g is active at lambda
#'
#' @param lambda numeric
#' @param lambda_c numeric > 0
#' @return character: "relaxation" (lambda < lambda_c), "critical" (near),
#'   "formation" (lambda > lambda_c)
#' @export
g_regime <- function(lambda, lambda_c, tol = 0.05) {
  stopifnot(lambda_c > 0)
  d <- abs(lambda - lambda_c) / lambda_c
  if (d < tol) return("critical")
  if (lambda < lambda_c) return("relaxation")
  "formation"
}
