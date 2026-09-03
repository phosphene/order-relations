# ---------------------------------------------------------------------------
# evaluate.R — Full 7-Layer Dispatch Engine
#
# Main entry point for the INFERNO evaluation protocol. Constructs a formal
# context from the axiom set, computes the concept lattice with circuit-breaker
# protection, dispatches all 7 layers in order, composes a verdict, and returns
# an EvaluationResult.
#
# Public API:
#   evaluate(target, axiom_set, config)     → EvaluationResult
#   compose_verdict(layers)                 → character
#   capture_session(seed)                   → list
# ---------------------------------------------------------------------------


#' Evaluate a research artifact using the 7-layer INFERNO protocol
#'
#' The top-level entry point. Constructs a \code{\link[fcaR]{FormalContext}}
#' from the \code{\link{AxiomSet}}, runs the circuit-breaker (safe lattice
#' computation), dispatches layers 1–7 in order, and assembles an
#' \code{\link{EvaluationResult}}.
#'
#' @section Layer dispatch order:
#' \enumerate{
#'   \item \code{\link{evaluate_layer1}} — Epistemic Stack
#'   \item \code{\link{evaluate_layer2}} — Claims/Evidence/Inference
#'     (M-Failure Audit)
#'   \item \code{\link{evaluate_layer3}} — Dual-Register Analysis
#'   \item \code{\link{evaluate_layer4}} — Compression Taxonomy
#'   \item \code{\link{evaluate_layer5}} — Semiotic Analysis
#'   \item \code{\link{evaluate_layer6}} — Analogical Argument
#'   \item \code{\link{evaluate_layer7}} — Weighted Credibility Index (WCI)
#' }
#'
#' Layer 7 receives the list of prior layers (L1–L6) as the
#' \code{prior_layers} argument, allowing it to synthesise cross-layer
#' metrics into the WCI.
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object describing the
#'   research artifact to evaluate.
#' @param axiom_set An \code{\link{AxiomSet}} R6 object providing the formal
#'   context (incidence matrix), domain mapping, and metric choice.
#' @param config A named list of evaluation options.
#'   Supported keys:
#'   \describe{
#'     \item{seed}{Integer — random seed for reproducibility. Default 42.}
#'     \item{verbose}{Logical — print progress messages. Default \code{FALSE}.}
#'     \item{layer_overrides}{Named list — per-layer overrides (e.g.,
#'       \code{list(L1 = list(mode = "hypothesis-testing"))}).}
#'     \item{max_attributes}{Integer — circuit-breaker threshold for attribute
#'       count. Default 50.}
#'     \item{max_density}{Numeric — circuit-breaker threshold for density.
#'       Default 0.85.}
#'     \item{compute_js_divergence}{Logical — passed to Layer 7. Default
#'       \code{FALSE}.}
#'   }
#'
#' @return An \code{\link{EvaluationResult}} R6 object containing:
#'   \itemize{
#'     \item \code{target} — the \code{\link{EvaluationTarget}}
#'     \item \code{axiom_set} — the \code{\link{AxiomSet}} used
#'     \item \code{layers} — list of 7 \code{\link{LayerResult}} objects
#'     \item \code{wci} — named numeric vector (6 dimensions + composite)
#'     \item \code{overall} — character verdict string
#'     \item \code{session_info} — list of session metadata
#'   }
#'
#' @examples
#' \donttest{
#' target    <- make_gard_target()
#' axiom_set <- make_test_axiom_set()
#' result    <- evaluate(target, axiom_set)
#' print(result)
#' }
#'
#' @export
evaluate <- function(target, axiom_set, config = list(seed = 42)) {
  # ---- Resolve defaults ----
  seed                <- config[["seed"]] %||% 42L
  verbose             <- isTRUE(config[["verbose"]])
  layer_overrides     <- config[["layer_overrides"]] %||% list()
  max_attributes      <- config[["max_attributes"]] %||% 50L
  max_density         <- config[["max_density"]] %||% 0.85
  compute_js_divergence <- isTRUE(config[["compute_js_divergence"]])

  set.seed(seed)

  # ---- Validate inputs ----
  stopifnot(inherits(target, "EvaluationTarget"))
  stopifnot(inherits(axiom_set, "AxiomSet"))

  if (verbose) message("INFERNO: Constructing formal context...")

  # ---- Step 1: Build formal context ----
  fc <- axiom_set$to_formal_context()

  # ---- Step 2: Compute lattice with circuit breaker ----
  if (verbose) message("INFERNO: Computing concept lattice (circuit-breaker)...")
  fc <- safe_compute_lattice(
    fc,
    max_attributes = max_attributes,
    max_density    = max_density
  )

  # Resolve per-layer overrides
  l1_opts <- layer_overrides[["L1"]] %||% list()
  l7_opts <- layer_overrides[["L7"]] %||% list()

  # ---- Step 3: Dispatch all 7 layers ----
  if (verbose) message("INFERNO: Dispatching L1 — Epistemic Stack...")
  l1 <- evaluate_layer1(
    target    = target,
    axiom_set = axiom_set,
    fc        = fc,
    mode      = l1_opts[["mode"]] %||% "crisp"
  )

  if (verbose) message("INFERNO: Dispatching L2 — M-Failure Audit...")
  l2 <- evaluate_layer2(
    target    = target,
    axiom_set = axiom_set,
    fc        = fc
  )

  if (verbose) message("INFERNO: Dispatching L3 — Dual-Register Analysis...")
  l3 <- evaluate_layer3(
    target         = target,
    axiom_set      = axiom_set,
    fc             = fc,
    manual_register = layer_overrides[["L3"]][["manual_register"]] %||% NULL
  )

  if (verbose) message("INFERNO: Dispatching L4 — Compression Taxonomy...")
  l4 <- evaluate_layer4(
    target    = target,
    axiom_set = axiom_set,
    fc        = fc
  )

  if (verbose) message("INFERNO: Dispatching L5 — Semiotic Analysis...")
  l5 <- evaluate_layer5(
    target    = target,
    axiom_set = axiom_set,
    fc        = fc
  )

  if (verbose) message("INFERNO: Dispatching L6 — Analogical Argument...")
  l6 <- evaluate_layer6(
    target    = target,
    axiom_set = axiom_set,
    fc        = fc
  )

  # ---- Layer 7: WCI (receives prior 6 layers) ----
  if (verbose) message("INFERNO: Dispatching L7 — WCI...")
  prior_layers <- list(l1, l2, l3, l4, l5, l6)
  l7 <- evaluate_layer7(
    target               = target,
    axiom_set            = axiom_set,
    prior_layers         = prior_layers,
    compute_js_divergence = compute_js_divergence
  )

  # ---- Step 4: Extract WCI from Layer 7 ----
  wci <- l7$scores

  # ---- Step 5: Compose overall verdict ----
  layers_list <- list(l1, l2, l3, l4, l5, l6, l7)
  overall <- compose_verdict(layers_list)

  # ---- Step 6: Capture session info ----
  session_info <- capture_session(seed)

  # ---- Step 7: Build and return EvaluationResult ----
  EvaluationResult$new(
    target       = target,
    axiom_set    = axiom_set,
    layers       = layers_list,
    wci          = wci,
    overall      = overall,
    session_info = session_info
  )
}


# ============================================================================
# compose_verdict
# ============================================================================

#' Compose a human-readable verdict from 7 layer results
#'
#' Analyses the gap diagnoses, flags, and WCI from all 7 layers to produce
#' a concise overall verdict string. The verdict highlights the strongest
#' and weakest layers, M-failure counts, and the composite WCI score.
#'
#' @param layers A list of 7 \code{\link{LayerResult}} objects in order.
#'
#' @return A character string summarising the evaluation outcome.
#'
#' @keywords internal
#' @export
compose_verdict <- function(layers) {
  stopifnot(is.list(layers), length(layers) == 7L)

  parts <- character(0L)

  # --- Layer 1 summary ---
  l1 <- layers[[1L]]
  if (!is.null(l1$gap_diagnosis)) {
    parts <- c(parts, sprintf("L1-%s", classify_gap_severity(l1$gap_diagnosis)))
  } else {
    parts <- c(parts, "L1-strong")
  }

  # --- Layer 2: M-failure count ---
  l2 <- layers[[2L]]
  m_failures <- l2$flags$m_failures %||% character(0L)
  n_m <- length(m_failures)
  if (n_m > 0) {
    parts <- c(parts, sprintf("%d M-failure(s) detected", n_m))
  } else {
    parts <- c(parts, "No M-failures")
  }

  # --- Layer 3: collapse errors ---
  l3 <- layers[[3L]]
  n_collapse <- sum(l3$flags$collapse_errors %||% logical(0L))
  if (n_collapse > 0) {
    parts <- c(parts, sprintf("%d collapse error(s)", n_collapse))
  }

  # --- Layer 4: compression summary ---
  l4 <- layers[[4L]]
  if (!is.null(l4$flags$reversibility)) {
    if (isTRUE(l4$flags$reversibility$lossless)) {
      parts <- c(parts, "Compression lossless")
    } else {
      parts <- c(parts, sprintf("Compression lossy (%d flux)",
                                l4$flags$reversibility$info_loss_n %||% 0L))
    }
  }

  # --- Layer 5: semiosis risk ---
  l5 <- layers[[5L]]
  n_risk <- l5$flags$risk_count %||% 0L
  if (n_risk > 0) {
    parts <- c(parts, sprintf("%d object(s) with semiosis risk", n_risk))
  }

  # --- Layer 6: analogy verdict ---
  l6 <- layers[[6L]]
  l6_verdict <- l6$flags$verdict %||% "not_admissible"
  # Simplify
  if (l6_verdict == "admissible") {
    parts <- c(parts, "Analogy admissible")
  } else if (l6_verdict == "admissible_with_caveats") {
    parts <- c(parts, "Analogy caveated")
  } else {
    parts <- c(parts, "Analogy not admissible")
  }

  # --- Layer 7: WCI ---
  l7 <- layers[[7L]]
  wci_composite <- if (is.numeric(l7$scores) && "composite" %in% names(l7$scores)) {
    l7$scores["composite"]
  } else {
    NA_real_
  }

  if (!is.na(wci_composite)) {
    parts <- c(parts, sprintf("WCI: %.3f", wci_composite))
  }

  # --- Gap diagnosis from Layer 1 if present ---
  if (!is.null(l1$gap_diagnosis)) {
    parts <- c(parts, sprintf("Gap: %s", l1$gap_diagnosis))
  }

  paste(parts, collapse = ". ")
}


#' Classify gap severity
#'
#' Returns "strong" if no gap, "weak" if a gap exists.
#'
#' @param gap Character gap diagnosis string.
#'
#' @return Character — "strong" or "weak".
#' @keywords internal
classify_gap_severity <- function(gap) {
  if (is.null(gap) || nchar(trimws(gap)) == 0) return("strong")
  if (grepl("PASS", gap, fixed = TRUE)) return("strong")
  "weak"
}


# ============================================================================
# capture_session
# ============================================================================

#' Capture session metadata for an evaluation run
#'
#' Records the current R version, the seed used, a timestamp, and the
#' INFERNO package version (read from \code{packageDescription} if available,
#' otherwise \code{"0.0.0"}).
#'
#' @param seed Integer — the random seed used for this evaluation.
#'
#' @return A named list with elements \code{r_version}, \code{seed},
#'   \code{timestamp}, and \code{inferno_version}.
#'
#' @keywords internal
#' @export
capture_session <- function(seed) {
  # Attempt to read the INFERNO package version
  pkg_version <- tryCatch(
    as.character(utils::packageVersion("inferno")),
    error = function(e) "0.0.0"
  )

  list(
    r_version       = paste(version$version.string,
                            version$platform, sep = ", "),
    seed            = as.integer(seed),
    timestamp       = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    inferno_version = pkg_version
  )
}


# ============================================================================
# Internal utility
# ============================================================================

#' Null-coalescing operator (internal)
#'
#' Returns \code{x} if not \code{NULL}, otherwise \code{y}.
#'
#' @param x Left-hand side value.
#' @param y Fallback value.
#'
#' @return \code{x} or \code{y}.
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
