# ---------------------------------------------------------------------------
# layer4-compression.R — Layer 4: Compression Taxonomy
#
# Detects and measures 5 compression operations in research claims, audits
# reversibility via fcaR closure (A'' = A test), and flags Counter-RL
# (Reverse Language) bias — vocabulary importing source-domain connotations
# that don't apply in the target domain.
#
# The reversibility audit uses Formal Concept Analysis: given a set of
# attribute-assigned objects, the closure A'' = (A')' maps A to the set of
# all attributes shared by all objects that share all of A's attributes.
# If A'' = A (closure equals original), the compression is information-
# theoretically lossless.  The size of A'' \ A measures information loss.
#
# Compression operations:
#   1. Aggregation       — multiple distinct items compressed into one object
#   2. Abstraction       — specific instances compressed into a category
#   3. Idealization      — real-world complexity compressed into a model
#   4. Narrative         — mechanistic detail compressed into a story
#   5. Vocabulary        — terms from one domain compressed into another
#
# LayerResult output:
#   $scores       — named numeric vector, one per detected compression type
#                   (score = confidence that the operation is present, [0,1])
#   $flags$counter_rl — named logical vector of Counter-RL bias flags
#   $flags$reversibility — named list:
#       $closure_original:  set_representation of the original A
#       $closure_closed:    set_representation of A''
#       $lossless:          logical — TRUE iff A'' == A
#       $info_loss_n:       integer — |A'' \ A|
#       $info_loss_items:   character vector of attributes lost/gained
#   $gap_diagnosis — textual summary of compression reversibility
# ---------------------------------------------------------------------------

#' Detect compression operations in a target's claims
#'
#' Analyses the text of each claim for the five compression operations
#' defined by the INFERNO Compression Taxonomy.
#'
#' @param target An \code{\link{EvaluationTarget}} object.
#'
#' @return A named numeric vector of length 5 with values in [0, 1],
#'   each representing the detection confidence for that operation.
#'
#' @keywords internal
detect_compression_operations <- function(target) {
  if (length(target$claims) == 0L) {
    return(c(
      aggregation    = 0,
      abstraction    = 0,
      idealization   = 0,
      narrative      = 0,
      vocabulary     = 0
    ))
  }

  # Concatenate claim texts for pattern matching
  texts <- vapply(target$claims, function(cl) cl$text, character(1L))
  evidence <- vapply(target$claims, function(cl) {
    if (is.null(cl$evidence)) "" else cl$evidence
  }, character(1L))
  all_text <- paste(c(texts, evidence), collapse = " ")

  # Patterns indicative of each compression type — deliberately inclusive;
  # scores are fraction of total claims that trigger at least one trigger phrase.
  n <- length(target$claims)

  # 1. Aggregation: lumping multiple items into one object
  agg_patterns <- c(
    "\\bcollectively\\b", "\\baggregate\\b", "\\bcomposite\\b",
    "\\bsystem\\b", "\\bensemble\\b", "\\bbundle\\b",
    "\\bcluster\\b", "\\baggregation\\b", "\\bset of\\b",
    "\\bunified\\b", "\\bcombine\\b", "\\bintegrated\\b"
  )
  agg_score <- sum(vapply(target$claims, function(cl) {
    any(vapply(agg_patterns, function(p) grepl(p, cl$text, ignore.case = TRUE),
               logical(1L)))
  }, logical(1L))) / n

  # 2. Abstraction: specific instances compressed into a category
  abs_patterns <- c(
    "\\bin general\\b", "\\babstract\\b", "\\bcategory\\b",
    "\\bclass of\\b", "\\btype of\\b", "\\bkind of\\b",
    "\\bgeneric\\b", "\\bprototypical\\b", "\\brepresentative\\b",
    "\\bparadigm\\b", "\\btemplate\\b", "\\bfamily of\\b"
  )
  abs_score <- sum(vapply(target$claims, function(cl) {
    any(vapply(abs_patterns, function(p) grepl(p, cl$text, ignore.case = TRUE),
               logical(1L)))
  }, logical(1L))) / n

  # 3. Idealization: real-world complexity simplified into a model
  ide_patterns <- c(
    "\\bidealize\\b", "\\bidealized\\b", "\\bapproximate\\b",
    "\\bsimplif(y|ied|ies|ication)\\b", "\\bin the limit\\b",
    "\\bperfect\\b", "\\bfrictionless\\b", "\\bwithout loss\\b",
    "\\btoy model\\b", "\\bcaricature\\b", "\\breduced\\b",
    "\\bassum(e|ing|ption)\\b", "\\bceteris paribus\\b",
    "\\bideal case\\b", "\\bidealization\\b"
  )
  ide_score <- sum(vapply(target$claims, function(cl) {
    any(vapply(ide_patterns, function(p) grepl(p, cl$text, ignore.case = TRUE),
               logical(1L)))
  }, logical(1L))) / n

  # 4. Narrative compression: mechanistic detail → story
  nar_patterns <- c(
    "\\bnarrative\\b", "\\bstory\\b", "\\btrajectory\\b",
    "\\bemergence\\b", "\\bunfolds?\\b", "\\bjourney\\b",
    "\\bfrom .* to\\b", "\\blue?\\b", "\\bpath\\b",
    "\\borigin\\b", "\\bevolution\\b", "\\bfate\\b",
    "\\btransition\\b", "\\bscenario\\b", "\\btimeline\\b"
  )
  nar_score <- sum(vapply(target$claims, function(cl) {
    any(vapply(nar_patterns, function(p) grepl(p, cl$text, ignore.case = TRUE),
               logical(1L)))
  }, logical(1L))) / n

  # 5. Vocabulary transfer: source-domain terms in target domain
  voc_patterns <- c(
    "\\bgenome\\b", "\\bvocabulary\\b", "\\btransfer\\b",
    "\\bborrow.*term\\b", "\\bimport\\b", "\\bmetaphor\\b",
    "\\banalogy\\b", "\\bmapped (to|onto)\\b",
    "\\btranslat(e|ion)\\b", "\\bmigration\\b",
    "\\bcompositional genome\\b"
  )
  voc_score <- sum(vapply(target$claims, function(cl) {
    any(vapply(voc_patterns, function(p) grepl(p, cl$text, ignore.case = TRUE),
               logical(1L)))
  }, logical(1L))) / n

  c(
    aggregation    = agg_score,
    abstraction    = abs_score,
    idealization   = ide_score,
    narrative      = nar_score,
    vocabulary     = voc_score
  )
}


#' Detect Counter-RL (Reverse Language) bias in claims
#'
#' Flags vocabulary that imports connotations from a source domain that may
#' not apply in the target domain.  For example, calling a lipid assembly
#' a "compositional genome" imports genomic connotations (replication,
#' mutation, transcription) that may not hold for the assembly itself.
#'
#' @param target An \code{\link{EvaluationTarget}} object.
#'
#' @return A named logical vector of bias flags, one per checked term.
#'
#' @keywords internal
detect_counter_rl_bias <- function(target) {
  if (length(target$claims) == 0L) {
    return(c(
      compositional_genome = FALSE,
      darwinian_evolution  = FALSE,
      artificial_intelligence = FALSE,
      information_processing  = FALSE,
      computation             = FALSE,
      language                = FALSE,
      learning                = FALSE,
      memory                  = FALSE,
      natural_selection       = FALSE,
      code                    = FALSE
    ))
  }

  texts <- vapply(target$claims, function(cl) cl$text, character(1L))
  all_text <- paste(texts, collapse = " ")

  # Source-domain terms that carry disanalogous connotations
  flags <- c(
    compositional_genome  = grepl("compositional genome|composome",
                                  all_text, ignore.case = TRUE),
    darwinian_evolution   = grepl("darwinian|natural selection|heritable",
                                  all_text, ignore.case = TRUE),
    artificial_intelligence = grepl("artificial intelligence|AI",
                                    all_text, ignore.case = TRUE),
    information_processing  = grepl("information (processing|storage|transfer)",
                                    all_text, ignore.case = TRUE),
    computation             = grepl("\\bcomput(e|ation|er)\\b",
                                    all_text, ignore.case = TRUE),
    language                = grepl("\\blanguage\\b",
                                    all_text, ignore.case = TRUE),
    learning                = grepl("\\blearn(ing)?\\b",
                                    all_text, ignore.case = TRUE),
    memory                  = grepl("\\bmemory\\b",
                                    all_text, ignore.case = TRUE),
    natural_selection       = grepl("natural selection|selective advantage",
                                    all_text, ignore.case = TRUE),
    code                    = grepl("\\bcode\\b",
                                    all_text, ignore.case = TRUE)
  )

  flags
}


#' Example: evaluate reversibility using fcaR closure
#'
#' The closure test: given a formal context (fc), compute A'' for each
#' compression-relevant attribute set and compare to the original set A.
#' If A'' == A (lossless), the compression preserves all information.
#' If A'' != A, the symmetric difference |A'' Δ A| measures information flux.
#'
#' @param target An \code{\link{EvaluationTarget}} object (used to derive
#'   attribute sets relevant to the target's claims).
#' @param fc An optional \code{fcaR::FormalContext} object.  If \code{NULL}
#'   and \code{axiom_set} is provided, one will be derived.
#' @param axiom_set An optional \code{\link{AxiomSet}}.  One of \code{fc} or
#'   \code{axiom_set} must be supplied.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{lossless}{logical — TRUE iff A'' == A for every tested set}
#'     \item{info_loss_n}{integer — total count of attributes added/removed
#'       across all tested sets}
#'     \item{info_loss_items}{character vector describing what was lost/gained}
#'     \item{tests}{list of per-set closure test results}
#'   }
#'
#' @importFrom fcaR Set FormalContext
#'
#' @keywords internal
evaluate_reversibility <- function(target, fc = NULL, axiom_set = NULL) {
  # Resolve the formal context
  if (is.null(fc)) {
    if (is.null(axiom_set)) {
      stop("evaluate_reversibility requires either 'fc' or 'axiom_set'")
    }
    fc <- axiom_set$to_formal_context()
  }

  attrs <- fc$attributes

  if (length(attrs) == 0L || nrow(fc$I) == 0L) {
    return(list(
      lossless       = TRUE,
      info_loss_n    = 0L,
      info_loss_items = character(0L),
      tests          = list()
    ))
  }

  # Derive attribute relevance from the target's claims
  claim_attrs <- character(0L)
  if (length(target$claims) > 0L) {
    texts <- vapply(target$claims, function(cl) cl$text, character(1L))
    all_text <- paste(texts, collapse = " ")

    # Which INFERNO attributes are touched by this target's language?
    for (attr in attrs) {
      # Match attr name parts against claim text
      parts <- strsplit(attr, "[-_]")[[1L]]
      if (any(vapply(parts, function(p) {
        nchar(p) >= 3L && grepl(p, all_text, ignore.case = TRUE)
      }, logical(1L)))) {
        claim_attrs <- c(claim_attrs, attr)
      }
    }
  }

  # If nothing matched, use at least the first attribute as a baseline test
  if (length(claim_attrs) == 0L) {
    claim_attrs <- attrs[1L]
  }

  # Compute closures for each singleton and for the full claim set
  # NOTE: fcaR::Set$new(attributes = ...) creates a Set whose universe is
  # given by the `attributes` parameter.  fc$closure(S) requires that
  # the Set S has fc$attributes as its universe.  Moreover, the R6
  # $assign() method returns NULL in fcaR 1.5, so we MUST NOT chain:
  # we create the Set first, then assign on the next line.
  tests <- list()

  for (a in claim_attrs) {
    # NOTE: fcaR::Set$assign(attributes =, values =) requires explicit
    # attributes= parameter — positional unquoted args go to ... and
    # are handled only when named.  Unnamed positional assignment is a no-op.
    S <- fcaR::Set$new(attributes = attrs)
    S$assign(attributes = a, values = 1)
    S_closed <- fc$closure(S)
    is_lossless <- S %==% S_closed

    # Determine symmetric difference
    s_attrs <- names(which(as.logical(S$get_vector())))
    sc_attrs <- names(which(as.logical(S_closed$get_vector())))

    gained <- setdiff(sc_attrs, s_attrs)
    lost   <- setdiff(s_attrs, sc_attrs)

    tests[[a]] <- list(
      attribute      = a,
      original       = s_attrs,
      closed         = sc_attrs,
      lossless       = is_lossless,
      gained         = gained,
      lost           = lost,
      info_loss_n    = length(gained) + length(lost)
    )
  }

  # Also test the full set of matched attributes (the "claim concept")
  if (length(claim_attrs) > 1L) {
    S_full <- fcaR::Set$new(attributes = attrs)
    S_full$assign(attributes = claim_attrs,
                  values = rep(1, length(claim_attrs)))
    S_full_closed <- fc$closure(S_full)
    is_full_lossless <- S_full %==% S_full_closed

    full_attrs <- names(which(as.logical(S_full$get_vector())))
    full_closed_attrs <- names(which(as.logical(S_full_closed$get_vector())))

    gained_full <- setdiff(full_closed_attrs, full_attrs)
    lost_full   <- setdiff(full_attrs, full_closed_attrs)

    tests[["(claim_concept)"]] <- list(
      attribute    = "(claim_concept)",
      original     = full_attrs,
      closed       = full_closed_attrs,
      lossless     = is_full_lossless,
      gained       = gained_full,
      lost         = lost_full,
      info_loss_n  = length(gained_full) + length(lost_full)
    )
  }

  # Aggregate
  total_info_loss <- sum(vapply(tests, `[[`, integer(1L), "info_loss_n"))
  all_lossless <- all(vapply(tests, `[[`, logical(1L), "lossless"))
  info_items <- character(0L)
  for (t in tests) {
    if (length(t$gained) > 0L) {
      info_items <- c(info_items,
        sprintf("%s gained {%s}", t$attribute,
                paste(t$gained, collapse = ", ")))
    }
    if (length(t$lost) > 0L) {
      info_items <- c(info_items,
        sprintf("%s lost {%s}", t$attribute,
                paste(t$lost, collapse = ", ")))
    }
  }

  list(
    lossless        = all_lossless,
    info_loss_n     = total_info_loss,
    info_loss_items = info_items,
    tests           = tests
  )
}


#' Evaluate Layer 4: Compression Taxonomy
#'
#' Analyses an evaluation target for the five compression operations, audits
#' reversibility via fcaR closure (A'' = A test), and flags Counter-RL
#' (Reverse Language) bias in transferred vocabulary.
#'
#' @param target An \code{\link{EvaluationTarget}} — the artifact whose claims
#'   are analysed for compression operations.
#' @param axiom_set An \code{\link{AxiomSet}} providing the formal context
#'   and metric for the reversibility audit.
#' @param fc An optional pre-computed \code{fcaR::FormalContext}.  If
#'   \code{NULL}, one will be derived from \code{axiom_set}.
#'
#' @return A \code{\link{LayerResult}} with:
#'   \describe{
#'     \item{scores}{Named numeric vector of 5 compression detection
#'       scores in [0, 1].}
#'     \item{flags$counter_rl}{Named logical vector of Counter-RL bias flags.}
#'     \item{flags$reversibility}{List of reversibility audit results.}
#'     \item{gap_diagnosis}{Character — lossless/lossy summary from the
#'       closure audit.}
#'     \item{notes}{Character — human-readable compression overview.}
#'   }
#'
#' @export
evaluate_layer4 <- function(target, axiom_set = NULL, fc = NULL) {
  # ---- Resolve formal context ----
  if (is.null(fc) && !is.null(axiom_set)) {
    fc <- axiom_set$to_formal_context()
  }

  # ---- 1. Detect compression operations ----
  compression_scores <- detect_compression_operations(target)

  # ---- 2. Detect Counter-RL bias ----
  bias_flags <- detect_counter_rl_bias(target)

  # ---- 3. Reversibility audit via fcaR closure ----
  if (!is.null(fc)) {
    rev_audit <- evaluate_reversibility(target, fc = fc)
  } else {
    rev_audit <- list(
      lossless        = TRUE,
      info_loss_n     = 0L,
      info_loss_items = character(0L),
      tests           = list()
    )
  }

  # ---- 4. Build gap diagnosis ----
  if (rev_audit$lossless) {
    gap_diag <- "All tested attribute closures are lossless (A'' = A)."
  } else {
    gap_diag <- sprintf(
      "Lossy compression detected: %d attribute(s) change under closure. %s",
      rev_audit$info_loss_n,
      if (length(rev_audit$info_loss_items) > 0L)
        paste(rev_audit$info_loss_items, collapse = "; ") else ""
    )
  }

  # ---- 5. Notes ----
  detected <- names(compression_scores[compression_scores > 0])
  bias_flagged <- names(bias_flags[bias_flags])
  notes <- sprintf(
    "Compression operations detected: %d/5 (%s). Counter-RL flags: %d/10 (%s).",
    length(detected),
    if (length(detected) > 0L) paste(detected, collapse = ", ") else "none",
    length(bias_flagged),
    if (length(bias_flagged) > 0L) paste(bias_flagged, collapse = ", ") else "none"
  )

  # ---- 6. Assemble LayerResult ----
  LayerResult$new(
    layer         = 4L,
    layer_name    = "Compression Taxonomy",
    scores        = compression_scores,
    gap_diagnosis = gap_diag,
    remediation   = NULL,
    flags         = list(
      counter_rl     = bias_flags,
      reversibility  = rev_audit
    ),
    notes         = notes
  )
}


#' Compute a canonical hash for an incidence matrix
#'
#' Sorts rows and columns lexicographically before hashing so that the
#' digest is invariant under permutation of objects and attributes.
#'
#' @param incidence A numeric matrix (0/1 or continuous) with dimnames.
#'
#' @return A character xxhash64 digest string.
#'
#' @export
compute_hash <- function(incidence) {
  stopifnot(is.matrix(incidence))
  rn <- sort(rownames(incidence))
  cn <- sort(colnames(incidence))
  mat <- incidence[rn, cn, drop = FALSE]
  digest::digest(mat, algo = "xxhash64")
}
