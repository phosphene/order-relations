# ---------------------------------------------------------------------------
# render.R — Output Rendering: JSON, YAML, Markdown
#
# Converts an EvaluationResult to structured output formats. The JSON and
# YAML renderers produce transport-friendly serializations suitable for
# storage, API responses, and downstream analytics. The Markdown renderer
# produces a human-readable evaluation report.
#
# Public API:
#   render(result, format = "json")  → character
#   render_json(result)              → character (JSON)
#   render_yaml(result)              → character (YAML)
#   render_markdown(result)          → character (Markdown)
# ---------------------------------------------------------------------------


#' Render an EvaluationResult to structured output
#'
#' Renders an \code{\link{EvaluationResult}} to one of three formats:
#' \describe{
#'   \item{\code{"json"}}{Pretty-printed JSON via \code{jsonlite::toJSON}}
#'   \item{\code{"yaml"}}{YAML via \code{yaml::as.yaml}}
#'   \item{\code{"md"}}{Human-readable Markdown summary}
#' }
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#' @param format Character — one of \code{"json"}, \code{"yaml"}, or
#'   \code{"md"}. Default \code{"json"}.
#' @param ... Additional arguments passed to the format-specific renderer.
#'
#' @return A character string containing the rendered output.
#'
#' @examples
#' \donttest{
#' result <- evaluate(make_gard_target(), make_test_axiom_set())
#' cat(render(result, format = "json"))
#' cat(render(result, format = "md"))
#' }
#'
#' @export
render <- function(result, format = "json", ...) {
  stopifnot(inherits(result, "EvaluationResult"))

  format <- match.arg(format, c("json", "yaml", "md"))

  switch(format,
    json = render_json(result, ...),
    yaml = render_yaml(result, ...),
    md   = render_markdown(result, ...)
  )
}


# ============================================================================
# render_json
# ============================================================================

#' Render an EvaluationResult to JSON
#'
#' Serializes the evaluation result as a structured JSON document using
#' \code{jsonlite::toJSON} with \code{pretty = TRUE} and
#' \code{auto_unbox = TRUE}. The WCI scores, session info, target metadata,
#' and all 7 layer results are included.
#'
#' Layer scores that are matrices are converted to lists of lists. Flags
#' containing igraph objects are serialized as summary stats rather than the
#' full graph structure.
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#' @param pretty Logical — pretty-print JSON. Default \code{TRUE}.
#' @param digits Integer — number of decimal places for numeric values.
#'   Default 4.
#'
#' @return A character string containing the JSON document.
#'
#' @keywords internal
#' @export
render_json <- function(result, pretty = TRUE, digits = 4) {
  payload <- build_serializable_list(result)

  jsonlite::toJSON(
    payload,
    pretty          = pretty,
    auto_unbox      = TRUE,
    digits          = digits,
    na              = "null",
    null            = "null"
  )
}


# ============================================================================
# render_yaml
# ============================================================================

#' Render an EvaluationResult to YAML
#'
#' Serializes the evaluation result as YAML using \code{yaml::as.yaml}.
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#'
#' @return A character string containing the YAML document.
#'
#' @keywords internal
#' @export
render_yaml <- function(result) {
  payload <- build_serializable_list(result)

  yaml::as.yaml(payload)
}


# ============================================================================
# render_markdown
# ============================================================================

#' Render an EvaluationResult to Markdown
#'
#' Produces a human-readable Markdown report with sections for target
#' metadata, a layer results table, WCI breakdown, and overall verdict.
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#'
#' @return A character string containing the Markdown report.
#'
#' @keywords internal
#' @export
render_markdown <- function(result) {
  lines <- character(0L)

  # ---- Header ----
  lines <- c(lines, sprintf("# INFERNO Evaluation: %s", result$target$title))
  lines <- c(lines, "")
  lines <- c(lines, sprintf("**AxiomSet:** `%s` | **Metric:** %s",
                            result$axiom_set$get_hash(),
                            result$axiom_set$metric))
  lines <- c(lines, sprintf("**Date:** %s",
                            result$session_info$timestamp %||% "unknown"))
  lines <- c(lines, sprintf("**INFERNO Version:** %s",
                            result$session_info$inferno_version %||% "0.0.0"))
  lines <- c(lines, "")

  # ---- Target metadata ----
  lines <- c(lines, "## Target")
  lines <- c(lines, "")
  lines <- c(lines, sprintf("- **Type:** %s", result$target$artifact_type))
  lines <- c(lines, sprintf("- **Title:** %s", result$target$title))
  if (!is.null(result$target$authors) && length(result$target$authors) > 0) {
    lines <- c(lines, sprintf("- **Authors:** %s",
                              paste(result$target$authors, collapse = ", ")))
  }
  if (!is.null(result$target$year)) {
    lines <- c(lines, sprintf("- **Year:** %d", result$target$year))
  }
  if (!is.null(result$target$doi)) {
    lines <- c(lines, sprintf("- **DOI:** %s", result$target$doi))
  }
  if (length(result$target$domain_dims) > 0) {
    dim_parts <- vapply(names(result$target$domain_dims), function(nm) {
      sprintf("%s = %s", nm, result$target$domain_dims[[nm]])
    }, character(1))
    lines <- c(lines, sprintf("- **Domains:** %s",
                              paste(dim_parts, collapse = ", ")))
  }
  lines <- c(lines, "")

  # ---- Layer results table ----
  lines <- c(lines, "## Layer Results")
  lines <- c(lines, "")
  lines <- c(lines, "| Layer | Name | Status | Gap Diagnosis |")
  lines <- c(lines, "|------|------|--------|---------------|")

  for (i in seq_along(result$layers)) {
    lr <- result$layers[[i]]
    status <- ifelse(is.null(lr$gap_diagnosis), "PASS", "GAP")
    gap <- lr$gap_diagnosis %||% ""
    # Truncate long gap diagnoses for table readability
    if (nchar(gap) > 60) gap <- paste0(substr(gap, 1, 57), "...")
    lines <- c(lines, sprintf("| %d | %s | %s | %s |",
                              lr$layer, lr$layer_name, status, gap))
  }
  lines <- c(lines, "")

  # ---- M-Failure detail ----
  l2 <- result$layers[[2L]]
  m_failures <- l2$flags$m_failures %||% character(0L)
  if (length(m_failures) > 0) {
    lines <- c(lines, "### M-Failures")
    lines <- c(lines, "")
    for (nm in names(m_failures)) {
      lines <- c(lines, sprintf("- **%s:** %s", nm, m_failures[nm]))
    }
    lines <- c(lines, "")
  }

  # ---- WCI breakdown ----
  lines <- c(lines, "## Weighted Credibility Index (WCI)")
  lines <- c(lines, "")

  wci <- result$wci
  if (is.numeric(wci) && length(wci) > 0) {
    lines <- c(lines, "| Dimension | Score |")
    lines <- c(lines, "|-----------|-------|")

    # Print all dimensions (including composite) in a fixed order
    ordered_dims <- c(
      "theoretical_coherence",
      "empirical_support",
      "replicability",
      "independent_uptake",
      "explanatory_power",
      "falsifiability",
      "composite"
    )

    for (dim_name in ordered_dims) {
      if (dim_name %in% names(wci)) {
        display <- gsub("_", " ", dim_name)
        display <- paste0(toupper(substr(display, 1, 1)), substr(display, 2, nchar(display)))
        lines <- c(lines, sprintf("| %s | %.4f |", display, wci[dim_name]))
      }
    }
  }
  lines <- c(lines, "")

  # ---- Verdict ----
  lines <- c(lines, "## Overall Verdict")
  lines <- c(lines, "")
  lines <- c(lines, result$overall %||% "No verdict available.")
  lines <- c(lines, "")

  # ---- Session info ----
  lines <- c(lines, "## Session Information")
  lines <- c(lines, "")
  si <- result$session_info
  lines <- c(lines, sprintf("- **R Version:** %s", si$r_version %||% "unknown"))
  lines <- c(lines, sprintf("- **Seed:** %d", si$seed %||% NA_integer_))
  lines <- c(lines, sprintf("- **Timestamp:** %s", si$timestamp %||% "unknown"))
  lines <- c(lines, sprintf("- **INFERNO Version:** %s",
                             si$inferno_version %||% "0.0.0"))
  lines <- c(lines, "")

  paste(lines, collapse = "\n")
}


# ============================================================================
# Internal serialization helper
# ============================================================================

#' Build a fully serializable nested list from an EvaluationResult
#'
#' Converts the R6 object tree (EvaluationResult → LayerResult → matrices,
#' lists, flags) into plain R lists and atomic vectors suitable for
#' \code{jsonlite::toJSON} and \code{yaml::as.yaml}.
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#'
#' @return A nested list.
#'
#' @keywords internal
build_serializable_list <- function(result) {
  # --- Target ---
  tgt <- result$target
  target_list <- list(
    artifact_type = tgt$artifact_type,
    title         = tgt$title,
    authors       = tgt$authors %||% list(),
    year          = tgt$year %||% NA_integer_,
    doi           = tgt$doi %||% NA_character_,
    domain_dims   = tgt$domain_dims %||% list(),
    n_claims      = length(tgt$claims %||% list()),
    metadata      = tgt$metadata %||% list()
  )

  # --- Claims ---
  claims_list <- list()
  for (cl in (tgt$claims %||% list())) {
    claims_list[[cl$id]] <- list(
      id        = cl$id,
      text      = cl$text,
      evidence  = cl$evidence %||% NA_character_,
      register  = cl$register %||% "unclear",
      m_failure = if (is.na(cl$m_failure)) NA_character_ else cl$m_failure
    )
  }

  # --- AxiomSet ---
  ax <- result$axiom_set
  axiom_set_list <- list(
    context_hash   = ax$get_hash(),
    n_objects      = length(ax$objects),
    n_attributes   = length(ax$attributes),
    density        = round(sum(ax$incidence) / length(ax$incidence), 4),
    domain_mapping = ax$domain_mapping %||% list(),
    metric         = ax$metric,
    metadata       = ax$metadata %||% list()
  )

  # --- Layers ---
  layers_list <- list()
  for (i in seq_along(result$layers)) {
    lr <- result$layers[[i]]

    # Convert scores to a serializable form
    scores_ser <- if (is.matrix(lr$scores)) {
      # Character matrix → list of named lists
      score_rows <- list()
      rn <- rownames(lr$scores) %||% as.character(seq_len(nrow(lr$scores)))
      cn <- colnames(lr$scores) %||% as.character(seq_len(ncol(lr$scores)))
      for (r in seq_len(nrow(lr$scores))) {
        row_list <- as.list(lr$scores[r, , drop = FALSE])
        names(row_list) <- cn
        row_list[["_row"]] <- rn[r]
        score_rows[[r]] <- row_list
      }
      score_rows
    } else if (is.numeric(lr$scores) && !is.null(names(lr$scores))) {
      as.list(lr$scores)
    } else {
      lr$scores
    }

    # Serialize flags, stripping non-serializable objects
    flags_ser <- serialize_flags(lr$flags)

    layers_list[[i]] <- list(
      layer          = lr$layer,
      layer_name     = lr$layer_name,
      scores         = scores_ser,
      gap_diagnosis  = lr$gap_diagnosis %||% NA_character_,
      remediation    = serialize_remediation(lr$remediation),
      flags          = flags_ser,
      notes          = lr$notes %||% NA_character_
    )
  }

  # --- WCI ---
  wci_list <- if (is.numeric(result$wci) && length(result$wci) > 0) {
    as.list(result$wci)
  } else {
    list()
  }

  # --- Assemble ---
  list(
    version     = "inferno-v1",
    target      = target_list,
    claims      = claims_list,
    axiom_set   = axiom_set_list,
    layers      = layers_list,
    wci         = wci_list,
    overall     = result$overall %||% NA_character_,
    session     = result$session_info
  )
}


#' Serialize flags to a plain-list form
#'
#' Strips igraph objects, R6 objects, and other non-serializable content.
#' Replaces igraph objects with a summary list of node count, edge count,
#' and degree distribution.
#'
#' @param flags List — the \code{$flags} field of a \code{\link{LayerResult}}.
#'
#' @return A flat list suitable for JSON/YAML serialization.
#'
#' @keywords internal
serialize_flags <- function(flags) {
  if (is.null(flags) || length(flags) == 0L) {
    return(list())
  }

  ser <- list()
  for (nm in names(flags)) {
    val <- flags[[nm]]

    # igraph objects → summary
    if (inherits(val, "igraph")) {
      ser[[nm]] <- list(
        "_type"      = "igraph_summary",
        n_nodes    = igraph::vcount(val),
        n_edges    = igraph::ecount(val),
        n_components = igraph::components(val)$no
      )
      next
    }

    # R6 objects → class name + str
    if (inherits(val, "R6")) {
      ser[[nm]] <- list(
        "_type"  = "R6",
        "_class" = class(val)[1L]
      )
      next
    }

    # Lists with sub-elements
    if (is.list(val)) {
      # Recurse for safe sub-lists
      sub <- serialize_flags(val)
      # If it's a list with names, keep names
      if (!is.null(names(val)) && length(val) > 0) {
        ser[[nm]] <- sub
      } else if (length(val) > 0) {
        ser[[nm]] <- sub
      } else {
        ser[[nm]] <- list()
      }
      next
    }

    # Atomic
    ser[[nm]] <- val
  }

  ser
}


#' Serialize a remediation list to a plain-list form
#'
#' @param remediation List or \code{NULL}.
#'
#' @return A plain list, or an empty list if \code{NULL}.
#'
#' @keywords internal
serialize_remediation <- function(remediation) {
  if (is.null(remediation)) {
    return(list())
  }
  if (is.list(remediation)) {
    return(remediation)
  }
  list(value = remediation)
}


# ============================================================================
# Internal utility
# ============================================================================

#' Null-coalescing operator (internal)
#'
#' @param x Left-hand side.
#' @param y Fallback if \code{x} is \code{NULL}.
#'
#' @return \code{x} or \code{y}.
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
