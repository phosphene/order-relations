#' AxiomSet: Versioned, hashable unit of evaluation context
#'
#' Represents a formal context (incidence matrix + object/attribute sets) with
#' domain mapping and metric choice. Two evaluations using the same AxiomSet
#' (same hash and metric) are comparable. The incidence matrix is canonicalized
#' and content-addressed via xxhash64.
#'
#' @field context_hash xxhash64 digest of the canonicalized incidence matrix.
#' @field objects Character vector of object names (the \eqn{G} set).
#' @field attributes Character vector of attribute names (the \eqn{M} set).
#' @field incidence Matrix (\eqn{|G| \times |M|}) of 0/1 values.
#' @field domain_mapping Named list mapping domain dimensions to labels, e.g.
#'   \code{list(D1 = "prebiotic", D2 = "info-theory")}.
#' @field metric Character, one of \code{"js"} (Jensen-Shannon) or \code{"kl"}
#'   (KL divergence). Default \code{"js"}.
#' @field metadata Named list for arbitrary user metadata (creator, timestamp,
#'   notes, etc.).
#'
#' @import R6
#' @export
AxiomSet <- R6::R6Class(
  "AxiomSet",
  public = list(

    #' @field context_hash xxhash64 digest of the canonicalized incidence
    #'   matrix.
    context_hash = NULL,

    #' @field objects Character vector — the \eqn{G} set.
    objects = NULL,

    #' @field attributes Character vector — the \eqn{M} set.
    attributes = NULL,

    #' @field incidence Matrix (\eqn{|G| \times |M|}) of 0/1.
    incidence = NULL,

    #' @field domain_mapping Named list: \code{list(D1 = "prebiotic", ...)}.
    domain_mapping = NULL,

    #' @field metric Distance metric, \code{"js"} or \code{"kl"}.
    metric = "js",

    #' @field metadata Named list (creator, timestamp, notes).
    metadata = NULL,

    #' Create a new AxiomSet
    #'
    #' @param incidence Matrix of 0/1 values.
    #' @param objects Character vector naming the rows (objects).
    #' @param attributes Character vector naming the columns (attributes).
    #' @param domain_mapping Optional named list of domain dimension labels.
    #' @param metric Character, \code{"js"} (default) or \code{"kl"}.
    #' @param metadata Optional named list.
    #'
    #' @return A new \code{AxiomSet} object.
    initialize = function(incidence, objects, attributes,
                          domain_mapping = NULL, metric = "js",
                          metadata = list()) {
      stopifnot(is.matrix(incidence), all(incidence %in% c(0, 1)))
      stopifnot(length(objects) == nrow(incidence))
      stopifnot(length(attributes) == ncol(incidence))
      rownames(incidence) <- objects
      colnames(incidence) <- attributes
      self$incidence <- incidence
      self$objects <- objects
      self$attributes <- attributes
      self$domain_mapping <- domain_mapping
      self$metric <- metric
      self$metadata <- metadata
      self$context_hash <- private$compute_hash()
    },

    #' Convert to an fcaR FormalContext
    #'
    #' @return A \code{fcaR::FormalContext} R6 object.
    to_formal_context = function() {
      fcaR::FormalContext$new(self$incidence)
    },

    #' Get the content-addressable hash
    #'
    #' @return Character xxhash64 digest.
    get_hash = function() {
      self$context_hash
    },

    #' Check whether another AxiomSet uses the same context and metric
    #'
    #' @param other Another \code{AxiomSet} object.
    #'
    #' @return \code{TRUE} if both the canonical hash and metric match.
    is_comparable = function(other) {
      identical(self$context_hash, other$context_hash) &&
        identical(self$metric, other$metric)
    },

    #' Print a human-readable summary
    #'
    #' @return \code{NULL}, invisibly.
    print = function() {
      cat(sprintf("AxiomSet [%s]\n", self$context_hash))
      cat(sprintf("  Objects: %d, Attributes: %d, Metric: %s\n",
                  length(self$objects), length(self$attributes),
                  self$metric))
      if (!is.null(self$domain_mapping)) {
        cat("  Domains:", paste(names(self$domain_mapping),
                                self$domain_mapping,
                                sep = "=", collapse = ", "), "\n")
      }
      cat(sprintf("  Density: %.3f\n",
                  sum(self$incidence) / length(self$incidence)))
    }
  ),
  private = list(
    compute_hash = function() {
      mat <- self$incidence
      rn <- sort(rownames(mat))
      cn <- sort(colnames(mat))
      mat <- mat[rn, cn, drop = FALSE]
      digest::digest(mat, algo = "xxhash64")
    }
  )
)


#' EvaluationTarget: The artifact being evaluated
#'
#' Describes a research artifact — paper, model, method, program, or claim —
#' that will be assessed by the INFERNO protocol. Contains metadata, domain
#' dimensions, and a list of associated \code{\link{Claim}} objects.
#'
#' @field artifact_type One of \code{"paper"}, \code{"model"}, \code{"method"},
#'   \code{"program"}, or \code{"claim"}.
#' @field title Character — the artifact title.
#' @field authors Character vector of author names.
#' @field year Integer publication year.
#' @field doi Character DOI identifier.
#' @field domain_dims Named list mapping dimension codes to labels.
#' @field claims List of \code{\link{Claim}} objects.
#' @field metadata Named list for arbitrary user metadata.
#'
#' @export
EvaluationTarget <- R6::R6Class(
  "EvaluationTarget",
  public = list(

    #' @field artifact_type One of \code{"paper"}, \code{"model"},
    #'   \code{"method"}, \code{"program"}, or \code{"claim"}.
    artifact_type = NULL,

    #' @field title Character — artifact title.
    title = NULL,

    #' @field authors Character vector of author names.
    authors = NULL,

    #' @field year Integer publication year.
    year = NULL,

    #' @field doi Character DOI identifier.
    doi = NULL,

    #' @field domain_dims Named list of domain dimension labels.
    domain_dims = NULL,

    #' @field claims List of \code{\link{Claim}} objects.
    claims = NULL,

    #' @field metadata Named list for arbitrary metadata.
    metadata = NULL,

    #' Create a new EvaluationTarget
    #'
    #' @param artifact_type Character — \code{"paper"}, \code{"model"},
    #'   \code{"method"}, \code{"program"}, or \code{"claim"}.
    #' @param title Character title.
    #' @param authors Optional character vector of authors.
    #' @param year Optional integer year.
    #' @param doi Optional DOI string.
    #' @param domain_dims Optional named list of domain dimensions.
    #' @param claims Optional list of \code{\link{Claim}} objects.
    #' @param metadata Optional named list.
    #'
    #' @return A new \code{EvaluationTarget} object.
    initialize = function(artifact_type, title, authors = NULL,
                          year = NULL, doi = NULL,
                          domain_dims = list(), claims = list(),
                          metadata = list()) {
      valid_types <- c("paper", "model", "method", "program", "claim")
      stopifnot(artifact_type %in% valid_types)
      self$artifact_type <- artifact_type
      self$title <- title
      self$authors <- authors
      self$year <- year
      self$doi <- doi
      self$domain_dims <- domain_dims
      self$claims <- claims
      self$metadata <- metadata
    },

    #' Count the number of claims
    #'
    #' @return Integer number of claims.
    n_claims = function() {
      length(self$claims)
    },

    #' Print a human-readable summary
    #'
    #' @return \code{NULL}, invisibly.
    print = function() {
      cat(sprintf("EvaluationTarget [%s]: %s\n",
                  self$artifact_type, self$title))
      cat(sprintf("  Authors: %s\n",
                  paste(self$authors, collapse = ", ")))
      cat(sprintf("  Claims: %d\n", length(self$claims)))
      if (length(self$domain_dims) > 0) {
        cat("  Domains:", paste(names(self$domain_dims),
                                self$domain_dims,
                                sep = "=", collapse = ", "), "\n")
      }
    }
  )
)


#' Claim: A single claim within an evaluation target
#'
#' Represents one atomic claim extracted from a research artifact. Each claim
#' has a register (research/rhetorical/unclear) and an M-failure assessment
#' (one of the 7 modes of model failure, or \code{NA} if unassessed).
#'
#' @field id Character — unique identifier within the target (e.g. \code{"C1"}).
#' @field text Character — the claim statement.
#' @field evidence Character — description of supporting evidence.
#' @field register One of \code{"R1_research"}, \code{"R2_rhetorical"}, or
#'   \code{"unclear"}.
#' @field m_failure Character or \code{NA}. One of \code{"PASS"}, \code{"M1"},
#'   \code{"M2"}, \code{"M3"}, \code{"M4"}, \code{"M5"}, \code{"M6"}, or
#'   \code{NA} (unassessed).
#'
#' @export
Claim <- R6::R6Class(
  "Claim",
  public = list(

    #' @field id Character — unique ID within the target.
    id = NULL,

    #' @field text Character — the claim statement.
    text = NULL,

    #' @field evidence Character — supporting evidence description.
    evidence = NULL,

    #' @field register Register: \code{"R1_research"}, \code{"R2_rhetorical"},
    #'   or \code{"unclear"}.
    register = NULL,

    #' @field m_failure NA (unassessed), \code{"PASS"}, or \code{"M1"}–\code{"M6"}.
    m_failure = NA,

    #' Create a new Claim
    #'
    #' @param id Character unique ID.
    #' @param text Character claim statement.
    #' @param evidence Optional evidence description.
    #' @param register Register — \code{"R1_research"}, \code{"R2_rhetorical"},
    #'   or \code{"unclear"} (default).
    #' @param m_failure NA (default), \code{"PASS"}, or \code{"M1"}–\code{"M6"}.
    #'
    #' @return A new \code{Claim} object.
    initialize = function(id, text, evidence = NULL,
                          register = "unclear", m_failure = NA) {
      valid_reg <- c("R1_research", "R2_rhetorical", "unclear")
      stopifnot(register %in% valid_reg)
      self$id <- id
      self$text <- text
      self$evidence <- evidence
      self$register <- register
      self$m_failure <- m_failure
    }
  )
)


#' LayerResult: Result of one layer's evaluation
#'
#' Captures the output of a single INFERNO layer: scores, gap diagnosis,
#' remediation suggestions, flags, and free-text evaluator notes.
#'
#' @field layer Integer — layer number (1–7).
#' @field layer_name Character — descriptive layer name.
#' @field scores Matrix (levels \eqn{\times} dimensions) or named numeric
#'   vector.
#' @field gap_diagnosis Character describing what is missing or problematic.
#' @field remediation List with elements like \code{complement} and
#'   \code{target_level}.
#' @field flags List of flags (e.g. \code{m_failures}, \code{collapse_errors}).
#' @field notes Character — free-text evaluator notes.
#'
#' @export
LayerResult <- R6::R6Class(
  "LayerResult",
  public = list(

    #' @field layer Integer — layer number (1–7).
    layer = NULL,

    #' @field layer_name Character — descriptive name.
    layer_name = NULL,

    #' @field scores Matrix (levels \eqn{\times} dimensions) or named vector.
    scores = NULL,

    #' @field gap_diagnosis Character — what's missing.
    gap_diagnosis = NULL,

    #' @field remediation List with \code{complement} and \code{target_level}.
    remediation = NULL,

    #' @field flags List of flags.
    flags = NULL,

    #' @field notes Character — evaluator notes.
    notes = NULL,

    #' Create a new LayerResult
    #'
    #' @param layer Integer (1–7).
    #' @param layer_name Character name.
    #' @param scores Matrix or named numeric vector.
    #' @param gap_diagnosis Optional character diagnosis.
    #' @param remediation Optional list of remediation suggestions.
    #' @param flags Optional list of flags.
    #' @param notes Optional character notes.
    #'
    #' @return A new \code{LayerResult} object.
    initialize = function(layer, layer_name, scores,
                          gap_diagnosis = NULL, remediation = NULL,
                          flags = list(), notes = NULL) {
      self$layer <- layer
      self$layer_name <- layer_name
      self$scores <- scores
      self$gap_diagnosis <- gap_diagnosis
      self$remediation <- remediation
      self$flags <- flags
      self$notes <- notes
    }
  )
)


#' EvaluationResult: Top-level INFERNO evaluation result
#'
#' The return type of \code{\link{evaluate()}}. Contains the evaluation target,
#' the axiom set used, all 7 layer results, the Weighted Confidence Index (WCI)
#' vector, a textual verdict, and session metadata.
#'
#' @field target The \code{\link{EvaluationTarget}} that was evaluated.
#' @field axiom_set The \code{\link{AxiomSet}} used as evaluation context.
#' @field layers List of 7 \code{\link{LayerResult}} objects (layers 1–7).
#' @field wci Named numeric vector — the 6 WCI dimensions plus \code{composite}.
#' @field overall Character — summary verdict string.
#' @field session_info List with \code{r_version}, \code{seed},
#'   \code{timestamp}, and \code{inferno_version}.
#'
#' @export
EvaluationResult <- R6::R6Class(
  "EvaluationResult",
  public = list(

    #' @field target \code{\link{EvaluationTarget}}.
    target = NULL,

    #' @field axiom_set \code{\link{AxiomSet}} used.
    axiom_set = NULL,

    #' @field layers List of 7 \code{\link{LayerResult}} objects.
    layers = NULL,

    #' @field wci Named numeric vector (6 dims + composite).
    wci = NULL,

    #' @field overall Character verdict.
    overall = NULL,

    #' @field session_info List (r_version, seed, timestamp, inferno_version).
    session_info = NULL,

    #' Create a new EvaluationResult
    #'
    #' @param target An \code{\link{EvaluationTarget}}.
    #' @param axiom_set An \code{\link{AxiomSet}}.
    #' @param layers List of 7 \code{\link{LayerResult}} objects.
    #' @param wci Named numeric vector.
    #' @param overall Character verdict.
    #' @param session_info List of session metadata.
    #'
    #' @return A new \code{EvaluationResult} object.
    initialize = function(target, axiom_set, layers, wci,
                          overall, session_info) {
      self$target <- target
      self$axiom_set <- axiom_set
      self$layers <- layers
      self$wci <- wci
      self$overall <- overall
      self$session_info <- session_info
    },

    #' Retrieve a single layer result by number
    #'
    #' @param n Integer — layer number (1–7).
    #'
    #' @return A \code{\link{LayerResult}} object.
    get_layer = function(n) {
      self$layers[[n]]
    },

    #' Print a human-readable summary
    #'
    #' @return \code{NULL}, invisibly.
    print = function() {
      cat(sprintf("=== INFERNO Evaluation: %s ===\n", self$target$title))
      cat(sprintf("AxiomSet: %s | Metric: %s\n",
                  self$axiom_set$get_hash(), self$axiom_set$metric))
      for (lr in self$layers) {
        cat(sprintf("  L%d %s: %s\n", lr$layer, lr$layer_name,
                    ifelse(is.null(lr$gap_diagnosis), "PASS",
                           paste0("GAP: ", lr$gap_diagnosis))))
      }
      cat(sprintf("\nWCI: %.3f\n", self$wci["composite"]))
      cat(sprintf("Verdict: %s\n", self$overall))
    }
  )
)