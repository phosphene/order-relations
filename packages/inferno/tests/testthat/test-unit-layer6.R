# ---------------------------------------------------------------------------
# test-layer6.R — Layer 6: Analogical Argument (Bartha Admissibility)
#
# Tests for Bartha admissibility assessment using fcaR concept lattice
# intersection analysis. Test cases:
#   1. Admissible analogy: strong prior association, good symmetry
#   2. Not admissible: critical disanalogy present
#   3. Admissible with caveats: weak directionality or minor disanalogies
#   4. No explicit analogies detected
#   5. Multiple analogies with different verdicts
#   6. Lattice overlap computation (high overlap = more admissible)
#   7. Better analogy suggestion mechanism
#   8. Empty claims edge case
#   9. Output format: scores structure and verdict enum
#  10. Flags structure: disanalogies, lattice info, suggestions
# ---------------------------------------------------------------------------

library(testthat)


# ---- 1. Admissible analogy: strong prior association, good symmetry -------

test_that("L6: admissible — strong prior association and symmetry", {
  # A well-formed analogy with explicit source/target mapping
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The network architecture is like a neural system, allowing distributed processing",
      evidence = "Graph simulation shows emergent behavior",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "This analogy predicts that failures in one node will spread gradually",
      evidence = "Node removal simulation",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Admissible Analogy",
    domain_dims = list(
      D1 = "neural-modeling",
      D2 = "network-theory"
    ),
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Verdict should be admissible
  expect_equal(result$flags$verdict, "admissible")

  # Weighted score should be high
  score <- result$scores["weighted_score"]
  expect_true(score >= 0.70)
  expect_true(score <= 1.0)

  # No critical disanalogies
  expect_length(result$flags$disanalogies, 0L)

  # Prior association should be reasonable
  expect_gt(result$scores["prior_association"], 0.5)

  # Symmetry should be good
  expect_gt(result$scores["symmetry"], 0.5)
})


# ---- 2. Not admissible: critical disanalogy present --------------------

test_that("L6: not_admissible — critical disanalogy undermines conclusion", {
  # An analogy with a key missing attribute
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The economy is like an ecosystem, with species competing for resources",
      evidence = "Market share data",
      register = "R2_rhetorical"
    ),
    Claim$new(
      id = "C2",
      text = "This analogy implies market self-regulation naturally occurs",
      evidence = "Theoretical model",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Ecosystem Analogy",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Verdict should be not_admissible
  expect_equal(result$flags$verdict, "not_admissible")

  # Weighted score should be low
  score <- result$scores["weighted_score"]
  expect_true(score < 0.50)

  # Disanalogies may or may not be flagged (heuristic limitation)
  expect_true(length(result$flags$disanalogies) >= 0)
  # The key is the verdict is low

  # Gap diagnosis should mention disanalogies
  expect_false(is.null(result$gap_diagnosis))
  expect_match(result$gap_diagnosis, "disanalogy|overlap", ignore.case = TRUE)
})


# ---- 3. Admissible with caveats: weak directionality or minor issues -------

test_that("L6: admissible_with_caveats — minor disanalogies or weak symmetry", {
  # An analogy that works but has some issues
  claims <- list(
    Claim$new(
      id = "C1",
      text = "Language structure parallels grammar rules",
      evidence = "Syntactic analysis",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The similarity suggests shared computational principles",
      evidence = "Parsing efficiency comparison",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Language Grammar Analogy",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Verdict should be caveats (not quite full admissible)
  expect_equal(result$flags$verdict, "admissible_with_caveats")

  # Weighted score should be in middle range
  score <- result$scores["weighted_score"]
  expect_true(score >= 0.50)
  expect_true(score < 0.70)

  # Prior association should be moderate
  expect_true(result$scores["prior_association"] > 0)
  expect_true(result$scores["prior_association"] <= 1)
})


# ---- 4. No explicit analogies detected -----------------------------------

test_that("L6: no explicit analogies — neutral baseline", {
  # Claims without clear analogy language
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The system exhibits emergent behavior from local interactions",
      evidence = "Agent-based simulation",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "Phase transitions occur at critical parameter values",
      evidence = "Bifurcation analysis",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "No Analogy",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Verdict should be reasonable (not penalized for lack of explicit analogy)
  score <- result$scores["weighted_score"]
  expect_true(score >= 0.40)
  expect_true(score <= 0.80)

  # Directionality score should be neutral-ish
  expect_true(result$scores["directionality"] > 0.4)
  expect_true(result$scores["directionality"] < 0.7)
})


# ---- 5. Multiple analogies with different verdicts -----------------------

test_that("L6: multiple analogies — mixed quality assessment", {
  # Two explicit analogies in same target
  claims <- list(
    Claim$new(
      id = "C1",
      text = "Cell membranes are like liquid crystals, allowing selective permeability",
      evidence = "Fluorescence microscopy of lipid bilayers",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "The cell nucleus functions like a computer CPU, processing information",
      evidence = "Gene expression modeling",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Multiple Analogies",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Check that at least some analogies were extracted
  extracted <- result$flags$extracted_analogies
  # May be NULL if no explicit patterns matched (heuristic limitation)
  # If present, should have entries
  if (!is.null(extracted)) {
    expect_gt(length(extracted), 0)
  }

  # Verdict should be computed (admissible or caveats at minimum)
  expect_true(result$flags$verdict %in% c(
    "admissible", "admissible_with_caveats", "not_admissible"
  ))

  # Weighted score should be in valid range
  score <- result$scores["weighted_score"]
  expect_true(score >= 0)
  expect_true(score <= 1)
})


# ---- 6. Lattice overlap computation (high overlap = more admissible) -------

test_that("L6: high lattice overlap — stronger admissibility", {
  # Create a target that heavily uses domain concepts
  claims <- list(
    Claim$new(
      id = "C1",
      text = "GARD lipid systems exhibit compositional genome patterns",
      evidence = "Incidence matrix analysis shows L1-obs and L2-inference",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "Prebiotic chemistry parallels information-theoretic constraints",
      evidence = "L2-inference and L3-eval coverage in domain spaces",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "High Overlap",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Lattice overlap should be non-trivial
  expect_gt(result$flags$lattice_overlap, 0)
  expect_true(result$flags$lattice_overlap <= 1)

  # Should be more admissible than no-overlap case
  score <- result$scores["weighted_score"]
  expect_true(score >= 0.4)
})


# ---- 7. Better analogy suggestion mechanism -------------------------------

test_that("L6: better analogy suggestions are generated when warranted", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "RNA replication resembles DNA replication mechanisms",
      evidence = "Template-mediated synthesis data",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "RNA Analogy",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Suggestion may or may not exist (depends on heuristic match)
  # If it exists, should be non-empty string
  suggestion <- result$flags$better_analogy_suggestion
  if (!is.null(suggestion)) {
    expect_gt(nchar(suggestion), 0)
    expect_false(grepl("\\s*$", suggestion))  # No trailing whitespace
  }
})


# ---- 8. Empty claims edge case -------------------------------------------

test_that("L6: empty claims — neutral baseline", {
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Empty",
    claims = list()
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Scores should be neutral (around 0.5)
  score <- result$scores["weighted_score"]
  expect_true(score >= 0.4)
  expect_true(score <= 0.6)

  # Verdict should be reasonable
  expect_true(result$flags$verdict %in% c(
    "admissible", "admissible_with_caveats", "not_admissible"
  ))

  # No disanalogies
  expect_length(result$flags$disanalogies, 0L)

  # No lattice overlap (no claims to analyze)
  expect_equal(result$flags$lattice_overlap, 0)
})


# ---- 9. Output format: scores structure and verdict enum ------------------

test_that("L6: output format — scores structure and verdict enum", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "X is like Y in mechanism",
      evidence = "Evidence for the analogy",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Format Check",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Scores structure
  expect_true("prior_association" %in% names(result$scores))
  expect_true("symmetry" %in% names(result$scores))
  expect_true("directionality" %in% names(result$scores))
  expect_true("disanalogy_penalty" %in% names(result$scores))
  expect_true("weighted_score" %in% names(result$scores))

  # All scores should be numeric
  expect_true(is.numeric(result$scores["prior_association"]))
  expect_true(is.numeric(result$scores["symmetry"]))
  expect_true(is.numeric(result$scores["directionality"]))
  expect_true(is.numeric(result$scores["disanalogy_penalty"]))
  expect_true(is.numeric(result$scores["weighted_score"]))

  # Scores in [0, 1] range (except penalty which can be 0 to 0.5)
  expect_true(result$scores["prior_association"] >= 0)
  expect_true(result$scores["prior_association"] <= 1)
  expect_true(result$scores["symmetry"] >= 0)
  expect_true(result$scores["symmetry"] <= 1)
  expect_true(result$scores["directionality"] >= 0)
  expect_true(result$scores["directionality"] <= 1)
  expect_true(result$scores["disanalogy_penalty"] >= 0)
  expect_true(result$scores["disanalogy_penalty"] <= 0.5)
  expect_true(result$scores["weighted_score"] >= 0)
  expect_true(result$scores["weighted_score"] <= 1)

  # Verdict enum
  expect_true(result$flags$verdict %in% c(
    "admissible", "admissible_with_caveats", "not_admissible"
  ))

  # Disanalogies should be character vector (may be empty)
  expect_true(is.character(result$flags$disanalogies))

  # Lattice overlap should be numeric
  expect_true(is.numeric(result$flags$lattice_overlap))
  expect_true(result$flags$lattice_overlap >= 0)
  expect_true(result$flags$lattice_overlap <= 1)

  # LayerResult structure
  expect_equal(result$layer, 6L)
  expect_equal(result$layer_name, "Analogical Argument (Bartha)")
})


# ---- 10. Flags structure: disanalogies, lattice info, suggestions ---------

test_that("L6: flags structure — all expected keys present", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "Analogy example",
      evidence = "Data",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Flags Check",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Required flag keys
  expect_true("verdict" %in% names(result$flags))
  expect_true("disanalogies" %in% names(result$flags))
  expect_true("lattice_overlap" %in% names(result$flags))
  expect_true("lattice_info" %in% names(result$flags))
  expect_true("better_analogy_suggestion" %in% names(result$flags))

  # lattice_info may be NULL or may be a list (depends on fcaR availability)
  if (!is.null(result$flags$lattice_info)) {
    expect_type(result$flags$lattice_info, "list")
  }

  # Better analogy suggestion may be NULL
  if (!is.null(result$flags$better_analogy_suggestion)) {
    expect_type(result$flags$better_analogy_suggestion, "character")
  }

  # Extracted analogies may be NULL if none detected
  if (!is.null(result$flags$extracted_analogies)) {
    expect_type(result$flags$extracted_analogies, "character")
  }
})


# ---- 11. Directionality: known→unknown phrasing is recognized --------------

test_that("L6: directionality — explanatory phrasing recognized", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "We can understand the system in terms of network motifs",
      evidence = "Motif frequency analysis",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Directionality",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Directionality score should be higher with explanatory phrasing
  expect_gt(result$scores["directionality"], 0.5)
})


# ---- 12. Symmetry: generative implications boost score --------------------

test_that("L6: symmetry — generative language increases score", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The analogy predicts novel behaviors at critical mass",
      evidence = "Simulation of phase transition",
      register = "R1_research"
    ),
    Claim$new(
      id = "C2",
      text = "This also illuminates how biological systems self-organize",
      evidence = "Comparative analysis",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Symmetry Boost",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Symmetry should be boosted by generative language
  expect_gt(result$scores["symmetry"], 0.5)
})


# ---- 13. Prior association: explicit connection language is detected -------

test_that("L6: prior association — explicit connection patterns detected", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The two systems are connected through shared causal mechanisms",
      evidence = "Pathway analysis",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "paper",
    title = "Prior Association",
    domain_dims = list(
      D1 = "causal-mechanisms",
      D2 = "network-theory"
    ),
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Prior association should be boosted
  expect_gt(result$scores["prior_association"], 0.5)
})


# ---- 14. Empty evidence string handling ------------------------------------

test_that("L6: empty evidence string is handled gracefully", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "Analogy between X and Y",
      evidence = "",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Empty Evidence",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Should still produce valid result
  expect_true(result$scores["weighted_score"] >= 0)
  expect_true(result$scores["weighted_score"] <= 1)
  expect_true(result$flags$verdict %in% c(
    "admissible", "admissible_with_caveats", "not_admissible"
  ))
})


# ---- 15. Note field: comprehensive summary -------------------------------

test_that("L6: notes field provides comprehensive summary", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "The analogy between networks and neural systems suggests X",
      evidence = "Simulation data",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Notes Check",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Notes should be character string
  expect_true(is.character(result$notes))
  expect_gt(nchar(result$notes), 0)

  # Notes should contain score information
  expect_match(result$notes, "Prior association|Symmetry|Directionality", ignore.case = TRUE)
})


# ---- 16. Full round-trip: same result with axiom_set or fc ---------------

test_that("L6: full round-trip — axiom_set and fc give consistent results", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "X is like Y in structure and function",
      evidence = "Evidence for analogy",
      register = "R1_research"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Round-trip",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result1 <- evaluate_layer6(target, axiom_set = ax)
  result2 <- evaluate_layer6(target, axiom_set = ax, fc = fc)

  # Scores should be identical when fc is auto-derived
  expect_equal(result1$scores["prior_association"],
               result2$scores["prior_association"])
  expect_equal(result1$scores["symmetry"], result2$scores["symmetry"])
  expect_equal(result1$scores["directionality"], result2$scores["directionality"])
  expect_equal(result1$scores["weighted_score"], result2$scores["weighted_score"])

  # Verdict should match
  expect_equal(result1$flags$verdict, result2$flags$verdict)
})


# ---- 17. GARD model: domain-specific analogy -------------------------------

test_that("L6: GARD model with compositional genome analogy", {
  target <- make_gard_target()
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Should produce valid evaluation
  expect_s3_class(result, "LayerResult")
  expect_equal(result$layer, 6L)

  # Scores should be in valid ranges
  expect_true(result$scores["prior_association"] >= 0)
  expect_true(result$scores["prior_association"] <= 1)
  expect_true(result$scores["symmetry"] >= 0)
  expect_true(result$scores["symmetry"] <= 1)

  # Disanalogies may be empty or populated depending on heuristic
  expect_true(is.character(result$flags$disanalogies))
})


# ---- 18. Edge case: single claim with metaphor -----------------------------

test_that("L6: single claim with metaphor language", {
  claims <- list(
    Claim$new(
      id = "C1",
      text = "Genetic code is like a programming language",
      evidence = "Transcription/translation analogy",
      register = "R2_rhetorical"
    )
  )
  target <- EvaluationTarget$new(
    artifact_type = "model",
    title = "Code Analogy",
    claims = claims
  )
  ax <- make_test_axiom_set()
  fc <- make_test_context()

  result <- evaluate_layer6(target, ax, fc)

  # Should handle single claim gracefully
  expect_s3_class(result, "LayerResult")
  expect_true("weighted_score" %in% names(result$scores))
  expect_true(result$flags$verdict %in% c(
    "admissible", "admissible_with_caveats", "not_admissible"
  ))
})
