#' Layer 5 — Semiotic Analysis
#'
#' Peircean semiotic typing of formal objects in evaluation claims. Each formal
#' object (noun, concept, entity) extracted from a target's claims is classified
#' as an **icon**, **index**, or **symbol** according to C. S. Peirce's
#' triadic sign model. The analysis builds a semiotic network topology using
#' igraph, identifies semiosis risks where interpretation may shift between
#' types, and flags objects with unstable or contested typing.
#'
#' **Peircean categories applied:**
#' \describe{
#'   \item{Icon}{Resembles its object (e.g., a diagram of a network, a
#'         simulation, a structural model).}
#'   \item{Index}{Causally or physically connected to its object (e.g., a
#'         measurement reading, an empirical observation, a data trace).}
#'   \item{Symbol}{Conventionally associated with its object (e.g.,
#'         mathematical notation, disciplinary terminology, a named concept).}
#' }
#'
#' **Semiosis risk:** occurs when the same object is classified differently
#' across claims, or when its type is ambiguous — indicating potential for
#' misinterpretation as the artifact moves between interpretive communities.
#'
#' @name layer5-semiotic
NULL


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Extract formal objects from a claim's text
#'
#' Identifies candidate formal objects (nouns, noun phrases, proper names,
#' technical terms) in claim text. Returns a character vector of unique terms.
#' This is a lightweight extraction; for production use, consider a proper NLP
#' pipeline (e.g., udpipe, spacyr).
#'
#' @param text Character — claim text to parse.
#' @param additional_terms Character vector of known domain terms to include.
#'
#' @return Character vector of extracted formal object terms.
#' @keywords internal
extract_formal_objects <- function(text, additional_terms = NULL) {
  # Domain-specific stopwords that are not formal objects
  stopwords <- c(
    "the", "a", "an", "this", "that", "these", "those", "it", "its",
    "is", "are", "was", "were", "be", "been", "being", "has", "have",
    "had", "do", "does", "did", "will", "would", "can", "could",
    "may", "might", "shall", "should", "to", "of", "in", "for",
    "on", "with", "at", "by", "from", "as", "into", "through",
    "during", "before", "after", "above", "below", "between",
    "out", "off", "over", "under", "again", "further", "then",
    "once", "here", "there", "when", "where", "why", "how",
    "all", "each", "every", "both", "few", "more", "most",
    "other", "some", "such", "no", "nor", "not", "only",
    "own", "same", "so", "than", "too", "very", "just",
    "because", "but", "and", "or", "if", "while", "although",
    "which", "who", "whom", "what", "whose",
    "also", "however", "therefore", "thus", "hence",
    "about", "within", "without", "among", "across", "along",
    "does", "shows", "demonstrates", "indicates", "suggests",
    "likely", "possible", "potential", "significant", "robust"
  )

  # Lowercase, split on non-alphanumeric (apostrophes and hyphens kept)
  words <- unlist(strsplit(text, "[^[:alnum:]['-]?[[:space:]]"))
  words <- tolower(words)
  words <- grep("^[a-z]", words, value = TRUE)
  words <- setdiff(words, stopwords)
  words <- unique(words)

  # Remove very short or very long words
  words <- words[nchar(words) >= 3 & nchar(words) <= 30]

  # Add domain-specific terms
  if (!is.null(additional_terms)) {
    words <- unique(c(words, tolower(additional_terms)))
  }

  words
}


#' Heuristic Peircean classification of a formal object
#'
#' Uses keyword- and context-based heuristics to classify a formal object as
#' icon, index, or symbol. Returns a named list with the primary type,
#' confidence (0-1), and alternative types that could apply.
#'
#' @param object Character — the formal object term.
#' @param evidence Character — the evidence context from the claim.
#' @param register Character — the claim register ("R1_research", "R2_rhetorical").
#'
#' @return A list with elements: \code{type} (character), \code{confidence}
#'   (numeric 0-1), \code{alternatives} (character vector of alternative types).
#' @keywords internal
classify_semiotic_type <- function(object, evidence = NULL, register = "unclear") {

  # --- Icon indicators: terms suggesting resemblance, diagram, model, simulation
  icon_keywords <- c(
    "diagram", "model", "simulation", "graph", "network", "map",
    "plot", "figure", "image", "schema", "visualization", "representation",
    "architecture", "topology", "structure", "framework", "pattern",
    "template", "blueprint", "sketch", "picture", "illustration"
  )

  # --- Index indicators: terms suggesting causal connection, measurement, trace
  index_keywords <- c(
    "measurement", "observation", "data", "signal", "reading", "trace",
    "record", "experiment", "assay", "detection", "sample", "empirical",
    "evidence", "correlation", "effect", "cause", "result", "outcome",
    "response", "indicator", "marker", "biomarker", "metric", "statistic",
    "frequency", "rate", "count", "intensity", "concentration", "ratio"
  )

  # --- Symbol indicators: abstract, conventional, notation-based
  symbol_keywords <- c(
    "notation", "symbol", "term", "concept", "definition", "axiom",
    "theorem", "hypothesis", "theory", "paradigm", "principle", "law",
    "equation", "formula", "function", "algorithm", "protocol", "category",
    "class", "type", "species", "genus", "ontology", "taxonomy",
    "mathematics", "logic", "algebra", "calculus", "set", "group",
    "ring", "field", "space", "manifold", "operator", "vector",
    "matrix", "tensor", "parameter", "coefficient", "invariant"
  )

  obj_lower <- tolower(object)

  # Score each category
  icon_score <- sum(sapply(icon_keywords, function(kw) grepl(kw, obj_lower, fixed = TRUE)))
  index_score <- sum(sapply(index_keywords, function(kw) grepl(kw, obj_lower, fixed = TRUE)))
  symbol_score <- sum(sapply(symbol_keywords, function(kw) grepl(kw, obj_lower, fixed = TRUE)))

  # Also check evidence context
  if (!is.null(evidence)) {
    ev_lower <- tolower(evidence)
    icon_score <- icon_score + sum(sapply(icon_keywords, function(kw) grepl(kw, ev_lower, fixed = TRUE)))
    index_score <- index_score + sum(sapply(index_keywords, function(kw) grepl(kw, ev_lower, fixed = TRUE)))
    symbol_score <- symbol_score + sum(sapply(symbol_keywords, function(kw) grepl(kw, ev_lower, fixed = TRUE)))
  }

  # Register heuristic: R1 claims favor index, R2 claims favor symbol
  if (register == "R1_research") {
    index_score <- index_score + 0.5
  } else if (register == "R2_rhetorical") {
    symbol_score <- symbol_score + 0.5
  }

  scores <- c(icon = icon_score, index = index_score, symbol = symbol_score)

  # If no keywords matched, default to heuristics
  if (all(scores == 0)) {
    # Default to "symbol" for abstract terms, "index" for concrete
    if (nchar(obj_lower) > 8) {
      # Longer terms tend to be technical/symbolic
      scores["symbol"] <- 1
    } else {
      # Shorter terms get a conservative default of index
      scores["index"] <- 1
    }
  }

  # Determine primary type
  primary_type <- names(which.max(scores))

  # Compute confidence as proportion of max score vs total (with smoothing)
  total <- sum(scores)
  if (total == 0) total <- 1
  confidence <- scores[primary_type] / total

  # Identify alternative types that are close
  alt_types <- setdiff(names(scores), primary_type)
  alternatives <- alt_types[scores[alt_types] >= scores[primary_type] * 0.5]

  list(
    type = primary_type,
    confidence = round(confidence, 3),
    alternatives = alternatives
  )
}


#' Build a semiotic relation network from claim-object pairs
#'
#' Constructs an igraph graph where nodes are formal objects and edges
#' represent co-occurrence within the same claim. Edge weights encode the
#' number of claims where both objects appear together.
#'
#' @param claim_objects Named list of character vectors — each element is a
#'   claim ID, and the value is the character vector of extracted objects.
#'
#' @return An igraph object with node attributes \code{type}, \code{stability},
#'   and \code{risk_flag} (initially NA — filled by the caller).
#'
#' @importFrom igraph graph_from_edgelist simplify E
#' @keywords internal
build_semiotic_network <- function(claim_objects) {
  # Collect all unique objects
  all_objects <- unique(unlist(claim_objects, use.names = FALSE))

  # Build edge list from co-occurrence within claims
  edge_list <- list()
  for (co in claim_objects) {
    if (length(co) >= 2) {
      # Create all pairwise combinations
      pairs <- combn(co, 2, simplify = FALSE)
      for (p in pairs) {
        key <- paste(sort(p), collapse = "||")
        if (is.null(edge_list[[key]])) {
          edge_list[[key]] <- list(from = p[1], to = p[2], weight = 0)
        }
        edge_list[[key]]$weight <- edge_list[[key]]$weight + 1
      }
    }
  }

  if (length(edge_list) == 0) {
    # No edges — return single-node graph
    g <- igraph::make_empty_graph(n = 0, directed = FALSE)
    return(g)
  }

  # Build edge matrix
  el <- do.call(rbind, lapply(edge_list, function(x) {
    data.frame(from = x$from, to = x$to, weight = x$weight,
               stringsAsFactors = FALSE)
  }))
  rownames(el) <- NULL

  g <- igraph::graph_from_data_frame(el, vertices = unique(all_objects),
                                      directed = FALSE)
  g <- igraph::simplify(g, edge.attr.comb = list(weight = "sum", "ignore"))

  # Initialize node attributes
  igraph::V(g)$type <- NA_character_
  igraph::V(g)$stability <- NA_real_
  igraph::V(g)$risk_flag <- FALSE

  g
}


#' Compute semiotic stability for an object across claims
#'
#' Stability measures how consistently an object is typed across all claims
#' where it appears. Value ranges from 0 (totally unstable — different types
#' in every claim) to 1 (perfectly stable — same type in every claim).
#'
#' @param types_per_claim Named character vector — the type labels assigned
#'   to the object in each claim.
#'
#' @return A numeric stability score between 0 and 1.
#' @keywords internal
compute_stability <- function(types_per_claim) {
  if (length(types_per_claim) <= 1) return(1.0)

  # Count type frequencies
  tbl <- table(types_per_claim)
  dominant <- max(tbl)
  total <- length(types_per_claim)

  # Stability = proportion of claims with the dominant type
  dominant / total
}


#' Detect semiosis risk for an object
#'
#' Semiosis risk is flagged when:
#' 1. The object is typed differently across claims (type instability)
#' 2. The object's confidence is low (< 0.6)
#' 3. The object has close alternative types
#'
#' @param stability Numeric — stability score from \code{\link{compute_stability}}.
#' @param confidence Numeric — classification confidence.
#' @param alternatives Character vector — alternative types that could apply.
#'
#' @return Logical — \code{TRUE} if semiosis risk is detected.
#' @keywords internal
detect_semiosis_risk <- function(stability, confidence, alternatives) {
  risk <- FALSE

  # Type instability across claims
  if (stability < 0.7) risk <- TRUE

  # Low classification confidence
  if (confidence < 0.6) risk <- TRUE

  # Close alternatives
  if (length(alternatives) > 0) risk <- TRUE

  risk
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Evaluate a target using Layer 5 — Semiotic Analysis
#'
#' Extracts formal objects from the target's claims, classifies each as
#' **icon**, **index**, or **symbol** using Peircean semiotics, builds a
#' semiotic network topology, and returns a structured \code{\link{LayerResult}}
#' with a scores matrix of \code{object × (type, stability, risk_flag)}.
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object.
#' @param axiom_set An \code{\link{AxiomSet}} R6 object. Used for the
#'   dimensionality of the result; not directly consulted for semiotic analysis.
#' @param fc An \code{fcaR::FormalContext} R6 object. Used for attribute
#'   context in semiotic typing; the attributes column names are used as
#'   additional domain terms.
#'
#' @return A \code{\link{LayerResult}} R6 object with:
#'   \describe{
#'     \item{scores}{A matrix with one row per formal object and columns:
#'           \code{type} (character), \code{stability} (numeric 0-1),
#'           \code{risk_flag} (logical).}
#'     \item{flags}{A list with keys \code{semiotic_network} (igraph object),
#'           \code{object_count}, \code{risk_count}, \code{type_distribution},
#'           and \code{semiosis_risks} (detailed list of risk objects).}
#'   }
#'
#' @examples
#' \donttest{
#' target <- make_gard_target()
#' ax <- make_test_axiom_set()
#' fc <- make_test_context()
#' result <- evaluate_layer5(target, ax, fc)
#' print(result$scores)
#' }
#'
#' @export
evaluate_layer5 <- function(target, axiom_set, fc) {

  # -- Validate inputs --
  stopifnot(inherits(target, "EvaluationTarget"))
  stopifnot(inherits(axiom_set, "AxiomSet"))
  stopifnot(inherits(fc, "FormalContext"))

  # -- Extract domain terms from the formal context and axiom set --
  domain_terms <- c(
    colnames(fc$I),
    rownames(fc$I),
    unlist(axiom_set$domain_mapping, use.names = FALSE),
    axiom_set$objects,
    axiom_set$attributes
  )

  # -- Extract formal objects from each claim --
  claim_objects <- list()
  object_classifications <- list()  # object -> list of (type, confidence, alt, claim_id)

  for (claim in target$claims) {
    cid <- claim$id
    text <- claim$text
    evidence <- claim$evidence
    register <- claim$register

    # Extract objects from claim text
    objects <- extract_formal_objects(text, domain_terms)

    # Also extract from evidence
    if (!is.null(evidence) && nchar(evidence) > 0) {
      ev_objects <- extract_formal_objects(evidence, domain_terms)
      objects <- unique(c(objects, ev_objects))
    }

    claim_objects[[cid]] <- objects

    # Classify each object
    for (obj in objects) {
      cls <- classify_semiotic_type(obj, evidence, register)
      if (is.null(object_classifications[[obj]])) {
        object_classifications[[obj]] <- list()
      }
      object_classifications[[obj]][[cid]] <- cls
    }
  }

  # -- Build semiotic network --
  g <- build_semiotic_network(claim_objects)

  # -- Compute per-object metrics --
  all_objects <- unique(unlist(claim_objects, use.names = FALSE))
  n_objects <- length(all_objects)

  if (n_objects == 0) {
    # No objects found — return empty result
    scores <- matrix(NA_character_, nrow = 0, ncol = 3,
                     dimnames = list(NULL, c("type", "stability", "risk_flag")))

    result <- LayerResult$new(
      layer = 5L,
      layer_name = "Semiotic Analysis",
      scores = scores,
      gap_diagnosis = "No formal objects extracted from claims",
      flags = list(
        semiotic_network = g,
        object_count = 0L,
        risk_count = 0L,
        type_distribution = c(icon = 0L, index = 0L, symbol = 0L),
        semiosis_risks = list()
      ),
      notes = "Cannot perform semiotic analysis on empty claim set."
    )
    return(result)
  }

  types <- character(n_objects)
  stabilities <- numeric(n_objects)
  risk_flags <- logical(n_objects)
  risk_details <- list()

  for (i in seq_along(all_objects)) {
    obj <- all_objects[i]
    classifications <- object_classifications[[obj]]
    type_per_claim <- sapply(classifications, function(c) c$type)
    confidence_per_claim <- sapply(classifications, function(c) c$confidence)
    alternatives_per_claim <- unlist(lapply(classifications, function(c) c$alternatives))
    alternatives_per_claim <- unique(alternatives_per_claim)

    # Primary type: majority vote across claims
    type_tbl <- table(type_per_claim)
    primary_type <- names(which.max(type_tbl))
    types[i] <- primary_type

    # Stability: how consistently typed across claims
    stabilities[i] <- compute_stability(type_per_claim)

    # Average confidence
    avg_confidence <- mean(confidence_per_claim)

    # Semiosis risk
    risk_flags[i] <- detect_semiosis_risk(stabilities[i], avg_confidence,
                                           alternatives_per_claim)

    if (risk_flags[i]) {
      risk_details[[obj]] <- list(
        type = primary_type,
        stability = stabilities[i],
        confidence = avg_confidence,
        alternatives = alternatives_per_claim,
        type_distribution = as.list(type_tbl)
      )
    }

    # Update node attributes in the graph
    if (igraph::vcount(g) > 0 && obj %in% igraph::V(g)$name) {
      idx <- which(igraph::V(g)$name == obj)
      igraph::V(g)[idx]$type <- primary_type
      igraph::V(g)[idx]$stability <- stabilities[i]
      igraph::V(g)[idx]$risk_flag <- risk_flags[i]
    }
  }

  # -- Build scores matrix --
  scores <- cbind(
    type = types,
    stability = as.character(round(stabilities, 3)),
    risk_flag = ifelse(risk_flags, "TRUE", "FALSE")
  )
  rownames(scores) <- all_objects
  colnames(scores) <- c("type", "stability", "risk_flag")

  # -- Type distribution --
  type_dist <- table(types)
  type_dist_full <- c(
    icon = unname(ifelse("icon" %in% names(type_dist), type_dist["icon"], 0)),
    index = unname(ifelse("index" %in% names(type_dist), type_dist["index"], 0)),
    symbol = unname(ifelse("symbol" %in% names(type_dist), type_dist["symbol"], 0))
  )
  names(type_dist_full) <- c("icon", "index", "symbol")

  # -- Gap diagnosis --
  risk_count <- sum(risk_flags)
  gap_diagnosis <- NULL
  if (risk_count > 0) {
    gap_diagnosis <- sprintf(
      "%d of %d objects (%d%%) flagged for semiosis risk",
      risk_count, n_objects, as.integer(100 * risk_count / n_objects)
    )
  }

  # -- Build LayerResult --
  result <- LayerResult$new(
    layer = 5L,
    layer_name = "Semiotic Analysis",
    scores = scores,
    gap_diagnosis = gap_diagnosis,
    remediation = NULL,
    flags = list(
      semiotic_network = g,
      object_count = as.integer(n_objects),
      risk_count = as.integer(risk_count),
      type_distribution = type_dist_full,
      semiosis_risks = risk_details
    ),
    notes = sprintf(
      "Semiotic analysis: %d objects across %d claims. Type distribution: icon=%d, index=%d, symbol=%d.",
      n_objects, length(target$claims),
      type_dist_full["icon"], type_dist_full["index"], type_dist_full["symbol"]
    )
  )

  result
}