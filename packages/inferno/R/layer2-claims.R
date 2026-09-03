#' Layer 2 — Claims/Evidence/Inference Triangle (M-Failure Audit)
#'
#' Evaluates each claim in an \code{\link{EvaluationTarget}} against its
#' supporting evidence, classifying any gap between the strength of the claim
#' and the strength of the evidence as one of six M-failure modes (M1–M6) or
#' PASS.
#'
#' @section M-Failure Types:
#' \describe{
#'   \item{M1}{Claim is more precise than evidence supports. The claim uses
#'     precise quantification (e.g. exact percentages, narrow ranges) while the
#'     evidence is qualitative, approximate, or uses wide ranges.}
#'   \item{M2}{Conditional stated as established. The claim uses definitive
#'     language (proves, demonstrates, establishes) while the evidence is
#'     conditional (may, suggests, indicates, under these conditions).}
#'   \item{M3}{Claim generalizes beyond tested domain. The claim uses universal
#'     quantifiers (all, every, always) while the evidence is specific to a
#'     bounded context.}
#'   \item{M4}{Correlation conflated with causation. The claim uses causal
#'     language (causes, produces, drives, because) while the evidence is
#'     correlational (associated with, correlated, related to).}
#'   \item{M5}{Historical claim with experimental confidence. The claim asserts
#'     a historical or evolutionary reconstruction with the confidence of a
#'     controlled experiment.}
#'   \item{M6}{R1 finding inflated to R2 framing. The claim is in the R2
#'     (rhetorical) register but is supported only by R1 (research) evidence
#'     without intermediate justification.}
#' }
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object containing a list
#'   of \code{\link{Claim}} objects.
#' @param axiom_set An \code{\link{AxiomSet}} R6 object providing the
#'   evaluation context (used for hash consistency, not directly for L2
#'   classification).
#' @param fc Optional \code{fcaR::FormalContext} for advanced concept-based
#'   analysis. Not required for the standard M-failure audit.
#'
#' @return A \code{\link{LayerResult}} R6 object with:
#'   \describe{
#'     \item{scores}{A character matrix with \code{n_claims} rows and one
#'       column \code{"M_classification"} containing the classification
#'       (\code{"PASS"} or \code{"M1"}–\code{"M6"}). Row names are the claim
#'       IDs.}
#'     \item{flags}{A list with element \code{m_failures} — a named character
#'       vector mapping claim IDs to their M-failure classification, or an
#'       empty character vector if all passed.}
#'     \item{gap_diagnosis}{A character string describing the composite audit,
#'       or \code{NULL} if no M-failures were found.}
#'   }
#'
#' @examples
#' \dontrun{
#' target <- make_gard_target()
#' ax     <- make_test_axiom_set()
#' result <- evaluate_layer2(target, ax)
#' result$flags$m_failures  # named character vector
#' result$scores            # matrix of classifications
#' }
#'
#' @importFrom stats setNames
#' @export
evaluate_layer2 <- function(target, axiom_set, fc = NULL) {
  # Validate inputs
  stopifnot(inherits(target, "EvaluationTarget"))
  stopifnot(inherits(axiom_set, "AxiomSet"))
  if (!is.null(fc)) {
    stopifnot(inherits(fc, "FormalContext"))
  }

  claims <- target$claims
  n      <- length(claims)

  if (n == 0) {
    # Empty claims — return a no-op result
    scores <- matrix(character(0), nrow = 0, ncol = 1,
                     dimnames = list(NULL, "M_classification"))
    return(LayerResult$new(
      layer           = 2L,
      layer_name      = "Claims/Evidence/Inference Triangle (M-Failure Audit)",
      scores          = scores,
      gap_diagnosis   = NULL,
      remediation     = NULL,
      flags           = list(m_failures = structure(character(0), names = character(0))),
      notes           = "No claims to evaluate."
    ))
  }

  # Classify each claim
  classifications <- vapply(claims, classify_claim, character(1),
                            USE.NAMES = FALSE)
  names(classifications) <- vapply(claims, function(cl) cl$id, character(1))

  # Update each claim's m_failure field (unname to avoid named-vector mismatch)
  for (i in seq_len(n)) {
    claims[[i]]$m_failure <- unname(classifications[i])
  }

  # Build scores matrix: one row per claim, one column "M_classification"
  scores <- matrix(
    classifications,
    nrow = n, ncol = 1,
    dimnames = list(names(classifications), "M_classification")
  )

  # Build flags
  m_failures <- classifications[classifications != "PASS"]
  flags <- list(m_failures = m_failures)

  # Build gap diagnosis if any M-failures found
  gap_diagnosis <- NULL
  if (length(m_failures) > 0) {
    diagnosis_parts <- vapply(seq_along(m_failures), function(i) {
      sprintf("%s: %s", names(m_failures)[i], m_failures[i])
    }, character(1))
    gap_diagnosis <- paste(
      sprintf("M-failure audit: %d of %d claims flagged.",
              length(m_failures), n),
      paste(diagnosis_parts, collapse = "; "),
      sep = " "
    )
  }

  LayerResult$new(
    layer         = 2L,
    layer_name    = "Claims/Evidence/Inference Triangle (M-Failure Audit)",
    scores        = scores,
    gap_diagnosis = gap_diagnosis,
    remediation   = NULL,
    flags         = flags,
    notes         = NULL
  )
}


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Classify a single claim for M-failure
#'
#' Applies the six M-failure detectors in order. If none fire, returns
#' \code{"PASS"}. The first matching classification wins (priority order: M1
#' through M6).
#'
#' @param claim A \code{\link{Claim}} R6 object.
#'
#' @return Character — \code{"PASS"} or \code{"M1"}–\code{"M6"}.
#'
#' @keywords internal
classify_claim <- function(claim) {
  if (detect_M1(claim)) return("M1")
  if (detect_M2(claim)) return("M2")
  if (detect_M3(claim)) return("M3")
  if (detect_M4(claim)) return("M4")
  if (detect_M5(claim)) return("M5")
  if (detect_M6(claim)) return("M6")
  "PASS"
}


# --- M1: Claim more precise than evidence supports -------------------------

#' @describeIn classify_claim Detect M1: precision mismatch
#'
#' Fires when the claim uses precise quantification (exact numbers, narrow
#' ranges, significant digits) while the evidence is qualitative, vague, or
#' uses wide ranges.
#'
#' @keywords internal
detect_M1 <- function(claim) {
  text_lower     <- tolower(claim$text)
  evidence_lower <- tolower(claim$evidence %||% "")

  # Precision markers in the claim
  precise_patterns <- c(
    "exactly ",
    "precisely ",
    "\\d+\\.\\d+",           # decimal numbers (significant digits)
    "\\d+%",                 # exact percentages
    "\\bexact\\b",
    "\\bprecise\\b",
    "±\\d+(\\.\\d+)?",      # tight tolerance
    "between \\d+ and \\d+", # narrow range (< 10 units apart)
    "\\baccurate to\\b"
  )

  has_precise_claim <- any(vapply(precise_patterns, function(p) {
    grepl(p, text_lower, perl = TRUE)
  }, logical(1)))

  if (!has_precise_claim) return(FALSE)

  # Evidence is NOT precise — it's qualitative, vague, or uses wide ranges
  vague_evidence <- any(grepl(
    paste0(
      "\\b(approximately|roughly|about|around|estimated|suggests|",
      "qualitative|broadly|generally|vague|approximately|",
      "wide range|order of magnitude|may indicate|might suggest)\\b"
    ),
    evidence_lower, perl = TRUE
  ))

  # Also fire if evidence is empty or purely descriptive
  evidence_empty <- nchar(evidence_lower) == 0

  # Also fire if evidence uses only qualitative descriptors
  only_qualitative <- !grepl("\\d", evidence_lower)

  vague_evidence || evidence_empty || only_qualitative
}


# --- M2: Conditional stated as established ----------------------------------

#' @describeIn classify_claim Detect M2: conditional stated as established
#'
#' Fires when the claim uses definitive, certainty-marked language while the
#' evidence is hedged, conditional, or qualified.
#'
#' @keywords internal
detect_M2 <- function(claim) {
  text_lower     <- tolower(claim$text)
  evidence_lower <- tolower(claim$evidence %||% "")

  # Definitive markers in the claim
  definitive_patterns <- paste0(
    "\\b(proves?|proven|demonstrates?|demonstrated|establishes?|",
    "established|confirms?|confirmed|determines?|determined|",
    "shows?|shown?|conclusively|undoubtedly|certainly|",
    "definitively|unequivocally|without doubt|is known to|",
    "it is established that|as a matter of fact)\\b"
  )

  has_definitive_claim <- grepl(definitive_patterns, text_lower, perl = TRUE)

  if (!has_definitive_claim) return(FALSE)

  # Conditional / hedging markers in the evidence
  conditional_patterns <- paste0(
    "\\b(may|might|could|perhaps|possibly|probably|suggests?|",
    "suggestive|indicates?|indicative|tentative|preliminary|",
    "under these conditions|in this context|within this framework|",
    "it appears|it seems|one might|not yet|pending|",
    "further research|further study|requires|",
    "remains to be|has yet to|uncertain|unclear|",
    "hypothesize|hypothesized|conjecture|speculate)\\b"
  )

  grepl(conditional_patterns, evidence_lower, perl = TRUE)
}


# --- M3: Generalizes beyond tested domain -----------------------------------

#' @describeIn classify_claim Detect M3: overgeneralization
#'
#' Fires when the claim uses universal quantifiers or unbounded scope while
#' the evidence is limited to a specific domain, population, or condition.
#'
#' @keywords internal
detect_M3 <- function(claim) {
  text_lower     <- tolower(claim$text)
  evidence_lower <- tolower(claim$evidence %||% "")

  # Universal/broad scope markers in the claim
  universal_patterns <- paste0(
    "\\b(all|every|always|any|never|none|everywhere|in all cases|",
    "universally|completely|entirely|wholly|absolutely|",
    "without exception|in general|as a general rule|",
    "fundamentally|inherently|intrinsically)\\b"
  )

  has_universal_claim <- grepl(universal_patterns, text_lower, perl = TRUE)

  if (!has_universal_claim) return(FALSE)

  # Domain-specific / bounded markers in the evidence
  bounded_patterns <- paste0(
    "\\b(in this study|in our experiment|in this system|",
    "under these conditions|within this domain|in this context|",
    "in this model|in vitro|in silico|in this population|",
    "in this sample|under laboratory conditions|",
    "in this specific|limited to|restricted to|bounded by|",
    "confined to|in this setting|this particular)\\b"
  )

  grepl(bounded_patterns, evidence_lower, perl = TRUE)
}


# --- M4: Correlation conflated with causation -------------------------------

#' @describeIn classify_claim Detect M4: causal conflation
#'
#' Fires when the claim uses causal language while the evidence is
#' correlational or associational.
#'
#' @keywords internal
detect_M4 <- function(claim) {
  text_lower     <- tolower(claim$text)
  evidence_lower <- tolower(claim$evidence %||% "")

  # Causal markers in the claim
  causal_patterns <- paste0(
    "\\b(causes?|caused|produced?|drives?|driven|leads? to|results? in|",
    "gives rise to|triggers?|elicits?|generates?|",
    "because of|due to|is responsible for|accounts for|",
    "determines?|controls?|regulates?\\b(?!\\s+expression))"
  )

  has_causal_claim <- grepl(causal_patterns, text_lower, perl = TRUE)

  if (!has_causal_claim) return(FALSE)

  # Correlational/associational markers in the evidence
  correlational_patterns <- paste0(
    "\\b(correlates?|correlated|correlation|associated with|",
    "related to|linked to|connected with|tends? to|",
    "co-occurs?|coincides? with|accompanies?|accompanied by|",
    "relationship between|association between|covaries?|",
    "co-variation|co-vary)\\b"
  )

  grepl(correlational_patterns, evidence_lower, perl = TRUE)
}


# --- M5: Historical claim with experimental confidence ----------------------

#' @describeIn classify_claim Detect M5: historical-claim experimental-confidence
#'
#' Fires when the claim asserts a historical, evolutionary, or deep-time
#' reconstruction with the certainty of a controlled experiment.
#'
#' @keywords internal
detect_M5 <- function(claim) {
  text_lower <- tolower(claim$text)

  # Historical / evolutionary / deep-time markers in the claim
  historical_patterns <- paste0(
    "\\b(evolved|evolutionary|ancestral|primordial|",
    "early earth|prebiotic|origin of life|",
    "emerged|emergence of|historical|ancient|",
    "deep time|billions of years|millions of years|",
    "primitive|primordial soup|proto-|protocell|",
    "last universal common ancestor|LUCA|",
    "convergent evolution|divergent|phylogenetic|",
    "fossil|palaeo|paleo|geological)\\b"
  )

  has_historical <- grepl(historical_patterns, text_lower, perl = TRUE)

  if (!has_historical) return(FALSE)

  # Experimental/predictive certainty markers in the claim
  experimental_certainty <- paste0(
    "\\b(demonstrates?|proves?|confirms?|established|",
    "determined|conclusively|unequivocally|",
    "predicts?|predicted|verified|validated)\\b"
  )

  grepl(experimental_certainty, text_lower, perl = TRUE)
}


# --- M6: R1 finding inflated to R2 framing ----------------------------------

#' @describeIn classify_claim Detect M6: register inflation
#'
#' Fires when the claim is in the R2 (rhetorical/broad significance) register
#' but is supported by evidence that is limited to R1 (research) findings
#' without intermediate justification.
#'
#' @keywords internal
detect_M6 <- function(claim) {
  # Claim must be in R2 register
  if (claim$register != "R2_rhetorical") return(FALSE)

  evidence_lower <- tolower(claim$evidence %||% "")

  # R1-limited patterns in the evidence (narrow, specific, experimental)
  r1_patterns <- paste0(
    "\\b(in this study|in our experiment|in this model|",
    "in vitro|in silico|in this simulation|",
    "in this system|in this analysis|in this dataset|",
    "in our sample|this particular)\\b"
  )

  # Check if the evidence is R1-level (limited to specific research findings)
  # AND does NOT contain R2-bridging language
  has_r1_evidence <- grepl(r1_patterns, evidence_lower, perl = TRUE)

  # Bridging language that would justify R2 framing
  bridging_patterns <- paste0(
    "\\b(meta-analysis|systematic review|broadly consistent|",
    "across multiple studies|convergent evidence|",
    "cumulative evidence|robust literature|extensive evidence|",
    "widely replicated|generally accepted|established consensus)\\b"
  )

  has_bridging <- grepl(bridging_patterns, evidence_lower, perl = TRUE)

  has_r1_evidence && !has_bridging
}


# ---------------------------------------------------------------------------
# Utility: null-coalescing operator (internal)
# ---------------------------------------------------------------------------

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}