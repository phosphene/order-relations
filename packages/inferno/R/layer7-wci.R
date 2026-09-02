# ---------------------------------------------------------------------------
# layer7-wci.R — Layer 7: Weighted Credibility Index (WCI) Assessment
#
# Synthesises the outputs of layers 1–6 and artifact metadata into a single
# multi-dimensional credibility score: the **Weighted Credibility Index**.
#
# The WCI comprises 6 dimensions, each scored in [0, 1]:
#   1. **theoretical_coherence**  — internal logical consistency; derived from
#      L1 (levels L2 + L3 both PASS → high).
#   2. **empirical_support**      — strength of empirical backing; derived from
#      L1 (L1 PASS → high) and L2 (M-failures reduce score).
#   3. **replicability**          — likelihood of independent reproduction;
#      derived from L1 (L1 PASS increases score) and independent validation
#      signals in the metadata.
#   4. **independent_uptake**     — adoption by the research community; drawn
#      from the target's metadata (citations, replications, external adoptions).
#   5. **explanatory_power**      — breadth and depth of explanation; derived
#      from L4 (compression reversibility) and L6 (analogy admissibility).
#   6. **falsifiability**         — amenability to empirical refutation; derived
#      from L1 (L3 PASS = can evaluate competitors = falsifiable) and L5
#      (stable semiotic typing → clear boundaries).
#
# **Composite:** weighted arithmetic mean of the 6 dimensions. Weights are
# configurable via `axiom_set$metadata$wci_weights`; defaults to equal weights.
#
# Optionally computes Jensen-Shannon divergence between the empirical
# evaluation concept distribution and an ideal concept distribution using
# philentropy::JSD().
#
# LayerResult output:
#   $scores  — named numeric vector of length 7:
#       theoretical_coherence, empirical_support, replicability,
#       independent_uptake, explanatory_power, falsifiability, composite
#   $flags$js_divergence  — numeric JS divergence (if computed) or NULL
#   $flags$weights        — numeric vector of the weights used
#   $gap_diagnosis        — character description of the weakest dimension
#   $remediation          — list with complement and target_level
# ---------------------------------------------------------------------------

#' Layer 7 — Weighted Credibility Index (WCI) Assessment
#'
#' Synthesises the six prior layer results into a multi-dimensional credibility
#' index. Each dimension is scored in \eqn{[0, 1]} using deterministic rules
#' that map layer outputs to numeric scores. The composite is a weighted
#' average with configurable weights (default: equal).
#'
#' @section Dimension Scoring Rules:
#' \describe{
#'   \item{Theoretical coherence}{Derived from L1's epistemic stack. If both
#'     L2 (Formal Generative Framework) and L3 (Evaluative Criteria) are PASS
#'     across all domains, score is high (0.9). If L2 is PASS and L3 is
#'     PARTIAL, moderate (0.6). If either is FAIL, low (0.3). Baseline is
#'     the proportion of PASS/ PARTIAL scores across all levels in L1.}
#'   \item{Empirical support}{Derived from L1 (L1 — Empirical Observation)
#'     and L2 (M-failure audit). A baseline of 0.7 if L1 is PASS, else 0.3.
#'     Reduced by \code{0.15 * prop_m_failures} where \code{prop_m_failures}
#'     is the proportion of claims flagged with M-failures in L2.}
#'   \item{Replicability}{Derived from L1 (L1 PASS — empirical observation
#'     present) and the target's metadata (evidence of independent
#'     replication). Baseline 0.5. Increased by 0.3 if L1 domain scores are
#'     PASS, and by up to 0.2 if metadata suggests independent validation.}
#'   \item{Independent uptake}{Derived from the target's metadata: citations,
#'     replications, external adoptions, and community references. Scaled
#'     heuristically from available metadata fields.}
#'   \item{Explanatory power}{Derived from L4 (compression reversibility) and
#'     L6 (analogy admissibility). The mean of L4's reversibility score (if
#'     available) and L6's admissibility score (if available). Falls back to
#'     a default of 0.5 if neither layer is available.}
#'   \item{Falsifiability}{Derived from L1 (L3 PASS — can evaluate
#'     competitors = falsifiable) and L5 (semiotic typing stability). Baseline
#'     0.4. Increased by 0.3 if L3 is PASS across all domains, and by up to
#'     0.3 if L5 reports stable semiotic typing (low instability proportion).}
#' }
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object — the artifact
#'   being evaluated.
#' @param axiom_set An \code{\link{AxiomSet}} R6 object providing the
#'   evaluation context. The \code{metadata} element may contain
#'   \code{wci_weights} (a named numeric vector of length 6 with names matching
#'   the dimension names) to override the default equal weights.
#' @param prior_layers A list of 6 \code{\link{LayerResult}} objects from
#'   layers 1–6, in order. Each layer is expected to have a specific
#'   \code{scores} structure:
#'   \describe{
#'     \item{L1}{\code{scored} = 4-row (L1–L4) by \emph{k}-column character
#'       matrix with values \code{PASS}, \code{FAIL}, \code{PARTIAL}, or
#'       \code{N/A}.}
#'     \item{L2}{\code{scored} = \emph{n}-row by 1-column character matrix
#'       with values \code{PASS} or \code{M1}–\code{M6}.}
#'     \item{L3}{\code{scored} = passage-level R1/R2 classification matrix.}
#'     \item{L4}{\code{scored} = named numeric vector of compression detection
#'       scores (0–1). \code{flags$reversibility$lossless} indicates
#'       reversibility.}
#'     \item{L5}{\code{scored} = Prior object-by-type classification matrix.
#'       \code{flags$type_counts} gives counts per type.}
#'     \item{L6}{\code{scored} = named numeric vector of analogy admissibility
#'       scores.}
#'   }
#' @param compute_js_divergence Logical — if \code{TRUE}, compute the
#'   Jensen-Shannon divergence between the empirical concept distribution
#'   (derived from the L1 scores) and an ideal uniform distribution using
#'   \code{philentropy::JSD()}. Default \code{FALSE}.
#'
#' @return A \code{\link{LayerResult}} R6 object with:
#'   \describe{
#'     \item{scores}{A named numeric vector of length 7:
#'       \code{theoretical_coherence}, \code{empirical_support},
#'       \code{replicability}, \code{independent_uptake},
#'       \code{explanatory_power}, \code{falsifiability}, \code{composite}.}
#'     \item{flags}{List with \code{js_divergence} (numeric or \code{NULL}),
#'       \code{weights} (numeric vector), and \code{dimension_contributions}
#'       (named numeric vector showing each dimension's contribution to the
#'       composite).}
#'     \item{gap_diagnosis}{Character describing the weakest dimension, or
#'       \code{NULL} if all dimensions are strong.}
#'     \item{remediation}{List with \code{complement} (suggested complementary
#'       target type) and \code{target_level} (the layer to remediate).
#'       \code{NULL} if no gap.}
#'   }
#'
#' @examples
#' \donttest{
#' target <- make_gard_target()
#' ax     <- make_test_axiom_set()
#' l1     <- evaluate_layer1(target, ax, ax$to_formal_context())
#' l2     <- evaluate_layer2(target, ax)
#' l3     <- evaluate_layer3(target, ax)
#' l4     <- evaluate_layer4(target, ax)
#' l5     <- evaluate_layer5(target, ax, ax$to_formal_context())
#' l6     <- evaluate_layer6(target, ax)
#' result <- evaluate_layer7(target, ax, list(l1, l2, l3, l4, l5, l6))
#' print(result$scores)
#' }
#'
#' @export
evaluate_layer7 <- function(target, axiom_set, prior_layers,
                            compute_js_divergence = FALSE) {
  # ---------------------------------------------------------------------------
  # 1. Extract prior layers
  # ---------------------------------------------------------------------------
  l1 <- prior_layers[[1L]]
  l2 <- prior_layers[[2L]]
  l3 <- prior_layers[[3L]]
  l4 <- prior_layers[[4L]]
  l5 <- prior_layers[[5L]]
  l6 <- prior_layers[[6L]]

  # ---------------------------------------------------------------------------
  # 2. Compute each dimension score
  # ---------------------------------------------------------------------------
  theoretical_coherence <- compute_theoretical_coherence(l1)
  empirical_support     <- compute_empirical_support(l1, l2)
  replicability_score   <- compute_replicability(l1, target)
  independent_uptake    <- compute_independent_uptake(target)
  explanatory_power     <- compute_explanatory_power(l4, l6)
  falsifiability_score  <- compute_falsifiability(l1, l5)

  # ---------------------------------------------------------------------------
  # 3. Compute composite (weighted average)
  # ---------------------------------------------------------------------------
  weights <- extract_weights(axiom_set)
  dim_scores <- c(
    theoretical_coherence = theoretical_coherence,
    empirical_support     = empirical_support,
    replicability         = replicability_score,
    independent_uptake    = independent_uptake,
    explanatory_power     = explanatory_power,
    falsifiability        = falsifiability_score
  )
  composite <- sum(dim_scores * weights)

  # Named vector of all 7 entries
  scores <- c(dim_scores, composite = unname(composite))

  # ---------------------------------------------------------------------------
  # 4. Optional: JS divergence
  # ---------------------------------------------------------------------------
  js_div <- NULL
  if (isTRUE(compute_js_divergence)) {
    js_div <- compute_js_divergence_score(l1)
  }

  # ---------------------------------------------------------------------------
  # 5. Gap diagnosis
  # ---------------------------------------------------------------------------
  gap <- diagnose_wci_gap(dim_scores)
  remediation <- build_wci_remediation(dim_scores, gap)

  # ---------------------------------------------------------------------------
  # 6. Build flags
  # ---------------------------------------------------------------------------
  flags <- list(
    js_divergence           = js_div,
    weights                 = weights,
    dimension_contributions = dim_scores * weights
  )

  # ---------------------------------------------------------------------------
  # 7. Construct and return LayerResult
  # ---------------------------------------------------------------------------
  LayerResult$new(
    layer          = 7L,
    layer_name     = "Weighted Credibility Index (WCI)",
    scores         = scores,
    gap_diagnosis  = gap,
    remediation    = remediation,
    flags          = flags,
    notes          = NULL
  )
}


# ============================================================================
# Dimension scoring functions
# ============================================================================

#' Compute theoretical coherence score
#'
#' Derived from L1 (Epistemic Stack). Evaluates whether L2 (Formal Generative
#' Framework) and L3 (Evaluative Criteria) are PASS across domains.
#'
#' @param l1 A \code{\link{LayerResult}} from layer 1.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_theoretical_coherence <- function(l1) {
  scores <- l1$scores

  # Extract L2 and L3 rows
  has_l2 <- "L2" %in% rownames(scores)
  has_l3 <- "L3" %in% rownames(scores)

  if (!has_l2 && !has_l3) {
    return(0.3)
  }

  # Proportion of PASS/PARTIAL across all L1 levels as baseline
  all_scores <- as.vector(scores)
  prop_pass <- sum(all_scores %in% c("PASS", "PARTIAL"), na.rm = TRUE) /
    max(1, sum(!is.na(all_scores)))

  # L2 and L3 specific boost
  l2_pass_prop <- if (has_l2) {
    mean(scores["L2", ] == "PASS", na.rm = TRUE)
  } else {
    0
  }

  l3_pass_prop <- if (has_l3) {
    mean(scores["L3", ] == "PASS", na.rm = TRUE)
  } else {
    0
  }

  # If both L2 and L3 are all PASS → high coherence
  if (l2_pass_prop >= 0.9 && l3_pass_prop >= 0.9) {
    return(min(1.0, 0.9))
  }

  # If L2 is PASS and L3 is PARTIAL → moderate
  if (l2_pass_prop >= 0.5 && l3_pass_prop >= 0.3) {
    return(min(1.0, 0.6 + 0.2 * prop_pass))
  }

  # General case: blend of PASS proportion and L2/L3 contributions
  score <- 0.3 + 0.4 * prop_pass + 0.2 * l2_pass_prop + 0.1 * l3_pass_prop
  min(1.0, max(0.0, score))
}


#' Compute empirical support score
#'
#' Derived from L1 (Empirical Observation level) and L2 (M-failure audit).
#' Baseline is high if L1 is PASS, reduced by M-failure proportion.
#'
#' @param l1 A \code{\link{LayerResult}} from layer 1.
#' @param l2 A \code{\link{LayerResult}} from layer 2.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_empirical_support <- function(l1, l2) {
  # L1 baseline: is L1 (Empirical Observation) PASS in any domain?
  l1_scores <- l1$scores
  has_l1_level <- "L1" %in% rownames(l1_scores)

  l1_pass <- if (has_l1_level) {
    any(l1_scores["L1", ] == "PASS", na.rm = TRUE)
  } else {
    FALSE
  }

  # More nuanced: proportion of PASS in L1
  l1_pass_prop <- if (has_l1_level) {
    mean(l1_scores["L1", ] == "PASS", na.rm = TRUE)
  } else {
    0
  }

  baseline <- if (l1_pass) {
    0.7 + 0.2 * l1_pass_prop
  } else {
    0.3
  }

  # L2: M-failure penalty
  l2_scores <- l2$scores
  if (nrow(l2_scores) > 0 && "M_classification" %in% colnames(l2_scores)) {
    m_failures <- l2_scores[, "M_classification"]
    prop_m <- mean(m_failures != "PASS", na.rm = TRUE)
    penalty <- 0.15 * prop_m
  } else {
    penalty <- 0
  }

  score <- baseline - penalty
  min(1.0, max(0.0, score))
}


#' Compute replicability score
#'
#' Derived from L1 (L1 PASS indicates empirical observation, base for
#' replication) and the target's metadata (independent validation signals).
#'
#' @param l1 A \code{\link{LayerResult}} from layer 1.
#' @param target An \code{\link{EvaluationTarget}}.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_replicability <- function(l1, target) {
  # Baseline: 0.5
  score <- 0.5

  # L1 boost: if L1 (Empirical Observation) is PASS → empirical basis exists
  l1_scores <- l1$scores
  has_l1_level <- "L1" %in% rownames(l1_scores)

  if (has_l1_level) {
    l1_pass_domains <- sum(l1_scores["L1", ] == "PASS", na.rm = TRUE)
    l1_total_domains <- max(1, sum(l1_scores["L1", ] != "N/A", na.rm = TRUE))
    l1_pass_prop <- l1_pass_domains / l1_total_domains

    if (l1_pass_prop >= 0.5) {
      score <- score + 0.3
    } else if (l1_pass_prop > 0) {
      score <- score + 0.15
    }
  }

  # Metadata boost: independent validation signals
  meta <- target$metadata %||% list()
  replication_indicators <- c(
    "replications"   = !is.null(meta[["replications"]]) &&
      length(meta[["replications"]]) > 0,
    "replicated_by"  = !is.null(meta[["replicated_by"]]) &&
      nchar(meta[["replicated_by"]]) > 0,
    "independent"    = !is.null(meta[["independent"]]) &&
      isTRUE(meta[["independent"]]),
    "multi_lab"      = !is.null(meta[["multi_lab"]]) &&
      isTRUE(meta[["multi_lab"]])
  )

  n_indicators <- sum(replication_indicators)
  if (n_indicators > 0) {
    score <- score + 0.05 * min(n_indicators, 4)
  }

  min(1.0, max(0.0, score))
}


#' Compute independent uptake score
#'
#' Derived from the target's metadata — citations, replications, external
#' adoptions, and community references.
#'
#' @param target An \code{\link{EvaluationTarget}}.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_independent_uptake <- function(target) {
  meta <- target$metadata %||% list()
  score <- 0.0

  # Citation count
  citations <- meta[["citations"]]
  if (!is.null(citations)) {
    if (is.numeric(citations)) {
      score <- score + min(citations / 100, 0.3)
    } else if (is.character(citations) && nchar(citations) > 0) {
      # Try to parse as number
      citations_num <- suppressWarnings(as.numeric(citations))
      if (!is.na(citations_num)) {
        score <- score + min(citations_num / 100, 0.3)
      } else {
        score <- score + 0.15  # cited but count unknown
      }
    }
  }

  # Independent adoptions
  adoptions <- meta[["adoptions"]]
  if (!is.null(adoptions)) {
    if (is.numeric(adoptions)) {
      score <- score + min(adoptions * 0.1, 0.25)
    } else {
      score <- score + 0.1
    }
  }

  # Replication count
  replications <- meta[["replications"]]
  if (!is.null(replications)) {
    if (is.numeric(replications)) {
      score <- score + min(replications * 0.15, 0.3)
    } else {
      score <- score + 0.1
    }
  }

  # Community references (e.g., textbooks, reviews)
  community_ref <- meta[["community_references"]]
  if (!is.null(community_ref) && isTRUE(community_ref > 0)) {
    score <- score + 0.1
  }

  # Review articles
  review_count <- meta[["review_count"]]
  if (!is.null(review_count) && is.numeric(review_count) && review_count > 0) {
    score <- score + min(review_count * 0.05, 0.15)
  }

  min(1.0, max(0.0, score))
}


#' Compute explanatory power score
#'
#' Derived from L4 (compression reversibility) and L6 (analogy admissibility).
#' Mean of the two if both available; falls back to whichever is available.
#'
#' @param l4 A \code{\link{LayerResult}} from layer 4.
#' @param l6 A \code{\link{LayerResult}} from layer 6.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_explanatory_power <- function(l4, l6) {
  scores_available <- c(FALSE, FALSE)
  values <- c(0.5, 0.5)

  # L4 contribution: compression reversibility
  if (!is.null(l4)) {
    l4_scores <- l4$scores
    if (is.numeric(l4_scores) && length(l4_scores) > 0) {
      # Mean of all compression detection scores
      values[1] <- mean(l4_scores, na.rm = TRUE)
      scores_available[1] <- TRUE
    }

    # Reversibility bonus
    if (!is.null(l4$flags$reversibility$lossless)) {
      if (isTRUE(l4$flags$reversibility$lossless)) {
        values[1] <- min(1.0, values[1] + 0.2)
      } else {
        # Partial reversibility
        info_loss <- l4$flags$reversibility$info_loss_n %||% 0
        values[1] <- max(0.0, values[1] - 0.05 * info_loss)
      }
    }
  }

  # L6 contribution: analogy admissibility
  if (!is.null(l6)) {
    l6_scores <- l6$scores
    if (is.numeric(l6_scores) && length(l6_scores) > 0) {
      # Look for an admissibility score
      if ("admissibility" %in% names(l6_scores)) {
        values[2] <- l6_scores[["admissibility"]]
      } else {
        values[2] <- mean(l6_scores, na.rm = TRUE)
      }
      scores_available[2] <- TRUE
    }
  }

  if (all(scores_available)) {
    mean(values)
  } else if (any(scores_available)) {
    values[scores_available]
  } else {
    0.5
  }
}


#' Compute falsifiability score
#'
#' Derived from L1 (L3 — Evaluative Criteria: ability to evaluate competitors
#' implies falsifiability) and L5 (semiotic typing stability: clear boundaries
#' enable falsification).
#'
#' @param l1 A \code{\link{LayerResult}} from layer 1.
#' @param l5 A \code{\link{LayerResult}} from layer 5.
#'
#' @return Numeric score in [0, 1].
#' @keywords internal
compute_falsifiability <- function(l1, l5) {
  score <- 0.4  # baseline

  # L1 contribution: L3 (Evaluative Criteria) PASS → can evaluate competitors
  l1_scores <- l1$scores
  has_l3 <- "L3" %in% rownames(l1_scores)

  if (has_l3) {
    l3_pass_prop <- mean(l1_scores["L3", ] == "PASS", na.rm = TRUE)
    if (l3_pass_prop >= 0.9) {
      score <- score + 0.3
    } else if (l3_pass_prop >= 0.5) {
      score <- score + 0.15
    } else if (l3_pass_prop > 0) {
      score <- score + 0.05
    }
  }

  # L5 contribution: stable semiotic typing
  if (!is.null(l5)) {
    if (!is.null(l5$flags$type_counts)) {
      type_counts <- l5$flags$type_counts
      # Stable typing: primarily one type dominates
      total <- sum(type_counts, na.rm = TRUE)
      if (total > 0) {
        max_type_prop <- max(type_counts, na.rm = TRUE) / total
        # High dominance of one type → stable typing
        if (max_type_prop >= 0.8) {
          score <- score + 0.3
        } else if (max_type_prop >= 0.6) {
          score <- score + 0.15
        } else {
          score <- score + 0.05
        }
      }
    }

    # Instability penalty
    if (!is.null(l5$flags$semiosis_risks)) {
      n_risks <- length(l5$flags$semiosis_risks)
      if (n_risks > 0) {
        score <- score - 0.05 * min(n_risks, 5)
      }
    }
  }

  min(1.0, max(0.0, score))
}


# ============================================================================
# Weight extraction
# ============================================================================

#' Extract WCI weights from axiom_set metadata
#'
#' Defaults to equal weights (1/6 each). If \code{axiom_set$metadata$wci_weights}
#' is a named numeric vector with names matching the 6 dimension names, those
#' weights are used after normalising to sum to 1.
#'
#' @param axiom_set An \code{\link{AxiomSet}}.
#'
#' @return A named numeric vector of length 6, summing to 1.
#' @keywords internal
extract_weights <- function(axiom_set) {
  dim_names <- c(
    "theoretical_coherence",
    "empirical_support",
    "replicability",
    "independent_uptake",
    "explanatory_power",
    "falsifiability"
  )

  default_weights <- rep(1 / 6, 6)
  names(default_weights) <- dim_names

  meta <- axiom_set$metadata %||% list()
  custom_weights <- meta[["wci_weights"]]

  if (is.null(custom_weights)) {
    return(default_weights)
  }

  if (!is.numeric(custom_weights) || length(custom_weights) != 6) {
    warning("wci_weights must be a numeric vector of length 6. Using defaults.",
            call. = FALSE)
    return(default_weights)
  }

  if (is.null(names(custom_weights))) {
    warning("wci_weights must be named. Using defaults.", call. = FALSE)
    return(default_weights)
  }

  # Check that names match
  if (!all(sort(names(custom_weights)) == sort(dim_names))) {
    warning("wci_weights names must match the 6 dimension names. Using defaults.",
            call. = FALSE)
    return(default_weights)
  }

  # Normalise to sum to 1
  custom_weights <- custom_weights / sum(custom_weights, na.rm = TRUE)
  custom_weights[is.na(custom_weights)] <- 0
  custom_weights
}


# ============================================================================
# JS divergence
# ============================================================================

#' Compute Jensen-Shannon divergence between empirical and ideal concept
#' distributions
#'
#' Constructs a concept distribution from the L1 scores (proportion of PASS,
#' PARTIAL, FAIL, N/A per level) and computes the JS divergence against an
#' ideal uniform distribution where all levels are PASS across all domains.
#'
#' @param l1 A \code{\link{LayerResult}} from layer 1.
#'
#' @return Numeric JS divergence value, or \code{NULL} if philentropy is not
#'   available.
#' @keywords internal
compute_js_divergence_score <- function(l1) {
  if (!requireNamespace("philentropy", quietly = TRUE)) {
    return(NULL)
  }

  scores <- l1$scores
  if (is.null(scores) || nrow(scores) == 0 || ncol(scores) == 0) {
    return(NULL)
  }

  # Build empirical distribution: count PASS, PARTIAL, FAIL, N/A per level
  level_names <- rownames(scores)
  n_levels <- length(level_names)
  n_domains <- ncol(scores)

  # Empirical distribution: flatten scores into probabilities
  # Map PASS → 1.0, PARTIAL → 0.5, FAIL → 0.0, N/A → 0.5 (neutral)
  score_map <- c("PASS" = 1.0, "PARTIAL" = 0.5, "FAIL" = 0.0, "N/A" = 0.5)
  empirical <- as.vector(scores)
  empirical_num <- score_map[empirical]
  empirical_num[is.na(empirical_num)] <- 0.5

  # Normalise to probability distribution
  empirical_dist <- empirical_num / sum(empirical_num, na.rm = TRUE)
  empirical_dist[is.na(empirical_dist)] <- 0

  # Ideal distribution: uniform across all (level, domain) cells
  n_cells <- n_levels * n_domains
  ideal_dist <- rep(1 / n_cells, n_cells)

  # Compute JS divergence
  js_matrix <- rbind(empirical_dist, ideal_dist)
  js_value <- philentropy::JSD(js_matrix)

  as.numeric(js_value)
}


# ============================================================================
# Gap diagnosis and remediation
# ============================================================================

#' Diagnose the weakest WCI dimension
#'
#' Identifies the dimension(s) with the lowest score and produces a
#' human-readable description.
#'
#' @param dim_scores Named numeric vector of 6 dimension scores.
#'
#' @return Character string, or \code{NULL} if all scores are above 0.6.
#' @keywords internal
diagnose_wci_gap <- function(dim_scores) {
  # Check if all dimensions are strong (≥ 0.6)
  if (all(dim_scores >= 0.6, na.rm = TRUE)) {
    return(NULL)
  }

  # Find the weakest dimension(s)
  min_score <- min(dim_scores, na.rm = TRUE)
  weakest <- names(dim_scores[dim_scores == min_score])

  threshold <- 0.3
  critical <- names(dim_scores[dim_scores < threshold])

  parts <- c()
  if (length(critical) > 0) {
    parts <- c(parts,
               sprintf("Critical weakness in %s (score: %.3f)",
                       paste(critical, collapse = ", "),
                       min(dim_scores[critical])))
  }

  if (length(weakest) > 0 && min_score >= threshold) {
    parts <- c(parts,
               sprintf("Weakest dimension: %s (score: %.3f)",
                       paste(weakest, collapse = ", "), min_score))
  }

  if (length(parts) == 0) {
    return(NULL)
  }

  paste(parts, collapse = "; ")
}


#' Build WCI remediation suggestions
#'
#' Maps the weakest dimension to a suggested complementary target type and
#' the layer to remediate.
#'
#' @param dim_scores Named numeric vector of 6 dimension scores.
#' @param gap Character gap diagnosis string.
#'
#' @return A list with \code{complement} and \code{target_level}, or
#'   \code{NULL}.
#' @keywords internal
build_wci_remediation <- function(dim_scores, gap) {
  if (is.null(gap)) {
    return(NULL)
  }

  # Find the dimension with the lowest score
  min_score <- min(dim_scores, na.rm = TRUE)
  weakest <- names(dim_scores[dim_scores == min_score])[1]

  # Map dimension to layer and complement
  remediation_map <- list(
    theoretical_coherence = list(
      target_level = 1L,
      complement = "Paper with formal generative framework and explicit evaluative criteria"
    ),
    empirical_support = list(
      target_level = 1L,
      complement = "Experimental paper with novel empirical observations"
    ),
    replicability = list(
      target_level = 1L,
      complement = "Independent replication study with documented protocols"
    ),
    independent_uptake = list(
      target_level = 7L,
      complement = "Community engagement, citation analysis, and adoption tracking"
    ),
    explanatory_power = list(
      target_level = 4L,
      complement = "Formal model with reversible compression and strong analogy admissibility"
    ),
    falsifiability = list(
      target_level = 5L,
      complement = "Artifact with clearly bounded formal objects and stable semiotic typing"
    )
  )

  remediation_map[[weakest]] %||% list(
    target_level = 7L,
    complement = "Supplementary evidence or community engagement"
  )
}


# ============================================================================
# Utility
# ============================================================================

#' Null-coalescing operator (internal)
#'
#' @param x Left-hand side.
#' @param y Right-hand side — returned if \code{x} is \code{NULL}.
#'
#' @return \code{x} if not \code{NULL}, else \code{y}.
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}