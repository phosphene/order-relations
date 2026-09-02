#' inferno: INFERNO Evaluation Protocol
#'
#' Formal 7-layer evaluation protocol for research claims, using Formal Concept
#' Analysis (FCA), Jensen-Shannon divergence, and content-addressable storage.
#'
#' The INFERNO (Inductive Framework for Evaluating Research through Normalized
#' Ontologies) method assesses epistemic weight, confidence, and integrability
#' of scientific claims across seven layers:
#' \itemize{
#'   \item Layer 1 — Epistemic Stack: validates the logical foundations of the
#'         formal context and concept lattice.
#'   \item Layer 2 — M-Failure Audit: evaluates each claim against 7 modes of
#'         model failure (M1–M7).
#'   \item Layer 3 — Dual-Register Analysis: classifies claims as research
#'         (R1) or rhetorical (R2).
#'   \item Layer 4 — Compression Taxonomy: measures information-theoretic
#'         compression via JS/KL divergence between object–attribute patterns.
#'   \item Layer 5 — Semiotic Analysis: evaluates the evidence graph topology
#'         for sign–object relations.
#'   \item Layer 6 — Analogical Argument: assesses analogical transfer between
#'         source and target domains.
#'   \item Layer 7 — WCI Assessment: computes the Weighted Confidence Index
#'         across 6 dimensions plus composite score.
#' }
#'
#' Core classes (all R6):
#' \describe{
#'   \item{\code{AxiomSet}}{Versioned, hashable formal context (incidence matrix
#'         + domain mapping + metric).}
#'   \item{\code{EvaluationTarget}}{The artifact being evaluated — paper, model,
#'         method, program, or claim.}
#'   \item{\code{Claim}}{A single claim with evidence, register, and M-failure
#'         assignment.}
#'   \item{\code{LayerResult}}{Result of one layer's evaluation (scores, gap
#'         diagnosis, flags).}
#'   \item{\code{EvaluationResult}}{Top-level result (layers, WCI, overall
#'         verdict).}
#' }
#'
#' Key functions:
#' \describe{
#'   \item{\code{evaluate()}}{Run the full 7-layer evaluation on a target with
#'         a given axiom set.}
#'   \item{\code{persist()}}{Store evaluation results to DuckDB.}
#'   \item{\code{load_evaluation()}}{Reconstruct R6 objects from storage.}
#'   \item{\code{render()}}{Serialize results to JSON, YAML, or Markdown.}
#' }
#'
#' @import R6
#' @importFrom digest digest
#' @importFrom igraph graph_from_edgelist topological.sort
#' @importFrom philentropy distance
#' @importFrom duckdb duckdb dbConnect
#' @importFrom DBI dbGetQuery dbWriteTable dbExecute
#' @importFrom jsonlite toJSON fromJSON
#' @importFrom yaml read_yaml write_yaml
#' @importFrom stats setNames
#'
#' @docType package
#' @name inferno
NULL