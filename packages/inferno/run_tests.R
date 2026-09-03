#!/usr/bin/env Rscript
#
# INFERNO-R test runner
#
# Runs the full test suite in tiers (invariants → serialization → lineage →
# property) and produces a JSON validation report.
#
# Usage:
#   Rscript run_tests.R                    # run all tiers
#   Rscript run_tests.R --tier invariants   # run single tier
#
# Output: tests/results/test-report.json

suppressPackageStartupMessages({
  library(testthat)
  library(jsonlite)
})

cli_args <- commandArgs(trailingOnly = TRUE)

# Default: run all tiers
tier_filter <- NULL
if (length(cli_args) >= 1 && grepl("^--tier=", cli_args[1])) {
  tier_filter <- sub("^--tier=", "", cli_args[1])
}

# Tier definitions
tiers <- list(
  invariants    = "test-invariants\\.[Rr]",
  serialization = "test-serialization\\.[Rr]",
  lineage       = "test-lineage\\.[Rr]",
  property      = "test-property\\.[Rr]",
  layer1        = "test-layer1\\.[Rr]",
  layer2        = "test-layer2\\.[Rr]",
  layer3        = "test-layer3\\.[Rr]",
  layer4        = "test-layer4\\.[Rr]",
  layer5        = "test-layer5\\.[Rr]",
  layer6        = "test-layer6\\.[Rr]",
  layer7        = "test-layer7\\.[Rr]",
  evaluate      = "test-evaluate\\.[Rr]"
)

if (!is.null(tier_filter) && !tier_filter %in% names(tiers)) {
  stop(sprintf("Unknown tier '%s'. Valid tiers: %s",
               tier_filter, paste(names(tiers), collapse = ", ")))
}

test_dir <- file.path("tests", "testthat")
results_file <- file.path("tests", "results", "test-report.json")

dir.create(dirname(results_file), showWarnings = FALSE, recursive = TRUE)

run_tier <- function(tier_name, filter_pattern, tier_filter) {
  if (!is.null(tier_filter) && tier_name != tier_filter) {
    return(NULL)
  }

  cat(sprintf("\n═══ Running tier: %s ═══\n", tier_name))
  result <- test_dir(
    test_dir,
    filter = filter_pattern,
    reporter = "silent",
    stop_on_failure = FALSE
  )

  result
}

results <- list()
all_passed <- TRUE

for (tier_name in names(tiers)) {
  pattern <- tiers[[tier_name]]
  test_result <- run_tier(tier_name, pattern, tier_filter)

  if (is.null(test_result)) next

  n_failed <- sum(sapply(test_result, function(tc) {
    if (inherits(tc, "testthat_results")) {
      sum(!tc$passed)
    } else {
      length(tc[!sapply(tc, `[[`, "passed")])
    }
  }))
  n_total <- length(test_result)

  tier_passed <- n_failed == 0
  if (!tier_passed) all_passed <- FALSE

  tier_record <- list(
    tier     = tier_name,
    total    = n_total,
    passed   = n_total - n_failed,
    failed   = n_failed,
    status   = if (tier_passed) "PASS" else "FAIL",
    failures = list()
  )

  # Collect failure details
  for (tc in test_result) {
    if (inherits(tc, "testthat_results")) {
      if (!tc$passed) {
        tier_record$failures <- c(
          tier_record$failures,
          list(list(test = tc$test, message = as.character(tc$message)))
        )
      }
    }
  }

  results[[tier_name]] <- tier_record

  cat(sprintf("  %s: %d/%d passed\n",
              if (tier_passed) "PASS" else "FAIL",
              tier_record$passed, tier_record$total))

  if (!tier_passed) {
    for (f in tier_record$failures) {
      cat(sprintf("    ✗ %s\n", f$test))
    }
  }
}

report <- list(
  timestamp   = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  package     = "inferno",
  version     = tryCatch(
    as.character(packageVersion("inferno")),
    error = function(e) "0.1.0"
  ),
  overall     = if (all_passed) "PASS" else "FAIL",
  tiers       = results,
  metadata    = list(
    r_version     = as.character(getRversion()),
    platform      = sessionInfo()$platform,
    testthat_edition = 3,
    runner        = "run_tests.R"
  )
)

write_json(report, results_file, pretty = TRUE, auto_unbox = TRUE)

cat(sprintf("\n═══ Results written to: %s ═══\n", results_file))
cat(sprintf("═══ Overall: %s ═══\n", report$overall))

if (!all_passed) {
  quit(status = 1, save = "no")
}