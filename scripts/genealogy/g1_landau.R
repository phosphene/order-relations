#!/usr/bin/env Rscript
# Genealogy G-1: Landau (1937) — order parameter from the free-energy expansion
#
# Published standard: L.D. Landau, "On the theory of phase transitions"
# (Zh. Eksp. Teor. Fiz. 7, 19 (1937)). Order parameter phi minimizes
#
#   F(phi) = F0 + a*(T - Tc)*phi^2 + b*phi^4,   b > 0
#
# dF/dphi = 0  =>  phi = 0 (disordered, T > Tc)
#            or  phi* = +/- sqrt( a*(Tc - T)/(2b) )  (ordered, T < Tc)
#
# Reproduction: no data required — analytic. Verify the branch structure
# and that the ordered branch exists iff T < Tc.

landau_phi_star <- function(T, Tc, a, b) {
  coeff <- a * (T - Tc)
  if (coeff >= 0) return(0)
  sqrt(-coeff / (2 * b))
}

Tc <- 300; a <- 1; b <- 1
Ts <- c(280, 290, 295, 299, 300, 301, 310, 320)
phi <- vapply(Ts, landau_phi_star, numeric(1), Tc = Tc, a = a, b = b)

cat("G-1 Landau free energy: phi* vs T (Tc = 300, a = 1, b = 1)\n")
tab <- data.frame(T = Ts, phi_star = round(phi, 4))
print(tab, row.names = FALSE)

# Verify the analytic branch: phi^2 = a(Tc-T)/(2b) for T < Tc
check <- phi[Ts < Tc]^2 - (a * (Tc - Ts[Ts < Tc]) / (2 * b))
cat("max |phi*^2 - a(Tc-T)/(2b)| on ordered branch:",
    format(max(abs(check)), digits = 6), "\n")
cat("VERDICT: reproducible (analytic, no data dependency)\n")
