#' Two-variable system (abstraction inventory row 1)
#'
#' The abstract two-variable system: tau1*xdot = f(x,y), tau2*ydot = g(x,y),
#' with timescale ratio epsilon = tau1/tau2. No substrate commitment:
#' x and y are abstract variables on a phase space; f and g are the
#' coupling functions. Concreteness arrives only at instantiation.
#'
#' @param f function(x, y) -> dx/dt * tau1 (fast-side equation)
#' @param g function(x, y) -> dy/dt * tau2 (slow-side equation)
#' @param tau1 numeric > 0: fast timescale
#' @param tau2 numeric > 0: slow timescale
#' @return list of class "tv_system" with fields f, g, tau1, tau2, epsilon
#' @export
tv_system <- function(f, g, tau1, tau2) {
  stopifnot(is.function(f), is.function(g))
  stopifnot(is.numeric(tau1), length(tau1) == 1L, tau1 > 0)
  stopifnot(is.numeric(tau2), length(tau2) == 1L, tau2 > 0)
  structure(
    list(f = f, g = g, tau1 = tau1, tau2 = tau2, epsilon = tau1 / tau2),
    class = "tv_system"
  )
}

#' Timescale ratio epsilon = tau1/tau2
#' @param sys a tv_system
#' @return numeric epsilon
#' @export
timescale_ratio <- function(sys) {
  stopifnot(inherits(sys, "tv_system"))
  sys$epsilon
}

#' Slaving holds iff the timescale separation is real
#'
#' The slaving relation is a *timescale fact*, not a direction claim:
#' it holds whenever epsilon = tau1/tau2 is small, regardless of which
#' variable drives which. Direction of drive is a separate, per-instance
#' read (see drive_direction).
#'
#' @param sys a tv_system
#' @param eps_max numeric threshold (default 0.1)
#' @return logical
#' @export
slaving_holds <- function(sys, eps_max = 0.1) {
  stopifnot(inherits(sys, "tv_system"))
  sys$epsilon < eps_max
}

#' Read the direction of drive from the coupling (per-instance, never intrinsic)
#'
#' The Jacobian off-diagonals at the operating point, timescale-normalized:
#' - rate_fast_from_slow = |df/dy| / tau1 : how the slow variable feeds the fast equation
#' - rate_slow_from_fast = |dg/dx| / tau2 : how the fast variable feeds the slow equation
#'
#' Classification is a per-instance read of f and g. The abstraction itself
#' is direction-free (slaving_without_directionality); any instance may land
#' fast->slow, slow->fast, or mutual.
#'
#' @param sys a tv_system
#' @param x0 numeric operating point, fast variable
#' @param y0 numeric operating point, slow variable
#' @param h numeric step for central differences (default 1e-6)
#' @param dominance numeric ratio threshold (default 10)
#' @return list(class, rate_fast_from_slow, rate_slow_from_fast)
#' @export
drive_direction <- function(sys, x0, y0, h = 1e-6, dominance = 10) {
  stopifnot(inherits(sys, "tv_system"))
  jac <- coupling_matrix(sys, x0, y0, h)
  r_fs <- abs(jac["f", "y"]) / sys$tau1
  r_sf <- abs(jac["g", "x"]) / sys$tau2
  cls <- if (r_sf > dominance * r_fs) {
    "fast_drives_slow"
  } else if (r_fs > dominance * r_sf) {
    "slow_drives_fast"
  } else if (r_fs == 0 && r_sf == 0) {
    "none"
  } else {
    "mutual"
  }
  list(class = cls, rate_fast_from_slow = r_fs, rate_slow_from_fast = r_sf)
}

#' Numerical Jacobian of the coupled system at (x0, y0)
#' @param sys a tv_system
#' @param x0 numeric
#' @param y0 numeric
#' @param h numeric step
#' @return 2x2 numeric matrix, rows = equations (f, g), cols = variables (x, y)
#' @export
coupling_matrix <- function(sys, x0, y0, h = 1e-6) {
  stopifnot(inherits(sys, "tv_system"))
  dfdx <- (sys$f(x0 + h, y0) - sys$f(x0 - h, y0)) / (2 * h)
  dfdy <- (sys$f(x0, y0 + h) - sys$f(x0, y0 - h)) / (2 * h)
  dgdx <- (sys$g(x0 + h, y0) - sys$g(x0 - h, y0)) / (2 * h)
  dgdy <- (sys$g(x0, y0 + h) - sys$g(x0, y0 - h)) / (2 * h)
  matrix(c(dfdx, dfdy, dgdx, dgdy), nrow = 2, byrow = TRUE,
         dimnames = list(c("f", "g"), c("x", "y")))
}

#' Print method for tv_system
#' @export
print.tv_system <- function(x, ...) {
  cat("two-variable system\n")
  cat(sprintf("  tau1 = %g, tau2 = %g, epsilon = %g\n",
              x$tau1, x$tau2, x$epsilon))
  cat(sprintf("  slaving holds: %s\n", slaving_holds(x)))
  invisible(x)
}
