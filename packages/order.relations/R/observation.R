#' Observation-window collapse (T-2)
#'
#' The resolution-limit fact: the *observable* two-rate ratio depends on
#' the sampling interval. A bi-exponential process with rates k1 >> k2
#' sampled at interval delta shows both phases only while the fast phase
#' survives between samples. Once exp(-k1*delta) ~ 0, the fast phase is
#' an unresolvable initial step, the data are effectively
#' mono-exponential, and the apparent ratio collapses toward 1.
#'
#' This is the formal address of the exploration's scale problem
#' (LTEE k1/k2 = 37.7 at ~15 yr fine sampling vs C4 ~ 1.0 at ~10 Myr
#' geological sampling): not a contradiction, a resolution ceiling.
#' Full numbers: docs/VERIFIED_RESULTS.md (T-2).
#'
#' Analytic resolution-limit curve (deterministic):
#'   fast_surviving(delta) = exp(-k1*delta)
#'   apparent_rate_ratio: k1/k2 while fast phase resolvable, smooth
#'   collapse to 1 as fast_surviving/tol -> 0.
#'
#' Fit-based check (with seeded noise): bi-exp vs mono-exp fits across
#' the sweep; dAIC(bi - mono) large positive at fine sampling, ~0 at
#' coarse sampling (models indistinguishable -> two-phase signature
#' undetectable).
#'
#' @param delta numeric > 0: sampling interval
#' @param k1 numeric > 0: fast rate
#' @return numeric in (0, 1]: fraction of fast amplitude surviving one interval
#' @export
fast_surviving <- function(delta, k1) {
  stopifnot(delta > 0, k1 > 0)
  exp(-k1 * delta)
}

#' Sampling interval at which the fast phase is tol-decayed between samples
#' @param k1 numeric > 0
#' @param tol numeric in (0, 1): surviving fraction at the resolution limit
#' @return numeric delta* (same time units as 1/k1)
#' @export
resolution_delta <- function(k1, tol = 0.05) {
  stopifnot(k1 > 0, tol > 0, tol < 1)
  -log(tol) / k1
}

#' Apparent two-rate ratio as a function of sampling interval
#'
#' Smooth resolution-limit curve: k1/k2 while the fast phase is
#' resolvable (fast_surviving >= tol), collapsing monotonically to 1
#' (single observable rate) as the interval grows.
#'
#' @param delta numeric > 0
#' @param k1 numeric > 0
#' @param k2 numeric > 0, k2 < k1
#' @param tol numeric in (0, 1): resolution tolerance
#' @return numeric apparent ratio >= 1
#' @export
apparent_rate_ratio <- function(delta, k1, k2, tol = 0.05) {
  stopifnot(delta > 0, k1 > 0, k2 > 0, k1 > k2)
  surv <- fast_surviving(delta, k1)
  if (surv >= tol) return(k1 / k2)
  1 + (k1 / k2 - 1) * (surv / tol)
}

#' Sample a bi-exponential process at given times (seeded, deterministic)
#' @param times numeric vector >= 0
#' @param A1 numeric: fast amplitude
#' @param k1 numeric > 0
#' @param A2 numeric: slow amplitude
#' @param k2 numeric > 0
#' @param noise numeric >= 0: additive noise sd
#' @param seed integer
#' @return numeric vector rho(times)
#' @export
sample_process <- function(times, A1, k1, A2, k2, noise = 0.001, seed = 42) {
  stopifnot(all(times >= 0), k1 > 0, k2 > 0)
  if (noise > 0) set.seed(seed)
  rho <- A1 * exp(-k1 * times) + A2 * exp(-k2 * times)
  if (noise > 0) rho <- rho + stats::rnorm(length(rho), 0, noise)
  rho
}

#' Nonlinear least-squares fit of a bi-exponential (log-parametrized)
#' @param times numeric vector
#' @param rho numeric vector
#' @param maxit integer: optim iterations
#' @return list(k1, k2, A1, A2, sse, converged)
#' @export
fit_biexp <- function(times, rho, maxit = 2000) {
  nll <- function(p) {
    A1 <- exp(p[1]); k1 <- exp(p[2]); A2 <- exp(p[3]); k2 <- exp(p[4])
    pred <- A1 * exp(-k1 * times) + A2 * exp(-k2 * times)
    sum((rho - pred)^2)
  }
  fit <- stats::optim(
    c(log(1), log(0.1), log(1), log(0.01)), nll, method = "L-BFGS-B",
    lower = c(log(1e-8), log(1e-6), log(1e-8), log(1e-6)),
    upper = c(log(1e6), log(1e6), log(1e6), log(1e6)),
    control = list(maxit = maxit)
  )
  p <- fit$par
  k1 <- exp(p[2]); k2 <- exp(p[4])
  if (k2 > k1) { tmp <- k1; k1 <- k2; k2 <- tmp }
  list(k1 = k1, k2 = k2, A1 = exp(p[1]), A2 = exp(p[3]),
       sse = fit$value, converged = fit$convergence == 0)
}

#' Nonlinear least-squares fit of a mono-exponential
#' @export
fit_monoexp <- function(times, rho, maxit = 2000) {
  nll <- function(p) {
    A <- exp(p[1]); k <- exp(p[2])
    pred <- A * exp(-k * times)
    sum((rho - pred)^2)
  }
  fit <- stats::optim(
    c(log(1), log(0.01)), nll, method = "L-BFGS-B",
    lower = c(log(1e-8), log(1e-6)), upper = c(log(1e6), log(1e6)),
    control = list(maxit = maxit)
  )
  p <- fit$par
  list(k = exp(p[2]), A = exp(p[1]), sse = fit$value,
       converged = fit$convergence == 0)
}

#' Window-collapse sweep: fit-based and analytic apparent ratios vs delta
#'
#' @param k1 numeric > 0: true fast rate
#' @param k2 numeric > 0: true slow rate
#' @param A1 numeric: fast amplitude
#' @param A2 numeric: slow amplitude
#' @param deltas numeric vector > 0: sampling intervals
#' @param n_max integer: point cap for fine sampling
#' @param noise numeric >= 0: seeded noise for the fits
#' @param seed integer
#' @return data.frame(delta, ratio_fit, dAIC, ratio_analytic, fast_surviving)
#' @export
window_collapse_sweep <- function(k1, k2, A1 = 1, A2 = 1,
                                  deltas = 10^seq(-2, 3, length.out = 15),
                                  n_max = 30000, noise = 0.001, seed = 42) {
  stopifnot(k1 > 0, k2 > 0, k1 > k2)
  span_base <- 2 / k2
  rows <- lapply(deltas, function(delta) {
    span <- max(span_base, 10 * delta)
    n <- min(n_max, max(6, ceiling(span / delta)))
    times <- seq(0, by = delta, length.out = n)
    rho <- sample_process(times, A1, k1, A2, k2, noise = noise, seed = seed)
    fb <- fit_biexp(times, rho)
    fm <- fit_monoexp(times, rho)
    ratio_fit <- if (fb$converged && is.finite(fb$k2) && fb$k2 > 0) {
      fb$k1 / fb$k2
    } else {
      NA_real_
    }
    aic_b <- n * log(fb$sse / n) + 2 * 4
    aic_m <- n * log(fm$sse / n) + 2 * 2
    data.frame(
      delta = delta,
      ratio_fit = ratio_fit,
      dAIC = aic_m - aic_b,
      ratio_analytic = apparent_rate_ratio(delta, k1, k2),
      fast_surviving = fast_surviving(delta, k1)
    )
  })
  do.call(rbind, rows)
}

#' The LTEE/C4 reading: observable ratio at two named windows
#'
#' LTEE: fine sampling (delta << 1/k1) -> ratio ~ k1/k2.
#' C4 deep time: geological sampling (delta >> 1/k1) -> ratio ~ 1.
#'
#' @param k1 numeric > 0
#' @param k2 numeric > 0, k2 < k1
#' @param delta_fine numeric: physiological sampling interval
#' @param delta_deep numeric: geological sampling interval
#' @return list(fine, deep, collapse) with the apparent ratios
#' @export
window_reading <- function(k1, k2, delta_fine = 0.1 / k1, delta_deep = 100 / k1) {
  list(
    fine = apparent_rate_ratio(delta_fine, k1, k2),
    deep = apparent_rate_ratio(delta_deep, k1, k2),
    collapse = apparent_rate_ratio(delta_deep, k1, k2) / apparent_rate_ratio(delta_fine, k1, k2)
  )
}
