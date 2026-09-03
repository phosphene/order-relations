# ---------------------------------------------------------------------------
# test-layer1.R — Layer 1: Epistemic Stack Tests
#
# Tests the evaluate_layer1() function across PASS, FAIL, PARTIAL, and N/A
# cases for each of the four epistemic levels (L1–L4) and domain dimensions.
#
# Test cases:
#   1. L1 PASS: artifact with novel empirical observation (R1_research +
#      evidence)
#   2. L1 FAIL: artifact with no evidence on any claim
#   3. L1 PARTIAL: artifact referencing others' empirical work
#   4. L2 PASS: formal generative framework with R1 claims
#   5. L2 FAIL: observations without formal machinery
#   6. L3 PASS: evaluative criteria in R2 register
#   7. L3 FAIL: only asserts own position
#   8. L4 PASS: integrates multiple traditions
#   9. L4 FAIL: single tradition only
#  10. N/A: level not present in incidence matrix
#  11. Gap diagnosis on FAIL level
#  12. Remediation chain structure
#  13. Hypothesis-testing mode: lattice significance
#  14. Crisp mode: direct incidence matrix reading
#  15. Empty claims edge case
# ---------------------------------------------------------------------------

# ---- 1. L1 PASS: artifact with novel empirical observation -----------------

test_that("L1 PASS: artifact with novel empirical observation", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L1 PASS",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Vesicle growth observed in simulation",
        evidence = "Gillespie simulation run #42",
        register = "R1_research"
      )
    )
  )

  # Use the standard test context — GARD has L1-obs
  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L1", "D1"], "PASS")
  expect_equal(result$layer, 1L)
  expect_equal(result$layer_name, "Epistemic Stack")
})


# ---- 2. L1 FAIL: artifact with no empirical evidence -----------------------

test_that("L1 FAIL: artifact with no evidence on any claim", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L1 FAIL",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Platonic space contains cognitive patterns",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L1", "D1"], "FAIL")
})


# ---- 3. L1 PARTIAL: artifact referencing others' empirical work ------------

test_that("L1 PARTIAL: artifact references others' empirical work", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L1 PARTIAL",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Bioelectric networks show learning",
        evidence = "Cited from Levin 2024",
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L1", "D1"], "PARTIAL")
})


# ---- 4. L2 PASS: formal generative framework -------------------------------

test_that("L2 PASS: formal generative framework with R1 claims", {
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Test L2 PASS",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "GARD model predicts compositional stability",
        evidence = "Kinetic equations show equilibrium states",
        register = "R1_research"
      ),
      Claim$new(
        id = "C2",
        text = "Framework generalizes to lipid systems",
        evidence = "Extended parameter sweep confirms predictions",
        register = "R1_research"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L2", "D1"], "PASS")
})


# ---- 5. L2 FAIL: observations without formal machinery ---------------------

test_that("L2 FAIL: observations without formal machinery", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L2 FAIL",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Vesicles sometimes grow larger",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L2", "D1"], "FAIL")
})


# ---- 6. L3 PASS: evaluative criteria applied to competing programs ---------

test_that("L3 PASS: evaluative criteria in R2 register", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L3 PASS",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "GARD outperforms RNA world on compositional criteria",
        evidence = "Comparison of information capacity metrics",
        register = "R2_rhetorical"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L3", "D1"], "PASS")
})


# ---- 7. L3 FAIL: only asserts own position ---------------------------------

test_that("L3 FAIL: only asserts own position", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L3 FAIL",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "GARD is the correct model for abiogenesis",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L3", "D1"], "FAIL")
})


# ---- 8. L4 PASS: integrates multiple traditions ----------------------------

test_that("L4 PASS: integrates multiple traditions", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L4 PASS",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Model integrates chemistry and information theory",
        evidence = "Bridging kinetics and Shannon entropy",
        register = "R1_research"
      ),
      Claim$new(
        id = "C2",
        text = "The synthesis unifies prebiotic and evolutionary frameworks",
        evidence = "Preservation and loss analysis across traditions",
        register = "R2_rhetorical"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L4", "D1"], "PASS")
})


# ---- 9. L4 FAIL: single tradition only -------------------------------------

test_that("L4 FAIL: single tradition only", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test L4 FAIL",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Lipid kinetics alone explain vesicle growth",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L4", "D1"], "FAIL")
})


# ---- 10. N/A: level not present in incidence matrix ------------------------

test_that("N/A: level not present for domain dimension", {
  # The Iron-Sulfur object in the test fixture has no L1-obs
  # Use a target that maps to Iron-Sulfur
  # Iron-Sulfur is the 3rd object in the fc (domain_mapping D3 = "evolutionary-biology")
  # Iron-Sulfur has no L1-obs in the incidence matrix, so L1 should be N/A
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Test N/A",
    domain_dims = list(D3 = "evolutionary-biology"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Iron-sulfur worlds show catalytic activity",
        evidence = "Wächtershäuser experiments",
        register = "R1_research"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(result$scores["L1", "D3"], "N/A")
})


# ---- 11. Gap diagnosis on FAIL level --------------------------------------

test_that("gap diagnosis: FAIL level produces non-NULL diagnosis", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Gap Diagnosis Test",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Pure theory with no evidence",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_false(is.null(result$gap_diagnosis))
  expect_type(result$gap_diagnosis, "character")
  expect_true(nchar(result$gap_diagnosis) > 0)
})


# ---- 12. Remediation chain structure ---------------------------------------

test_that("remediation chain: structure is correct for FAIL level", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Remediation Test",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(
        id = "C1",
        text = "Pure theory with no evidence",
        evidence = NULL,
        register = "unclear"
      )
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_false(is.null(result$remediation))
  expect_true("complement" %in% names(result$remediation))
  expect_true("target_level" %in% names(result$remediation))
  expect_type(result$remediation$complement, "character")
  expect_true(nchar(result$remediation$complement) > 0)
})


# ---- 13. Hypothesis-testing mode: lattice significance ---------------------

test_that("hypothesis-testing mode: flags lattice significance", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc, mode = "hypothesis-testing")

  expect_equal(result$flags$mode, "hypothesis-testing")
  expect_type(result$flags$lattice_significant, "logical")
  expect_type(result$flags$concept_count, "integer")
  expect_type(result$flags$implication_count, "integer")
  expect_true(result$flags$lattice_significant)
  expect_false(result$flags$degenerate_lattice)
  expect_gt(result$flags$concept_count, 2)
  expect_gt(result$flags$implication_count, 0)
})


# ---- 14. Crisp mode: direct incidence matrix reading -----------------------

test_that("crisp mode: scores reflect incidence matrix", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc, mode = "crisp")

  expect_equal(result$flags$mode, "crisp")
  # GARD domain has all 4 levels in incidence matrix
  # With the GARD target's claims, L1 should be PASS (C1, C2 have R1 evidence)
  expect_equal(result$scores["L1", "D1"], "PASS")
  expect_equal(result$scores["L2", "D1"], "PASS")
})


# ---- 15. Empty claims edge case --------------------------------------------

test_that("empty claims: returns PARTIAL on levels with incidence", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Empty Claims",
    domain_dims = list(D1 = "GARD"),
    claims = list()
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  # GARD has all levels in incidence, but no claims →
  # PARTIAL because we can't confirm PASS criteria
  expect_equal(result$scores["L1", "D1"], "PARTIAL")
  expect_equal(result$scores["L2", "D1"], "PARTIAL")
})


# ---- 16. Integration test: full GARD target with make_gard_target ----------

test_that("integration: GARD target produces expected LayerResult structure", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)

  # Structural checks
  expect_s3_class(result, "LayerResult")
  expect_equal(result$layer, 1L)
  expect_equal(result$layer_name, "Epistemic Stack")

  # Scores matrix dimensions
  expect_equal(nrow(result$scores), 4)   # L1-L4
  expect_equal(ncol(result$scores), 2)   # D1, D2 (GARD target has 2 dims)

  # All values are valid
  valid_scores <- c("PASS", "FAIL", "PARTIAL", "N/A")
  for (i in seq_len(nrow(result$scores))) {
    for (j in seq_len(ncol(result$scores))) {
      expect_true(result$scores[i, j] %in% valid_scores)
    }
  }

  # GARD model has R1 claims with evidence → L1, L2 should be PASS
  expect_equal(result$scores["L1", "D1"], "PASS")
  expect_equal(result$scores["L2", "D1"], "PASS")
})


# ---- 17. No gaps when all levels PASS --------------------------------------

test_that("no gap when all levels pass", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "All PASS",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(id = "C1", text = "Observed novel phenomenon",
                evidence = "Experiment #42", register = "R1_research"),
      Claim$new(id = "C2", text = "Framework predicts outcomes",
                evidence = "Model equations", register = "R1_research"),
      Claim$new(id = "C3", text = "Compare with alternative models",
                evidence = "Comparison table", register = "R2_rhetorical"),
      Claim$new(id = "C4", text = "Integrates chemistry and biology",
                evidence = "Synthesis framework", register = "R1_research")
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_null(result$gap_diagnosis)
  expect_null(result$remediation)
})


# ---- 18. PARTIAL leads to non-NULL gap diagnosis ---------------------------

test_that("PARTIAL score produces gap diagnosis", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Partial Gap Test",
    domain_dims = list(D1 = "GARD"),
    claims = list(
      Claim$new(id = "C1", text = "Others observed this",
                evidence = "Cited from Smith 2020", register = "unclear")
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_false(is.null(result$gap_diagnosis))
  expect_true(grepl("PARTIAL", result$gap_diagnosis) ||
                nchar(result$gap_diagnosis) > 0)
})


# ---- 19. Multiple domain dimensions produce correct matrix shape ------------

test_that("multiple domain dimensions: correct matrix shape", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Multi-domain Test",
    domain_dims = list(
      D1 = "prebiotic-chemistry",
      D2 = "information-theory",
      D3 = "evolutionary-biology"
    ),
    claims = list(
      Claim$new(id = "C1", text = "Claim with evidence",
                evidence = "Data", register = "R1_research")
    )
  )

  ax <- make_test_axiom_set()
  fc <- ax$to_formal_context()
  fc <- safe_compute_lattice(fc)

  result <- evaluate_layer1(target, ax, fc)
  expect_equal(nrow(result$scores), 4)
  expect_equal(ncol(result$scores), 3)
  expect_equal(colnames(result$scores), c("D1", "D2", "D3"))
  expect_equal(rownames(result$scores), c("L1", "L2", "L3", "L4"))
})


# ---- 20. Degenerate lattice detection in hypothesis-testing mode -----------

test_that("degenerate lattice: hypothesis-testing mode flags it", {
  # Create a degenerate incidence matrix (all zeros produces a minimal lattice
  # with only bottom and top concepts, and no implications)
  I <- matrix(0, nrow = 2, ncol = 2)
  dimnames(I) <- list(c("A", "B"), c("L1-obs", "L2-inference"))

  ax <- AxiomSet$new(
    incidence = I,
    objects = c("A", "B"),
    attributes = c("L1-obs", "L2-inference"),
    domain_mapping = list(D1 = "A")
  )

  fc <- ax$to_formal_context()
  fc$find_concepts()
  fc$find_implications()

  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Degenerate Test",
    domain_dims = list(D1 = "A"),
    claims = list(
      Claim$new(id = "C1", text = "Nothing observed",
                evidence = NULL, register = "unclear")
    )
  )

  result <- evaluate_layer1(target, ax, fc, mode = "hypothesis-testing")
  expect_true(result$flags$degenerate_lattice)
  expect_false(result$flags$lattice_significant)
})