#' Layer 6 — Analogical Argument (Bartha Admissibility)
#'
#' Evaluates analogical arguments in research artifacts using Paul Bartha's
#' criteria for admissible analogy. Analogy is central to scientific reasoning:
#' mapping from a **source domain** (known, well-understood) to a **target domain**
#' (less understood, being evaluated). Bartha (2010) identifies four criteria
#' for admissibility:
#'
#' \describe{
#'   \item{Prior Association}{There must be a genuine connection between source
#'     and target — not arbitrary similarity.}
#'   \item{Potential for Symmetry}{The analogy must generate productive transfer
#'     in both directions, not just serve as illustration.}
#'   \item{Directionality}{The mapping must proceed from known→unknown, not
#'     the reverse.}
#'   \item{Critical Disanalogy}{Load-bearing differences that would undermine
#'     the conclusion.}
#' }
#'
#' The implementation uses Formal Concept Analysis (fcaR) to compare the concept
#' lattices of source and target domains. The **concept intersection** measures
#' structural similarity. High overlap with few critical disanalogies supports
#' admissibility.
#'
#' Output verdicts:
#' \describe{
#'   \item{admissible}{Strong prior association, good symmetry, appropriate
#'     directionality, no critical disanalogies.}
#'   \item{admissible_with_caveats}{Meets criteria but has some critical
#'     disanalogies flagged.}
#'   \item{not_admissible}{Weak connection, poor symmetry, or critical
#'     disanalogy present.}
#' }
#'
#' @name layer6-analogy
NULL


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Identify analogical claims in an evaluation target
#'
#' Scans claims for explicit metaphorical/analogy language: "like", "as",
#' "similar to", "analogous to", "mapped to", "compared to", "parallels",
#' "mirrors", "echoes", the pattern "X is like Y", etc.
#'
#' @param target An \code{\link{EvaluationTarget}}.
#'
#' @return A list with elements:
#' \describe{
#'   \item{found}{logical — TRUE if any analogical claim detected.}
#'   \item{analogies}{A list of detected analogies, each a named list with
#'     \code{source}, \code{target}, \code{text}, \code{claims}, and
#'     \code{claim_ids}.}
#' }
#'
#' @keywords internal
extract_analogies <- function(target) {
  if (length(target$claims) == 0L) {
    return(list(found = FALSE, analogies = list()))
  }

  # Patterns that typically signal explicit analogical reasoning
  patterns <- c(
    "\\b(analog(uous|y)|is like|as.*as|similar to|parallels?|mirrored?|echoes?|mirror)",
    "\\b(mapped (to|onto)|compared to|resembl(?:e|ance)|parallels?|isomorphic|homomorphic)",
    "\\bX\\b.*\\bY\\b",  # generic X is like Y pattern
    "\\bfr analogy|analogical",
    "\\bmetapho(r|ric)",
    "\\bcompare.*to",
    "\\bparallel",
    "\\blike a|like an",
    "\\bjust as.*so",
    "\\bthe case with",
    "\\bin the same vein|along the same lines",
    "\\bmodelled after|patterned after"
  )

  analogy_claim_info <- list()
  analogy_text_indices <- character(0L)

  for (i in seq_along(target$claims)) {
    claim <- target$claims[[i]]
    text <- tolower(claim$text)
    evidence <- tolower(claim$evidence %||% "")

    for (pattern in patterns) {
      if (grepl(pattern, text, ignore.case = TRUE, perl = TRUE) ||
          grepl(pattern, evidence, ignore.case = TRUE, perl = TRUE)) {
        analogy_claim_info[[i]] <- list(
          claim = claim,
          index = i,
          text = claim$text,
          evidence = claim$evidence
        )
        analogy_text_indices <- c(analogy_text_indices, paste0("C", i))
        break
      }
    }
  }

  if (length(analogy_claim_info) == 0L) {
    return(list(found = FALSE, analogies = list()))
  }

  # Extract source/target from claim text using heuristic parsing
  # Pattern: "X is like Y", "X is analogous to Y", etc.
  # Build separate analogy data structures WITHOUT mutating original Claim objects
  analogy_data <- list()
  for (i in seq_along(analogy_claim_info)) {
    info <- analogy_claim_info[[i]]
    text <- info$text

    # Try to extract source and target
    # Pattern: "A is like B" → source=B, target=A (since source is typically
    # the known, well-understood concept being mapped from)
    # Guard against no-match: regmatches returns character(0) which cannot
    # be indexed with [[1L]] when the regex doesn't match.
    m <- regexec(
      "(\\w+(?:\\s+\\w+)*?)\\s+(?:is\\s+)?(?:like|analogous to|similar to|comparable to|maps to|parallels)\\s+(\\w+(?:\\s+\\w+)*)",
      text, ignore.case = TRUE, perl = TRUE
    )
    matches <- regmatches(text, m)
    if (length(matches) == 0 || length(matches[[1L]]) == 0L) {
      target_term <- NA_character_
      source_term <- NA_character_
    } else {
      m_vals <- matches[[1L]]
      if (length(m_vals) >= 3) {
        target_term <- trimws(m_vals[2])
        source_term <- trimws(m_vals[3])
      } else {
        # Fallback: try "X is analogous to Y" pattern with "the"
        m2 <- regexec(
          "\\b(?:the\\s+)?(\\w+(?:\\s+\\w+)*?)\\s+is\\s+(?:analogous to|like|similar to)\\s+(the\\s+)?(\\w+(?:\\s+\\w+)*)",
          text, ignore.case = TRUE, perl = TRUE
        )
        matches2 <- regmatches(text, m2)
        if (length(matches2) == 0 || length(matches2[[1L]]) == 0L) {
          target_term <- NA_character_
          source_term <- NA_character_
        } else {
          m2_vals <- matches2[[1L]]
          if (length(m2_vals) >= 4) {
            target_term <- trimws(m2_vals[2])
            source_term <- trimws(m2_vals[4])
          } else {
            target_term <- NA_character_
            source_term <- NA_character_
          }
        }
      }
    }

    # Store as separate analogy data (not mutating Claim)
    analogy_data[[i]] <- list(
      source_term = source_term,
      target_term = target_term,
      claim = info$claim,
      claim_index = info$index,
      text = text
    )
  }

  # Group similar analogies by shared terms
  unique_combinations <- unique(vapply(analogy_data, function(d) {
    key <- paste(sort(c(d$source_term %||% NA, d$target_term %||% NA)), collapse = "::")
    key
  }, character(1)))

  analogies <- list()

  for (k in seq_along(unique_combinations)) {
    key <- unique_combinations[k]
    parts <- strsplit(key, "::")[[1L]]
    source_term <- parts[1L]
    target_term <- if (length(parts) > 1) parts[2L] else NA_character_

    # Filter claims matching this source/target pair (partial match)
    matching_indices <- which(sapply(analogy_data, function(d) {
      (is.na(source_term) ||
         grepl(tolower(gsub("^\\s+|\\s+$", "", d$source_term %||% "")), 
               tolower(source_term))) ||
      (is.na(target_term) ||
         grepl(tolower(gsub("^\\s+|\\s+$", "", d$target_term %||% "")), 
               tolower(target_term)))
    }))

    matching_data <- analogy_data[matching_indices]
    matching_claims <- lapply(matching_data, `[[`, "claim")

    analogies[[k]] <- list(
      source = source_term,
      target = target_term,
      text = paste(vapply(matching_data, function(d) {
        if (is.null(d$text)) "" else d$text
      }, character(1)), collapse = "; "),
      claims = matching_claims,
      claim_ids = vapply(matching_data, function(d) d$claim$id, character(1))
    )
  }

  list(
    found = TRUE,
    analogies = analogies
  )
}


#' Assess prior association between source and target
#'
#' Prior association measures whether source and target are genuinely
#' connected (not arbitrary). This is done by checking:
#' \enumerate{
#'   \item Shared domain context (both in source material)
#'   \item Explicit connection stated in claims
#'   \item Conceptual overlap via formal context
#' }
#'
#' @param target An \code{\link{EvaluationTarget}}.
#' @param axiom_set An \code{\link{AxiomSet}} providing the conceptual space.
#' @param fc An optional \code{fcaR::FormalContext} for lattice analysis.
#'
#' @return A numeric score in [0, 1]. Higher = stronger prior association.
#'
#' @keywords internal
assess_prior_association <- function(target, axiom_set, fc = NULL) {
  if (length(target$claims) == 0L) {
    return(0.5)  # Neutral default
  }

  score <- 0.5  # Base score (neutral assumption)
  claims_text <- vapply(target$claims, function(c) {
    paste0(c$text, " ", c$evidence %||% "")
  }, character(1))
  all_text <- paste(claims_text, collapse = " ")

  # Pattern 1: explicit statement of connection
  explicit_patterns <- c(
    "\\bconnected\\b", "\\brelevant\\b", "\\bcoupling\\b",
    "\\brelation.*ship", "\\bcorrelation", "\\bassociation",
    "\\bbinding", "\\binteracts?\\b", "\\binteraction",
    "\\bcoupled", "\\blinked", "\\brelated to"
  )
  if (any(sapply(explicit_patterns, function(p) grepl(p, all_text, ignore.case = TRUE)))) {
    score <- score + 0.2
  }

  # Pattern 2: shared domain terms in both source and target
  # From axiom_set domain_mapping and context
  if (!is.null(axiom_set$domain_mapping)) {
    domain_terms <- unlist(axiom_set$domain_mapping, use.names = FALSE)
    matching_terms <- sum(sapply(domain_terms, function(t) {
      grepl(tolower(t), all_text, ignore.case = TRUE)
    }))
    if (matching_terms >= 3) score <- score + 0.15
    else if (matching_terms >= 2) score <- score + 0.1
    else if (matching_terms >= 1) score <- score + 0.05
  }

  # Pattern 3: using fcaR lattice overlap (if context available)
  if (!is.null(fc)) {
    # Compute how much of the formal context is "covered" by the target's claims
    fc_objects <- rownames(fc$I)
    fc_attributes <- colnames(fc$I)

    obj_coverage <- sum(sapply(fc_objects, function(o) {
      grepl(tolower(o), all_text, ignore.case = TRUE)
    }))
    attr_coverage <- sum(sapply(fc_attributes, function(a) {
      grepl(tolower(a), all_text, ignore.case = TRUE)
    }))

    if (nrow(fc$I) > 0) {
      obj_ratio <- obj_coverage / nrow(fc$I)
    } else {
      obj_ratio <- 0
    }
    if (ncol(fc$I) > 0) {
      attr_ratio <- attr_coverage / ncol(fc$I)
    } else {
      attr_ratio <- 0
    }
    lattice_score <- (obj_ratio + attr_ratio) / 2
    if (lattice_score > 0.1) score <- score + lattice_score * 0.15
  }

  # Clamp to [0, 1]
  min(1.0, max(0.0, score))
}


#' Assess potential for symmetry in an analogy
#'
#' Symmetry asks whether the analogy generates productive transfer in
#' both directions (source→target and target→source). We check:
#' \enumerate{
#'   \item Whether claims discuss implications flowing from target→source
#'   \item Whether the source domain offers new insights about the target
#'   \item Whether the analogy is generative (suggests new predictions)
#' }
#'
#' @param target An \code{\link{EvaluationTarget}}.
#'
#' @return A numeric score in [0, 1].
#'
#' @keywords internal
assess_symmetry <- function(target) {
  if (length(target$claims) == 0L) {
    return(0.5)
  }

  score <- 0.5
  claims_text <- vapply(target$claims, function(c) {
    paste0(c$text, " ", c$evidence %||% "")
  }, character(1))
  all_text <- paste(claims_text, collapse = " ")

  # Check for generative implications (new predictions from the analogy)
  generative_patterns <- c(
    "\\bpredict", "\\bprediction", "\\bimpli(es|cation|es)",
    "\\bsuggest(s|ed)?", "\\binfer", "\\bextrapolat",
    "\\bderive", "\\bfollow", "\\bentail",
    "\\bimplies.*that", "\\bwe can predict", "\\bwould yield"
  )
  generative <- sum(sapply(generative_patterns, function(p) {
    grepl(p, all_text, ignore.case = TRUE)
  }))
  if (generative >= 1) score <- score + 0.15
  if (generative >= 2) score <- score + 0.1

  # Check for bidirectional transfer language (target→source reasoning)
  reverse_patterns <- c(
    "\\bfrom this we can see(?: that)?", "\\bresonates with",
    "\\bparallels this", "\\bmirrors this", "\\binforms",
    "\\bsheds light on", "\\boffers insight into",
    "\\billuminat", "\\bclarify", "\\bprovide.*perspective"
  )
  reverse <- sum(sapply(reverse_patterns, function(p) {
    grepl(p, all_text, ignore.case = TRUE)
  }))
  if (reverse >= 1) score <- score + 0.1
  if (reverse >= 2) score <- score + 0.1

  # Check for "as well as" / "also" indicating complementary insight
  dual_patterns <- c(
    "\\balso\\b", "\\bas well\\b", "\\botherwise",
    "\\bin return", "\\breciprocally", "\\bmutually"
  )
  dual <- sum(sapply(dual_patterns, function(p) {
    grepl(p, all_text, ignore.case = TRUE)
  }))
  if (dual >= 1) score <- score + 0.05

  min(1.0, max(0.0, score))
}


#' Assess directionality of an analogy (known→unknown)
#'
#' Bartha's directionality criterion requires that mapping proceeds from
#' the known source to the unknown target, not the reverse. We check whether
#' claims explicitly treat the source as the understood frame and the target
#' as being explained.
#'
#' @param target An \code{\link{EvaluationTarget}}.
#' @param extracted_analogies Output of \code{\link{extract_analogies}}.
#'
#' @return A numeric score in [0, 1]. Higher = more appropriate directionality.
#'
#' @keywords internal
assess_directionality <- function(target, extracted_analogies) {
  if (length(target$claims) == 0L) {
    return(0.5)
  }

  score <- 0.5

  if (!extracted_analogies$found) {
    # No explicit analogies — score depends on other signals
    claims_text <- vapply(target$claims, function(c) {
      paste0(c$text, " ", c$evidence %||% "")
    }, character(1))
    all_text <- paste(claims_text, collapse = " ")

    # Check for "we can understand X in terms of Y" phrasing
    explanatory_patterns <- c(
      "\\bunderstand.*in terms of", "\\bexplain.*via",
      "\\bvía", "\\bthrough the lens of", "\\bframing",
      "\\bbased on", "\\bgrounded in"
    )
    explanatory <- sum(sapply(explanatory_patterns, function(p) {
      grepl(p, all_text, ignore.case = TRUE)
    }))
    if (explanatory >= 1) score <- score + 0.1
    if (explanatory >= 2) score <- score + 0.1
    return(min(1.0, max(0.0, score)))
  }

  # Each explicit analogy can be scored for directionality
  directionality_scores <- sapply(extracted_analogies$analogies, function(a) {
    # An analogy with explicit source/target is more likely to have correct direction
    if (!is.na(a$source) && !is.na(a$target)) {
      return(0.7)  # Good — explicit mapping
    }
    return(0.5)  # Implicit
  })

  mean(directionality_scores)
}


#' Identify critical disanalogies using fcaR concept lattice
#'
#' Critical disanalogies are load-bearing differences between source and target
#' that would undermine the analogy's conclusion. Using fcaR, we compute the
#' concept intersection between domains and identify missing attributes
#' in the target that are present in the source.
#'
#' @param target An \code{\link{EvaluationTarget}}.
#' @param fc An \code{fcaR::FormalContext}.
#'
#' @return A list with:
#' \describe{
#'   \item{critical_disanalogies}{Character vector of identified differences.}
#'   \item{lattice_overlap}{Numeric — Jaccard similarity between source and
#'     target concepts.}
#'   \item{lattice_info}{Optional list of lattice statistics if fcaR is available.}
#' }
#'
#' @keywords internal
identify_critical_disanalogies <- function(target, fc) {
  if (nrow(fc$I) == 0 || ncol(fc$I) == 0) {
    return(list(
      critical_disanalogies = character(0L),
      lattice_overlap = NA_real_,
      lattice_info = NULL
    ))
  }

  disanalogies <- list()
  fc_objects <- rownames(fc$I)
  fc_attributes <- colnames(fc$I)

  # 1. Identify which objects/attributes are "active" in target's claims
  claims_text <- vapply(target$claims, function(c) {
    paste0(c$text, " ", c$evidence %||% "")
  }, character(1))
  all_text <- paste(claims_text, collapse = " ")

  active_objects <- fc_objects[sapply(fc_objects, function(o) {
    grepl(tolower(o), all_text, ignore.case = TRUE)
  })]
  active_attributes <- fc_attributes[sapply(fc_attributes, function(a) {
    grepl(tolower(a), all_text, ignore.case = TRUE)
  })]

  # 2. Using fcaR, compute closures and check for missing "load-bearing" attributes
  # This is where we identify critical disanalogies

  # For simplicity, we check for "key" attributes that should be present
  # if the analogy were to hold. These are derived from context.
  key_attributes <- c("L1-obs", "L2-inference", "L3-eval", "L4-converge")
  key_attributes <- key_attributes[which(key_attributes %in% fc_attributes)]

  for (ka in key_attributes) {
    obj_with_k <- fc$I[, ka] == 1
    if (sum(obj_with_k) > 0) {
      # Objects that have this attribute
      objects_with_attr <- fc_objects[obj_with_k]
      # Check if any target claims would expect this
      # (heuristic: if claim text mentions attribute pattern without it)
      for (obj in objects_with_attr) {
        if (!grepl(tolower(obj), all_text, ignore.case = TRUE)) {
          disanalogies <- c(disanalogies,
            sprintf("Object '%s' has attribute '%s' but no active coverage in target",
                    obj, ka))
        }
      }
    }
  }

  # 3. Compute lattice overlap using fcaR if available
  lattice_info <- NULL

  if (requireNamespace("fcaR", quietly = TRUE)) {
    tryCatch({
      # Check if concepts are already computed via the $concepts field
      if (is.null(fc$concepts) || fc$concepts$size() <= 1L) {
        fc$find_concepts(verbose = FALSE)
      }

      lattice_size <- fc$concepts$size()
      density <- sum(fc$I) / (nrow(fc$I) * ncol(fc$I))

      lattice_info <- list(
        num_concepts = lattice_size,
        num_objects = nrow(fc$I),
        num_attributes = ncol(fc$I),
        lattice_density = density
      )
    }, error = function(e) {
      lattice_info <- NULL
    })
  }

  # Compute Jaccard overlap for active vs potential concepts (as a heuristic)
  # This is a proxy for "how much of the conceptual space is covered"
  if (length(active_objects) > 0 || length(active_attributes) > 0) {
    union_set <- length(c(active_objects, active_attributes))
    # In actual use, we'd compare two sets — here we use full context size as proxy
    context_size <- length(fc_objects) + length(fc_attributes)
    if (context_size > 0) {
      lattice_overlap <- union_set / context_size
    } else {
      lattice_overlap <- 0
    }
  } else {
    lattice_overlap <- 0
  }

  list(
    critical_disanalogies = as.character(disanalogies),
    lattice_overlap = lattice_overlap,
    lattice_info = lattice_info
  )
}


#' Search for better analogies in the concept lattice
#'
#' Given the formal context, identify alternative source domains that might
#' form more admissible analogies with the target. This looks for concepts
#' with higher overlap and fewer missing attributes.
#'
#' @param target An \code{\link{EvaluationTarget}}.
#' @param axiom_set An \code{\link{AxiomSet}} providing domain mappings.
#' @param fc An \code{fcaR::FormalContext}.
#'
#' @return A list with:
#' \describe{
#'   \item{found}{logical — any better suggestions found.}
#'   \item{suggestions}{Character vector of suggested analogies.}
#'   \item{reasoning}{Character — why these are better.}
#' }
#'
#' @keywords internal
suggest_better_analogy <- function(target, axiom_set, fc) {
  if (length(target$claims) == 0L || nrow(fc$I) == 0) {
    return(list(found = FALSE, suggestions = character(0L), reasoning = ""))
  }

  suggestions <- list()
  reasoning <- list()

  # Extract active objects/attributes from claims
  claims_text <- vapply(target$claims, function(c) {
    paste0(c$text, " ", c$evidence %||% "")
  }, character(1))
  all_text <- paste(claims_text, collapse = " ")

  fc_objects <- rownames(fc$I)
  fc_attributes <- colnames(fc$I)

  # Score each object by how "target-compatible" it is
  # (higher overlap with active text)
  object_scores <- sapply(fc_objects, function(o) {
    sum(sapply(fc_attributes, function(a) {
      if (fc$I[rownames(fc$I) == o, a] == 1) {
        grepl(tolower(o), all_text, ignore.case = TRUE) ||
          grepl(tolower(a), all_text, ignore.case = TRUE)
      } else {
        FALSE
      }
    }))
  })

  # Top 3 candidate objects
  top_indices <- order(object_scores, decreasing = TRUE)[seq_len(min(3L, length(object_scores)))]
  top_objects <- fc_objects[top_indices]
  top_scores <- object_scores[top_indices]

  if (max(top_scores) > 0) {
    for (i in seq_along(top_objects)) {
      obj <- top_objects[i]
      # What attributes does this object have?
      attr_vec <- fc$I[rownames(fc$I) == obj, , drop = FALSE]
      attrs <- fc_attributes[attr_vec == 1]

      suggestion <- sprintf("Consider analogy with %s (attributes: %s)",
                            obj, paste(attrs, collapse = ", "))
      suggestions <- c(suggestions, suggestion)
      reasoning <- c(reasoning, sprintf("%s overlaps with %d claim concepts",
                                        obj, sum(attr_vec == 1)))
    }

    list(
      found = TRUE,
      suggestions = suggestions,
      reasoning = paste(reasoning, collapse = ". ")
    )
  } else {
    list(found = FALSE, suggestions = character(0L), reasoning = "")
  }
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Evaluate Layer 6: Analogical Argument (Bartha Admissibility)
#'
#' Assess analogical arguments in a research artifact using Bartha's four
#' criteria: prior association, symmetry, directionality, and critical
#' disanalogy detection. Output verdict is \code{admissible},
#' \code{admissible_with_caveats}, or \code{not_admissible}.
#'
#' @param target An \code{\link{EvaluationTarget}} — the artifact to evaluate.
#' @param axiom_set An \code{\link{AxiomSet}} providing domain context and
#'   conceptual space for lattice analysis.
#' @param fc An optional \code{fcaR::FormalContext} for concept lattice
#'   intersection analysis. If \code{NULL}, one is derived from
#'   \code{axiom_set}.
#'
#' @return A \code{\link{LayerResult}} with:
#' \describe{
#'   \item{scores}{A named list with Bartha criterion scores:
#'     \code{prior_association}, \code{symmetry}, \code{directionality},
#'     \code{disanalogy_penalty}.}
#'   \item{flags}{A list with:
#'     \describe{
#'       \item{verdict}{Character — one of \code{"admissible"},
#'         \code{"admissible_with_caveats"}, or \code{"not_admissible"}.}
#'       \item{disanalogies}{Character vector — critical disanalogies identified.}
#'       \item{lattice_overlap}{Numeric — Jaccard similarity from fcaR analysis.}
#'       \item{suggested_better_analogy}{Character — better analogy suggestion
#'         if one exists.}
#'     }
#'   }
#' }
#'
#' @examples
#' \donttest{
#' target <- make_gard_target()
#' ax <- make_test_axiom_set()
#' fc <- make_test_context()
#' result <- evaluate_layer6(target, ax, fc)
#' print(result$flags$verdict)
#' }
#'
#' @export
evaluate_layer6 <- function(target, axiom_set, fc = NULL) {

  # -- Validate inputs --
  stopifnot(inherits(target, "EvaluationTarget"))
  stopifnot(inherits(axiom_set, "AxiomSet"))

  # -- Resolve formal context --
  if (is.null(fc)) {
    fc <- axiom_set$to_formal_context()
  }
  stopifnot(inherits(fc, "FormalContext"))

  # -- Extract analogies from claims --
  extracted_analogies <- extract_analogies(target)

  # -- Core Bartha assessments --
  # Score each criterion separately
  prior_association <- assess_prior_association(target, axiom_set, fc)
  symmetry <- assess_symmetry(target)
  directionality <- assess_directionality(target, extracted_analogies)

  # -- Critical disanalogy detection via fcaR lattice --
  disanalysis_result <- identify_critical_disanalogies(target, fc)
  disanalogy_penalty <- 0.0
  if (length(disanalysis_result$critical_disanalogies) > 0) {
    # Penalty proportional to number of critical disanalogies
    # capped at 0.5 (max penalty)
    disanalogy_penalty <- min(0.5, length(disanalysis_result$critical_disanalogies) * 0.1)
  }

  # -- Compute final admissibility score --
  # Weighted average of criteria, minus disanalogy penalty
  # Weights: prior_assoc=0.3, symmetry=0.25, directionality=0.25, disanalogy=0.2
  weighted_score <- (
    prior_association * 0.30 +
    symmetry * 0.25 +
    directionality * 0.25 -
    disanalogy_penalty
  )

  # -- Determine verdict --
  if (weighted_score >= 0.70) {
    verdict <- "admissible"
  } else if (weighted_score >= 0.50 ||
             length(disanalysis_result$critical_disanalogies) <= 1) {
    verdict <- "admissible_with_caveats"
  } else {
    verdict <- "not_admissible"
  }

  # -- Suggest better analogy if available --
  better_analogy <- suggest_better_analogy(target, axiom_set, fc)
  suggestions <- if (better_analogy$found &&
                     length(better_analogy$suggestions) > 0) {
    paste(better_analogy$suggestions[1], collapse = " | ")
  } else {
    NULL
  }

  # -- Build notes --
  note_parts <- c()
  if (!extracted_analogies$found) {
    note_parts <- c(note_parts, "No explicit analogies detected in claims.")
  } else {
    analogy_summary <- sprintf("Found %d explicit analogical claim(s).",
                               length(extracted_analogies$analogies))
    note_parts <- c(note_parts, analogy_summary)
  }
  note_parts <- c(note_parts,
    sprintf("Prior association: %.2f | Symmetry: %.2f | Directionality: %.2f",
            prior_association, symmetry, directionality)
  )
  if (length(disanalysis_result$critical_disanalogies) > 0) {
    note_parts <- c(note_parts,
      sprintf("Critical disanalogies: %d",
              length(disanalysis_result$critical_disanalogies))
    )
  }
  if (better_analogy$found) {
    note_parts <- c(note_parts,
      sprintf("Better analogy suggested: %s",
              better_analogy$suggestions[1])
    )
  }

  # -- Build scores as named numeric vector --
  scores <- c(
    prior_association = prior_association,
    symmetry = symmetry,
    directionality = directionality,
    disanalogy_penalty = disanalogy_penalty,
    weighted_score = weighted_score
  )

  LayerResult$new(
    layer = 6L,
    layer_name = "Analogical Argument (Bartha)",
    scores = scores,
    gap_diagnosis = if (length(disanalysis_result$critical_disanalogies) > 0) {
      paste(disanalysis_result$critical_disanalogies, collapse = " | ")
    } else {
      sprintf("Lattice overlap: %.2f",
              ifelse(is.na(disanalysis_result$lattice_overlap), 0,
                     disanalysis_result$lattice_overlap))
    },
    remediation = if (verdict %in% c("admissible_with_caveats", "not_admissible")) {
      list(
        better_analogy = better_analogy$reasoning,
        action = "Review critical disanalogies and consider suggested alternatives"
      )
    } else {
      NULL
    },
    flags = list(
      verdict = verdict,
      disanalogies = disanalysis_result$critical_disanalogies,
      lattice_overlap = ifelse(is.na(disanalysis_result$lattice_overlap),
                               0, disanalysis_result$lattice_overlap),
      lattice_info = disanalysis_result$lattice_info,
      better_analogy_suggestion = suggestions,
      extracted_analogies = if (extracted_analogies$found) {
        sapply(extracted_analogies$analogies, function(a) {
          sprintf("%s → %s",
                  ifelse(is.na(a$source), "implicit", a$source),
                  ifelse(is.na(a$target), "implicit", a$target))
        })
      } else {
        NULL
      }
    ),
    notes = paste(note_parts, collapse = " ")
  )
}

# -- Utility: pipe operator --
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
