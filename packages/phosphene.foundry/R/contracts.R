#' Contract validation and pure transform utilities
#'
#' Foundry primitives for the MPI Handoff Blueprint. Enforces
#' input/output contracts on data frames and provides a declarative
#' wrapper for pure functional transforms.
#'
#' @name contracts
NULL


#' Validate a data frame contract
#'
#' Checks that a data frame contains required columns with expected types.
#' Designed for use at function entry points (precondition) and exits
#' (postcondition) in the MPI Blueprint pattern.
#'
#' @param df A data frame to validate.
#' @param required_cols Character vector of required column names.
#' @param col_types Optional named list mapping column names to expected
#'   R type strings (as returned by `typeof()`). E.g.,
#'   `list(lat = "double", id = "character")`.
#' @param allow_na Logical; if `FALSE`, fails on any NA in required columns.
#'   Default `TRUE`.
#' @param label Character label for error messages (e.g., `"input"`,
#'   `"output"`).
#' @return Invisible `TRUE` if validation passes. Throws an error otherwise.
#' @export
#' @examples
#' df <- data.frame(id = c("a", "b"), value = c(1.0, 2.0))
#' validate_contract(df, required_cols = c("id", "value"))
validate_contract <- function(df,
                              required_cols = character(0),
                              col_types = NULL,
                              allow_na = TRUE,
                              label = "data") {
  if (!is.data.frame(df)) {
    stop(sprintf("[%s] Expected a data.frame, got %s.", label, class(df)[1]))
  }

  # Check required columns
  missing <- setdiff(required_cols, names(df))
  if (length(missing) > 0L) {
    stop(sprintf("[%s] Missing required columns: %s",
                 label, paste(missing, collapse = ", ")))
  }

  # Check column types
  if (!is.null(col_types)) {
    stopifnot(is.list(col_types), !is.null(names(col_types)))
    for (col_name in names(col_types)) {
      if (!col_name %in% names(df)) next
      actual_type <- typeof(df[[col_name]])
      expected_type <- col_types[[col_name]]
      if (actual_type != expected_type) {
        stop(sprintf("[%s] Column '%s': expected type '%s', got '%s'.",
                     label, col_name, expected_type, actual_type))
      }
    }
  }

  # Check NAs
 if (!allow_na) {
    for (col_name in required_cols) {
      if (any(is.na(df[[col_name]]))) {
        n_na <- sum(is.na(df[[col_name]]))
        stop(sprintf("[%s] Column '%s' has %d NA values (allow_na = FALSE).",
                     label, col_name, n_na))
      }
    }
  }

  invisible(TRUE)
}


#' Apply a pure functional transform with contract enforcement
#'
#' Wraps a transform function with pre- and post-condition contract
#' checks. The transform must accept a data frame and return a data frame.
#' This is the core MPI Blueprint pattern: data in, data out, contracts
#' enforced.
#'
#' @param df Input data frame.
#' @param transform_fn Function that accepts a data frame and returns
#'   a data frame.
#' @param input_cols Character vector of required input columns.
#' @param output_cols Character vector of required output columns.
#' @param input_types Optional named list of input column type checks.
#' @param output_types Optional named list of output column type checks.
#' @return Transformed data frame (validated).
#' @export
#' @examples
#' add_doubled <- function(df) {
#'   df$doubled <- df$value * 2
#'   df
#' }
#' result <- pure_transform(
#'   data.frame(value = 1:5),
#'   transform_fn = add_doubled,
#'   input_cols = "value",
#'   output_cols = c("value", "doubled")
#' )
pure_transform <- function(df,
                           transform_fn,
                           input_cols = character(0),
                           output_cols = character(0),
                           input_types = NULL,
                           output_types = NULL) {
  # Precondition
  validate_contract(df, required_cols = input_cols, col_types = input_types,
                    label = "input")

  # Transform
  result <- transform_fn(df)

  # Postcondition
  if (!is.data.frame(result)) {
    stop("Transform function must return a data.frame, got: ", class(result)[1])
  }
  validate_contract(result, required_cols = output_cols, col_types = output_types,
                    label = "output")

  result
}


#' Validate a Foundry artifact structure
#'
#' Checks that a directory follows the Foundry conventions:
#' required files exist, DESCRIPTION is parseable, tests directory
#' is populated.
#'
#' @param path Path to the artifact root directory.
#' @param strict Logical; if `TRUE`, also checks for optional but
#'   recommended files (LICENSE, .lintr, run_pipeline.sh).
#' @return A list with `valid` (logical), `errors` (character vector),
#'   and `warnings` (character vector).
#' @export
#' @examples
#' \dontrun{
#' foundry_validate("/path/to/my-analysis")
#' }
foundry_validate <- function(path, strict = FALSE) {
  errors <- character(0)
  warnings <- character(0)

  # Required files
  required <- c("DESCRIPTION", "NAMESPACE", "R/", "tests/", "run_tests.R")
  for (f in required) {
    target <- file.path(path, f)
    if (!file.exists(target)) {
      errors <- c(errors, sprintf("Missing required: %s", f))
    }
  }

  # Check DESCRIPTION is parseable
  desc_path <- file.path(path, "DESCRIPTION")
  if (file.exists(desc_path)) {
    tryCatch(
      read.dcf(desc_path),
      error = function(e) {
        errors <<- c(errors, sprintf("DESCRIPTION parse error: %s", e$message))
      }
    )
  }

  # Check tests directory has content
  test_dir <- file.path(path, "tests", "testthat")
  if (dir.exists(test_dir)) {
    test_files <- list.files(test_dir, pattern = "^test[_-].*\\.R$")
    if (length(test_files) == 0L) {
      warnings <- c(warnings, "tests/testthat/ exists but contains no test files")
    }
  }

  # Strict checks
  if (strict) {
    optional <- c("LICENSE", ".lintr", "run_pipeline.sh", ".github/workflows/ci.yml")
    for (f in optional) {
      if (!file.exists(file.path(path, f))) {
        warnings <- c(warnings, sprintf("Recommended file missing: %s", f))
      }
    }
  }

  list(
    valid = length(errors) == 0L,
    errors = errors,
    warnings = warnings
  )
}
