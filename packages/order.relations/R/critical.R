#' Critical slowing down (abstraction inventory row 7)
#'
#' Near an instability the relaxation time of the order parameter
#' diverges. For a control parameter lambda approaching the critical
#' value lambda_c, the effective slow rate vanishes as
#'
#'   k2_eff(lambda) = k2 * (1 - lambda/lambda_c)
#'
#' so the relaxation time tau_relax = 1/k2_eff diverges. This is the
#' formal address of the window-collapse test (T-2): as the system
#' approaches the instability, the apparent slow rate collapses toward
#' the fast rate (k1/k2 -> 1).
#'
#' @param k2 numeric > 0: baseline slow rate
#' @param lambda numeric: control parameter value
#' @param lambda_c numeric: critical value (lambda < lambda_c)
#' @return numeric effective slow rate k2_eff
#' @export
critical_slowing_rate <- function(k2, lambda, lambda_c) {
  stopifnot(k2 > 0)
  k2 * (1 - lambda / lambda_c)
}

#' Apparent rate ratio k1/k2_eff under critical slowing (T-2 prediction)
#'
#' As lambda -> lambda_c, k2_eff -> 0 and the ratio k1/k2_eff diverges;
#' equivalently, sampled over a fixed observation window the two rates
#' become indistinguishable (k1/k2_eff -> 1 in the deep-time reading).
#' The two limits are the same fact read at different windows.
#'
#' @param k1 numeric > 0: fast rate
#' @param k2 numeric > 0: baseline slow rate
#' @param lambda numeric
#' @param lambda_c numeric
#' @return numeric k1/k2_eff
#' @export
apparent_rate_ratio <- function(k1, k2, lambda, lambda_c) {
  k2eff <- critical_slowing_rate(k2, lambda, lambda_c)
  k1 / k2eff
}
