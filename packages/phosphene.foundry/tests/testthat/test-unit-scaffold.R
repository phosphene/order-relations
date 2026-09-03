# test-unit-scaffold.R
# Unit tests for artifact scaffolding.
# Tier 1: filesystem operations, deterministic.

test_that("foundry_scaffold creates correct directory structure", {
  tmp <- tempdir()
  target <- file.path(tmp, paste0("test-scaffold-", Sys.getpid()))

  on.exit(unlink(target, recursive = TRUE), add = TRUE)

  result <- foundry_scaffold(target, name = "Test Artifact")

  expect_true(result)
  expect_true(dir.exists(file.path(target, "R")))
  expect_true(dir.exists(file.path(target, "tests", "testthat")))
  expect_true(dir.exists(file.path(target, "data")))
  expect_true(dir.exists(file.path(target, "results")))
  expect_true(dir.exists(file.path(target, ".github", "workflows")))
  expect_true(file.exists(file.path(target, "DESCRIPTION")))
  expect_true(file.exists(file.path(target, ".gitignore")))
  expect_true(file.exists(file.path(target, ".lintr")))
  expect_true(file.exists(file.path(target, "run_pipeline.sh")))
  expect_true(file.exists(file.path(target, "run_tests.R")))
  expect_true(file.exists(file.path(target, "README.md")))
  expect_true(file.exists(file.path(target, ".github", "workflows", "ci.yml")))
})

test_that("foundry_scaffold DESCRIPTION is parseable", {
  tmp <- tempdir()
  target <- file.path(tmp, paste0("test-desc-", Sys.getpid()))

  on.exit(unlink(target, recursive = TRUE), add = TRUE)

  foundry_scaffold(target, name = "Parse Test")

  desc <- read.dcf(file.path(target, "DESCRIPTION"))
  expect_true("Package" %in% colnames(desc))
  expect_true("Title" %in% colnames(desc))
  expect_equal(unname(desc[1, "Title"]), "Parse Test")
})

test_that("foundry_scaffold with use_brms adds Stan directory", {
  tmp <- tempdir()
  target <- file.path(tmp, paste0("test-brms-", Sys.getpid()))

  on.exit(unlink(target, recursive = TRUE), add = TRUE)

  foundry_scaffold(target, name = "Brms Test", use_brms = TRUE)

  expect_true(dir.exists(file.path(target, "inst", "stan")))

  # Check DESCRIPTION includes brms
  desc <- readLines(file.path(target, "DESCRIPTION"))
  expect_true(any(grepl("brms", desc)))
})

test_that("foundry_scaffold rejects empty path", {
  expect_error(foundry_scaffold(""))
})

test_that("foundry_validate detects missing files", {
  tmp <- tempdir()
  target <- file.path(tmp, paste0("test-validate-", Sys.getpid()))
  dir.create(target, showWarnings = FALSE)
  on.exit(unlink(target, recursive = TRUE), add = TRUE)

  result <- foundry_validate(target)
  expect_false(result$valid)
  expect_true(length(result$errors) > 0)
})

test_that("foundry_validate passes on scaffolded artifact", {
  tmp <- tempdir()
  target <- file.path(tmp, paste0("test-valid-scaffold-", Sys.getpid()))
  on.exit(unlink(target, recursive = TRUE), add = TRUE)

  foundry_scaffold(target, name = "Validation Test")

  # Need a NAMESPACE file for validation
  writeLines("# auto", file.path(target, "NAMESPACE"))

  result <- foundry_validate(target)
  expect_true(result$valid)
})
