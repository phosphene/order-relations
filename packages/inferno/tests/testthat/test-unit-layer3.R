# ---------------------------------------------------------------------------
# test-layer3.R — Tests for Layer 3: Dual-Register Analysis
#
# Coverage:
#   - R1_research claim (manual register)
#   - R2_rhetorical claim (manual register)
#   - Unclear claim auto-classified as R1 via hedging patterns
#   - Unclear claim auto-classified as R2 via superlative patterns
#   - Mixed-signal unclear claim (both R1 and R2 indicators)
#   - Collapse error detection (R1 evidence supporting R2 claim)
#   - Collapse error detection via cross-claim text overlap
#   - No collapse error when R2 has no R1 evidence
#   - Manual annotation override
#   - Corrected R1 generation for collapsed claims
#   - Empty claims list
#   - NULL/empty text handling
# ---------------------------------------------------------------------------

library(testthat)
library(inferno)

# ===========================================================================
# Fixture helpers
# ===========================================================================

#' Create a single Claim with the given parameters
#' @noRd
make_claim <- function(id, text, evidence = NULL,
                       register = "unclear", m_failure = NA) {
  Claim$new(id = id, text = text, evidence = evidence,
            register = register, m_failure = m_failure)
}

#' Create an EvaluationTarget with the given claims
#' @noRd
make_target <- function(claims, artifact_type = "model",
                        title = "Test Target") {
  EvaluationTarget$new(
    artifact_type = artifact_type,
    title         = title,
    claims        = claims
  )
}

# ===========================================================================
# Tests: Known register (manual annotation mode)
# ===========================================================================

test_that("R1_research claim is classified correctly from stored register", {
  target <- make_target(list(
    make_claim("C1", "Simulation shows 5% increase in vesicle growth rate",
               evidence = "Gillespie run #42", register = "R1_research")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R1_research")
  expect_equal(scores["C1", "collapse_error"], "FALSE")
  expect_null(result$gap_diagnosis)
})

test_that("R2_rhetorical claim is classified correctly from stored register", {
  target <- make_target(list(
    make_claim("C1", "This framework fundamentally transforms our understanding",
               evidence = "Theoretical extrapolation",
               register = "R2_rhetorical")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
  expect_equal(scores["C1", "collapse_error"], "FALSE")
  expect_null(result$gap_diagnosis)
})

# ===========================================================================
# Tests: Auto-classification of unclear claims
# ===========================================================================

test_that("unclear claim with hedging language is classified as R1", {
  target <- make_target(list(
    make_claim("C1", "These results suggest a possible correlation between X and Y",
               evidence = "Regression analysis", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R1_research")
})

test_that("unclear claim with citations is classified as R1", {
  target <- make_target(list(
    make_claim("C1", "As shown in Smith (2020), the effect is consistent",
               evidence = "Cited in Smith 2020", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R1_research")
})

test_that("unclear claim with quantitative data is classified as R1", {
  target <- make_target(list(
    make_claim("C1", "n = 150 participants showed a 12% improvement (p < 0.05)",
               evidence = "Clinical trial data", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R1_research")
})

test_that("unclear claim with superlatives is classified as R2", {
  target <- make_target(list(
    make_claim("C1", "This is the fundamental driver of all biological complexity",
               evidence = "Conceptual argument", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
})

test_that("unclear claim with persuasive language is classified as R2", {
  target <- make_target(list(
    make_claim("C1", "Clearly, this mechanism must be the primary cause",
               evidence = "Logical deduction", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
})

test_that("unclear claim with sweeping statements is classified as R2", {
  target <- make_target(list(
    make_claim("C1", "This theory explains everything in the field",
               evidence = "Conceptual framework", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
})

test_that("unclear claim with mixed signals resolves to higher-scoring register", {
  # R1 indicators (2) > R2 indicators (1) → R1
  target <- make_target(list(
    make_claim("C1",
               "The data suggests interesting implications for the fundamental mechanism",
               evidence = "Mixed evidence", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R1_research")
})

test_that("unclear claim with no matching patterns remains unclear", {
  target <- make_target(list(
    make_claim("C1", "The sky is blue",
               evidence = NULL, register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "unclear")
})

# ===========================================================================
# Tests: Collapse error detection
# ===========================================================================

test_that("collapse error detected: R1 evidence used to support R2 claim", {
  claims <- list(
    make_claim("C1", "Vesicle growth rate increased by 5% in the simulation",
               evidence = "Gillespie run #42", register = "R1_research"),
    make_claim("C2", "This fundamentally proves the GARD model is correct",
               evidence = "Our simulation data confirms this definitively",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C2", "collapse_error"], "TRUE")
  expect_true(!is.null(result$gap_diagnosis))
  expect_true(grepl("collapse error", result$gap_diagnosis, ignore.case = TRUE))
})

test_that("collapse error detected: R2 claim with evidence containing R1 indicators", {
  claims <- list(
    make_claim("C1", "The experiment showed a 3% increase in X",
               evidence = "Controlled trial with n=50", register = "R1_research"),
    make_claim("C2", "This is the fundamental driver of biological evolution",
               evidence = "Experimental data from our lab confirms this finding",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C2", "collapse_error"], "TRUE")
})

test_that("no collapse error when R2 claim has no R1 evidence", {
  claims <- list(
    make_claim("C1", "The experiment showed a 3% increase",
               evidence = "Trial data", register = "R1_research"),
    make_claim("C2", "This framework is the most promising approach",
               evidence = "Theoretical reasoning", register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C2", "collapse_error"], "FALSE")
})

test_that("no collapse error for R1 claims", {
  claims <- list(
    make_claim("C1", "The data suggests a correlation between A and B",
               evidence = "Regression analysis", register = "R1_research"),
    make_claim("C2", "The model predicts a 2% increase in C",
               evidence = "Simulation results", register = "R1_research")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equivalent(scores[, "collapse_error"], c("FALSE", "FALSE"))
  expect_null(result$gap_diagnosis)
})

# ===========================================================================
# Tests: Corrected R1 generation
# ===========================================================================

test_that("corrected R1 statement is generated for collapsed R2 claims", {
  claims <- list(
    make_claim("C1", "Vesicle growth rate increased by 5%",
               evidence = "Gillespie run #42", register = "R1_research"),
    make_claim("C2", "This fundamentally proves the GARD model is correct",
               evidence = "Our simulation data confirms this",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  corrected <- scores["C2", "corrected_r1"]
  expect_true(nchar(corrected) > 0)
  # Should remove superlatives like "fundamentally"
  expect_false(grepl("fundamentally", corrected, fixed = TRUE))
  # Should start with evidence-grounded phrasing
  expect_true(grepl("Evidence suggests", corrected, fixed = TRUE))
})

test_that("corrected R1 retains evidence reference", {
  claims <- list(
    make_claim("C1", "Vesicle growth rate increased by 5%",
               evidence = "Gillespie run #42", register = "R1_research"),
    make_claim("C2", "This is the most important finding in the field",
               evidence = "Our simulation data",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  corrected <- scores["C2", "corrected_r1"]
  expect_true(grepl("simulation data", corrected, fixed = TRUE))
})

# ===========================================================================
# Tests: Manual annotation override
# ===========================================================================

test_that("manual_register overrides stored register and auto-classification", {
  claims <- list(
    make_claim("C1", "This is clearly the most important finding",
               evidence = "Data", register = "unclear"),
    make_claim("C2", "The data suggests a correlation",
               evidence = "Data", register = "R1_research")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(
    target,
    manual_register = c(C1 = "R2_rhetorical", C2 = "R2_rhetorical")
  )
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
  expect_equal(scores["C2", "register"], "R2_rhetorical")
})

test_that("manual_register overrides only named claims", {
  claims <- list(
    make_claim("C1", "This is clearly the most important finding",
               evidence = "Data", register = "unclear"),
    make_claim("C2", "The data suggests a correlation",
               evidence = "Data", register = "R1_research")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(
    target,
    manual_register = c(C1 = "R2_rhetorical")
  )
  scores <- result$scores
  expect_equal(scores["C1", "register"], "R2_rhetorical")
  # C2 should retain its stored register
  expect_equal(scores["C2", "register"], "R1_research")
})

# ===========================================================================
# Tests: Edge cases
# ===========================================================================

test_that("empty claims list returns empty score matrix", {
  target <- make_target(list())
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(nrow(scores), 0)
  expect_equal(ncol(scores), 3)
  expect_null(result$gap_diagnosis)
})

test_that("NULL text in claim is handled gracefully", {
  target <- make_target(list(
    make_claim("C1", NULL, register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "unclear")
})

test_that("empty text in claim is handled gracefully", {
  target <- make_target(list(
    make_claim("C1", "", register = "unclear")
  ))
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C1", "register"], "unclear")
})

test_that("score matrix has correct dimensions and column names", {
  claims <- list(
    make_claim("C1", "Test claim 1", evidence = "Evidence 1",
               register = "R1_research"),
    make_claim("C2", "Test claim 2", evidence = "Evidence 2",
               register = "R2_rhetorical"),
    make_claim("C3", "Test claim 3", evidence = "Evidence 3",
               register = "unclear")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(nrow(scores), 3)
  expect_equal(ncol(scores), 3)
  expect_equal(colnames(scores), c("register", "collapse_error", "corrected_r1"))
  expect_equal(rownames(scores), c("C1", "C2", "C3"))
})

test_that("LayerResult has correct metadata", {
  target <- make_target(list(
    make_claim("C1", "Test claim", evidence = "Evidence",
               register = "R1_research")
  ))
  result <- evaluate_layer3(target)
  expect_equal(result$layer, 3L)
  expect_equal(result$layer_name, "Dual-Register Analysis")
  expect_type(result$flags, "list")
  expect_true("collapse_errors" %in% names(result$flags))
  expect_type(result$notes, "character")
})

# ===========================================================================
# Tests: Fixture-based integration with helpers
# ===========================================================================

test_that("evaluate_layer3 works with helper-fixtures GARD target", {
  target <- make_gard_target()
  result <- evaluate_layer3(target)
  scores <- result$scores
  # C1 and C2 are R1_research, C3 is R2_rhetorical
  expect_equal(scores["C1", "register"], "R1_research")
  expect_equal(scores["C2", "register"], "R1_research")
  expect_equal(scores["C3", "register"], "R2_rhetorical")
  # C3 evidence "Theoretical extrapolation from experimental data" contains
  # "data" which is an R1 word — this is a genuine collapse error
  expect_equal(scores["C3", "collapse_error"], "TRUE")
})

test_that("evaluate_layer3 accepts axiom_set and fc arguments for dispatch compatibility", {
  target <- make_gard_target()
  result <- evaluate_layer3(target, axiom_set = NULL, fc = NULL)
  expect_s3_class(result, "LayerResult")
  expect_equal(result$layer, 3L)
})

# ===========================================================================
# Tests: Multiple collapse errors summary
# ===========================================================================

test_that("multiple collapse errors are detected and summarized", {
  claims <- list(
    make_claim("C1", "Vesicle growth rate increased by 5%",
               evidence = "Gillespie run #42", register = "R1_research"),
    make_claim("C2", "This fundamentally proves the model is correct",
               evidence = "Our simulation data confirms this",
               register = "R2_rhetorical"),
    make_claim("C3", "Crystal size increased by 2%",
               evidence = "Lab measurement", register = "R1_research"),
    make_claim("C4", "This is undoubtedly the most comprehensive theory",
               evidence = "Our experimental data supports this conclusion",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  scores <- result$scores
  expect_equal(scores["C2", "collapse_error"], "TRUE")
  expect_equal(scores["C4", "collapse_error"], "TRUE")
  expect_equal(scores["C1", "collapse_error"], "FALSE")
  expect_equal(scores["C3", "collapse_error"], "FALSE")
  expect_true(!is.null(result$gap_diagnosis))
  expect_true(grepl("2 collapse error", result$gap_diagnosis))
})

# ===========================================================================
# Tests: Corrected R1 in remediation list
# ===========================================================================

test_that("remediation list contains corrected R1 statements", {
  claims <- list(
    make_claim("C1", "Vesicle growth rate increased by 5%",
               evidence = "Gillespie run #42", register = "R1_research"),
    make_claim("C2", "This fundamentally proves the GARD model is correct",
               evidence = "Our simulation data confirms this",
               register = "R2_rhetorical")
  )
  target <- make_target(claims)
  result <- evaluate_layer3(target)
  expect_true(!is.null(result$remediation$corrected_r1))
  expect_length(result$remediation$corrected_r1, 2)
  expect_true(is.na(result$remediation$corrected_r1[1]))  # C1 — no correction
  expect_true(nchar(result$remediation$corrected_r1[2]) > 0)  # C2 — corrected
})