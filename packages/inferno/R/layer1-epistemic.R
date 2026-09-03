#' Layer 1 — Epistemic Stack Evaluation
#'
#' Evaluates the epistemic standing of a research artifact across four levels
#' (L1–L4) and one or more domain dimensions (D1, D2, ...). Uses the formal
#' concept lattice (passed as an \code{fcaR::FormalContext}) to determine
#' which levels are present for each domain, then refines the assessment
#' using the artifact's claim structure.
#'
#' @section Evaluation Criteria:
#' \describe{
#'   \item{L1 — Empirical Observation}{PASS if the artifact contains at least
#'     one documented, verifiable novel empirical observation with
#'     \code{R1_research} register evidence. PARTIAL if it only references
#'     others' empirical work. FAIL if purely theoretical.}
#'   \item{L2 — Formal Generative Framework}{PASS if the artifact provides a
#'     formal framework that generates predictions, classifications, or
#'     inferences beyond the original cases. PARTIAL if the framework is
#'     descriptive but not generative. FAIL if observations without formal
#'     machinery.}
#'   \item{L3 — Evaluative Criteria}{PASS if explicit evaluative criteria are
#'     applied to competing research programs. PARTIAL if alternatives are
#'     acknowledged without formal comparison. FAIL if only own position
#'     asserted.}
#'   \item{L4 — Tradition Integration}{PASS if the artifact integrates two or
#'     more intellectual traditions with explicit preservation/loss analysis.
#'     PARTIAL if other traditions are referenced but not formally integrated.
#'     FAIL if single tradition only.}
#' }
#'
#' @section Modes:
#' \describe{
#'   \item{Crisp (default)}{Directly reads the incidence matrix of the formal
#'     context to determine which levels are present for each domain.}
#'   \item{Hypothesis-testing}{Checks lattice significance:
#'     \code{concept_count > 2} and \code{implication_count > 0}. If the
#'     lattice is degenerate (too few concepts or no implications), the
#'     evaluation is flagged as unreliable.}
#' }
#'
#' @section FormalContext API Note:
#' The fcaR package stores the incidence matrix with attributes as rows and
#' objects as columns (\code{fc$I[attribute, object]}). This function handles
#' the transposition internally.
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object. The artifact
#'   being evaluated.
#' @param axiom_set An \code{\link{AxiomSet}} R6 object providing the
#'   evaluation context, domain mapping, and metric.
#' @param fc An \code{fcaR::FormalContext} R6 object with concepts and
#'   implications already computed (e.g. via
#'   \code{\link{safe_compute_lattice}}).
#' @param mode Character, one of \code{"crisp"} (default) or
#'   \code{"hypothesis-testing"}. Controls whether lattice significance
#'   statistics are included in the evaluation flags.
#'
#' @return A \code{\link{LayerResult}} R6 object containing:
#'   \itemize{
#'     \item \code{scores}: A 4-row (L1–L4) by \eqn{k}-column (domain
#'       dimensions) character matrix with values \code{PASS}, \code{FAIL},
#'       \code{PARTIAL}, or \code{N/A}.
#'     \item \code{gap_diagnosis}: Character string describing the most
#'       significant gap found, or \code{NULL} if all levels pass.
#'     \item \code{remediation}: A list with \code{complement} (suggested
#'       complementary target type) and \code{target_level} (the level to
#'       remediate).
#'     \item \code{flags}: List containing \code{lattice_significant}
#'       (logical), \code{concept_count}, \code{implication_count},
#'       \code{mode}, and \code{degenerate_lattice} (logical).
#'   }
#'
#' @examples
#' \donttest{
#' library(fcaR)
#' target <- make_gard_target()
#' ax     <- make_test_axiom_set()
#' fc     <- ax$to_formal_context()
#' fc     <- safe_compute_lattice(fc)
#' result <- evaluate_layer1(target, ax, fc)
#' print(result$scores)
#' }
#'
#' @export
evaluate_layer1 <- function(target, axiom_set, fc,
                            mode = c("crisp", "hypothesis-testing")) {
  mode <- match.arg(mode)

  # ---------------------------------------------------------------------------
  # 1. Determine domain dimensions to evaluate
  # ---------------------------------------------------------------------------
  dims <- names(target$domain_dims)
  if (length(dims) == 0) {
    dims <- names(axiom_set$domain_mapping)
  }
  if (length(dims) == 0) {
    dims <- "D1"
  }

  levels <- c("L1", "L2", "L3", "L4")

  # ---------------------------------------------------------------------------
  # 2. Extract lattice information from the FormalContext
  #
  #    fcaR stores the incidence matrix with attributes as rows and objects
  #    as columns: fc$I[attribute, object]
  # ---------------------------------------------------------------------------
  incidence <- fc$I
  # Attributes (levels) are rownames, Objects (domains) are colnames
  attr_names <- rownames(incidence)
  obj_names <- colnames(incidence)

  # Count concepts and implications using the correct fcaR API
  concept_count <- tryCatch(fc$concepts$size(), error = function(e) 0L)
  implication_count <- tryCatch(nrow(fc$implications$size()),
                                error = function(e) 0L)

  lattice_significant <- concept_count > 2L && implication_count > 0L
  degenerate_lattice <- !lattice_significant

  # ---------------------------------------------------------------------------
  # 3. Build the scores matrix (levels × dimensions)
  # ---------------------------------------------------------------------------
  scores <- matrix("N/A", nrow = length(levels), ncol = length(dims),
                   dimnames = list(levels, dims))

  # Map domain dimension codes to fc object names
  domain_obj_map <- build_domain_object_map(dims, target, axiom_set, obj_names)

  for (d_idx in seq_along(dims)) {
    dim_name <- dims[d_idx]
    matched_objs <- domain_obj_map[[dim_name]]

    for (l_idx in seq_along(levels)) {
      level <- levels[l_idx]
      lvl_attr <- level_to_attribute(level)

      # Check incidence: does any matched object (column) have this attribute
      # (row)?
      # fc$I[lvl_attr, obj_name] == 1 means the object has the attribute
      has_attr <- if (lvl_attr %in% attr_names && length(matched_objs) > 0) {
        valid_objs <- intersect(matched_objs, obj_names)
        length(valid_objs) > 0 &&
          any(incidence[lvl_attr, valid_objs, drop = FALSE] == 1)
      } else {
        FALSE
      }

      # Evaluate using claims to refine PASS vs PARTIAL vs FAIL
      tmp <- target$domain_dims[[dim_name]]
      if (is.null(tmp)) tmp <- axiom_set$domain_mapping[[dim_name]]
      if (is.null(tmp)) tmp <- dim_name
      dim_label <- tmp

      scores[level, dim_name] <- evaluate_level(
        target = target,
        level = level,
        has_attr = has_attr,
        dim_label = dim_label
      )
    }
  }

  # ---------------------------------------------------------------------------
  # 4. Gap diagnosis
  # ---------------------------------------------------------------------------
  gap <- diagnose_gaps(scores, dims, levels)

  # ---------------------------------------------------------------------------
  # 5. Remediation chain
  # ---------------------------------------------------------------------------
  remediation <- build_remediation(scores, dims, levels, gap)

  # ---------------------------------------------------------------------------
  # 6. Build flags
  # ---------------------------------------------------------------------------
  flags <- list(
    mode = mode,
    lattice_significant = lattice_significant,
    degenerate_lattice = degenerate_lattice,
    concept_count = concept_count,
    implication_count = implication_count
  )

  # ---------------------------------------------------------------------------
  # 7. Construct and return the LayerResult
  # ---------------------------------------------------------------------------
  LayerResult$new(
    layer = 1L,
    layer_name = "Epistemic Stack",
    scores = scores,
    gap_diagnosis = gap,
    remediation = remediation,
    flags = flags,
    notes = NULL
  )
}


# ============================================================================
# Internal helpers
# ============================================================================

#' Map domain dimension codes to FormalContext object names
#'
#' Uses the axiom_set's domain_mapping to find which fc objects correspond
#' to each domain dimension. Falls back to index-based matching when the
#' domain_mapping labels match object names, or simply returns all objects.
#'
#' @param dims Character vector of dimension codes (e.g. \code{c("D1", "D2")}).
#' @param target An \code{\link{EvaluationTarget}}.
#' @param axiom_set An \code{\link{AxiomSet}}.
#' @param obj_names Character vector of FormalContext object names (columns
#'   of \code{fc$I}).
#'
#' @return A named list, each element a character vector of object names.
#' @keywords internal
build_domain_object_map <- function(dims, target, axiom_set, obj_names) {
  map <- list()

  # Build a label lookup: target domain_dims override axiom_set domain_mapping
  labels <- list()
  if (!is.null(axiom_set$domain_mapping)) {
    labels <- axiom_set$domain_mapping
  }
  if (!is.null(target$domain_dims)) {
    for (nm in names(target$domain_dims)) {
      labels[[nm]] <- target$domain_dims[[nm]]
    }
  }

  for (dim_name in dims) {
    label <- labels[[dim_name]]
    matched <- character(0)

    if (!is.null(label)) {
      # Try to match the label to object names
      # Exact match first, then case-insensitive, then substring
      matched <- obj_names[obj_names == label]
      if (length(matched) == 0) {
        matched <- obj_names[tolower(obj_names) == tolower(label)]
      }
      if (length(matched) == 0) {
        # Substring match: does the label appear in the object name?
        matched <- obj_names[grepl(label, obj_names, ignore.case = TRUE)]
      }
    }

    # If no match found, use index-based mapping
    if (length(matched) == 0) {
      dim_idx <- which(names(labels) == dim_name)
      if (length(dim_idx) == 1 && dim_idx <= length(obj_names)) {
        matched <- obj_names[dim_idx]
      }
    }

    # Final fallback: use all objects
    if (length(matched) == 0) {
      matched <- obj_names
    }

    map[[dim_name]] <- matched
  }

  map
}


#' Convert a level code to the corresponding attribute name in the fc
#'
#' @param level Character, one of \code{"L1"}, \code{"L2"}, \code{"L3"},
#'   \code{"L4"}.
#'
#' @return Character attribute name.
#' @keywords internal
level_to_attribute <- function(level) {
  switch(level,
    "L1" = "L1-obs",
    "L2" = "L2-inference",
    "L3" = "L3-eval",
    "L4" = "L4-converge",
    stop("Unknown level: ", level, call. = FALSE)
  )
}


#' Evaluate a single (level, dimension) pair
#'
#' Combines the incidence matrix signal (has_attr) with the artifact's claims
#' to determine PASS/FAIL/PARTIAL.
#'
#' @inheritParams evaluate_layer1
#' @param level Character level code.
#' @param has_attr Logical — does the incidence matrix indicate this level is
#'   present for this domain?
#' @param dim_label Character — human-readable dimension label for messaging.
#'
#' @return Character \code{"PASS"}, \code{"FAIL"}, \code{"PARTIAL"}, or
#'   \code{"N/A"}.
#' @keywords internal
evaluate_level <- function(target, level, has_attr, dim_label) {
  if (!has_attr) {
    return("N/A")
  }

  claims <- target$claims
  if (is.null(claims) || length(claims) == 0) {
    return("PARTIAL")
  }

  switch(level,
    "L1" = evaluate_L1(claims, dim_label),
    "L2" = evaluate_L2(claims, dim_label),
    "L3" = evaluate_L3(claims, dim_label),
    "L4" = evaluate_L4(claims, dim_label),
    stop("Unknown level: ", level, call. = FALSE)
  )
}


#' Evaluate L1 — Empirical Observation
#'
#' PASS: artifact has at least one claim with non-NULL evidence and
#' R1_research register (novel empirical observation).
#' PARTIAL: references others' empirical work (has evidence but not R1).
#' FAIL: no evidence on any claim.
#'
#' @param claims List of \code{\link{Claim}} objects.
#' @param dim_label Character dimension label.
#'
#' @return Character score.
#' @keywords internal
evaluate_L1 <- function(claims, dim_label) {
  has_original_evidence <- any(vapply(claims, function(c) {
    !is.null(c$evidence) && nchar(c$evidence) > 0 &&
      identical(c$register, "R1_research")
  }, logical(1)))

  if (has_original_evidence) {
    return("PASS")
  }

  has_cited_evidence <- any(vapply(claims, function(c) {
    !is.null(c$evidence) && nchar(c$evidence) > 0
  }, logical(1)))

  if (has_cited_evidence) {
    return("PARTIAL")
  }

  "FAIL"
}


#' Evaluate L2 — Formal Generative Framework
#'
#' PASS: claims describe a framework that generates predictions or
#' classifications beyond the original cases (indicated by R1_research
#' register with evidence linking to formal structural claims).
#' PARTIAL: framework exists but is descriptive (register is unclear
#' or evidence is vague).
#' FAIL: no framework present.
#'
#' @param claims List of \code{\link{Claim}} objects.
#' @param dim_label Character dimension label.
#'
#' @return Character score.
#' @keywords internal
evaluate_L2 <- function(claims, dim_label) {
  has_generative <- any(vapply(claims, function(c) {
    # A generative framework claim has R1 register and specific evidence
    # that goes beyond description
    !is.null(c$evidence) && nchar(c$evidence) > 0 &&
      identical(c$register, "R1_research")
  }, logical(1)))

  if (has_generative) {
    return("PASS")
  }

  has_any_evidence <- any(vapply(claims, function(c) {
    !is.null(c$evidence) && nchar(c$evidence) > 0
  }, logical(1)))

  if (has_any_evidence) {
    return("PARTIAL")
  }

  "FAIL"
}


#' Evaluate L3 — Evaluative Criteria
#'
#' PASS: at least one claim addresses competing programs or alternatives
#' with explicit evaluative criteria (R2_rhetorical register with evidence
#' of comparison).
#' PARTIAL: acknowledges alternatives but no formal comparative criteria.
#' FAIL: only asserts own position.
#'
#' @param claims List of \code{\link{Claim}} objects.
#' @param dim_label Character dimension label.
#'
#' @return Character score.
#' @keywords internal
evaluate_L3 <- function(claims, dim_label) {
  has_comparison <- any(vapply(claims, function(c) {
    # R2_rhetorical register claims may discuss competing programs
    !is.null(c$evidence) && nchar(c$evidence) > 0 &&
      identical(c$register, "R2_rhetorical")
  }, logical(1)))

  if (has_comparison) {
    return("PASS")
  }

  has_broad_claim <- any(vapply(claims, function(c) {
    # Claims that cross domains or make general statements
    !is.null(c$text) && nchar(c$text) > 0 &&
      grepl("bridge|gap|between|compare|versus|alternative",
            c$text, ignore.case = TRUE)
  }, logical(1)))

  if (has_broad_claim) {
    return("PARTIAL")
  }

  "FAIL"
}


#' Evaluate L4 — Tradition Integration
#'
#' PASS: artifact integrates two or more intellectual traditions with
#' preservation/loss analysis (multiple domain dimensions, or claims
#' that span traditions with explicit analytical comparison).
#' PARTIAL: references other traditions but doesn't formally integrate.
#' FAIL: single tradition only.
#'
#' @param claims List of \code{\link{Claim}} objects.
#' @param dim_label Character dimension label.
#'
#' @return Character score.
#' @keywords internal
evaluate_L4 <- function(claims, dim_label) {
  has_integration <- any(vapply(claims, function(c) {
    # Integration claims cross domains with evidence
    !is.null(c$evidence) && nchar(c$evidence) > 0 &&
      (!is.null(c$text) && grepl(
        "integrate|synthesize|unify|bridge|combine",
        c$text, ignore.case = TRUE
      ))
  }, logical(1)))

  if (has_integration) {
    return("PASS")
  }

  has_cross_domain <- any(vapply(claims, function(c) {
    !is.null(c$text) && nchar(c$text) > 0 &&
      grepl("between|across|both|multi|interdisciplin",
            c$text, ignore.case = TRUE)
  }, logical(1)))

  if (has_cross_domain) {
    return("PARTIAL")
  }

  "FAIL"
}


#' Diagnose gaps in the scores matrix
#'
#' Scans for FAIL and PARTIAL scores and produces a concise diagnosis.
#'
#' @param scores The scores matrix (levels \eqn{\times} dimensions).
#' @param dims Character vector of dimension names.
#' @param levels Character vector of level names.
#'
#' @return Character string describing the most significant gap, or
#'   \code{NULL} if all levels pass across all dimensions.
#' @keywords internal
diagnose_gaps <- function(scores, dims, levels) {
  gaps <- list()

  # Check for FAIL scores first (more severe)
  for (lvl in levels) {
    for (dim in dims) {
      score <- scores[lvl, dim]
      dim_label <- dim

      if (identical(score, "FAIL")) {
        gaps <- c(gaps, sprintf("%s: %s is FAIL",
                                level_to_name(lvl), dim_label))
      } else if (identical(score, "PARTIAL")) {
        gaps <- c(gaps, sprintf("%s: %s is PARTIAL",
                                level_to_name(lvl), dim_label))
      }
    }
  }

  if (length(gaps) == 0) {
    return(NULL)
  }

  paste(gaps, collapse = "; ")
}


#' Convert a level code to a human-readable name
#'
#' @param level Character, one of \code{"L1"}–\code{"L4"}.
#'
#' @return Character name.
#' @keywords internal
level_to_name <- function(level) {
  switch(level,
    "L1" = "Empirical Observation",
    "L2" = "Formal Generative Framework",
    "L3" = "Evaluative Criteria",
    "L4" = "Tradition Integration",
    level
  )
}


#' Build a remediation chain for the most significant gap
#'
#' Identifies the first FAIL or PARTIAL score and constructs a remediation
#' suggestion: a complementary target type that would strengthen the gap,
#' and the level to focus on.
#'
#' @param scores The scores matrix.
#' @param dims Character vector of dimension names.
#' @param levels Character vector of level names.
#' @param gap Character gap diagnosis string (from
#'   \code{\link{diagnose_gaps}}).
#'
#' @return A list with \code{complement} (character) and \code{target_level}
#'   (character), or \code{NULL} if no gap.
#' @keywords internal
build_remediation <- function(scores, dims, levels, gap) {
  if (is.null(gap)) {
    return(NULL)
  }

  # Find the first FAIL or PARTIAL level
  target_level <- NULL
  target_dim <- NULL

  for (lvl in levels) {
    for (dim in dims) {
      score <- scores[lvl, dim]
      if (identical(score, "FAIL") || identical(score, "PARTIAL")) {
        target_level <- lvl
        target_dim <- dim
        break
      }
    }
    if (!is.null(target_level)) break
  }

  if (is.null(target_level)) {
    return(NULL)
  }

  # Determine the complementary target type based on the failed level
  complement <- switch(target_level,
    "L1" = "Experimental paper with novel empirical observations",
    "L2" = "Formal model with predictive-generative framework",
    "L3" = "Comparative review with explicit evaluative criteria",
    "L4" = "Synthesis paper integrating multiple intellectual traditions",
    "Complementary target within the same domain"
  )

  list(
    complement = complement,
    target_level = target_level,
    target_dim = target_dim
  )
}