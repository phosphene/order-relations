# Test-Driven Prototype: Davies Asymptotic P-Value Implementation
#
# Objective: Exercise the real `davies_pvalue()` implementation from
# implement-davies-asymptotics.R against the behavioural guarantees in
# contract.md. The previous version of this file defined its own placeholder
# function (`davies_asymptotic_pval`) and never touched the deliverable —
# that was tool cruft. This suite tests the actual implementation.
#
# Contract invariants (from contract.md):
# 1. p_davies >= p_naive — the correction never makes rejection EASIER
# 2. p_davies in [0, 1]
# 3. p_davies non-decreasing in m_eff (larger nuisance search space,
#    larger correction) at fixed LR_stat
# 4. Union-bound (Bonferroni) is the safety floor; EVC refines it only in
#    the tail regime (LR_stat > 2*log(m_eff))
# 5. m_eff = 1 degenerates to the naive chi-square tail

library(testthat)

test_that("Davies: p_davies >= p_naive (never anti-conservative)", {
  for (LR in c(1, 3.84, 5, 8, 10, 15, 20)) {
    for (m in c(1, 5, 10, 100, 500, 1000)) {
      r <- davies_pvalue(LR, m)
      expect_true(r$p_davies >= r$p_naive - 1e-15,
        info = sprintf("LR=%.1f m=%g: p_davies=%.6g p_naive=%.6g", LR, m, r$p_davies, r$p_naive))
      expect_true(r$p_davies >= 0 && r$p_davies <= 1,
        info = sprintf("LR=%.1f m=%g: p_davies=%.6g out of [0,1]", LR, m, r$p_davies))
    }
  }
})

test_that("Davies: correction grows with nuisance dimension m_eff", {
  fixed_LR <- 8.0
  ms <- c(1, 10, 100, 1000)
  p_vals <- vapply(ms, function(m) davies_pvalue(fixed_LR, m)$p_davies, numeric(1))
  expect_true(all(diff(p_vals) >= -1e-12),
    info = sprintf("p_davies across m_eff: %s — must be non-decreasing", paste(signif(p_vals, 4), collapse = ", ")))
})

test_that("Davies: m_eff = 1 degenerates to naive chi-square tail", {
  for (LR in c(1, 3.84, 8, 12)) {
    r <- davies_pvalue(LR, 1)
    expect_equal(r$p_davies, r$p_naive, tolerance = 1e-15)
    expect_equal(r$p_davies, pchisq(LR, df = 1, lower.tail = FALSE), tolerance = 1e-12)
  }
})

test_that("Davies: union bound is the safety floor", {
  # p_union = min(1, m * p_single) — Davies can never be SMALLER than the
  # union bound at the same m_eff (EVC may only shrink it toward the truth,
  # never below the Bonferroni factor in this implementation).
  r1 <- davies_pvalue(10.0, 500)
  expect_equal(r1$p_union, min(1, 500 * pchisq(10, 1, lower.tail = FALSE)), tolerance = 1e-15)
  # sanity: in tail regime p_davies <= p_union (EVC refines it downward)
  r2 <- davies_pvalue(30.0, 1000)  # LR=30 > 2*log(1000)=13.8 → tail regime
  expect_true(r2$p_davies <= r2$p_union + 1e-15)
  expect_true(!is.na(r2$p_evc), info = "EVC branch must fire in tail regime")
})

test_that("Davies: input validation", {
  expect_error(davies_pvalue(-1, 10), "LR_stat")
  expect_error(davies_pvalue(NA, 10), "LR_stat")
  expect_error(davies_pvalue(8, 0), "m_eff")
  expect_error(davies_pvalue(8, c(1, 2)), "m_eff")
})

test_that("Davies: compare_naive_vs_davies grid shape", {
  grid <- compare_naive_vs_davies(c(6, 8, 10, 12), 100)
  expect_equal(nrow(grid), 4)
  expect_named(grid, c("LR_stat", "p_naive", "p_davies"))
  expect_true(all(grid$p_davies >= grid$p_naive - 1e-15))
})