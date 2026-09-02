#' Adiabatic elimination (abstraction inventory row 3)
#'
#' In the slaving limit (epsilon << 1) the fast variable relaxes on a much
#' shorter timescale than the slow one, so we may set tau1*xdot = 0 and
#' solve f(x, y) = 0 for the slow manifold x*(y). Substituting into the
#' slow equation gives the effective dynamics on the slow manifold:
#'
#'   tau2 * ydot = g(x*(y), y) =: G(y)
#'
#' This is the formal core of the program: slaving reduces the two-variable
#' system to effective one-variable dynamics on the order parameter.
#' Substrate-free: x, y, f, g carry no biological meaning until instantiated.
#'
#' @param sys a tv_system
#' @param y numeric vector: slow-variable values at which to evaluate
#' @param x_interval numeric(2): bracket for root-finding on x
#' @return numeric vector x*(y): the slow manifold
#' @export
slow_manifold <- function(sys, y, x_interval = c(-1e6, 1e6)) {
  stopifnot(inherits(sys, "tv_system"))
  vapply(y, function(yi) {
    root <- tryCatch(
      uniroot(function(x) sys$f(x, yi), interval = x_interval, tol = 1e-12)$root,
      error = function(e) NA_real_
    )
    root
  }, numeric(1))
}

#' Effective dynamics G(y) on the slow manifold
#' @param sys a tv_system
#' @param y numeric vector
#' @param x_interval numeric(2) root-finding bracket
#' @return numeric vector G(y) = g(x*(y), y)
#' @export
effective_dynamics <- function(sys, y, x_interval = c(-1e6, 1e6)) {
  stopifnot(inherits(sys, "tv_system"))
  xstar <- slow_manifold(sys, y, x_interval)
  mapply(function(xs, yi) sys$g(xs, yi), xstar, y)
}

#' Landscape L(y) = -integral G(y) dy (the effective potential)
#'
#' The slow dynamics tau2*ydot = G(y) is a gradient flow on L when G is
#' integrable. L is the object whose curvature at a minimum gives the
#' slow relaxation constant (see k2_from_curvature).
#'
#' @param y numeric vector (grid, ascending)
#' @param G numeric vector G(y) evaluated on the same grid
#' @return numeric vector L(y), normalized so min(L) = 0
#' @export
landscape <- function(y, G) {
  stopifnot(length(y) == length(G), length(y) >= 2)
  if (any(diff(y) <= 0)) stop("y must be an ascending grid")
  dy <- diff(y)
  dL <- -0.5 * (G[-1] + G[-length(G)]) * dy
  L <- c(0, cumsum(dL))
  L - min(L)
}

#' Curvature kappa = L''(y*) at a landscape minimum (second derivative)
#' @param y numeric vector grid
#' @param L numeric vector landscape on the grid
#' @param ystar numeric: point of interest (default: argmin of L)
#' @return numeric kappa
#' @export
curvature <- function(y, L, ystar = y[which.min(L)]) {
  stopifnot(length(y) == length(L), length(y) >= 3)
  i <- which.min(abs(y - ystar))
  if (i == 1L || i == length(y)) {
    # one-sided second difference at the boundary
    h <- y[i + 1L] - y[i]
    (L[i + 2L] - 2 * L[i + 1L] + L[i]) / h^2
  } else {
    h <- y[i + 1L] - y[i]
    (L[i + 1L] - 2 * L[i] + L[i - 1L]) / h^2
  }
}

#' Slow relaxation constant k2 = kappa / tau2
#'
#' The curvature of the effective landscape sets the slow rate:
#' near a minimum y*, L ~ 0.5*kappa*(y - y*)^2, so the slow variable
#' relaxes as exp(-t/tau_relax) with tau_relax = tau2/kappa, i.e.
#' k2 = kappa / tau2.
#'
#' @param kappa numeric curvature at the minimum
#' @param tau2 numeric slow timescale
#' @return numeric k2 (units 1/time)
#' @export
k2_from_curvature <- function(kappa, tau2) {
  stopifnot(is.numeric(kappa), length(kappa) == 1L, kappa >= 0)
  stopifnot(is.numeric(tau2), length(tau2) == 1L, tau2 > 0)
  kappa / tau2
}
