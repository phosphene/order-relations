# Step definitions for data_pipeline.feature

library(cucumber)
library(testthat)

world <- new.env(parent = emptyenv())

# --- Given steps ---

given("a data frame with columns {string} and {string}", function(col1, col2) {
  world$df <- data.frame(
    placeholder1 = c("a", "b", "c"),
    placeholder2 = c(1.0, 2.0, 3.0),
    stringsAsFactors = FALSE
  )
  names(world$df) <- c(col1, col2)
})

given("a data frame with columns {string} only", function(col1) {
  world$df <- data.frame(placeholder = c("a", "b", "c"), stringsAsFactors = FALSE)
  names(world$df) <- col1
})

given("a data frame where column {string} has type {string}", function(col_name, col_type) {
  if (col_type == "integer") {
    world$df <- data.frame(placeholder = c(1L, 2L, 3L))
  } else {
    world$df <- data.frame(placeholder = c(1.0, 2.0, 3.0))
  }
  names(world$df) <- col_name
})

given("a data frame with NA values in column {string}", function(col_name) {
  world$df <- data.frame(placeholder = c("a", NA, "c"), stringsAsFactors = FALSE)
  names(world$df) <- col_name
})

given("a data frame with columns {string} containing numbers {int} to {int}", function(col_name, from_val, to_val) {
  world$df <- data.frame(placeholder = seq(from_val, to_val))
  names(world$df) <- col_name
})

# --- When steps ---

when("I validate the contract requiring columns {string} and {string}", function(col1, col2) {
  world$required_cols <- c(col1, col2)
  world$result <- tryCatch(
    {
      validate_contract(world$df, required_cols = world$required_cols)
      list(success = TRUE, error = NULL)
    },
    error = function(e) list(success = FALSE, error = e$message)
  )
})

when("I validate the contract expecting column {string} to be type {string}", function(col_name, expected_type) {
  world$result <- tryCatch(
    {
      validate_contract(world$df, required_cols = col_name,
                        col_types = setNames(list(expected_type), col_name))
      list(success = TRUE, error = NULL)
    },
    error = function(e) list(success = FALSE, error = e$message)
  )
})

when("I validate the contract for column {string} with allow_na disabled", function(col_name) {
  world$result <- tryCatch(
    {
      validate_contract(world$df, required_cols = col_name, allow_na = FALSE)
      list(success = TRUE, error = NULL)
    },
    error = function(e) list(success = FALSE, error = e$message)
  )
})

when("I apply a pure transform requiring input column {string}", function(col_name) {
  world$result <- tryCatch(
    {
      pure_transform(world$df, transform_fn = identity, input_cols = col_name)
      list(success = TRUE, error = NULL)
    },
    error = function(e) list(success = FALSE, error = e$message)
  )
})

when("I apply a transform that drops column {string} but output requires {string} and {string}",
  function(drop_col, req1, req2) {
    world$result <- tryCatch(
      {
        pure_transform(
          world$df,
          transform_fn = function(df) df[, setdiff(names(df), drop_col), drop = FALSE],
          output_cols = c(req1, req2)
        )
        list(success = TRUE, error = NULL)
      },
      error = function(e) list(success = FALSE, error = e$message)
    )
  }
)

when("I apply a transform that doubles the values", function() {
  world$df <- pure_transform(
    world$df,
    transform_fn = function(df) {
      col <- names(df)[1]
      df$doubled <- df[[col]] * 2
      df
    },
    input_cols = names(world$df)[1],
    output_cols = c(names(world$df)[1], "doubled")
  )
})

when("I apply a transform that labels values above {int} as {string}", function(threshold, high_label) {
  world$df <- pure_transform(
    world$df,
    transform_fn = function(df) {
      df$label <- ifelse(df$doubled > threshold, high_label, "low")
      df
    },
    input_cols = "doubled",
    output_cols = c("doubled", "label")
  )
})

# --- Then steps ---

then("the validation should succeed", function() {
  expect_true(world$result$success,
    info = paste("Expected success but got error:", world$result$error))
})

then("the validation should fail with message {string}", function(expected_msg) {
  expect_false(world$result$success)
  expect_true(grepl(expected_msg, world$result$error, fixed = TRUE),
    info = paste("Expected message containing:", expected_msg,
                 "\nGot:", world$result$error))
})

then("the transform should fail with message {string}", function(expected_msg) {
  expect_false(world$result$success)
  expect_true(grepl(expected_msg, world$result$error, fixed = TRUE),
    info = paste("Expected:", expected_msg, "\nGot:", world$result$error))
})

then("the final result should have a {string} column", function(col_name) {
  expect_true(col_name %in% names(world$df))
})

then("values {int} and {int} should be labeled {string}", function(v1, v2, expected_label) {
  labels <- world$df$label[world$df$doubled %in% c(v1 * 2, v2 * 2)]
  expect_true(all(labels == expected_label))
})

then("values {int} {int} and {int} should be labeled {string}", function(v1, v2, v3, expected_label) {
  labels <- world$df$label[world$df$doubled %in% c(v1 * 2, v2 * 2, v3 * 2)]
  expect_true(all(labels == expected_label))
})
