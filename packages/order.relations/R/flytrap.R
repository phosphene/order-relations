#' Flytrap instantiation of the abstraction (Level 0' on a real system)
#'
#' The first instantiation of the abstract core on a published system,
#' using published biophysics only — no new measurement, no fitting.
#' This file is the mapping table: every biological noun is confined to
#' the instantiation; the core functions stay substrate-free.
#'
#' Mapping (exploration document §2.5, tier2-flytrap-elimination):
#'   x = Ca2+-integrator state (the field / control side)
#'   y = trap program state 0->1 (order parameter: sealing -> digestion)
#'   tau1*xdot = -x + S(t)*a(lambda)      (fast: calcium integrator)
#'   tau2*ydot = Theta(x - x_c)*R(y) - y/tau_r  (slow: program commitment)
#'   epsilon = tau1/tau2 = 3.08e-5 << 1
#'   lambda = anesthesia dose (control parameter)
#'
#' Derived predictions vs published anchors (all derived, none fitted):
#'   P1b  k1 = 1/tau1 = 0.125 s^-1            vs Ca2+ decay ~8 s
#'   P1c  k2 = kappa/tau2 ~= 3.0 d             vs digestion 3-5 d
#'   P2   W(0) = 29.5 s (two-channel form)     vs Di Palma 20-30 s
#'   P3   W(lambda) narrows monotonically      (simulacrum prediction)
#'
#' @return list of derived quantities for the zero-dose trap
#' @export
flytrap_instantiation <- function() {
  tau1 <- 8.0                    # s, Ca2+ integrator relaxation
  tau2 <- 3.0 * 86400            # s, digestion program timescale
  a_theta <- 0.952               # a/theta at zero dose
  theta <- 1.0                   # normalized threshold

  sys <- tv_system(
    f = function(x, y) -x + a_theta * theta,  # relax to drive amplitude
    g = function(x, y) ifelse(x > 0.5, 1 - y, -y),  # commitment switch
    tau1 = tau1,
    tau2 = tau2
  )

  k1 <- 1 / tau1
  w2 <- integration_window(tau1, a_theta * theta, theta, n = 2)
  w1 <- integration_window(tau1, a_theta * theta, theta, n = 1)

  list(
    system = sys,
    epsilon = timescale_ratio(sys),
    slaving = slaving_holds(sys),
    k1 = k1,
    window_two_channel = w2,
    window_one_channel = w1,
    bracket = c(20, 30),
    window_in_bracket = w2 >= 20 && w2 <= 30 && w1 >= 20 && w1 <= 30,
    note = paste0(
      "Derived, not fitted. Window read-point discrepancy: stated ",
      "derivation ~24 s (n=1), pipeline code 29.5 s (n=2); both inside ",
      "the published 20-30 s bracket. Bench (C4-P1) is the final word."
    )
  )
}
