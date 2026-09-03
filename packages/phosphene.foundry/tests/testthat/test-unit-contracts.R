# test-unit-contracts.R
# Unit tests for contract validation and pure transform utilities.
# Tier 1: deterministic, fast, no external deps.

test_that("validate_contract passes on valid data frame", {
  df <- data.frame(id = c("a", "b"), value = c(1.0, 2.0))
  expect_true(validate_contract(df, required_cols = c("id", "value")))
})

test_that("validate_contract fails on missing columns", {
  df <- data.frame(id = c("a", "b"))
  expect_error(
    validate_contract(df, required_cols = c("id", "value")),
    "Missing required columns: value"
  )
})

test_that("validate_contract checks column types", {
  df <- data.frame(id = c("a", "b"), value = c(1.0, 2.0))
  expect_true(
    validate_contract(df, required_cols = "value",
                      col_types = list(value = "double"))
  )
  expect_error(
    validate_contract(df, required_cols = "value",
                      col_types = list(value = "character")),
    "expected type 'character', got 'double'"
  )
})

test_that("validate_contract catches NAs when allow_na = FALSE", {
  df <- data.frame(id = c("a", NA), value = c(1.0, 2.0))
  expect_true(validate_contract(df, required_cols = "id"))
  expect_error(
    validate_contract(df, required_cols = "id", allow_na = FALSE),
    "has 1 NA values"
  )
})

test_that("validate_contract rejects non-data.frame input", {
  expect_error(
    validate_contract(list(a = 1), required_cols = "a"),
    "Expected a data.frame"
  )
})

test_that("pure_transform enforces input and output contracts", {
  add_doubled <- function(df) {
    df$doubled <- df$value * 2
    df
  }

  result <- pure_transform(
    data.frame(value = 1:5),
    transform_fn = add_doubled,
    input_cols = "value",
    output_cols = c("value", "doubled")
  )

  expect_equal(result$doubled, c(2, 4, 6, 8, 10))
})

test_that("pure_transform fails when input contract violated", {
  identity_fn <- function(df) df
  expect_error(
    pure_transform(
      data.frame(x = 1:3),
      transform_fn = identity_fn,
      input_cols = "y"
    ),
    "Missing required columns: y"
  )
})

test_that("pure_transform fails when output contract violated", {
  drop_fn <- function(df) df[, "value", drop = FALSE]
  expect_error(
    pure_transform(
      data.frame(value = 1:3, extra = 4:6),
      transform_fn = drop_fn,
      input_cols = "value",
      output_cols = c("value", "result")
    ),
    "Missing required columns: result"
  )
})

test_that("pure_transform rejects non-data.frame return", {
  bad_fn <- function(df) as.list(df)
  expect_error(
    pure_transform(data.frame(x = 1), transform_fn = bad_fn),
    "must return a data.frame"
  )
})
