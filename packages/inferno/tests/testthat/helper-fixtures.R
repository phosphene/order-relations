# ---------------------------------------------------------------------------
# helper-fixtures.R — Test fixtures for INFERNO-R
#
# Provides reusable factory functions for building test objects across all
# test files. Every fixture is deterministic and self-contained.
# ---------------------------------------------------------------------------

#' Create a standard 3x4 test incidence matrix
#'
#' Rows = domains (GARD, RNA-World, Iron-Sulfur)
#' Cols = evaluation levels (L1-obs through L4-converge)
#'
#' @return A 3x4 integer matrix of 0/1 with named dimnames.
make_test_incidence <- function() {
  I <- matrix(
    c(1, 1, 1, 1,     # GARD: all levels observed
      1, 1, 1, 0,     # RNA-World: missing L4
      0, 1, 0, 1),    # Iron-Sulfur: only L2 and L4
    nrow = 3, ncol = 4, byrow = TRUE
  )
  rownames(I) <- c("GARD", "RNA-World", "Iron-Sulfur")
  colnames(I) <- c("L1-obs", "L2-inference", "L3-eval", "L4-converge")
  I
}


#' Create an fcaR FormalContext from the test incidence matrix
#'
#' fcaR stores the incidence matrix with attributes as rows and objects as
#' columns (transposed from the raw fixture). The FormalContext constructor
#' accepts the matrix in the standard format (objects as rows, attributes as
#' columns) and transposes internally.
#'
#' @return An fcaR::FormalContext R6 object.
make_test_context <- function() {
  I <- make_test_incidence()
  fcaR::FormalContext$new(I)
}


#' Create an AxiomSet from the test incidence matrix
#'
#' @param metric Character, one of "js" (default) or "kl".
#' @param domain_mapping Optional named list of domain dimension labels.
#'
#' @return An AxiomSet R6 object.
make_test_axiom_set <- function(metric = "js", domain_mapping = NULL) {
  I <- make_test_incidence()
  if (is.null(domain_mapping)) {
    domain_mapping <- list(
      D1 = "prebiotic-chemistry",
      D2 = "information-theory",
      D3 = "evolutionary-biology"
    )
  }
  AxiomSet$new(
    incidence      = I,
    objects        = rownames(I),
    attributes     = colnames(I),
    domain_mapping = domain_mapping,
    metric         = metric
  )
}


#' Create a mock EvaluationTarget for the GARD model
#'
#' Produces an EvaluationTarget representing the Graded Autocatalysis
#' Replication Domain (GARD) model with 3 claims at various registers.
#'
#' @return An EvaluationTarget R6 object with 3 claims.
make_gard_target <- function() {
  claims <- list(
    Claim$new(
      id        = "C1",
      text      = "GARD exhibits graded autocatalysis in lipid systems",
      evidence  = "Experimental demonstration of lipid vesicle growth",
      register  = "R1_research",
      m_failure = NA
    ),
    Claim$new(
      id        = "C2",
      text      = "GARD compositional information is heritable",
      evidence  = "Time-series analysis of vesicle composition",
      register  = "R1_research",
      m_failure = NA
    ),
    Claim$new(
      id        = "C3",
      text      = "GARD bridges the gap between chemistry and biology",
      evidence  = "Theoretical extrapolation from experimental data",
      register  = "R2_rhetorical",
      m_failure = NA
    )
  )

  EvaluationTarget$new(
    artifact_type = "model",
    title         = "Graded Autocatalysis Replication Domain",
    authors       = c("Segré", "Lancet", "Kedem", "Pilpel"),
    year          = 2000L,
    doi           = "10.1101/gr.10.9.1291",
    domain_dims   = list(
      D1 = "prebiotic-chemistry",
      D2 = "information-theory"
    ),
    claims = claims
  )
}


#' Create a mock Claim object
#'
#' Convenience wrapper around Claim$new with sensible defaults.
#'
#' @param id Character — unique identifier (e.g. "C1").
#' @param text Character — claim statement.
#' @param evidence Character — supporting evidence description (default NULL).
#' @param register Character — "R1_research", "R2_rhetorical", or "unclear"
#'   (default "unclear").
#'
#' @return A Claim R6 object.
make_mock_claim <- function(id, text, evidence = NULL,
                            register = "unclear") {
  Claim$new(
    id        = id,
    text      = text,
    evidence  = evidence,
    register  = register,
    m_failure = NA
  )
}


#' Create a mock LayerResult for testing
#'
#' @param layer Integer — layer number (1-7).
#' @param scores Optional scores matrix (default: a 3x2 matrix).
#'
#' @return A LayerResult R6 object.
make_mock_layer_result <- function(layer = 1L, scores = NULL) {
  if (is.null(scores)) {
    scores <- matrix(
      c(0.8, 0.6, 0.4, 0.7, 0.5, 0.3),
      nrow = 3, ncol = 2,
      dimnames = list(c("high", "medium", "low"), c("D1", "D2"))
    )
  }

  LayerResult$new(
    layer          = layer,
    layer_name     = sprintf("Layer-%d", layer),
    scores         = scores,
    gap_diagnosis  = NULL,
    remediation    = NULL,
    flags          = list(),
    notes          = NULL
  )
}


#' Create a mock EvaluationResult for testing persistence round-trips
#'
#' @param target Optional EvaluationTarget (default: make_gard_target()).
#' @param axiom_set Optional AxiomSet (default: make_test_axiom_set()).
#'
#' @return An EvaluationResult R6 object with 7 mock layers.
make_mock_evaluation_result <- function(target = NULL, axiom_set = NULL) {
  if (is.null(target))    target <- make_gard_target()
  if (is.null(axiom_set)) axiom_set <- make_test_axiom_set()

  layers <- lapply(1:7, function(i) {
    make_mock_layer_result(layer = i)
  })

  wci <- c(
    composite      = 0.72,
    theoretical    = 0.80,
    empirical      = 0.65,
    replicability  = 0.70,
    uptake         = 0.60,
    explanatory    = 0.75,
    falsifiability = 0.68
  )

  session_info <- list(
    r_version       = as.character(getRversion()),
    seed            = 42L,
    timestamp       = Sys.time(),
    inferno_version = "0.1.0"
  )

  EvaluationResult$new(
    target       = target,
    axiom_set    = axiom_set,
    layers       = layers,
    wci          = wci,
    overall      = "Moderate confidence — claims are empirically grounded but require further replication.",
    session_info = session_info
  )
}#' Create a target for the high-WCI scenario
#'
#' @return An \code{\link{EvaluationTarget}} with strong claims and rich
#'   metadata.
#' @keywords internal
make_strong_target <- function() {
  EvaluationTarget$new(
    artifact_type = "paper",
    title         = "Strong Empirical Paper",
    authors       = "A. Researcher",
    year          = 2023L,
    doi           = "10.1234/strong",
    domain_dims   = list(D1 = "test-domain"),
    metadata      = list(
      citations           = 150,
      replications        = 5,
      adoptions           = 3,
      independent          = TRUE,
      multi_lab            = TRUE,
      community_references = TRUE,
      review_count         = 2
    ),
    claims = list(
      Claim$new(id = "C1", text = "Novel empirical observation X",
                evidence = "Controlled experiment with p < 0.01",
                register = "R1_research"),
      Claim$new(id = "C2", text = "Formal generative model Y predicts Z",
                evidence = "Theoretical framework with predictions",
                register = "R1_research"),
      Claim$new(id = "C3", text = "The model accounts for competing theories",
                evidence = "Comparative analysis across three frameworks",
                register = "R2_rhetorical")
    )
  )
}


#' Create a target for the medium-WCI scenario
#'
#' @return An \code{\link{EvaluationTarget}} with mixed claims and moderate
#'   metadata.
#' @keywords internal
make_mixed_target <- function() {
  EvaluationTarget$new(
    artifact_type = "model",
    title         = "Mixed Evidence Model",
    authors       = "C. Scholar",
    year          = 2022L,
    domain_dims   = list(D1 = "test-domain"),
    metadata      = list(
      citations    = 25,
      replications = 1
    ),
    claims = list(
      Claim$new(id = "C1", text = "The model suggests a mechanism",
                evidence = "Simulation results are indicative",
                register = "R1_research"),
      Claim$new(id = "C2", text = "This bridges two fields",
                evidence = "Qualitative comparison with literature",
                register = "R2_rhetorical")
    )
  )
}


#' Create a target for the low-WCI scenario
#'
#' @return An \code{\link{EvaluationTarget}} with weak claims and minimal
#'   metadata.
#' @keywords internal
make_weak_target <- function() {
  EvaluationTarget$new(
    artifact_type = "claim",
    title         = "Speculative Claim",
    authors       = "P. Thinker",
    year          = 2024L,
    claims = list(
      Claim$new(id = "C1", text = "All systems evolve toward complexity",
                evidence = "Philosophical argument, no data",
                register = "R2_rhetorical"),
      Claim$new(id = "C2", text = "The pattern is universal",
                evidence = "Anecdotal observations",
                register = "R2_rhetorical")
    )
  )
}


# ============================================================================
# Mock prior layer factories
# ============================================================================

#' Create mock prior layers for a high-WCI scenario
#'
#' All layers report strong PASS results. L1 has all levels PASS across
#' all domains. L2 has zero M-failures. L4 and L6 report high scores.
#' L5 reports stable, dominant semiotic typing.
#'
#' @return A list of 6 \code{\link{LayerResult}} objects.
#' @keywords internal
make_high_wci_prior_layers <- function() {
  # L1: All PASS in all domains
  l1_scores <- matrix(
    rep(c("PASS", "PASS", "PASS", "PASS"), 2),
    nrow = 4, ncol = 2,
    dimnames = list(c("L1", "L2", "L3", "L4"), c("D1", "D2"))
  )

  # L2: All claims PASS
  l2_scores <- matrix(
    c("PASS", "PASS", "PASS"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "M_classification")
  )

  # L3: Clean R1/R2 separation
  l3_scores <- matrix(
    c("R1_research", "R1_research", "R2_rhetorical"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "register")
  )

  # L4: High compression scores, fully reversible
  l4 <- LayerResult$new(
    layer = 4L, layer_name = "Compression",
    scores = c(aggregation = 0.9, abstraction = 0.8,
               idealization = 0.7, narrative = 0.6, vocabulary = 0.5),
    flags = list(
      reversibility = list(
        lossless = TRUE,
        closure_original = "A",
        closure_closed = "A",
        info_loss_n = 0L,
        info_loss_items = character(0)
      ),
      counter_rl = c(aggregation = FALSE, abstraction = FALSE,
                     idealization = FALSE, narrative = FALSE,
                     vocabulary = TRUE)
    )
  )

  # L5: Stable semiotic typing (mostly icon)
  l5_objects <- c("model", "simulation", "experiment", "theory")
  l5_scores <- matrix(
    c("icon", 0.9,
      "icon", 0.8,
      "index", 0.7,
      "symbol", 0.6),
    nrow = 4, ncol = 2, byrow = TRUE,
    dimnames = list(l5_objects, c("type", "confidence"))
  )
  l5 <- LayerResult$new(
    layer = 5L, layer_name = "Semiotic",
    scores = l5_scores,
    flags = list(
      type_counts = c(icon = 2, index = 1, symbol = 1),
      semiosis_risks = list()
    )
  )

  # L6: High analogy admissibility
  l6 <- LayerResult$new(
    layer = 6L, layer_name = "Analogy",
    scores = c(
      admissibility      = 0.9,
      prior_association  = 0.8,
      symmetry           = 0.7,
      directionality     = 0.9
    ),
    flags = list(
      admissible = TRUE,
      critical_disanalogies = list()
    )
  )

  list(
    LayerResult$new(1L, "Epistemic Stack", scores = l1_scores,
                    flags = list(lattice_significant = TRUE,
                                 concept_count = 5L, implication_count = 3L)),
    LayerResult$new(2L, "Claims Audit", scores = l2_scores,
                    flags = list(m_failures = character(0))),
    LayerResult$new(3L, "Dual-Register", scores = l3_scores),
    l4,
    l5,
    l6
  )
}


#' Create mock prior layers for a medium-WCI scenario
#'
#' Mixed results: some PASS, some PARTIAL, some M-failures. L4 and L6 are
#' moderate. L5 has moderate type diversity.
#'
#' @return A list of 6 \code{\link{LayerResult}} objects.
#' @keywords internal
make_medium_wci_prior_layers <- function() {
  # L1: Mixed — L1 PASS, L2 PARTIAL, L3 PARTIAL, L4 N/A
  l1_scores <- matrix(
    c("PASS", "PARTIAL", "PARTIAL", "N/A",
      "PASS", "PARTIAL",  "FAIL",  "PARTIAL"),
    nrow = 4, ncol = 2,
    dimnames = list(c("L1", "L2", "L3", "L4"), c("D1", "D2"))
  )

  # L2: Some M-failures
  l2_scores <- matrix(
    c("PASS", "M2", "PASS"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "M_classification")
  )

  # L3
  l3_scores <- matrix(
    c("R1_research", "unclear", "R2_rhetorical"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "register")
  )

  # L4: Moderate scores, some information loss
  l4 <- LayerResult$new(
    layer = 4L, layer_name = "Compression",
    scores = c(aggregation = 0.6, abstraction = 0.5,
               idealization = 0.4, narrative = 0.3, vocabulary = 0.2),
    flags = list(
      reversibility = list(
        lossless = FALSE,
        info_loss_n = 2L,
        info_loss_items = c("precision", "specificity")
      )
    )
  )

  # L5: Mixed typing
  l5_objects <- c("model", "pattern", "mechanism")
  l5_scores <- matrix(
    c("symbol", 0.5,
      "icon", 0.4,
      "index", 0.3),
    nrow = 3, ncol = 2, byrow = TRUE,
    dimnames = list(l5_objects, c("type", "confidence"))
  )
  l5 <- LayerResult$new(
    layer = 5L, layer_name = "Semiotic",
    scores = l5_scores,
    flags = list(
      type_counts = c(icon = 1, index = 1, symbol = 1),
      semiosis_risks = list("model" = c("icon", "symbol"))
    )
  )

  # L6: Moderate admissibility
  l6 <- LayerResult$new(
    layer = 6L, layer_name = "Analogy",
    scores = c(admissibility = 0.5, prior_association = 0.4,
               symmetry = 0.3, directionality = 0.5),
    flags = list(
      admissible = TRUE,
      critical_disanalogies = list("scaling difference")
    )
  )

  list(
    LayerResult$new(1L, "Epistemic Stack", scores = l1_scores,
                    flags = list(lattice_significant = TRUE,
                                 concept_count = 3L, implication_count = 1L)),
    LayerResult$new(2L, "Claims Audit", scores = l2_scores,
                    flags = list(m_failures = c(C2 = "M2"))),
    LayerResult$new(3L, "Dual-Register", scores = l3_scores),
    l4, l5, l6
  )
}


#' Create mock prior layers for a low-WCI scenario
#'
#' Weak results: mostly FAIL/N/A in L1, many M-failures in L2, low L4/L6
#' scores, unstable L5 typing.
#'
#' @return A list of 6 \code{\link{LayerResult}} objects.
#' @keywords internal
make_low_wci_prior_layers <- function() {
  # L1: Mostly FAIL/N/A
  l1_scores <- matrix(
    c("FAIL", "FAIL", "FAIL", "N/A",
      "N/A",  "N/A",  "FAIL", "N/A"),
    nrow = 4, ncol = 2,
    dimnames = list(c("L1", "L2", "L3", "L4"), c("D1", "D2"))
  )

  # L2: Many M-failures
  l2_scores <- matrix(
    c("M1", "M2", "M6"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "M_classification")
  )

  # L3:
  l3_scores <- matrix(
    c("R2_rhetorical", "R2_rhetorical", "R2_rhetorical"),
    nrow = 3, ncol = 1,
    dimnames = list(c("C1", "C2", "C3"), "register")
  )

  # L4: Very low scores, substantial information loss
  l4 <- LayerResult$new(
    layer = 4L, layer_name = "Compression",
    scores = c(aggregation = 0.2, abstraction = 0.1,
               idealization = 0.3, narrative = 0.1, vocabulary = 0.0),
    flags = list(
      reversibility = list(
        lossless = FALSE,
        info_loss_n = 5L,
        info_loss_items = c("a", "b", "c", "d", "e")
      )
    )
  )

  # L5: Unstable typing
  l5_objects <- c("concept", "force", "field")
  l5_scores <- matrix(
    c("symbol", 0.2,
      "icon", 0.2,
      "index", 0.2),
    nrow = 3, ncol = 2, byrow = TRUE,
    dimnames = list(l5_objects, c("type", "confidence"))
  )
  l5 <- LayerResult$new(
    layer = 5L, layer_name = "Semiotic",
    scores = l5_scores,
    flags = list(
      type_counts = c(icon = 1, index = 1, symbol = 1),
      semiosis_risks = list(
        "concept" = c("icon", "symbol"),
        "force"   = c("index", "symbol")
      )
    )
  )

  # L6: Low admissibility
  l6 <- LayerResult$new(
    layer = 6L, layer_name = "Analogy",
    scores = c(admissibility = 0.2, prior_association = 0.1,
               symmetry = 0.1, directionality = 0.1),
    flags = list(
      admissible = FALSE,
      critical_disanalogies = list("structural mismatch",
                                   "domain incommensurability",
                                   "directionality reversal")
    )
  )

  list(
    LayerResult$new(1L, "Epistemic Stack", scores = l1_scores,
                    flags = list(lattice_significant = FALSE,
                                 concept_count = 1L, implication_count = 0L)),
    LayerResult$new(2L, "Claims Audit", scores = l2_scores,
                    flags = list(m_failures = c(C1 = "M1", C2 = "M2", C3 = "M6"))),
    LayerResult$new(3L, "Dual-Register", scores = l3_scores),
    l4, l5, l6
  )
}