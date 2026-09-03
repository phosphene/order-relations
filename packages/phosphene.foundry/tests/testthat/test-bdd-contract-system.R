# test-bdd-contract-system.R
# BDD specs for the contract validation and pure transform system.
# describe()/it() blocks read as a specification document.

describe("Contract Validation System", {

  describe("Column presence checks", {
    it("accepts a data frame with all required columns", {
      df <- data.frame(id = 1:3, value = c(1.0, 2.0, 3.0), group = c("a", "b", "c"))
      expect_true(validate_contract(df, required_cols = c("id", "value", "group")))
    })

    it("rejects a data frame missing required columns", {
      df <- data.frame(id = 1:3)
      expect_error(
        validate_contract(df, required_cols = c("id", "missing_col")),
        "Missing required columns: missing_col"
      )
    })

    it("reports all missing columns in a single error", {
      df <- data.frame(x = 1)
      expect_error(
        validate_contract(df, required_cols = c("a", "b", "c")),
        "a, b, c"
      )
    })
  })

  describe("Type enforcement", {
    it("accepts columns matching expected types", {
      df <- data.frame(name = c("a", "b"), score = c(1.5, 2.5))
      expect_true(
        validate_contract(df,
          required_cols = c("name", "score"),
          col_types = list(name = "character", score = "double"))
      )
    })

    it("rejects columns with wrong types", {
      df <- data.frame(value = c(1L, 2L, 3L))  # integer, not double
      expect_error(
        validate_contract(df,
          required_cols = "value",
          col_types = list(value = "double")),
        "expected type 'double', got 'integer'"
      )
    })

    it("skips type checks for columns not in col_types", {
      df <- data.frame(a = 1:3, b = c("x", "y", "z"))
      expect_true(
        validate_contract(df,
          required_cols = c("a", "b"),
          col_types = list(a = "integer"))
      )
    })
  })

  describe("NA handling policy", {
    it("allows NAs by default", {
      df <- data.frame(id = c("a", NA, "c"), value = c(1.0, 2.0, 3.0))
      expect_true(validate_contract(df, required_cols = c("id", "value")))
    })

    it("rejects NAs when allow_na = FALSE", {
      df <- data.frame(id = c("a", NA), value = c(1.0, 2.0))
      expect_error(
        validate_contract(df, required_cols = "id", allow_na = FALSE),
        "has 1 NA values"
      )
    })

    it("counts multiple NAs in the error message", {
      df <- data.frame(x = c(NA, NA, NA, 1.0))
      expect_error(
        validate_contract(df, required_cols = "x", allow_na = FALSE),
        "has 3 NA values"
      )
    })
  })

  describe("Error labeling", {
    it("includes the custom label in error messages", {
      df <- data.frame(a = 1)
      expect_error(
        validate_contract(df, required_cols = "b", label = "grambank_input"),
        "\\[grambank_input\\]"
      )
    })
  })
})


describe("Pure Transform Pipeline", {

  describe("Pre-condition enforcement", {
    it("fails before running the transform when input contract is violated", {
      transform_called <- FALSE
      bad_transform <- function(df) {
        transform_called <<- TRUE
        df
      }

      expect_error(
        pure_transform(
          data.frame(wrong = 1:3),
          transform_fn = bad_transform,
          input_cols = "required_col"
        ),
        "Missing required columns"
      )
      expect_false(transform_called)
    })
  })

  describe("Post-condition enforcement", {
    it("validates the transform output against required columns", {
      drop_col <- function(df) df[, "a", drop = FALSE]

      expect_error(
        pure_transform(
          data.frame(a = 1:3, b = 4:6),
          transform_fn = drop_col,
          input_cols = "a",
          output_cols = c("a", "b")
        ),
        "Missing required columns: b"
      )
    })

    it("rejects non-data.frame return values", {
      to_list <- function(df) as.list(df)

      expect_error(
        pure_transform(data.frame(x = 1), transform_fn = to_list),
        "must return a data.frame"
      )
    })
  })

  describe("Composition of transforms", {
    it("chains multiple pure_transform calls maintaining contracts", {
      step1 <- function(df) {
        df$doubled <- df$value * 2
        df
      }
      step2 <- function(df) {
        df$label <- ifelse(df$doubled > 5, "high", "low")
        df
      }

      input <- data.frame(value = 1:5)

      result <- pure_transform(input, step1,
        input_cols = "value", output_cols = c("value", "doubled"))

      result <- pure_transform(result, step2,
        input_cols = c("value", "doubled"), output_cols = c("value", "doubled", "label"))

      expect_equal(result$label, c("low", "low", "high", "high", "high"))
    })
  })
})
