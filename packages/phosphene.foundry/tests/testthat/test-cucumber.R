# test-cucumber.R
# Gherkin acceptance test runner.
# Executes .feature files from inst/features/ using cucumber step definitions.

test_that("Gherkin acceptance specifications pass", {
  skip_if_not_installed("cucumber")

  # Source step definitions
  step_dir <- system.file("../tests/testthat/step-definitions",
                           package = "phosphene.foundry",
                           mustWork = FALSE)
  if (!nzchar(step_dir) || !dir.exists(step_dir)) {
    step_dir <- file.path("step-definitions")
  }

  feature_dir <- system.file("features",
                              package = "phosphene.foundry",
                              mustWork = FALSE)
  if (!nzchar(feature_dir) || !dir.exists(feature_dir)) {
    feature_dir <- file.path("..", "..", "inst", "features")
  }

  skip_if(!dir.exists(feature_dir), "Feature directory not found")
  skip_if(!dir.exists(step_dir), "Step definitions directory not found")

  cucumber::run(
    features = feature_dir,
    steps = step_dir
  )
})
