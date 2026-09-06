#!/usr/bin/env Rscript
# AICc Formula Prototype Runner
# 
# Executes test-driven development cycle for AICc implementation
# Usage: Rscript run-prototype.R

library(testthat)
library(MuMIn)

cat("=== AICc Formula Prototype Test Suite ===\n")
cat("Running 5 test cases...\n\n")

# Load implementation
source("implement-aicc.R")

# Run tests
test_results <- test_file("test-aicc.R", reporter = "summary")

# Print summary
df <- as.data.frame(test_results)
passed <- sum(df$passed)
failed <- sum(df$failed)
errors <- sum(df$error)

cat("\n=== RESULTS ===\n")
cat(sprintf("Passed: %d / %d tests\n", passed, nrow(df)))
if (failed > 0) cat(sprintf("Failed: %d tests\n", failed))
if (errors > 0) cat(sprintf("Errors: %d tests\n", errors))

if (failed == 0 && errors == 0) {
  cat("\n✅ All tests green. Prototype validated.\n")
  quit(status = 0)
} else {
  cat("\n❌ Some tests failed. Review output above.\n")
  quit(status = 1)
}
