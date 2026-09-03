# ---------------------------------------------------------------------------
# test-serialization.R — Level 2: Serialization Round-Trips
#
# Tests that INFERNO-R objects survive serialization and deserialization
# through the DuckDB persistence layer. Every test follows the pattern:
#   create → persist → load → compare
#
# Properties tested:
#   1. Incidence matrix survives DuckDB round-trip
#   2. AxiomSet hash is stable across save/load
#   3. Hydrated FormalContext produces same concept count as fresh
#   4. Full evaluation round-trip: WCI and layer scores survive
# ---------------------------------------------------------------------------

# ---- 1. Incidence matrix survives DuckDB round-trip ------------------------

test_that("incidence matrix survives DuckDB round-trip", {
  I <- make_test_incidence()
  ax <- AxiomSet$new(
    incidence  = I,
    objects    = rownames(I),
    attributes = colnames(I)
  )

  # Store in an in-memory DuckDB database
  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  init_db(conn)
  persist_axiom_set(ax, conn)

  # Load back
  ax2 <- load_axiom_set(ax$get_hash(), conn)

  # The incidence matrix should be identical after round-trip
  expect_identical(ax$incidence, ax2$incidence)
  expect_identical(ax$objects, ax2$objects)
  expect_identical(ax$attributes, ax2$attributes)
  expect_identical(ax$metric, ax2$metric)
  expect_identical(ax$domain_mapping, ax2$domain_mapping)
})


# ---- 2. AxiomSet hash is stable across save/load --------------------------

test_that("AxiomSet hash stable across save/load", {
  I <- make_test_incidence()
  ax <- AxiomSet$new(
    incidence  = I,
    objects    = rownames(I),
    attributes = colnames(I)
  )

  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  init_db(conn)
  persist_axiom_set(ax, conn)

  # Load back and verify hash
  ax2 <- load_axiom_set(ax$get_hash(), conn)

  # Hash should be identical — it's content-addressed
  expect_identical(ax$get_hash(), ax2$get_hash())

  # Reconstructing the same matrix should produce the same hash
  ax3 <- AxiomSet$new(
    incidence  = I,
    objects    = rownames(I),
    attributes = colnames(I)
  )
  expect_identical(ax$get_hash(), ax3$get_hash())
})


# ---- 3. Hydrated FormalContext produces same concept count as fresh -------

test_that("hydrated FormalContext produces same concept count as fresh", {
  I <- make_test_incidence()

  # Fresh context: compute concepts directly
  fc_fresh <- fcaR::FormalContext$new(I)
  fc_fresh$find_concepts(verbose = FALSE)
  n_concepts_fresh <- fc_fresh$concepts$size()

  # Round-trip through AxiomSet → DuckDB → AxiomSet → FormalContext
  ax <- AxiomSet$new(
    incidence  = I,
    objects    = rownames(I),
    attributes = colnames(I)
  )

  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  init_db(conn)
  persist_axiom_set(ax, conn)

  ax2 <- load_axiom_set(ax$get_hash(), conn)
  fc_hydrated <- ax2$to_formal_context()
  fc_hydrated$find_concepts(verbose = FALSE)
  n_concepts_hydrated <- fc_hydrated$concepts$size()

  # Both should produce the same number of concepts
  expect_equal(n_concepts_fresh, n_concepts_hydrated)
})


# ---- 4. Full evaluation round-trip: WCI and layer scores survive -----------

test_that("full evaluation round-trip: persist EvaluationResult → load → compare", {
  target <- make_gard_target()
  ax     <- make_test_axiom_set()
  result <- make_mock_evaluation_result(target = target, axiom_set = ax)

  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  init_db(conn)

  # Persist the full evaluation result
  eval_id <- persist_evaluation(result, conn)
  expect_type(eval_id, "character")
  expect_true(nchar(eval_id) > 0)

  # Load back with hydration
  result2 <- load_evaluation(eval_id, conn, hydrate = TRUE)
  expect_s3_class(result2, "EvaluationResult")
  expect_s3_class(result2$target, "EvaluationTarget")
  expect_s3_class(result2$axiom_set, "AxiomSet")

  # Compare WCI — all 7 dimensions should match
  expect_equal(result$wci, result2$wci)

  # Compare layer count and structure
  expect_equal(length(result$layers), length(result2$layers))
  for (i in seq_along(result$layers)) {
    lr_orig <- result$layers[[i]]
    lr_load <- result2$layers[[i]]

    expect_equal(lr_orig$layer, lr_load$layer)
    expect_equal(lr_orig$layer_name, lr_load$layer_name)

    # Score matrices should be identical
    if (!is.null(lr_orig$scores) && !is.null(lr_load$scores)) {
      expect_equal(lr_orig$scores, lr_load$scores)
    }
  }

  # Compare overall verdict
  expect_equal(result$overall, result2$overall)

  # Compare target metadata
  expect_equal(result$target$title, result2$target$title)
  expect_equal(result$target$artifact_type, result2$target$artifact_type)
  expect_equal(result$target$n_claims(), result2$target$n_claims())

  # Compare axiom set identity via content-addressable hash
  expect_identical(result$axiom_set$get_hash(), result2$axiom_set$get_hash())
})