# ---------------------------------------------------------------------------
# test-layer2.R — Layer 2: M-Failure Audit Tests
#
# Tests for the six M-failure modes (M1–M6) and the PASS case. Each test
# constructs a deterministic EvaluationTarget with a single claim designed to
# trigger exactly one classification, then verifies that evaluate_layer2()
# returns the correct result.
#
# The test also verifies that the claim's m_failure field is updated, the
# scores matrix is well-formed, and the flags list is populated correctly.
# ---------------------------------------------------------------------------

library(testthat)

# ---- 1. M1: Claim more precise than evidence supports ----------------------

test_that("M1: claim more precise than evidence supports", {
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title         = "Precision Mismatch Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The reaction rate is exactly 42.7 µmol/s",
        evidence = "Approximately estimated from qualitative observations",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  # Classification
  expect_equal(result$scores["C1", "M_classification"], "M1")
  expect_equal(target$claims[[1]]$m_failure, "M1")

  # Flags
  expect_equal(result$flags$m_failures, c(C1 = "M1"))

  # Gap diagnosis present
  expect_true(grepl("M1", result$gap_diagnosis))
  expect_equal(result$layer, 2L)
  expect_equal(result$layer_name, "Claims/Evidence/Inference Triangle (M-Failure Audit)")
})


# ---- 2. M2: Conditional stated as established ------------------------------

test_that("M2: conditional stated as established", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Conditional Stated as Established Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "This proves that bioelectric signaling controls morphogenesis",
        evidence = "Preliminary results suggest a possible role in this context",
        register = "R2_rhetorical"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M2")
  expect_equal(target$claims[[1]]$m_failure, "M2")
  expect_true(grepl("M2", result$gap_diagnosis))
})


# ---- 3. M3: Generalizes beyond tested domain -------------------------------

test_that("M3: claim generalizes beyond tested domain", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Overgeneralization Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "All biological systems exhibit this property inherently",
        evidence = "In this study, the property was observed in vitro under these conditions",
        register = "R2_rhetorical"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M3")
  expect_equal(target$claims[[1]]$m_failure, "M3")
  expect_true(grepl("M3", result$gap_diagnosis))
})


# ---- 4. M4: Correlation conflated with causation ---------------------------

test_that("M4: correlation conflated with causation", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Causal Conflation Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "Gene expression causes the observed phenotypic change",
        evidence = "Gene expression is correlated with the observed phenotypic change",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M4")
  expect_equal(target$claims[[1]]$m_failure, "M4")
  expect_true(grepl("M4", result$gap_diagnosis))
})


# ---- 5. M5: Historical claim with experimental confidence ------------------

test_that("M5: historical claim with experimental confidence", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Historical Certainty Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "This demonstrates how the primordial cell evolved",
        evidence = "Simulation shows a plausible pathway under laboratory conditions",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M5")
  expect_equal(target$claims[[1]]$m_failure, "M5")
  expect_true(grepl("M5", result$gap_diagnosis))
})


# ---- 6. M6: R1 finding inflated to R2 framing ------------------------------

test_that("M6: R1 finding inflated to R2 framing", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Register Inflation Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "This finding revolutionizes our understanding of cellular evolution",
        evidence = "In this study, we observed a single instance of this phenomenon",
        register = "R2_rhetorical"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M6")
  expect_equal(target$claims[[1]]$m_failure, "M6")
  expect_true(grepl("M6", result$gap_diagnosis))
})


# ---- 7. PASS: Well-supported claim with no M-failure -----------------------

test_that("PASS: well-supported claim with no M-failure", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Clean Claim Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The reaction proceeds under these laboratory conditions",
        evidence = "Controlled experiment shows reproducible results",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "PASS")
  expect_equal(target$claims[[1]]$m_failure, "PASS")
  expect_null(result$gap_diagnosis)
  expect_length(result$flags$m_failures, 0)
})


# ---- 8. Multiple claims, mixed results -------------------------------------

test_that("multiple claims produce correct per-claim classifications", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Mixed Claims Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The rate is exactly 42.7 µmol/s",
        evidence = "Qualitative estimate",
        register = "R1_research"
      ),
      Claim$new(
        id       = "C2",
        text     = "This proves the mechanism entirely",
        evidence = "Preliminary data suggests a role",
        register = "R2_rhetorical"
      ),
      Claim$new(
        id       = "C3",
        text     = "The reaction proceeds under these conditions",
        evidence = "Controlled experiment confirms reproducibility",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  # C1: M1 (precision), C2: M2 (conditional-as-established), C3: PASS
  expect_equal(result$scores["C1", "M_classification"], "M1")
  expect_equal(result$scores["C2", "M_classification"], "M2")
  expect_equal(result$scores["C3", "M_classification"], "PASS")

  # Verify claims are updated
  expect_equal(target$claims[[1]]$m_failure, "M1")
  expect_equal(target$claims[[2]]$m_failure, "M2")
  expect_equal(target$claims[[3]]$m_failure, "PASS")

  # Flags should contain only the two failures
  expect_length(result$flags$m_failures, 2)
  expect_equal(result$flags$m_failures[["C1"]], "M1")
  expect_equal(result$flags$m_failures[["C2"]], "M2")

  # Gap diagnosis should mention both
  expect_true(grepl("M1", result$gap_diagnosis))
  expect_true(grepl("M2", result$gap_diagnosis))
  expect_true(grepl("2 of 3", result$gap_diagnosis))
})


# ---- 9. Empty claims list --------------------------------------------------

test_that("empty claims list returns a no-op LayerResult", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Empty Claims Test",
    claims = list()
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(nrow(result$scores), 0)
  expect_null(result$gap_diagnosis)
  expect_length(result$flags$m_failures, 0)
  expect_equal(result$notes, "No claims to evaluate.")
})


# ---- 10. LayerResult structure invariants ----------------------------------

test_that("LayerResult structure invariants hold", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Structure Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "This proves the mechanism completely",
        evidence = "Preliminary data suggests a possible role",
        register = "R2_rhetorical"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  # Layer number
  expect_equal(result$layer, 2L)

  # Layer name
  expect_type(result$layer_name, "character")
  expect_true(nchar(result$layer_name) > 0)

  # Scores matrix structure
  expect_true(is.matrix(result$scores))
  expect_equal(ncol(result$scores), 1)
  expect_equal(colnames(result$scores), "M_classification")
  expect_equal(rownames(result$scores), "C1")

  # Flags is a list
  expect_type(result$flags, "list")
  expect_true("m_failures" %in% names(result$flags))

  # Gap diagnosis is a character string
  expect_type(result$gap_diagnosis, "character")
  expect_true(nchar(result$gap_diagnosis) > 0)

  # Notes is NULL
  expect_null(result$notes)
})


# ---- 11. M4: Additional causal conflation pattern variants -----------------

test_that("M4: multiple causal conflation patterns", {
  # "causes" + "associated with"
  t1 <- EvaluationTarget$new(
    artifact_type = "paper", title = "M4a",
    claims = list(Claim$new("C1",
      "X causes Y in this system",
      "X is associated with Y in this study", register = "R1_research"))
  )
  # "drives" + "correlated with"
  t2 <- EvaluationTarget$new(
    artifact_type = "paper", title = "M4b",
    claims = list(Claim$new("C1",
      "A drives B in this system",
      "A is correlated with B in this dataset", register = "R1_research"))
  )
  ax <- make_test_axiom_set()
  r1 <- evaluate_layer2(t1, ax)
  r2 <- evaluate_layer2(t2, ax)

  expect_equal(r1$scores["C1", "M_classification"], "M4")
  expect_equal(r2$scores["C1", "M_classification"], "M4")
})


# ---- 12. M5: Historical claim variants with different evidence -------------

test_that("M5: historical + experimental certainty fires regardless of evidence", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "M5 Variant",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The emergence of life is conclusively demonstrated by this model",
        evidence = "Simulation results under controlled conditions",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "M5")
})


# ---- 13. M6: R2 claim with bridging evidence should PASS -------------------

test_that("R2 claim with bridging evidence passes M6", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Bridged R2 Test",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "This finding revolutionizes our understanding of cellular evolution",
        evidence = "Across multiple studies, convergent evidence supports this conclusion",
        register = "R2_rhetorical"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  # Should NOT be M6 because evidence is bridging, not R1-limited
  expect_equal(result$scores["C1", "M_classification"], "PASS")
})


# ---- 14. M1 does not fire on non-precise claims ----------------------------

test_that("M1 does not fire on non-precise claims", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "No M1",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The reaction rate is approximately 40 µmol/s",
        evidence = "Measured within an order of magnitude",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  # "approximately" is not precise — claim is hedged, not precise
  expect_equal(result$scores["C1", "M_classification"], "PASS")
})


# ---- 15. M2 does not fire on non-definitive claims -------------------------

test_that("M2 does not fire on non-definitive claims", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title         = "No M2",
    claims = list(
      Claim$new(
        id       = "C1",
        text     = "The mechanism may involve bioelectric signaling",
        evidence = "This study explores the possible role",
        register = "R1_research"
      )
    )
  )
  ax <- make_test_axiom_set()
  result <- evaluate_layer2(target, ax)

  expect_equal(result$scores["C1", "M_classification"], "PASS")
})