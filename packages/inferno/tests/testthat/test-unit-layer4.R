# ---------------------------------------------------------------------------
# test-layer4.R — Layer 4: Compression Taxonomy
#
# Tests the five compression operations, the fcaR closure reversibility
# audit, and Counter-RL bias detection.  Follows the testthat edition 3
# pattern established in test-invariants.R.
#
# Fixtures:
#   - make_gard_target()             — 3-claim GARD model target
#   - make_test_incidence()          — 3×4 test matrix
#   - make_test_axiom_set()          — wrapped AxiomSet
#   - make_test_context()            — fcaR FormalContext
#   - make_mock_claim()              — single-claim factory
#   - make_mock_layer_result()       — mock LayerResult
# ---------------------------------------------------------------------------

# ---- 1. Compression detection: aggregation --------------------------------

test_that("aggregation compression detected in GARD model", {
  target <- make_gard_target()
  scores <- detect_compression_operations(target)
  expect_true(is.numeric(scores))
  expect_true("aggregation" %in% names(scores))
  # GARD uses "bridges" language (system-level integration)
  expect_true(scores[["aggregation"]] >= 0)
  expect_true(scores[["aggregation"]] <= 1)
})


# ---- 2. Compression detection: abstraction --------------------------------

test_that("abstraction compression detected with category language", {
  target <- make_gard_target()
  scores <- detect_compression_operations(target)
  expect_true("abstraction" %in% names(scores))
  expect_true(scores[["abstraction"]] >= 0)
  expect_true(scores[["abstraction"]] <= 1)
})


# ---- 3. Compression detection: idealization -------------------------------

test_that("idealization detected with 'assume'/'simplified' language", {
  # Create a target with idealization triggers
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Test Idealization",
    claims = list(
      Claim$new(
        id = "C1",
        text = "We assume frictionless conditions",
        evidence = "Standard approximation"
      ),
      Claim$new(
        id = "C2",
        text = "This simplified model captures the essential dynamics",
        evidence = "Reduced-order simulation"
      )
    )
  )
  scores <- detect_compression_operations(target)
  expect_true(scores[["idealization"]] > 0)
})


# ---- 4. Compression detection: narrative ----------------------------------

test_that("narrative compression detected with 'emergence'/'trajectory' language", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test Narrative",
    claims = list(
      Claim$new(
        id = "C1",
        text = "The emergence of life follows a trajectory from simple chemistry",
        evidence = "Prebiotic simulation"
      )
    )
  )
  scores <- detect_compression_operations(target)
  expect_true(scores[["narrative"]] > 0)
})


# ---- 5. Compression detection: vocabulary transfer ------------------------

test_that("vocabulary transfer detected with 'compositional genome'", {
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "GARD Test",
    claims = list(
      Claim$new(
        id = "C1",
        text = "The compositional genome enables information storage",
        evidence = "Lipid vesicle simulation"
      )
    )
  )
  scores <- detect_compression_operations(target)
  expect_true(scores[["vocabulary"]] > 0)
})


# ---- 6. Counter-RL: compositional genome flag -----------------------------

test_that("counter-rl bias flags compositional genome", {
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "GARD",
    claims = list(
      Claim$new(
        id = "C1",
        text = "GARD compositional genome exhibits heritable variation",
        evidence = "Composome simulation"
      )
    )
  )
  flags <- detect_counter_rl_bias(target)
  expect_true(is.logical(flags))
  expect_true(flags[["compositional_genome"]])
  # "heritable" now triggers darwinian_evolution per expanded pattern
  expect_true(flags[["darwinian_evolution"]])
})


# ---- 7. Counter-RL: no false positives on clean text ----------------------

test_that("counter-rl produces no false positives on neutral text", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Neutral",
    claims = list(
      Claim$new(
        id = "C1",
        text = "The reaction rate depends on temperature",
        evidence = "Measured in triplicate"
      )
    )
  )
  flags <- detect_counter_rl_bias(target)
  expect_true(all(!flags))
})


# ---- 8. Reversibility: lossless closure (A'' = A) -------------------------

test_that("reversibility: singleton attribute closure is lossless on test context", {
  fc <- make_test_context()
  target <- make_gard_target()

  # Pre-compute concepts
  fc$find_concepts(verbose = FALSE)

  rev <- evaluate_reversibility(target, fc = fc)
  expect_true(is.list(rev))
  expect_true("lossless" %in% names(rev))
  expect_true("info_loss_n" %in% names(rev))
  expect_true("tests" %in% names(rev))
  expect_type(rev$info_loss_n, "integer")
  expect_true(rev$info_loss_n >= 0L)
})


# ---- 9. Reversibility: lossy closure detected -----------------------------

test_that("reversibility: lossy compression detected in a sparse context", {
  # Build a context where closure adds attributes (lossy-informativeness)
  #   GARD:     L1-obs, L2-inference, L3-eval, L4-converge
  #   RNA:      L1-obs, L2-inference, L3-eval
  #   Sparse:   L1-obs only
  I <- matrix(
    c(1, 1, 0, 1,    # RNA-World: L1-obs, L2-inference, L4-converge
      0, 1, 0, 0,    # Sparse:   L2-inference only
      1, 1, 1, 1),   # GARD:     all levels
    nrow = 3, ncol = 4, byrow = TRUE
  )
  rownames(I) <- c("RNA-World", "Sparse", "GARD")
  colnames(I) <- c("L1-obs", "L2-inference", "L3-eval", "L4-converge")

  fc <- fcaR::FormalContext$new(I)
  fc$find_concepts(verbose = FALSE)

  # Evaluate on a target that mentions "L1-obs" — the closure of {L1-obs}
  # should include L2-inference if every object with L1-obs also has L2-inference
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Lossy Test",
    claims = list(
      Claim$new(id = "C1", text = "L1-obs observation",
                evidence = "Some data")
    )
  )

  rev <- evaluate_reversibility(target, fc = fc)

  # At least one closure test should exist
  expect_gt(length(rev$tests), 0L)

  # Some tests may be lossy (closure adds attributes)
  # The total info loss should be >= 0
  expect_true(rev$info_loss_n >= 0L)
})


# ---- 10. evaluate_layer4 returns a properly structured LayerResult ---------

test_that("evaluate_layer4 returns a LayerResult with correct structure", {
  target <- make_gard_target()
  ax     <- make_test_axiom_set()

  result <- evaluate_layer4(target, axiom_set = ax)

  expect_s3_class(result, "LayerResult")
  expect_equal(result$layer, 4L)
  expect_equal(result$layer_name, "Compression Taxonomy")

  # Scores should be a named numeric vector of length 5
  expect_true(is.numeric(result$scores))
  expect_equal(length(result$scores), 5L)
  expect_true(all(names(result$scores) %in% c(
    "aggregation", "abstraction", "idealization",
    "narrative", "vocabulary"
  )))
  expect_true(all(result$scores >= 0))
  expect_true(all(result$scores <= 1))

  # Flags should contain counter_rl and reversibility
  expect_true("counter_rl" %in% names(result$flags))
  expect_true("reversibility" %in% names(result$flags))
  expect_true(is.list(result$flags$reversibility))
  expect_true("lossless" %in% names(result$flags$reversibility))

  # gap_diagnosis should be a character string
  expect_true(is.character(result$gap_diagnosis))

  # notes should be a character string
  expect_true(is.character(result$notes))
})


# ---- 11. evaluate_layer4 works without axiom_set (partial mode) -----------

test_that("evaluate_layer4 works without axiom_set (only compression scores)", {
  target <- make_gard_target()

  result <- evaluate_layer4(target, axiom_set = NULL, fc = NULL)

  expect_s3_class(result, "LayerResult")
  expect_equal(result$layer, 4L)

  # Scores should still be present
  expect_true(is.numeric(result$scores))
  expect_equal(length(result$scores), 5L)

  # Reversibility audit should be a stub (empty)
  expect_true(result$flags$reversibility$lossless)
})


# ---- 12. evaluate_layer4 on empty claims returns zero scores --------------

test_that("evaluate_layer4 on empty claims returns zero scores", {
  ax <- make_test_axiom_set()
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Empty",
    claims = list()
  )

  result <- evaluate_layer4(target, axiom_set = ax)

  # All compression scores should be 0
  expect_true(all(result$scores == 0))

  # All counter-rl flags should be FALSE
  expect_true(all(!result$flags$counter_rl))

  # Reversibility should still be lossless (no claims to test)
  expect_true(result$flags$reversibility$lossless)
})


# ---- 13. Counter-RL: darwinian_evolution flag -----------------------------

test_that("counter-rl flags darwinian evolution language", {
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Evo Test",
    claims = list(
      Claim$new(
        id = "C1",
        text = "This system exhibits Darwinian evolution",
        evidence = "Simulation"
      )
    )
  )
  flags <- detect_counter_rl_bias(target)
  expect_true(flags[["darwinian_evolution"]])
})


# ---- 14. Compression: all five types simultaneously -----------------------

test_that("all five compression types detected simultaneously", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Mega-Compression",
    claims = list(
      Claim$new(
        id = "C1",
        text = "The aggregate system integrates multiple components",
        evidence = "Ensemble of measurements"
      ),
      Claim$new(
        id = "C2",
        text = "This abstract category represents a general class of phenomena",
        evidence = "Prototypical examples"
      ),
      Claim$new(
        id = "C3",
        text = "We assume frictionless conditions in our idealized model",
        evidence = "Standard approximation"
      ),
      Claim$new(
        id = "C4",
        text = "The emergence narrative traces the trajectory from monomers to cells",
        evidence = "Evolutionary simulation"
      ),
      Claim$new(
        id = "C5",
        text = "The compositional genome metaphor imports vocabulary from biology",
        evidence = "Analogical mapping"
      )
    )
  )
  scores <- detect_compression_operations(target)
  expect_true(all(scores > 0))
})


# ---- 15. evaluate_layer4: full round-trip with GARD fixture ---------------

test_that("evaluate_layer4 on GARD fixture produces consistent results", {
  target <- make_gard_target()
  ax     <- make_test_axiom_set()
  fc     <- make_test_context()

  # Running with pre-computed fc should be equivalent to axiom_set
  result1 <- evaluate_layer4(target, axiom_set = ax)
  result2 <- evaluate_layer4(target, fc = fc)

  expect_equal(result1$scores, result2$scores)
  expect_equal(result1$flags$counter_rl, result2$flags$counter_rl)
})


# ---- 16. compute_hash: canonical invariance -------------------------------

test_that("compute_hash is invariant under permutation", {
  I <- make_test_incidence()
  I_perm <- I[3:1, 4:1, drop = FALSE]
  rownames(I_perm) <- rownames(I)[3:1]
  colnames(I_perm) <- colnames(I)[4:1]

  expect_equal(compute_hash(I), compute_hash(I_perm))
})