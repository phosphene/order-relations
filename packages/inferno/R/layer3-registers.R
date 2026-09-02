#' Layer 3 — Dual-Register Analysis
#'
#' Classifies each claim as R1 (research register) or R2 (rhetorical register),
#' auto-classifies unclear claims via text-pattern heuristics, detects collapse
#' errors (R1 findings used to support R2 claims without intermediate
#' justification), and produces corrected R1 statements for collapsed passages.
#'
#' @section Register definitions:
#' \describe{
#'   \item{R1\_research}{Empirical, evidence-grounded claim. Contains specific
#'     data, hedging qualifiers, citations, or measured quantities.}
#'   \item{R2\_rhetorical}{Persuasive, interpretive, or generalized claim.
#'     Contains superlatives, value judgments, sweeping statements, or
#'     unsupported extrapolations.}
#'   \item{unclear}{Ambiguous register. The classifier will attempt to resolve
#'     via text-pattern matching.}
#' }
#'
#' @section Collapse error:
#' A collapse error occurs when an R1 finding is used to directly support an R2
#' claim without an intermediate bridging justification. For example: "Our
#' experiment showed a 3\% increase in X (R1) therefore X is the fundamental
#' driver of Y (R2)" — the leap from measurement to fundamental status is
#' unjustified.
#'
#' @name layer3-registers
NULL


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Patterns indicative of R1 (research) register
#' @noRd
.R1_INDICATORS <- list(
  hedging = paste0(
    "\\b(suggests?|indicates?|implies?|may|might|could|possibly|",
    "tentatively|consistent with|appears? to|seems? to|",
    "provisionally|preliminary)\\b"
  ),
  citations = "\\b\\w+\\s*\\(\\d{4}\\)|\\bet al\\.|\\set al\\b|\\bcited\\b",
  quantification = paste0(
    "\\b(\\d+\\.?\\d*\\s*[%‰]|n\\s*=\\s*\\d+|p\\s*[<>=]\\s*0\\.\\d+|",
    "r\\s*=\\s*0\\.\\d+|\\d+\\.?\\d*\\s*±\\s*\\d+|",
    "\\d+\\.?\\d*\\s*\\(\\s*[A-Z]+\\s*\\))\\b"
  ),
  methodology = paste0(
    "\\b(experiment|measurement|observation|sample|assay|trial|",
    "protocol|replicate|calibrat|quantif|statistical|",
    "regression|correlation|logistic|bayesian|likelihood)\\b"
  ),
  empirical = paste0(
    "\\b(evidence|data|finding|result|observed|measured|detected|",
    "recorded|demonstrated|shown|reported|documented)\\b"
  )
)

#' Patterns indicative of R2 (rhetorical) register
#' @noRd
.R2_INDICATORS <- list(
  superlatives = paste0(
    "\\b(fundamentally?|essentially?|critically|pivotally?|paramount|",
    "revolutionary|groundbreaking|unprecedented|transformative|",
    "most important|most significant|key driver|core principle|",
    "central tenet|ultimate|definitive)\\b"
  ),
  persuasive = paste0(
    "\\b(clearly|obviously|undoubtedly|without doubt|",
    "must be|cannot be|inevitably|necessarily|of course|",
    "it is evident that|it is clear that|it follows that|",
    "naturally|trivially|simply|merely)\\b"
  ),
  sweeping = paste0(
    "\\b(always|never|every|all|none|nothing|everything|",
    "universally|invariably|categorically|absolutely|",
    "completely|entirely|wholly)\\b"
  ),
  value_judgment = paste0(
    "\\b(interestingly|importantly|remarkably|strikingly|",
    "notably|surprisingly|unexpectedly|compellingly|",
    "elegantly|powerfully|profoundly|deeply)\\b"
  ),
  extrapolation = paste0(
    "\\b(bridges the gap|explains everything|accounts for all|",
    "solves the problem|resolves the debate|",
    "provides a unified|offers a complete|",
    "has profound implications for|revolutionizes our understanding|",
    "transforms the field)\\b"
  )
)


#' Classify a single claim text as R1 or R2 using pattern matching
#'
#' @param text Character — the claim text.
#' @param score Logical — if TRUE, return a named numeric vector of R1 and R2
#'   scores instead of the classification label.
#'
#' @return Character — \code{"R1_research"}, \code{"R2_rhetorical"}, or
#'   \code{"unclear"}. If \code{score = TRUE}, a named numeric vector with
#'   \code{r1_score} and \code{r2_score}.
#'
#' @keywords internal
classify_register <- function(text, score = FALSE) {
  if (is.null(text) || is.na(text) || nchar(trimws(text)) == 0) {
    if (score) return(c(r1_score = 0, r2_score = 0))
    return("unclear")
  }

  text_lower <- tolower(text)

  # Count R1 indicator matches
  r1_count <- 0L
  for (pattern in .R1_INDICATORS) {
    m <- gregexpr(pattern, text_lower, perl = TRUE)[[1]]
    if (length(m) == 1L && m == -1L) next
    r1_count <- r1_count + length(m)
  }

  # Count R2 indicator matches
  r2_count <- 0L
  for (pattern in .R2_INDICATORS) {
    m <- gregexpr(pattern, text_lower, perl = TRUE)[[1]]
    if (length(m) == 1L && m == -1L) next
    r2_count <- r2_count + length(m)
  }

  if (score) {
    return(c(r1_score = r1_count, r2_score = r2_count))
  }

  if (r1_count > 0 && r2_count == 0) {
    return("R1_research")
  }
  if (r2_count > 0 && r1_count == 0) {
    return("R2_rhetorical")
  }
  if (r1_count > 0 && r2_count > 0) {
    # Mixed signals: whichever has more matches wins
    if (r1_count >= r2_count) {
      return("R1_research")
    } else {
      return("R2_rhetorical")
    }
  }
  # Neither matched
  return("unclear")
}


#' Detect collapse errors in a list of claims
#'
#' A collapse error occurs when an R1 claim's evidence is used to directly
#' support an R2 claim without intermediate bridging justification. We detect
#' this by looking for patterns where an R2 claim references back to evidence
#' that is clearly R1 in nature, or where the evaluation context shows R1
#' findings being leveraged for R2 conclusions.
#'
#' @param claims List of \code{\link{Claim}} objects.
#' @param r1_register Character vector of resolved register labels (one per
#'   claim, in order).
#'
#' @return A list with elements:
#'   \describe{
#'     \item{collapse_errors}{Logical vector — TRUE for each claim that has a
#'       collapse error.}
#'     \item{corrected_r1}{Character vector — corrected R1 statement for each
#'       claim, or NA if no correction is needed.}
#'   }
#'
#' @keywords internal
detect_collapse_errors <- function(claims, r1_register) {
  n <- length(claims)
  collapse_errors <- logical(n)
  corrected_r1 <- character(n)

  for (i in seq_len(n)) {
    corrected_r1[i] <- NA_character_

    if (r1_register[i] == "R2_rhetorical") {
      # Check if the evidence for this R2 claim is R1 in nature
      # (i.e., the evidence text contains R1 indicators)
      evidence <- claims[[i]]$evidence
      if (!is.null(evidence) && !is.na(evidence) &&
          nchar(trimws(evidence)) > 0) {
        ev_score <- classify_register(evidence, score = TRUE)
        if (ev_score["r1_score"] > 0) {
          # R1 evidence being used to support an R2 claim — collapse error
          collapse_errors[i] <- TRUE
          corrected_r1[i] <- generate_corrected_r1(claims[[i]], evidence)
        }
      }

      # Also check: is there a preceding R1 claim whose evidence is implicitly
      # being used to support this R2 claim? Look for text overlap.
      if (!collapse_errors[i] && i > 1L) {
        for (j in seq_len(i - 1L)) {
          if (r1_register[j] == "R1_research") {
            prev_text <- tolower(claims[[j]]$text)
            curr_text <- tolower(claims[[i]]$text)
            # Look for shared key terms that suggest the R2 claim builds on
            # the R1 claim without bridging
            shared_words <- intersect(
              strsplit(prev_text, "\\s+")[[1]],
              strsplit(curr_text, "\\s+")[[1]]
            )
            # Filter out very short stop words
            shared_words <- shared_words[nchar(shared_words) > 3]
            if (length(shared_words) >= 2) {
              collapse_errors[i] <- TRUE
              corrected_r1[i] <- generate_corrected_r1(
                claims[[i]],
                claims[[j]]$evidence
              )
              break
            }
          }
        }
      }
    }
  }

  list(
    collapse_errors = collapse_errors,
    corrected_r1    = corrected_r1
  )
}


#' Generate a corrected R1 statement from a claim and its evidence
#'
#' Produces a de-escalated, evidence-grounded version of the claim that
#' restates it in the R1 research register.
#'
#' @param claim A \code{\link{Claim}} object.
#' @param evidence Character — the evidence text.
#'
#' @return Character — the corrected R1 statement.
#'
#' @keywords internal
generate_corrected_r1 <- function(claim, evidence) {
  # Strip superlatives and value judgments from the claim text
  text <- claim$text
  for (pattern in .R2_INDICATORS) {
    text <- gsub(pattern, "", text, perl = TRUE, ignore.case = TRUE)
  }

  # Clean up whitespace from removals
  text <- gsub("\\s+", " ", text)
  text <- trimws(text)

  # Add hedging prefix
  text <- paste0("Evidence suggests that ", tolower(substr(text, 1, 1)),
                 substr(text, 2, nchar(text)))

  # Append evidence reference
  if (!is.null(evidence) && !is.na(evidence) && nchar(trimws(evidence)) > 0) {
    text <- paste0(text, " (supported by: ", trimws(evidence), ").")
  } else {
    text <- paste0(text, ".")
  }

  text
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Evaluate Layer 3 — Dual-Register Analysis
#'
#' Performs the dual-register analysis on the claims of an evaluation target.
#' Each claim is classified as R1 (research) or R2 (rhetorical). Unclear claims
#' are resolved via text-pattern heuristics. Collapse errors — where R1
#' findings are used to support R2 claims without intermediate justification —
#' are detected and corrected R1 statements are generated.
#'
#' @param target An \code{\link{EvaluationTarget}} object whose \code{claims}
#'   list will be analyzed.
#' @param axiom_set An \code{\link{AxiomSet}} object (used for domain context;
#'   currently carried for signature compatibility with the dispatch engine).
#' @param fc An \code{fcaR::FormalContext} object (carried for signature
#'   compatibility with the dispatch engine).
#' @param manual_register Optional named character vector. Names are claim IDs,
#'   values are \code{"R1_research"} or \code{"R2_rhetorical"}. When provided,
#'   these override both the claim's stored register and any auto-classification
#'   for the named claims.
#'
#' @return A \code{\link{LayerResult}} object with:
#'   \describe{
#'     \item{scores}{A character matrix with rows = claim IDs and columns =
#'       \code{register}, \code{collapse_error}, \code{corrected_r1}.}
#'     \item{flags}{A list with element \code{collapse_errors} — a logical
#'       vector indicating which claims have collapse errors.}
#'     \item{gap_diagnosis}{Character describing collapse errors, if any.}
#'     \item{remediation}{A list with element \code{corrected_r1} — a character
#'       vector of corrected R1 statements.}
#'   }
#'
#' @examples
#' target <- EvaluationTarget$new(
#'   artifact_type = "model",
#'   title = "Test Model",
#'   claims = list(
#'     Claim$new(id = "C1", text = "Simulation shows 5% increase",
#'               evidence = "Gillespie run #42", register = "R1_research"),
#'     Claim$new(id = "C2", text = "This is the fundamental driver",
#'               evidence = "Simulation data", register = "unclear")
#'   )
#' )
#' result <- evaluate_layer3(target)
#' result$scores
#'
#' @export
evaluate_layer3 <- function(target, axiom_set = NULL, fc = NULL,
                            manual_register = NULL) {
  claims <- target$claims
  n <- length(claims)

  # Step 1: Resolve register for each claim
  # Priority: manual_register > claim$register > auto-classify
  resolved_register <- character(n)

  for (i in seq_len(n)) {
    cid <- claims[[i]]$id
    stored <- claims[[i]]$register

    # Manual override
    if (!is.null(manual_register) && cid %in% names(manual_register)) {
      resolved_register[i] <- manual_register[cid]
      next
    }

    # Already known
    if (stored != "unclear") {
      resolved_register[i] <- stored
      next
    }

    # Auto-classify
    resolved_register[i] <- classify_register(claims[[i]]$text)
  }

  # Step 2: Detect collapse errors
  collapse <- detect_collapse_errors(claims, resolved_register)

  # Step 3: Build score matrix
  score_matrix <- matrix(
    nrow = n, ncol = 3L,
    dimnames = list(
      vapply(claims, `[[`, character(1L), "id"),
      c("register", "collapse_error", "corrected_r1")
    )
  )
  score_matrix[, "register"]        <- resolved_register
  score_matrix[, "collapse_error"]  <- ifelse(collapse$collapse_errors,
                                               "TRUE", "FALSE")
  score_matrix[, "corrected_r1"]    <- ifelse(
    is.na(collapse$corrected_r1), "", collapse$corrected_r1
  )

  # Step 4: Build diagnosis
  n_collapse <- sum(collapse$collapse_errors)
  if (n_collapse > 0) {
    collapsed_ids <- vapply(
      claims[collapse$collapse_errors], `[[`, character(1L), "id"
    )
    gap_diagnosis <- sprintf(
      "%d collapse error(s) detected in claim(s): %s. R1 findings used to support R2 claims without intermediate justification.",
      n_collapse, paste(collapsed_ids, collapse = ", ")
    )
  } else {
    gap_diagnosis <- NULL
  }

  # Step 5: Build remediation
  remediation <- list(
    corrected_r1 = collapse$corrected_r1
  )

  # Step 6: Build flags
  flags <- list(
    collapse_errors = collapse$collapse_errors
  )

  # Step 7: Summary notes
  r1_count <- sum(resolved_register == "R1_research")
  r2_count <- sum(resolved_register == "R2_rhetorical")
  unclear_count <- sum(resolved_register == "unclear")
  notes <- sprintf(
    "Layer 3 Dual-Register Analysis: %d R1 claims, %d R2 claims, %d unclear. %d collapse errors.",
    r1_count, r2_count, unclear_count, n_collapse
  )

  LayerResult$new(
    layer          = 3L,
    layer_name     = "Dual-Register Analysis",
    scores         = score_matrix,
    gap_diagnosis  = gap_diagnosis,
    remediation    = remediation,
    flags          = flags,
    notes          = notes
  )
}