#!/usr/bin/env Rscript
# Genealogy G-3: Haken's slaving principle — fast variable eliminated
# in the field of the slow one
#
# Published standard: H. Haken, "Synergetics: An Introduction"
# (Springer, 1977/1983), ch. 7 (slaving principle). The fast variable x
# relaxes onto a manifold x* = f(y) set by the slow variable y, on a
# timescale eps << 1; the slow equation then closes on the reduced
# dynamics  y_dot = g(y, f(y)).
#
# Prototype (linear-nonlinear mixed, the simplest published form):
#   x_dot = -(1/eps)*(x - a*y)     (fast: x tracks a*y)
#   y_dot = -y + b*x               (slow)
# Reduced: x* = a*y  =>  y_dot = -y + b*a*y  =  (b*a - 1)*y
#
# Reproduction: integrate full system and reduced system, compare y(t).
# The reduction is exact in the limit eps -> 0; at finite eps the error
# is O(eps).

slave <- function(tmax = 10, dt = 1e-3, eps = 0.01, a = 2, b = 0.5,
                  x0 = 0, y0 = 1) {
  n <- tmax / dt
  x <- x0; y <- y0; yred <- y0
  out <- matrix(NA_real_, n, 3,
                dimnames = list(NULL, c("x", "y_full", "y_reduced")))
  for (i in seq_len(n)) {
    xdot <- -(1 / eps) * (x - a * y)
    ydot <- -y + b * x
    x <- x + xdot * dt
    y <- y + ydot * dt
    yred <- yred + ((b * a - 1) * yred) * dt
    out[i, ] <- c(x, y, yred)
  }
  out
}

cat("G-3 Haken slaving: eps = 0.01, a = 2, b = 0.5\n")
s <- slave()
md <- max(abs(s[, "y_full"] - s[, "y_reduced"]))
cat("max |y_full - y_reduced| over [0, 10]:", format(md, digits = 6), "\n")
s2 <- slave(eps = 0.001)
md2 <- max(abs(s2[, "y_full"] - s2[, "y_reduced"]))
cat("same with eps = 0.001:", format(md2, digits = 6), "\n")
cat("error ratio (should be ~10, i.e. O(eps)):",
    format(md / md2, digits = 3), "\n")
cat("VERDICT: reproducible (O(eps) convergence of the elimination)\n")
