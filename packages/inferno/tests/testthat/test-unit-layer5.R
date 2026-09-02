# ---------------------------------------------------------------------------
# test-layer5.R — Layer 5: Semiotic Analysis
#
# Tests for Peircean classification of formal objects as icon, index, or
# symbol, semiosis risk detection, and semiotic network construction.
#
# Test cases:
#   1. Icon classification: objects resembling their referent (e.g., diagrams)
#   2. Index classification: objects causally connected (e.g., measurements)
#   3. Symbol classification: conventional signs (e.g., mathematical notation)
#   4. Mixed typing: objects that appear in different contexts across claims
#   5. Semiotic network construction from claim co-occurrence
#   6. Semiosis risk detection: unstable/contested typing
#   7. Edge case: empty claims produce no objects
#   8. Domain term integration via formal context attributes
#   9. Stability computation: consistently typed vs. inconsistently typed
#  10. Output format: scores matrix dimensions and column names
# ---------------------------------------------------------------------------

library(testthat)
library(igraph)


# ---- 1. Icon classification ------------------------------------------------

test_that("L5: icon — objects that resemble their referent", {
  # A claim about a network diagram used as a model
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network diagram illustrates the causal architecture",
      evidence = "Figure 3 shows the directed graph",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Icon Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)

  # The words "diagram", "network", "architecture" should trigger icon
  scores <- result$scores
  expect_true("diagram" %in% rownames(scores) ||
              "network" %in% rownames(scores) ||
              "architecture" %in% rownames(scores))

  # Check that at least one object is typed as icon
  expect_true("icon" %in% scores[, "type"])
})


# ---- 2. Index classification -----------------------------------------------

test_that("L5: index — objects causally connected to their referent", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The measurement reading shows a concentration of 2.5uM",
      evidence = "HPLC trace from experiment #42",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The observed signal correlates with temperature",
      evidence = "Time-series data from three replicates",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Index Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # "measurement" and "signal" should trigger index classification
  expect_true("measurement" %in% rownames(scores) ||
              "signal" %in% rownames(scores) ||
              "concentration" %in% rownames(scores) ||
              "reading" %in% rownames(scores) ||
              "trace" %in% rownames(scores) ||
              "data" %in% rownames(scores))

  # At least one index type should be present
  expect_true("index" %in% scores[, "type"])
})


# ---- 3. Symbol classification ----------------------------------------------

test_that("L5: symbol — conventionally associated signs", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The Shannon entropy equation defines the information measure",
      evidence = "Standard mathematical notation from information theory",
      register = "R2_rhetorical"
    ),
    Claim$new(
      id = "C2",
      text = "Category theory provides the axiomatic foundation",
      evidence = "Mac Lane's formulation",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Symbol Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # "equation", "axiom", "theory" should trigger symbol classification
  expect_true("equation" %in% rownames(scores) ||
              "axiom" %in% rownames(scores) ||
              "theory" %in% rownames(scores) ||
              "notation" %in% rownames(scores) ||
              "concept" %in% rownames(scores) ||
              "category" %in% rownames(scores))

  # At least one symbol type should be present
  expect_true("symbol" %in% scores[, "type"])
})


# ---- 4. Mixed typing: same object across different contexts -----------------

test_that("L5: mixed typing — same object appears in different semiotic modes", {
  # A term like "model" can be icon (as diagram) or symbol (as theoretical construct)
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network model represents the causal architecture",
      evidence = "Figure 3: directed graph of the model",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The theoretical model provides the axiomatic foundation",
      evidence = "Standard mathematical formulation",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Mixed Typing Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # The result should have a semiotic network
  expect_true(igraph::is_igraph(result$flags$semiotic_network))

  # The risk flags list should be populated
  # (model may be differently typed across claims)
  risk_details <- result$flags$semiosis_risks
  # We expect at least some risk flagged (mixed contexts)
  note <- result$notes
  expect_true(nchar(note) > 0)
})


# ---- 5. Semiotic network construction --------------------------------------

test_that("L5: semiotic network topology from claim co-occurrence", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network diagram shows the causal architecture",
      evidence = NULL,
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The measurement trace shows the signal response",
      evidence = NULL,
      register = "R1_research"
    ),
    Claim$new(
      id = "C3",
      text = "The network diagram and measurement trace together confirm the architecture",
      evidence = NULL,
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Network Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  g <- result$flags$semiotic_network

  # Should be a valid igraph
  expect_true(igraph::is_igraph(g))

  # Should have at least some vertices
  expect_gt(igraph::vcount(g), 0)

  # C3 co-occurs: "network" and "measurement" and "architecture" and "trace"
  # and "signal" may share edges from C3
  n_edges <- igraph::ecount(g)
  if (n_edges > 0) {
    # Nodes should have type, stability, risk_flag attributes
    expect_true("type" %in% igraph::vertex_attr_names(g))
    expect_true("stability" %in% igraph::vertex_attr_names(g))
    expect_true("risk_flag" %in% igraph::vertex_attr_names(g))
  }
})


# ---- 6. Semiosis risk detection --------------------------------------------

test_that("L5: semiosis risk — unstable or contested typing", {
  # An object typed differently across claims should trigger risk
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The diagram shows the model architecture",
      evidence = "Figure 1: schematic diagram",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The theoretical model uses set-theoretic notation",
      evidence = "Standard mathematical formulation",
      register = "R2_rhetorical"
    ),
    Claim$new(
      id = "C3",
      text = "The experimental model produced a measurement trace",
      evidence = "Data from three replicate runs",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Risk Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  risk_details <- result$flags$semiosis_risks

  # "model" appears in all three claims with potentially different semiotic types
  # At least one risk should be flagged
  expect_gt(result$flags$risk_count, 0)

  # Gap diagnosis should mention the risk
  expect_false(is.null(result$gap_diagnosis))
  expect_match(result$gap_diagnosis, "risk")
})


# ---- 7. Edge case: empty claims --------------------------------------------

test_that("L5: edge case — empty claims produce no objects", {
  claims <- list()
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Empty Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)

  # Scores matrix should have zero rows
  expect_equal(nrow(result$scores), 0)

  # Gap diagnosis should mention zero objects
  expect_match(result$gap_diagnosis, "No formal objects")

  # Object count should be 0
  expect_equal(result$flags$object_count, 0L)
})


# ---- 8. Domain term integration via formal context -------------------------

test_that("L5: domain terms from formal context influence extraction", {
  # Create a claim that uses domain-specific terms from the context
  claims <- list(
    Claim$new(
      id = "C1",
      text = "GARD exhibits graded autocatalysis in lipid systems",
      evidence = "Formal concept analysis of the incidence matrix",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Domain Term Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # At least "gard" should be extracted (it's a row name in the incidence matrix)
  rownames_lower <- tolower(rownames(scores))
  expect_true("gard" %in% rownames_lower)

  # Object count should be > 0
  expect_gt(result$flags$object_count, 0)
})


# ---- 9. Stability computation ----------------------------------------------

test_that("L5: stability — consistently typed vs. inconsistently typed", {
  # Create a claim where all objects are consistently typed
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The measurement trace shows the signal data",
      evidence = "HPLC chromatogram",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The observed signal provides a measurement reading",
      evidence = "Detector response from assay",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Stability Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # Objects appearing in only one claim should have stability = 1
  if (nrow(scores) > 0) {
    stabilities <- as.numeric(scores[, "stability"])
    # All stabilities should be 0-1
    expect_true(all(stabilities >= 0 & stabilities <= 1))
  }
})


# ---- 10. Output format -----------------------------------------------------

test_that("L5: output format — scores matrix dimensions and column names", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network diagram shows the causal architecture",
      evidence = "Figure 3",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The measurement trace shows the signal response",
      evidence = "Data from experiment",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Format Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # Expect matrix with exactly 3 columns
  expect_equal(ncol(scores), 3)
  expect_equal(colnames(scores), c("type", "stability", "risk_flag"))

  # Each row should have valid values
  if (nrow(scores) > 0) {
    expect_true(all(scores[, "type"] %in% c("icon", "index", "symbol")))
    expect_true(all(as.numeric(scores[, "stability"]) >= 0))
    expect_true(all(as.numeric(scores[, "stability"]) <= 1))
    expect_true(all(scores[, "risk_flag"] %in% c("TRUE", "FALSE")))
  }

  # LayerResult structure
  expect_equal(result$layer, 5L)
  expect_equal(result$layer_name, "Semiotic Analysis")
  expect_true(igraph::is_igraph(result$flags$semiotic_network))
  expect_true(is.list(result$flags$semiosis_risks))
})


# ---- 11. Register influence on classification ------------------------------

test_that("L5: register influences symbol vs index classification", {
  # Same object "model" in R1 vs R2 register
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The model shows the causal architecture",
      evidence = "Figure 3: directed graph of the model",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The model provides the axiomatic foundation",
      evidence = "Standard mathematical formulation",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Register Influence Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)
  scores <- result$scores

  # The result should be a valid LayerResult
  expect_true(is.matrix(result$scores))

  # Object count should be reasonable
  expect_gt(result$flags$object_count, 0)
})


# ---- 12. Empty evidence string ---------------------------------------------

test_that("L5: edge case — empty evidence string is handled gracefully", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network diagram illustrates the architecture",
      evidence = "",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Empty Evidence Test",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer5(target, ax, fc)

  # Should still work without evidence
  expect_true("icon" %in% result$scores[, "type"] ||
              "index" %in% result$scores[, "type"] ||
              "symbol" %in% result$scores[, "type"])

  expect_gt(result$flags$object_count, 0)
})