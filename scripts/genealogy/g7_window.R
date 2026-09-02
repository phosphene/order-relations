#!/usr/bin/env Rscript
# Genealogy G-7: the integration window — leaky summation of two pulses
#
# Published standard: temporal summation in a leaky integrator
# (neural excitation / two-stimulus summation, e.g. Volkov et al. on
# Dionaea). A stimulus of amplitude a sets the integrator to a; the
# level decays as a*exp(-dt/tau). A second stimulus of amplitude a
# arriving dt later sums:
#
#   V = a*exp(-dt/tau) + a  >=  theta
#
#   =>  dt_max = tau * ln( a / (theta - a) )      [single-channel form]
#
# Our flytrap code uses the two-channel form
#
#   dt_max = tau * ln( 2a / (theta - a) )         [two-channel form]
#
# both of which sit inside the published 20-30 s bracket for the
# Dionaea decision window. This is a documented AMBIGUITY in the
# published artifact: the "standard" does not uniquely fix the channel
# count, and the two forms differ by ln(2)*tau (~5.5 s at tau = 8 s).

window_single <- function(tau, a, theta) tau * log(a / (theta - a))
window_two <- function(tau, a, theta) tau * log(2 * a / (theta - a))

tau <- 8
ratio <- 0.952                # a/theta from the flytrap instantiation
a <- ratio; theta <- 1
cat("G-7 integration window (tau =", tau, "s, a/theta =", ratio, ")\n")
w1 <- window_single(tau, a, theta)
w2 <- window_two(tau, a, theta)
cat(sprintf("single-channel: %.1f s\n", w1))
cat(sprintf("two-channel  : %.1f s\n", w2))
cat(sprintf("published bracket: 20-30 s | both inside: %s\n",
            if (w1 >= 20 && w2 <= 30) "YES" else "NO"))
cat("delta (ln2*tau):", sprintf("%.1f s", w2 - w1), "\n")
cat("VERDICT: PARTIALLY reproducible — formula derivable from the\n")
cat("         published leaky-summation standard, but the channel count\n")
cat("         is underdetermined (24 vs 29.5 s); flagged in Appendix B.\n")
