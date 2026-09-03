#' Perturbation sweep and loss ordering (T-1)
#'
#' The perturbation-reversal test, substrate-free. N subsystems carry an
#' abstract "integration depth" d_i in [0,1]. Deeper integration implies
#' slower intrinsic loss:
#'
#'   k_i = k1 + (k2 - k1) * d_i      (k1 > k2: shallow is fast)
#'
#' A control perturbation lambda adds an exposure term:
#'
#'   k_i^eff(lambda) = k_i + lambda * s_i
#'
#' with exposure profile s_i:
#'   - "depth":    s_i = s0 * d_i       (perturbation hits the integrated
#'                 core hardest — the lesion scenario)
#'   - "shallow":  s_i = s0 * (1 - d_i) (perturbation hits the periphery)
#'   - "uniform":  s_i = s0
#'
#' Predicted regimes (the T-1 claim):
#'   - Relaxation (lambda -> 0): intrinsic rates dominate; loss order
#'     matches integration depth (shallow first) -> rho(depth, loss_time) > 0.
#'   - Strong perturbation with depth exposure: lambda*s_i dominates;
#'     the core is hit hardest, loss order reverses -> rho < 0.
#'   - The reversal is a regime boundary, not a refutation of the
#'     integration-depth ordering — the model maps where it happens.
#'
#' @param depths numeric vector in [0,1]: integration depths
#' @param k1 numeric > 0: fast (shallow) intrinsic rate
#' @param k2 numeric > 0: slow (deep) intrinsic rate, k2 < k1
#' @param lambdas numeric vector >= 0: perturbation sweep
#' @param theta numeric in (0,1): loss threshold (capacity crosses below)
#' @param noise numeric >= 0: lognormal multiplicative noise on rates
#' @param n_rep integer: replicates per lambda
#' @param exposure character: "depth", "shallow", or "uniform"
#' @param s0 numeric > 0: exposure scale
#' @param seed integer: RNG seed (deterministic per MPI blueprint)
#' @return data.frame(lambda, rho_mean, rho_sd)
#' @export
lambda_sweep_ordering <- function(depths,
                                  k1,
                                  k2,
                                  lambdas,
                                  theta = 0.5,
                                  noise = 0,
                                  n_rep = 50,
                                  exposure = "depth",
                                  s0 = 1,
                                  seed = 42) {
  stopifnot(is.numeric(depths), all(depths >= 0 & depths <= 1))
  stopifnot(k1 > 0, k2 > 0, k1 > k2)
  stopifnot(is.numeric(lambdas), all(lambdas >= 0))
  stopifnot(theta > 0 && theta < 1)
  stopifnot(noise >= 0, n_rep >= 1, s0 > 0)
  stopifnot(exposure %in% c("depth", "shallow", "uniform"))

  set.seed(seed)
  rows <- lapply(lambdas, function(lam) {
    rho <- replicate(n_rep, {
      k_eff <- perturbation_rates(depths, k1, k2, lam, exposure, s0)
      t_loss <- loss_times(k_eff, theta, noise)
      stats::cor(depths, t_loss, method = "spearman")
    })
    data.frame(lambda = lam, rho_mean = mean(rho), rho_sd = stats::sd(rho))
  })
  do.call(rbind, rows)
}

#' Effective rates under perturbation
#' @export
perturbation_rates <- function(depths, k1, k2, lambda, exposure = "depth", s0 = 1) {
  k_i <- k1 + (k2 - k1) * depths
  s_i <- switch(exposure,
    depth = s0 * depths,
    shallow = s0 * (1 - depths),
    uniform = rep(s0, length(depths))
  )
  k_i + lambda * s_i
}

#' Loss times: time for exponential decay to cross theta
#' @export
loss_times <- function(k_eff, theta = 0.5, noise = 0) {
  k <- k_eff * exp(stats::rnorm(length(k_eff), 0, noise))
  -log(theta) / k
}

#' Locate the reversal boundary: the smallest lambda where rho <= 0
#'
#' @param sweep data.frame from lambda_sweep_ordering
#' @return list(lambda_star, rho_at_star, reversed) or NULL if never crosses
#' @export
reversal_boundary <- function(sweep) {
  stopifnot(all(c("lambda", "rho_mean") %in% names(sweep)))
  idx <- which(sweep$rho_mean <= 0)
  if (length(idx) == 0) return(NULL)
  list(
    lambda_star = sweep$lambda[idx[1]],
    rho_at_star = sweep$rho_mean[idx[1]],
    reversed = sweep$rho_mean[length(sweep$rho_mean)] < 0
  )
}
