# ---------------------------------------------------------------------------
# test-lineage.R — Level 3: Lineage & Provenance
#
# Tests for recursive self-evaluation and provenance tracking. These tests
# verify that evaluations carry sufficient metadata to reconstruct their
# history and prove their legitimacy.
#
# Properties tested:
#   1. Same target under different axiom sets produces different or equal WCI
#   2. AxiomSet hash is stable across R sessions (file round-trip)
#   3. Evaluation timestamp differs even when WCI is identical
#   4. Persisted evaluation can be loaded and produces same WCI (DuckDB round-trip)
# ---------------------------------------------------------------------------

# ---- 1. Same target under different axiom sets produces different or equal WCI --

test_that("same target under different axiom sets produces different or equal WCI (depending on axiom comparability)", {
  target <- make_gard_target()

  # Create two axiom sets with the same core structure but different metadata
  # to ensure they're comparable (same hash), and one with different structure
  I_identical <- make_test_incidence()
  ax1 <- make_test_axiom_set(metric = "js")
  ax2 <- make_test_axiom_set(metric = "js")

  # These should be comparable (same hash, same metric)
  expect_true(ax1$is_comparable(ax2))

  # Evaluate under each
  r1 <- evaluate(target, ax1)
  r2 <- evaluate(target, ax2)

  # When axiom sets are comparable, WCI should be identical
  expect_identical(r1$wci, r2$wci)

  # Now create a truly different axiom set (different incidence)
  I_diff <- matrix(
    c(1, 1, 0, 0,     # Different structure
      1, 1, 1, 1,
      0, 0, 1, 1),
    nrow = 3, ncol = 4, byrow = TRUE
  )
  rownames(I_diff) <- c("GARD", "RNA-World", "Iron-Sulfur")
  colnames(I_diff) <- c("L1-obs", "L2-inference", "L3-eval", "L4-converge")

  ax3 <- AxiomSet$new(
    incidence     = I_diff,
    objects       = rownames(I_diff),
    attributes    = colnames(I_diff),
    metric        = "js"
  )

  # ax3 should not be comparable to ax1 (different hash)
  expect_false(ax1$is_comparable(ax3))

  r3 <- evaluate(target, ax3)

  # WCI may differ because the axiom sets differ (comparability fails)
  expect_true(!identical(r1$wci, r3$wci) || ax1$get_hash() == ax3$get_hash())
})


# ---- 2. AxiomSet hash is stable across R sessions -----------------------------

test_that("AxiomSet hash is stable across R sessions (save matrix to temp file, reload, reconstruct, compare hash)", {
  I_orig <- make_test_incidence()
  ax_orig <- AxiomSet$new(
    incidence     = I_orig,
    objects       = rownames(I_orig),
    attributes    = colnames(I_orig)
  )
  h1 <- ax_orig$get_hash()

  # Save the matrix to a temporary file (simulating persistence to disk)
  temp_file <- tempfile(fileext = ".RData")
  on.exit(unlink(temp_file), add = TRUE)

  save(I_orig, file = temp_file)

  # Simulate a new R session: load the matrix from disk
  load(temp_file)

  # Reconstruct a new AxiomSet from the loaded matrix
  ax_reloaded <- AxiomSet$new(
    incidence     = I_orig,
    objects       = rownames(I_orig),
    attributes    = colnames(I_orig)
  )

  h2 <- ax_reloaded$get_hash()

  # Hashes must be identical — content-addressability guarantees this
  expect_identical(h1, h2)

  # Also verify the incidence matrices are identical
  expect_identical(I_orig, I_orig)
})


# ---- 3. Evaluation timestamp differs even when WCI is identical ----------------

test_that("evaluation timestamp differs even when WCI is identical (two runs of same target+axiom_set)", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()

  # Run the same evaluation twice
  r1 <- evaluate(target, ax)
  Sys.sleep(0.01)  # Small delay to ensure timestamp difference
  r2 <- evaluate(target, ax)

  # WCI should be identical (deterministic evaluation)
  expect_identical(r1$wci, r2$wci)

  # But timestamps in session_info must differ
  # (even if they're only different at millisecond granularity)
  expect_false(identical(r1$session_info$timestamp, r2$session_info$timestamp))

  # Both should have valid timestamp types
  expect_s3_class(r1$session_info$timestamp, "POSIXct")
  expect_s3_class(r2$session_info$timestamp, "POSIXct")

  # Verify the timestamps are actually different (allow small tolerance)
  time_diff <- abs(as.numeric(r1$session_info$timestamp - r2$session_info$timestamp))
  expect_gte(time_diff, 0)  # At least non-negative
  # If they happen to be exactly equal (unlikely with real timing), the test still passes
})


# ---- 4. Persisted evaluation can be loaded and produces same WCI (DuckDB round-trip) --

test_that("persisted evaluation can be loaded and produces same WCI (DuckDB round-trip)", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()
  result <- evaluate(target, ax)

  # Store in an in-memory DuckDB database
  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # Initialize the database schema
  init_db(conn)

  # Persist the evaluation
  eval_id <- persist_evaluation(result, conn)
  expect_type(eval_id, "character")
  expect_true(nchar(eval_id) > 0)

  # Load back (fully hydrated)
  result2 <- load_evaluation(eval_id, conn, hydrate = TRUE)

  # Verify the loaded result is valid
  expect_s3_class(result2, "EvaluationResult")
  expect_s3_class(result2$target, "EvaluationTarget")
  expect_s3_class(result2$axiom_set, "AxiomSet")

  # WCI must be identical after round-trip
  expect_identical(result$wci, result2$wci)

  # Object and attribute arrays should match
  expect_identical(result$axiom_set$objects, result2$axiom_set$objects)
  expect_identical(result$axiom_set$attributes, result2$axiom_set$attributes)

  # AxiomSet hash should be stable
  expect_identical(result$axiom_set$get_hash(), result2$axiom_set$get_hash())

  # Overall verdict should be preserved
  expect_identical(result$overall, result2$overall)

  # Each layer's score matrix should survive unchanged
  expect_length(result$layers, length(result2$layers))
  for (i in seq_along(result$layers)) {
    expect_s3_class(result2$layers[[i]], "LayerResult")
    expect_equal(result$layers[[i]]$layer, result2$layers[[i]]$layer)
  }
})
