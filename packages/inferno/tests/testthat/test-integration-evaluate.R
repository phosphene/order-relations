# ---------------------------------------------------------------------------
# test-integration-evaluate.R — Full 7-layer integration tests for evaluate()
#
# Tier 2: Integration. Guarded by RUN_INTEGRATION env var.
# Exercises the complete dispatch pipeline: evaluate() → 7 layers →
# EvaluationResult. Verifies structural invariants, WCI shape, and render

if (Sys.getenv("RUN_INTEGRATION") != "true") {
  message("Skipping integration tests (RUN_INTEGRATION != true)")
  return(invisible())
}
# output correctness.
#
# Test cases:
#   1. Full 7-layer pass on GARD mock target
#   2. All 7 layers present in result
#   3. WCI has 6 dimensions + composite
#   4. render() produces valid parseable JSON
#   5. render() produces Markdown with layer table
#   6. evaluate() with config overrides
#   7. evaluate() with circuit-breaker-safe context
#   8. compose_verdict() produces expected format
#   9. capture_session() returns named fields
# ---------------------------------------------------------------------------

# ---- 1. Full 7-layer pass on GARD mock target ------------------------------

test_that("evaluate runs full 7-layer pipeline on GARD target", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()

  # Suppress fcaR messages during lattice computation
  result <- evaluate(target, axiom_set, config = list(seed = 42))

  # Should return an EvaluationResult
  expect_s3_class(result, "EvaluationResult")
  expect_true(inherits(result, "EvaluationResult"))

  # Target and axiom set should be preserved
  expect_identical(result$target$title, target$title)
  expect_identical(result$axiom_set$get_hash(), axiom_set$get_hash())

  # Verdict should be a non-empty character string
  expect_type(result$overall, "character")
  expect_true(nchar(result$overall) > 0)

  # Session info should be a list with the expected fields
  expect_type(result$session_info, "list")
  expect_true("r_version" %in% names(result$session_info))
  expect_true("seed" %in% names(result$session_info))
  expect_true("timestamp" %in% names(result$session_info))
  expect_true("inferno_version" %in% names(result$session_info))
})


# ---- 2. All 7 layers present in result -------------------------------------

test_that("all 7 layers are present in the result", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  layers <- result$layers
  expect_length(layers, 7L)

  # Each layer should be a LayerResult with correct layer number
  for (i in seq_len(7L)) {
    expect_s3_class(layers[[i]], "LayerResult")
    expect_true(inherits(layers[[i]], "LayerResult"))
    expect_equal(layers[[i]]$layer, i)
    expect_type(layers[[i]]$layer_name, "character")
    expect_true(nchar(layers[[i]]$layer_name) > 0)
  }

  # Named layer order
  expected_names <- c(
    "Epistemic Stack",
    "Claims/Evidence/Inference Triangle (M-Failure Audit)",
    "Dual-Register Analysis",
    "Compression Taxonomy",
    "Semiotic Analysis",
    "Analogical Argument (Bartha)",
    "Weighted Credibility Index (WCI)"
  )
  for (i in seq_len(7L)) {
    expect_equal(layers[[i]]$layer_name, expected_names[i])
  }

  # get_layer convenience method should work
  for (i in seq_len(7L)) {
    expect_equal(result$get_layer(i)$layer, i)
  }
})


# ---- 3. WCI has 6 dimensions + composite -----------------------------------

test_that("WCI has 6 dimensions plus composite score", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  wci <- result$wci
  expect_type(wci, "double")

  # Should have exactly 7 named entries
  expect_length(wci, 7L)

  expected_dims <- c(
    "theoretical_coherence",
    "empirical_support",
    "replicability",
    "independent_uptake",
    "explanatory_power",
    "falsifiability",
    "composite"
  )
  expect_true(all(expected_dims %in% names(wci)))

  # All scores should be in [0, 1]
  for (dim_name in expected_dims) {
    expect_true(wci[[dim_name]] >= 0, info = sprintf("%s >= 0", dim_name))
    expect_true(wci[[dim_name]] <= 1, info = sprintf("%s <= 1", dim_name))
  }

  # Composite should be consistent with component scores
  # (weighted average of the 6, using equal weights by default)
  components <- wci[expected_dims[1:6]]
  expected_composite <- mean(components)
  expect_equal(wci["composite"], expected_composite, tolerance = 1e-6)
})


# ---- 4. render() produces valid JSON that can be parsed back -----------------

test_that("render() produces valid parseable JSON", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  json_str <- render(result, format = "json")
  expect_type(json_str, "character")
  expect_true(nchar(json_str) > 0)

  # Verify it parses back to a list
  parsed <- jsonlite::fromJSON(json_str, simplifyVector = FALSE)
  expect_type(parsed, "list")

  # Top-level structure
  expect_true("version" %in% names(parsed))
  expect_true("target" %in% names(parsed))
  expect_true("layers" %in% names(parsed))
  expect_true("wci" %in% names(parsed))
  expect_true("overall" %in% names(parsed))
  expect_true("session" %in% names(parsed))

  # Version should be inferno-v1
  expect_equal(parsed$version, "inferno-v1")

  # Should have 7 layers
  expect_length(parsed$layers, 7L)

  # WCI should have 7 values
  expect_length(parsed$wci, 7L)
  expect_true("composite" %in% names(parsed$wci))

  # Session should have expected fields
  expect_true("r_version" %in% names(parsed$session))
  expect_true("seed" %in% names(parsed$session))
  expect_true("timestamp" %in% names(parsed$session))
})


# ---- 5. render() produces Markdown with layer table -------------------------

test_that("render() produces Markdown with layer table", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  md_str <- render(result, format = "md")
  expect_type(md_str, "character")
  expect_true(nchar(md_str) > 0)

  # Should contain a level-1 heading with the target title
  expect_match(md_str, sprintf("# INFERNO Evaluation: %s", target$title))

  # Should contain a layer results table
  expect_match(md_str, "| Layer | Name | Status | Gap Diagnosis |")
  expect_match(md_str, "|------|------|--------|---------------|")

  # Should have exactly 7 data rows in the layer table
  layer_rows <- regmatches(md_str, gregexpr("^\\|\\s*\\d+\\s*\\|", md_str, multiline = TRUE))[[1]]
  expect_length(layer_rows, 7L)

  # Should contain WCI section
  expect_match(md_str, "## Weighted Credibility Index \\(WCI\\)")
  expect_match(md_str, "\\| composite \\|")

  # Should contain overall verdict section
  expect_match(md_str, "## Overall Verdict")

  # Should contain session info section
  expect_match(md_str, "## Session Information")
  expect_match(md_str, "Seed:")
  expect_match(md_str, "Timestamp:")
})


# ---- 6. evaluate() with config overrides ------------------------------------

test_that("evaluate() respects config overrides", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()

  # Different seed should produce same result (deterministic pipeline)
  result1 <- evaluate(target, axiom_set, config = list(seed = 1))
  result2 <- evaluate(target, axiom_set, config = list(seed = 99))

  # All layers should be deterministic regardless of seed
  for (i in seq_len(7L)) {
    expect_equal(result1$layers[[i]]$layer_name, result2$layers[[i]]$layer_name)
  }

  # WCI should be identical (deterministic pipeline)
  expect_equal(result1$wci, result2$wci, tolerance = 1e-6)

  # Session info should differ in seed
  expect_equal(result1$session_info$seed, 1L)
  expect_equal(result2$session_info$seed, 99L)
})


# ---- 7. evaluate() with circuit-breaker-safe context ------------------------

test_that("evaluate handles small contexts safely", {
  # A minimal 2x2 context
  I <- matrix(c(1, 0, 0, 1), nrow = 2, ncol = 2,
              dimnames = list(c("obj1", "obj2"), c("L1-obs", "L2-inference")))
  small_ax <- AxiomSet$new(
    incidence  = I,
    objects    = c("obj1", "obj2"),
    attributes = c("L1-obs", "L2-inference")
  )

  small_target <- EvaluationTarget$new(
    artifact_type = "model",
    title         = "Minimal Model",
    claims = list(
      Claim$new(id = "C1", text = "Minimal observation",
                evidence = "Basic test", register = "R1_research")
    )
  )

  # Should not trigger circuit breaker
  result <- evaluate(small_target, small_ax)
  expect_s3_class(result, "EvaluationResult")
  expect_length(result$layers, 7L)
})


# ---- 8. compose_verdict() produces expected format --------------------------

test_that("compose_verdict produces expected format", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  # compose_verdict should be callable directly
  verdict <- compose_verdict(result$layers)
  expect_type(verdict, "character")
  expect_true(nchar(verdict) > 0)

  # The overall field in the result should match
  expect_equal(result$overall, verdict)
})


# ---- 9. capture_session() returns named fields -----------------------------

test_that("capture_session returns expected fields", {
  si <- capture_session(seed = 42L)

  expect_type(si, "list")
  expect_named(si, c("r_version", "seed", "timestamp", "inferno_version"))

  expect_type(si$r_version, "character")
  expect_true(nchar(si$r_version) > 0)

  expect_equal(si$seed, 42L)

  expect_type(si$timestamp, "character")
  expect_true(nchar(si$timestamp) > 0)

  expect_type(si$inferno_version, "character")
  expect_true(nchar(si$inferno_version) > 0)
})


# ---- 10. render_yaml() produces valid YAML ---------------------------------

test_that("render_yaml produces valid YAML", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  yaml_str <- render(result, format = "yaml")
  expect_type(yaml_str, "character")
  expect_true(nchar(yaml_str) > 0)

  # Should contain key YAML structure
  expect_match(yaml_str, "version: inferno-v1")
  expect_match(yaml_str, "target:")
  expect_match(yaml_str, "layers:")
  expect_match(yaml_str, "wci:")
})


# ---- 11. render_json() handles edge cases with no claims --------------------

test_that("render_json handles empty claims gracefully", {
  empty_target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Empty Target",
    claims        = list()
  )
  I <- make_test_incidence()
  ax <- AxiomSet$new(
    incidence  = I,
    objects    = rownames(I),
    attributes = colnames(I)
  )

  result <- evaluate(empty_target, ax, config = list(seed = 42))
  json_str <- render(result, format = "json")

  parsed <- jsonlite::fromJSON(json_str, simplifyVector = FALSE)
  expect_equal(parsed$target$n_claims, 0)
  expect_length(parsed$layers, 7L)
})


# ---- 12. Layer 7 WCI detail from render_markdown ---------------------------

test_that("render_markdown shows all 6 WCI dimensions plus composite", {
  target    <- make_gard_target()
  axiom_set <- make_test_axiom_set()
  result    <- evaluate(target, axiom_set, config = list(seed = 42))

  md_str <- render(result, format = "md")

  # Each dimension should appear in the WCI table
  dims_display <- c(
    "Theoretical coherence",
    "Empirical support",
    "Replicability",
    "Independent uptake",
    "Explanatory power",
    "Falsifiability",
    "Composite"
  )

  for (dd in dims_display) {
    expect_match(md_str, sprintf("\\| %s \\|", dd))
  }
})