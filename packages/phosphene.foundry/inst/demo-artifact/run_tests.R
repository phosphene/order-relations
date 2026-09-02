#!/usr/bin/env Rscript
# Demo artifact test runner.
# Usage: Rscript run_tests.R

# Source the library
source("R/posterior.R")

library(testthat)

results <- testthat::test_dir(
  "tests/testthat",
  reporter = testthat::ListReporter
)

summary_data <- as.data.frame(results)
n_pass <- sum(summary_data$passed, na.rm = TRUE)
n_fail <- sum(summary_data$failed, na.rm = TRUE)

if (n_fail > 0) {
  message(sprintf("FAIL: %d tests failed", n_fail))
  quit(status = 1)
} else {
  message(sprintf("PASS: All %d tests passed", n_pass))
}
