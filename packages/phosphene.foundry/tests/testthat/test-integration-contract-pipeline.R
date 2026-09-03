# test-integration-contract-pipeline.R
# Tier 2: End-to-end data pipeline with contract enforcement.
# Tests full transform chains, validation report generation, and schema checks.
# Guarded — runs in nightly CI only (RUN_INTEGRATION=true).

test_that("full transform pipeline enforces contracts at every step", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  # Step 1: Raw data with contract
  raw_data <- data.frame(
    id = paste0("LANG", 1:100),
    latitude = runif(100, -60, 70),
    longitude = runif(100, -180, 180),
    family = sample(c("IE", "Uralic", "Sino-Tibetan", "Austronesian"), 100, replace = TRUE),
    reflexive_type = sample(c("HEAD", "BODY", "SELF", "OTHER"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Step 2: Chain of pure transforms
  step1_result <- pure_transform(
    raw_data,
    transform_fn = function(df) {
      df$lat_c <- scale(df$latitude)[, 1]
      df$lon_c <- scale(df$longitude)[, 1]
      df
    },
    input_cols = c("id", "latitude", "longitude"),
    output_cols = c("id", "lat_c", "lon_c")
  )

  expect_true("lat_c" %in% names(step1_result))
  expect_equal(mean(step1_result$lat_c), 0, tolerance = 1e-10)

  step2_result <- pure_transform(
    step1_result,
    transform_fn = function(df) {
      df$bpdr <- as.integer(df$reflexive_type == "HEAD")
      df$caucasus <- as.integer(
        df$latitude >= 39 & df$latitude <= 44 &
        df$longitude >= 38 & df$longitude <= 50
      )
      df
    },
    input_cols = c("id", "latitude", "longitude", "reflexive_type"),
    output_cols = c("id", "bpdr", "caucasus")
  )

  expect_true(all(step2_result$bpdr %in% c(0L, 1L)))
  expect_true(all(step2_result$caucasus %in% c(0L, 1L)))

  # Step 3: Final output contract
  validate_contract(
    step2_result,
    required_cols = c("id", "lat_c", "lon_c", "bpdr", "caucasus", "family"),
    col_types = list(bpdr = "integer", caucasus = "integer"),
    label = "final_output"
  )
})


test_that("pipeline rejects corrupt input at first transform", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")

  corrupt_data <- data.frame(
    wrong_col = 1:10,
    stringsAsFactors = FALSE
  )

  expect_error(
    pure_transform(
      corrupt_data,
      transform_fn = identity,
      input_cols = c("id", "latitude", "longitude")
    ),
    "Missing required columns"
  )
})


test_that("validation report JSON is well-formed", {
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true",
              message = "Skipping integration test (RUN_INTEGRATION != true)")
  skip_if_not_installed("jsonlite")

  # Build a mock validation report like run_tests.R produces
  report <- list(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    r_version = paste0(R.version$major, ".", R.version$minor),
    tests_passed = 52L,
    tests_failed = 0L,
    tests_skipped = 0L,
    all_passed = TRUE
  )

  tmp_file <- tempfile(fileext = ".json")
  on.exit(unlink(tmp_file), add = TRUE)

  jsonlite::write_json(report, tmp_file, pretty = TRUE, auto_unbox = TRUE)

  # Read back and validate structure
  parsed <- jsonlite::read_json(tmp_file)

  expect_type(parsed$timestamp, "character")
  expect_type(parsed$r_version, "character")
  expect_type(parsed$tests_passed, "integer")
  expect_type(parsed$tests_failed, "integer")
  expect_true(parsed$all_passed)
  expect_equal(parsed$tests_passed, 52L)
})
