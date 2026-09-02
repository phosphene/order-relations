# test-cucumber.R
# Gherkin acceptance test runner for INFERNO-R.
# Executes .feature files from inst/features/ using cucumber step definitions.

test_that("Gherkin acceptance specifications pass", {
  skip_if_not_installed("cucumber")

  feature_dir <- tryCatch(
    system.file("features", package = "inferno", mustWork = TRUE),
    error = function(e) file.path("..", "..", "inst", "features")
  )

  skip_if(!dir.exists(feature_dir), "Feature directory not found")

  # Source step definitions if they exist
  step_dir <- file.path("step-definitions")
  if (dir.exists(step_dir)) {
    for (f in list.files(step_dir, pattern = "\\.R$", full.names = TRUE)) {
      source(f)
    }
  }

  cucumber::run(features = feature_dir)
})
