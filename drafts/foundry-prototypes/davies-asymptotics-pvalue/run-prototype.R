#!/usr/bin/env Rscript
# Davies Asymptotic P-Value Prototype Runner
# Usage: Rscript run-prototype.R

library(testthat)

cat("=== Davies Asymptotic P-Value Prototype Test Suite ===\n\n")

source("implement-davies-asymptotics.R")

test_results <- test_file("test-davies-asymptotics.R", reporter = "summary")

df <- as.data.frame(test_results)
passed <- sum(df$passed); failed <- sum(df$failed); errors <- sum(df$error)

cat("\n=== RESULTS ===\n")
cat(sprintf("Passed: %d / %d tests\n", passed, nrow(df)))
if (failed > 0) cat(sprintf("Failed: %d\n", failed))
if (errors > 0) cat(sprintf("Errors: %d\n", errors))

if (failed == 0 && errors == 0) {
  cat("\n✅ All tests green. Prototype validated.\n")
  quit(status = 0)
} else {
  cat("\n❌ Some tests failed. Review output above.\n")
  quit(status = 1)
}
