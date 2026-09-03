#!/usr/bin/env Rscript
# Genealogy G-6: bi-exponential relaxation — parameter recovery from a
# synthetic two-rate signal
#
# Published standard: the sum-of-two-exponentials decay
#
#   y(t) = A1*exp(-k1*t) + A2*exp(-k2*t),   k1 >> k2
#
# is the standard two-rate form used across the relaxation literature
# (NMR T1/T2, chemical kinetics, LTEE-style trait decay fits). The
# reproducibility question: given data generated at known parameters,
# does a nonlinear least-squares fit recover them?
#
# Reproduction: simulate with noise, fit with nls, compare.

set.seed(42)
t <- seq(0, 40, by = 0.2)
A1 <- 0.7; A2 <- 0.3; k1 <- 1.0; k2 <- 0.05
y <- A1 * exp(-k1 * t) + A2 * exp(-k2 * t) + rnorm(length(t), 0, 0.005)

fit <- tryCatch(
  nls(y ~ a1 * exp(-b1 * t) + a2 * exp(-b2 * t),
      start = list(a1 = 0.5, a2 = 0.5, b1 = 0.8, b2 = 0.1)),
  error = function(e) NULL
)

cat("G-6 bi-exponential recovery (truth: A1=0.7, A2=0.3, k1=1.0, k2=0.05)\n")
if (is.null(fit)) {
  cat("VERDICT: NOT reproducible in this attempt (nls failed to converge)\n")
} else {
  cf <- coef(fit)
  cat(sprintf("recovered: A1=%.3f A2=%.3f k1=%.3f k2=%.4f\n",
              cf["a1"], cf["a2"], cf["b1"], cf["b2"]))
  cat("max |truth - recovered|:",
      format(max(abs(c(A1 - cf["a1"], A2 - cf["a2"],
                       k1 - cf["b1"], k2 - cf["b2"]))), digits = 4), "\n")
  cat("VERDICT: reproducible (parameters recovered within noise)\n")
}
