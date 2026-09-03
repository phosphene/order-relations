#!/usr/bin/env Rscript
# Automated test runner with JSON validation report output.
#
# Usage: Rscript run_tests.R

library(testthat)

results <- testthat::test_local(
  path = ".",
  reporter = testthat::ListReporter
)

# Build validation report
summary_data <- as.data.frame(results)
n_pass <- sum(summary_data$passed, na.rm = TRUE)
n_fail <- sum(summary_data$failed, na.rm = TRUE)
n_skip <- sum(summary_data$skipped, na.rm = TRUE)

report <- list(
  timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  r_version = paste0(R.version$major, ".", R.version$minor),
  tests_passed = n_pass,
  tests_failed = n_fail,
  tests_skipped = n_skip,
  all_passed = n_fail == 0
)

dir.create("results", showWarnings = FALSE)

if (requireNamespace("jsonlite", quietly = TRUE)) {
  jsonlite::write_json(report, "results/validation_report.json",
                       pretty = TRUE, auto_unbox = TRUE)
} else {
  # Fallback: manual JSON
  json_str <- sprintf(
    '{\n  "timestamp": "%s",\n  "r_version": "%s",\n  "tests_passed": %d,\n  "tests_failed": %d,\n  "tests_skipped": %d,\n  "all_passed": %s\n}',
    report$timestamp, report$r_version,
    report$tests_passed, report$tests_failed, report$tests_skipped,
    tolower(as.character(report$all_passed))
  )
  writeLines(json_str, "results/validation_report.json")
}

if (n_fail > 0) {
  message(sprintf("FAIL: %d tests failed", n_fail))
  quit(status = 1)
} else {
  message(sprintf("PASS: All %d tests passed", n_pass))
}
