# Davies Asymptotic P-Value Implementation
#
# Independent implementation of Davies (1987) correction for hypothesis tests
# where a nuisance parameter (e.g. breakpoint location) exists only under the
# alternative. The naive chi-square p-value anti-conservatively rejects because
# it ignores the maximization over the nuisance parameter. Davies' correction
# inflates p-values accordingly.
#
# Citations:
# - Davies, R. B. (1987). "Hypothesis testing when a nuisance parameter is
#   present only under the alternative." Biometrika 74(1):33-43.
# - Implementation reference: strucchange (Zeileis et al.), following
#   Andrews & Ploberger (1994) for the averaging/exp family.

# Implementation is self-contained (chi-square tails only) — strucchange is
# the literature REFERENCE, not a runtime dependency. Loading it here would
# break environments without zoo/lmtest (observed on the OC host).

#' Davies-corrected p-value for a maximized statistic
#'
#' Implements the boundary-problem intuition of Davies (1987): if the LR
#' statistic is maximized over m effectively independent values of the
#' nuisance parameter, the tail probability of the max of m chi2(1)
#' variables is bounded by m times the single-point tail (union bound),
#' refined with the standard sqrt(2 log m) extreme-value correction.
#'
#' @param LR_stat numeric: likelihood-ratio statistic (already maximized over
#'   the nuisance parameter, e.g. SupF)
#' @param m_eff numeric: effective number of independent nuisance evaluations
#' @return list with p_naive, p_union, p_evc, p_davies, m_eff, LR_stat
davies_pvalue <- function(LR_stat, m_eff) {
  stopifnot(is.numeric(LR_stat), is.finite(LR_stat), LR_stat >= 0)
  stopifnot(is.numeric(m_eff), length(m_eff) == 1, is.finite(m_eff), m_eff >= 1)

  p_single <- pchisq(LR_stat, df = 1, lower.tail = FALSE)

  # Bound 1 (union / Bonferroni over nuisance evaluations):
  p_union <- min(1, m_eff * p_single)

  # Bound 2 (extreme-value refinement valid when LR_stat exceeds the typical
  # max scale b_m = 2 log m): the max of ~m chi2(1) concentrates near b_m and
  # its tail decays like m * p_single / sqrt(2 log m) — the boundary-crossing
  # rate from Davies (1987).
  p_evc <- if (m_eff > 1 && LR_stat > 2 * log(m_eff)) {
    min(1, m_eff * p_single / sqrt(2 * log(m_eff)))
  } else {
    NA_real_
  }

  p_davies <- if (is.na(p_evc)) p_union else min(p_union, p_evc)

  # Sanity invariant: Davies p-value must NEVER be smaller than the naive
  # single-point chi-square tail (it corrects FOR the maximization).
  p_davies <- max(p_davies, p_single)

  list(
    p_naive = p_single,
    p_union = min(1, m_eff * p_single),
    p_evc = p_evc,
    p_davies = p_davies,
    m_eff = m_eff,
    LR_stat = LR_stat
  )
}

#' Compare naive vs Davies p-values across a grid
#'
#' @param stats numeric vector of SupF statistics
#' @param m_eff effective nuisance count
#' @return data.frame with naive and Davies p-values
compare_naive_vs_davies <- function(stats, m_eff) {
  data.frame(
    LR_stat = stats,
    p_naive = pchisq(stats, df = 1, lower.tail = FALSE),
    p_davies = vapply(stats, function(s) davies_pvalue(s, m_eff)$p_davies, numeric(1))
  )
}
