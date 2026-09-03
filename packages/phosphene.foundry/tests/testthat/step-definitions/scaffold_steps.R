# Step definitions for artifact_scaffold.feature

library(cucumber)
library(testthat)

world <- new.env(parent = emptyenv())

given("I scaffold a new artifact called {string}", function(name) {
  world$artifact_path <- file.path(tempdir(), paste0("cucumber-", name, "-", Sys.getpid()))
  foundry_scaffold(world$artifact_path, name = name)
})

given("I scaffold a new artifact called {string} with name {string}", function(dir_name, display_name) {
  world$artifact_path <- file.path(tempdir(), paste0("cucumber-", dir_name, "-", Sys.getpid()))
  foundry_scaffold(world$artifact_path, name = display_name)
})

given("I scaffold a new artifact called {string} with use_brms enabled", function(name) {
  world$artifact_path <- file.path(tempdir(), paste0("cucumber-", name, "-", Sys.getpid()))
  foundry_scaffold(world$artifact_path, name = name, use_brms = TRUE)
})

given("I add a NAMESPACE file to the artifact", function() {
  writeLines("# auto-generated", file.path(world$artifact_path, "NAMESPACE"))
})

then("the artifact should contain a {string} file", function(filepath) {
  full_path <- file.path(world$artifact_path, filepath)
  expect_true(file.exists(full_path),
    info = paste("Expected file:", filepath))
})

then("the artifact should contain a {string} directory", function(dirpath) {
  full_path <- file.path(world$artifact_path, dirpath)
  expect_true(dir.exists(full_path),
    info = paste("Expected directory:", dirpath))
})

then("the DESCRIPTION Title should be {string}", function(expected_title) {
  desc <- read.dcf(file.path(world$artifact_path, "DESCRIPTION"))
  expect_equal(unname(desc[1, "Title"]), expected_title)
})

then("the DESCRIPTION should include {string} in Imports", function(pkg_name) {
  desc_text <- readLines(file.path(world$artifact_path, "DESCRIPTION"))
  expect_true(any(grepl(pkg_name, desc_text)),
    info = paste("Expected", pkg_name, "in DESCRIPTION Imports"))
})

then("the artifact should pass foundry_validate", function() {
  result <- foundry_validate(world$artifact_path)
  expect_true(result$valid,
    info = paste("Validation errors:", paste(result$errors, collapse = "; ")))
})
