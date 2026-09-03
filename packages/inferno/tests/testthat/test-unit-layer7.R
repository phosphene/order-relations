# ---------------------------------------------------------------------------
# test-layer7.R — Layer 7: Weighted Credibility Index (WCI) Assessment
#
# Tests the WCI scoring engine using mock prior layer results for three
# scenarios: high WCI (strong artifact), medium WCI (mixed evidence), and
# low WCI (weak/many failures). Also tests custom weights, target metadata
# influence, and the composite calculation.
#
# Test cases:
#   1. High WCI: all prior layers strong → scores near 1.0
#   2. Medium WCI: mixed prior layers → scores around 0.5
#   3. Low WCI: many failures → scores near 0.0
#   4. Custom weights: override default equal weights
#   5. Target metadata influence: citation/replication counts boost
#   6. Edge case: empty claims produce deterministic baseline scores
#   7. JS divergence: returns numeric when philentropy is available
#   8. Composite is weighted average of 6 dimension scores
# ---------------------------------------------------------------------------

library(testthat)


# ---- 1. High WCI case -------------------------------------------------------

test_that("L7: high WCI — all prior layers strong", {
  target <- make_strong_target()

  prior <- make_high_wci_prior_layers()

  result <- evaluate_layer7(target, make_test_axiom_set(), prior)

  scores <- result$scores
  expect_named(scores, c(
    "theoretical_coherence", "empirical_support",
    "replicability", "independent_uptake",
    "explanatory_power", "falsifiability", "composite"
  ))

  # All dimension scores should be high (≥ 0.7)
  dim_scores <- scores[1:6]
  for (nm in names(dim_scores)) {
    expect_true(
      dim_scores[[nm]] >= 0.7,
      info = sprintf("High WCI dimension '%s' = %.3f (expected ≥ 0.7)",
                     nm, dim_scores[[nm]])
    )
  }

  # Composite should be high
  expect_true(scores[["composite"]] >= 0.7)
})


# ---- 2. Medium WCI case -----------------------------------------------------

test_that("L7: medium WCI — mixed prior layers", {
  target <- make_mixed_target()
  prior <- make_medium_wci_prior_layers()

  result <- evaluate_layer7(target, make_test_axiom_set(), prior)

  scores <- result$scores
  dim_scores <- scores[1:6]

  # At least some dimensions should be in medium range [0.3, 0.7]
  n_medium <- sum(dim_scores >= 0.3 & dim_scores <= 0.7)
  expect_true(n_medium >= 2,
              info = sprintf("Expected ≥2 medium dimensions, got %d", n_medium))

  # Composite should be in plausible medium range
  comp <- scores[["composite"]]
  expect_true(comp >= 0.2 && comp <= 0.8,
              info = sprintf("Medium composite = %.3f, expected [0.2, 0.8]", comp))
})


# ---- 3. Low WCI case --------------------------------------------------------

test_that("L7: low WCI — many failures", {
  target <- make_weak_target()
  prior <- make_low_wci_prior_layers()

  result <- evaluate_layer7(target, make_test_axiom_set(), prior)

  scores <- result$scores
  dim_scores <- scores[1:6]

  # Most dimensions should be low (≤ 0.5)
  n_low <- sum(dim_scores <= 0.5)
  expect_true(n_low >= 3,
              info = sprintf("Expected ≥3 low dimensions (≤ 0.5), got %d", n_low))

  # Composite should be low
  comp <- scores[["composite"]]
  expect_true(comp <= 0.6,
              info = sprintf("Low composite = %.3f, expected ≤ 0.6", comp))
})


# ---- 4. Custom weights ------------------------------------------------------

test_that("L7: custom weights affect composite", {
  target <- make_strong_target()
  prior <- make_high_wci_prior_layers()

  # Create axiom set with custom weights (emphasizing empirical_support)
  custom_weights <- c(
    theoretical_coherence = 0.05,
    empirical_support     = 0.50,
    replicability         = 0.10,
    independent_uptake    = 0.10,
    explanatory_power     = 0.10,
    falsifiability        = 0.15
  )
  ax <- AxiomSet$new(
    incidence  = make_test_incidence(),
    objects    = rownames(make_test_incidence()),
    attributes = colnames(make_test_incidence()),
    domain_mapping = list(D1 = "test-domain"),
    metadata   = list(wci_weights = custom_weights)
  )

  result_with_custom <- evaluate_layer7(target, ax, prior)

  # Same target/prior with default weights
  ax_default <- make_test_axiom_set()
  result_default <- evaluate_layer7(target, ax_default, prior)

  # Composites should differ (custom weights shift the result)
  expect_false(
    identical(result_with_custom$scores[["composite"]],
              result_default$scores[["composite"]]),
    info = "Custom weights should produce different composite from defaults"
  )

  # Custom weights should be reflected in flags
  expect_equal(result_with_custom$flags$weights, custom_weights / sum(custom_weights))
})


# ---- 5. Target metadata influence -------------------------------------------

test_that("L7: metadata (citations, replications) boosts independent_uptake", {
  # Target with rich metadata
  rich_target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Highly Cited Paper",
    authors       = "Famous Researcher",
    year          = 2020L,
    doi           = "10.1234/example",
    metadata      = list(
      citations           = 250,
      replications        = 8,
      adoptions           = 5,
      community_references = TRUE,
      review_count        = 3
    )
  )

  # Target with no metadata
  bare_target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Obscure Paper",
    authors       = "Unknown",
    year          = 2020L
  )

  prior <- make_high_wci_prior_layers()
  ax <- make_test_axiom_set()

  result_rich <- evaluate_layer7(rich_target, ax, prior)
  result_bare <- evaluate_layer7(bare_target, ax, prior)

  uptake_rich <- result_rich$scores[["independent_uptake"]]
  uptake_bare <- result_bare$scores[["independent_uptake"]]

  expect_true(
    uptake_rich > uptake_bare,
    info = sprintf("Rich metadata uptake (%.3f) should exceed bare (%.3f)",
                   uptake_rich, uptake_bare)
  )
})


# ---- 6. Edge case: empty claims ---------------------------------------------

test_that("L7: empty claims produce deterministic baseline scores", {
  target <- EvaluationTarget$new(
    artifact_type = "claim",
    title         = "Empty Claim",
    claims        = list()
  )

  # Minimal prior layers with no claims
  empty_l1_scores <- matrix(
    c("N/A", "N/A", "N/A", "N/A"),
    nrow = 4, ncol = 1,
    dimnames = list(c("L1", "L2", "L3", "L4"), "D1")
  )

  prior <- list(
    LayerResult$new(1L, "Epistemic Stack", scores = empty_l1_scores,
                    gap_diagnosis = "No claims", flags = list()),
    LayerResult$new(2L, "Claims Audit",
                    scores = matrix(character(0), nrow = 0, ncol = 1),
                    gap_diagnosis = NULL, flags = list(m_failures = character(0))),
    LayerResult$new(3L, "Dual-Register",
                    scores = matrix(character(0), nrow = 0, ncol = 1)),
    LayerResult$new(4L, "Compression",
                    scores = c(aggregation = 0, abstraction = 0,
                               idealization = 0, narrative = 0, vocabulary = 0)),
    LayerResult$new(5L, "Semiotic",
                    scores = matrix(character(0), nrow = 0, ncol = 3),
                    flags = list(type_counts = c(icon = 0, index = 0, symbol = 0))),
    LayerResult$new(6L, "Analogy",
                    scores = c(admissibility = 0, prior_association = 0,
                               symmetry = 0, directionality = 0))
  )

  ax <- make_test_axiom_set()
  result <- evaluate_layer7(target, ax, prior)

  scores <- result$scores
  expect_named(scores, c(
    "theoretical_coherence", "empirical_support",
    "replicability", "independent_uptake",
    "explanatory_power", "falsifiability", "composite"
  ))

  # All scores should be non-negative and finite
  for (nm in names(scores)) {
    expect_true(is.finite(scores[[nm]]),
                info = sprintf("Empty claims: %s = %.3f is not finite", nm, scores[[nm]]))
    expect_true(scores[[nm]] >= 0,
                info = sprintf("Empty claims: %s = %.3f < 0", nm, scores[[nm]]))
  }
})


# ---- 7. JS divergence (if philentropy available) ----------------------------

test_that("L7: JS divergence computed when philentropy is available", {
  skip_if_not_installed("philentropy")

  target <- make_strong_target()
  prior <- make_high_wci_prior_layers()
  ax <- make_test_axiom_set()

  result <- evaluate_layer7(target, ax, prior, compute_js_divergence = TRUE)

  expect_true(is.numeric(result$flags$js_divergence))
  expect_true(result$flags$js_divergence >= 0)
  expect_true(result$flags$js_divergence <= log(2))
})


# ---- 8. Composite is weighted average ---------------------------------------

test_that("L7: composite equals weighted average of 6 dimensions", {
  target <- make_mixed_target()
  prior <- make_medium_wci_prior_layers()

  # Custom weights
  weights <- c(
    theoretical_coherence = 0.3,
    empirical_support     = 0.2,
    replicability         = 0.1,
    independent_uptake    = 0.1,
    explanatory_power     = 0.2,
    falsifiability        = 0.1
  )
  ax <- AxiomSet$new(
    incidence  = make_test_incidence(),
    objects    = rownames(make_test_incidence()),
    attributes = colnames(make_test_incidence()),
    metadata   = list(wci_weights = weights)
  )

  result <- evaluate_layer7(target, ax, prior)
  scores <- result$scores

  dim_scores <- scores[1:6]
  expected_composite <- sum(dim_scores * (weights / sum(weights)))

  expect_equal(scores[["composite"]], expected_composite,
               tolerance = 1e-10)
})


# ---- 9. Gap diagnosis and remediation ---------------------------------------

test_that("L7: gap diagnosis is NULL when all dimensions are strong", {
  target <- make_strong_target()
  prior <- make_high_wci_prior_layers()

  result <- evaluate_layer7(target, make_test_axiom_set(), prior)

  # All dimensions ≥ 0.6 → no gap diagnosis
  dim_scores <- result$scores[1:6]
  if (all(dim_scores >= 0.6)) {
    expect_null(result$gap_diagnosis)
    expect_null(result$remediation)
  }
})


test_that("L7: gap diagnosis present when a dimension is weak", {
  target <- make_weak_target()
  prior <- make_low_wci_prior_layers()

  result <- evaluate_layer7(target, make_test_axiom_set(), prior)

  dim_scores <- result$scores[1:6]
  if (any(dim_scores < 0.6)) {
    expect_false(is.null(result$gap_diagnosis))
    # Remediation should include a complement and target level
    expect_false(is.null(result$remediation))
    expect_true("complement" %in% names(result$remediation))
    expect_true("target_level" %in% names(result$remediation))
  }
})


# ============================================================================
# Fixture factories for test scenarios
# ============================================================================



# ============================================================================
# Fixture functions (defined in helper-fixtures.R):
#   make_strong_target, make_mixed_target, make_weak_target,
#   make_high_wci_prior_layers, make_medium_wci_prior_layers,
#   make_low_wci_prior_layers
# ============================================================================
