#' DuckDB persistence layer for the INFERNO evaluation protocol
#'
#' Provides the analytical persistence layer for INFERNO-R, using an embedded
#' DuckDB database via the \pkg{DBI} and \pkg{duckdb} packages. Six core tables
#' store axiom sets, evaluation targets, claims, evaluations, layer results,
#' and normalized layer scores. Content-addressable hashing (\code{xxhash64})
#' ensures idempotent inserts throughout.
#'
#' \strong{Hot path:} WCI composite scores and layer scores are stored as
#' first-class columns, enabling SQL aggregate queries without deserialization.
#' \strong{Cold path:} Full incidence matrices are stored as serialized BLOBs,
#' hydrated on demand via \code{\link{load_axiom_set}}.
#'
#' @section Schema:
#' See the architecture specification (\code{inferno-r-architecture-spec.md})
#' Section 4 for the full DDL, indexes, and key analytical queries.
#'
#' @name duckdb-store
#' @keywords internal
"_PACKAGE"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Compute a target_id from an EvaluationTarget
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object.
#'
#' @return A character xxhash64 digest.
#' @keywords internal
compute_target_id <- function(target) {
  raw <- paste(
    target$title,
    paste(if (is.null(target$authors)) "" else target$authors,
          collapse = "|"),
    if (is.null(target$year)) "" else as.character(target$year)
  )
  digest::digest(raw, algo = "xxhash64")
}

#' Compute an eval_id from an EvaluationResult
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#'
#' @return A character xxhash64 digest.
#' @keywords internal
compute_eval_id <- function(result) {
  target_id <- compute_target_id(result$target)
  ts <- if (is.null(result$session_info$timestamp)) {
    format(Sys.time(), "%Y%m%d%H%M%S")
  } else {
    format(result$session_info$timestamp, "%Y%m%d%H%M%S")
  }
  raw <- paste(target_id, result$axiom_set$context_hash, ts)
  digest::digest(raw, algo = "xxhash64")
}

#' Flatten a scores matrix or named vector to a data frame
#'
#' Converts the \code{scores} field of a \code{\link{LayerResult}} into the
#' long-format rows expected by the \code{layer_scores} table.
#'
#' @param scores A matrix (levels \eqn{\times} dimensions) or a named numeric/
#'   character vector.
#'
#' @return A data frame with columns \code{level}, \code{dimension},
#'   \code{score} (character). Zero rows if the input is unsupported.
#' @keywords internal
flatten_scores <- function(scores) {
  if (is.null(scores) || length(scores) == 0) {
    return(data.frame(
      level = character(0), dimension = character(0),
      score = character(0), stringsAsFactors = FALSE
    ))
  }

  if (is.matrix(scores)) {
    lvls <- rownames(scores)
    dims <- colnames(scores)
    if (is.null(lvls)) lvls <- paste0("L", seq_len(nrow(scores)))
    if (is.null(dims)) dims <- paste0("D", seq_len(ncol(scores)))

    result <- data.frame(
      level = rep(lvls, times = length(dims)),
      dimension = rep(dims, each = length(lvls)),
      score = as.character(scores),
      stringsAsFactors = FALSE
    )
    return(result)
  }

  if (is.vector(scores) && !is.null(names(scores))) {
    rows <- lapply(names(scores), function(nm) {
      parts <- strsplit(nm, "_")[[1]]
      if (length(parts) >= 2) {
        data.frame(
          level = parts[1],
          dimension = paste(parts[-1], collapse = "_"),
          score = as.character(scores[nm]),
          stringsAsFactors = FALSE
        )
      } else {
        data.frame(
          level = "L1",
          dimension = nm,
          score = as.character(scores[nm]),
          stringsAsFactors = FALSE
        )
      }
    })
    return(do.call(rbind, rows))
  }

  data.frame(
    level = character(0), dimension = character(0),
    score = character(0), stringsAsFactors = FALSE
  )
}

#' Reconstruct a LayerResult from database rows
#'
#' @param lr_row A single-row data frame from the \code{layer_results} table.
#' @param score_rows A data frame of matching rows from \code{layer_scores}.
#'
#' @return A \code{\link{LayerResult}} R6 object.
#' @keywords internal
hydrate_layer_result <- function(lr_row, score_rows) {
  # Rebuild scores matrix from long format
  if (nrow(score_rows) > 0) {
    lvls <- unique(score_rows$level)
    dims <- unique(score_rows$dimension)
    mat <- matrix(score_rows$score,
                  nrow = length(lvls), ncol = length(dims),
                  dimnames = list(lvls, dims),
                  byrow = FALSE)
  } else {
    mat <- NULL
  }

  LayerResult$new(
    layer = as.integer(lr_row$layer),
    layer_name = lr_row$layer_name,
    scores = mat,
    gap_diagnosis = lr_row$gap_diagnosis,
    remediation = if (is.null(lr_row$remediation) ||
                      is.na(lr_row$remediation) ||
                      nchar(lr_row$remediation) == 0) {
      NULL
    } else {
      jsonlite::fromJSON(lr_row$remediation, simplifyVector = FALSE)
    },
    flags = if (is.null(lr_row$flags) ||
                is.na(lr_row$flags) ||
                nchar(lr_row$flags) == 0) {
      list()
    } else {
      jsonlite::fromJSON(lr_row$flags, simplifyVector = FALSE)
    },
    notes = lr_row$notes
  )
}

# ---------------------------------------------------------------------------
# Public functions
# ---------------------------------------------------------------------------

#' Initialize the DuckDB schema
#'
#' Creates all six core tables and supporting indexes if they do not already
#' exist. Safe to call multiple times (uses \code{IF NOT EXISTS}).
#'
#' @param conn A DBI database connection (typically from
#'   \code{DBI::dbConnect(duckdb::duckdb())}).
#'
#' @return \code{NULL}, invisibly. Called for side effects.
#'
#' @examples
#' \dontrun{
#' conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
#' init_db(conn)
#' }
#'
#' @export
init_db <- function(conn) {
  # -- 6 core tables -------------------------------------------------------
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS axiom_sets (
        context_hash    VARCHAR PRIMARY KEY,
        num_objects     INTEGER NOT NULL,
        num_attributes  INTEGER NOT NULL,
        density         DOUBLE NOT NULL,
        concept_count   INTEGER,
        implication_count INTEGER,
        lattice_depth   INTEGER,
        metric          VARCHAR DEFAULT 'js',
        domain_mapping  TEXT,
        created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        incidence_blob  BLOB
    )
  ")

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS targets (
        target_id       VARCHAR PRIMARY KEY,
        artifact_type   VARCHAR NOT NULL,
        title           VARCHAR NOT NULL,
        authors         VARCHAR,
        year            INTEGER,
        doi             VARCHAR,
        domain_dims     TEXT,
        created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ")

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS claims (
        claim_id        VARCHAR PRIMARY KEY,
        target_id       VARCHAR NOT NULL REFERENCES targets(target_id),
        local_id        VARCHAR NOT NULL,
        text            TEXT NOT NULL,
        evidence        TEXT,
        register        VARCHAR DEFAULT 'unclear',
        m_failure       VARCHAR,
        UNIQUE(target_id, local_id)
    )
  ")

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS evaluations (
        eval_id             VARCHAR PRIMARY KEY,
        target_id           VARCHAR NOT NULL REFERENCES targets(target_id),
        axiom_set_hash      VARCHAR NOT NULL REFERENCES axiom_sets(context_hash),
        wci_composite       DOUBLE NOT NULL,
        wci_theoretical     DOUBLE NOT NULL,
        wci_empirical       DOUBLE NOT NULL,
        wci_replicability   DOUBLE NOT NULL,
        wci_uptake          DOUBLE NOT NULL,
        wci_explanatory     DOUBLE NOT NULL,
        wci_falsifiability  DOUBLE NOT NULL,
        overall             TEXT,
        r_version           VARCHAR,
        seed                INTEGER,
        timestamp           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(target_id, axiom_set_hash, timestamp)
    )
  ")

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS layer_results (
        eval_id         VARCHAR NOT NULL REFERENCES evaluations(eval_id),
        layer           INTEGER NOT NULL,
        layer_name      VARCHAR NOT NULL,
        gap_diagnosis   TEXT,
        remediation     TEXT,
        flags           TEXT,
        notes           TEXT,
        PRIMARY KEY (eval_id, layer)
    )
  ")

  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS layer_scores (
        eval_id         VARCHAR NOT NULL,
        layer           INTEGER NOT NULL,
        level           VARCHAR NOT NULL,
        dimension       VARCHAR NOT NULL,
        score           VARCHAR NOT NULL,
        PRIMARY KEY (eval_id, layer, level, dimension),
        FOREIGN KEY (eval_id) REFERENCES evaluations(eval_id)
    )
  ")

  # -- Indexes (with IF NOT EXISTS guard via CREATE INDEX IF NOT EXISTS) ---
  DBI::dbExecute(conn, "
    CREATE INDEX IF NOT EXISTS idx_eval_target
    ON evaluations(target_id)
  ")
  DBI::dbExecute(conn, "
    CREATE INDEX IF NOT EXISTS idx_eval_axiom
    ON evaluations(axiom_set_hash)
  ")
  DBI::dbExecute(conn, "
    CREATE INDEX IF NOT EXISTS idx_eval_wci
    ON evaluations(wci_composite)
  ")
  DBI::dbExecute(conn, "
    CREATE INDEX IF NOT EXISTS idx_layer_scores_score
    ON layer_scores(score)
  ")
  DBI::dbExecute(conn, "
    CREATE INDEX IF NOT EXISTS idx_claims_mfailure
    ON claims(m_failure)
  ")

  invisible(NULL)
}


#' Persist an AxiomSet to the database
#'
#' Idempotent insert: if an axiom set with the same \code{context_hash} already
#' exists, the insert is silently skipped (via \code{ON CONFLICT DO NOTHING}).
#' The incidence matrix is serialized via \code{base::serialize()} and stored
#' as a BLOB. Density is computed as \code{sum(I > 0) / length(I)}.
#'
#' @param ax An \code{\link{AxiomSet}} R6 object.
#' @param conn A DBI database connection.
#'
#' @return The \code{context_hash} (invisibly), or \code{NULL} if the insert
#'   was skipped due to conflict.
#'
#' @examples
#' \dontrun{
#' I <- matrix(c(1,0,0,1), nrow = 2,
#'             dimnames = list(c("a", "b"), c("x", "y")))
#' ax <- AxiomSet$new(I, c("a", "b"), c("x", "y"))
#' persist_axiom_set(ax, conn)
#' }
#'
#' @export
persist_axiom_set <- function(ax, conn) {
  incidence_blob <- serialize(ax$incidence, NULL)
  density <- sum(ax$incidence > 0) / length(ax$incidence)

  domain_json <- if (is.null(ax$domain_mapping)) {
    NA_character_
  } else {
    jsonlite::toJSON(ax$domain_mapping, auto_unbox = TRUE)
  }

  rows <- DBI::dbExecute(conn,
    "INSERT INTO axiom_sets
       (context_hash, num_objects, num_attributes, density,
        metric, domain_mapping, incidence_blob)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT (context_hash) DO NOTHING",
    params = list(
      ax$context_hash,
      as.integer(length(ax$objects)),
      as.integer(length(ax$attributes)),
      density,
      ax$metric,
      domain_json,
      list(incidence_blob)
    )
  )

  if (rows == 0) invisible(NULL) else invisible(ax$context_hash)
}


#' Persist an EvaluationTarget to the database
#'
#' Idempotent insert via \code{ON CONFLICT DO NOTHING}. The \code{target_id} is
#' computed as an xxhash64 digest of \code{title + "|" + authors + "|" + year}.
#' Author names are collapsed with newlines for storage.
#'
#' @param target An \code{\link{EvaluationTarget}} R6 object.
#' @param conn A DBI database connection.
#'
#' @return The \code{target_id} (invisibly), or \code{NULL} if the insert was
#'   skipped due to conflict.
#'
#' @export
persist_target <- function(target, conn) {
  target_id <- compute_target_id(target)

  authors_str <- if (is.null(target$authors) || length(target$authors) == 0) {
    NA_character_
  } else {
    paste(target$authors, collapse = "\n")
  }

  domain_json <- if (length(target$domain_dims) == 0) {
    NA_character_
  } else {
    jsonlite::toJSON(target$domain_dims, auto_unbox = TRUE)
  }

  rows <- DBI::dbExecute(conn,
    "INSERT INTO targets
       (target_id, artifact_type, title, authors, year, doi, domain_dims)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT (target_id) DO NOTHING",
    params = list(
      target_id,
      target$artifact_type,
      target$title,
      authors_str,
      target$year,
      target$doi %||% NA_character_,
      domain_json
    )
  )

  if (rows == 0) invisible(NULL) else invisible(target_id)
}


#' Persist claims to the database
#'
#' Inserts each \code{\link{Claim}} from a list, using \code{ON CONFLICT}
#' \code{DO NOTHING} on the \code{claim_id} primary key. Each claim obtains a
#' globally unique \code{claim_id} of the form
#' \code{target_id :: claim$id}.
#'
#' @param target_id Character — the target identifier returned by
#'   \code{\link{persist_target}}.
#' @param claims List of \code{\link{Claim}} R6 objects.
#' @param conn A DBI database connection.
#'
#' @return The number of claims inserted (invisibly). Duplicates are not
#'   counted.
#'
#' @export
persist_claims <- function(target_id, claims, conn) {
  if (is.null(claims) || length(claims) == 0) {
    return(invisible(0L))
  }

  count <- 0L
  for (cl in claims) {
    claim_id <- paste0(target_id, "::", cl$id)
    mf <- if (is.na(cl$m_failure)) NA_character_ else cl$m_failure
    rows <- DBI::dbExecute(conn,
      "INSERT INTO claims
         (claim_id, target_id, local_id, text, evidence, register, m_failure)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT (claim_id) DO NOTHING",
      params = list(
        claim_id,
        target_id,
        cl$id,
        cl$text,
        cl$evidence %||% NA_character_,
        cl$register,
        mf
      )
    )
    count <- count + rows
  }

  invisible(count)
}


#' Persist a complete EvaluationResult to the database
#'
#' Master persistence function that stores an entire evaluation result in a
#' single database transaction. Writes (in order):
#' \enumerate{
#'   \item The \code{\link{AxiomSet}} (via \code{\link{persist_axiom_set}})
#'   \item The \code{\link{EvaluationTarget}} (via \code{\link{persist_target}})
#'   \item Claims (via \code{\link{persist_claims}})
#'   \item The \code{evaluations} row
#'   \item Seven \code{layer_results} rows (one per layer)
#'   \item Normalized \code{layer_scores} rows
#' }
#'
#' All operations are wrapped in \code{DBI::dbWithTransaction}. If any step
#' fails, the entire write is rolled back.
#'
#' @param result An \code{\link{EvaluationResult}} R6 object.
#' @param conn A DBI database connection.
#'
#' @return The \code{eval_id} character string (invisibly).
#'
#' @export
persist_evaluation <- function(result, conn) {
  DBI::dbWithTransaction(conn, {

    # 1. Axiom set (idempotent)
    persist_axiom_set(result$axiom_set, conn)

    # 2. Target (idempotent)
    target_id <- persist_target(result$target, conn)
    # If target already existed, compute target_id directly
    if (is.null(target_id)) {
      target_id <- compute_target_id(result$target)
    }

    # 3. Claims (idempotent)
    persist_claims(target_id, result$target$claims, conn)

    # 4. Evaluation row
    eval_id <- compute_eval_id(result)

    wci <- result$wci
    si  <- result$session_info

    DBI::dbExecute(conn,
      "INSERT INTO evaluations
         (eval_id, target_id, axiom_set_hash,
          wci_composite, wci_theoretical, wci_empirical,
          wci_replicability, wci_uptake, wci_explanatory,
          wci_falsifiability, overall,
          r_version, seed, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT (eval_id) DO NOTHING",
      params = list(
        eval_id,
        target_id,
        result$axiom_set$context_hash,
        wci[["composite"]],
        wci[["theoretical"]],
        wci[["empirical"]],
        wci[["replicability"]],
        wci[["uptake"]],
        wci[["explanatory"]],
        wci[["falsifiability"]],
        result$overall %||% NA_character_,
        si$r_version %||% as.character(getRversion()),
        si$seed %||% NA_integer_,
        si$timestamp %||% Sys.time()
      )
    )

    # 5. Layer results and scores
    for (lr in result$layers) {
      remediation_json <- if (is.null(lr$remediation) ||
                              length(lr$remediation) == 0) {
        NA_character_
      } else {
        jsonlite::toJSON(lr$remediation, auto_unbox = TRUE)
      }

      flags_json <- if (is.null(lr$flags) || length(lr$flags) == 0) {
        NA_character_
      } else {
        jsonlite::toJSON(lr$flags, auto_unbox = TRUE)
      }

      DBI::dbExecute(conn,
        "INSERT INTO layer_results
           (eval_id, layer, layer_name, gap_diagnosis, remediation, flags, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT (eval_id, layer) DO NOTHING",
        params = list(
          eval_id,
          as.integer(lr$layer),
          lr$layer_name,
          lr$gap_diagnosis %||% NA_character_,
          remediation_json,
          flags_json,
          lr$notes %||% NA_character_
        )
      )

      # Insert scores in long format
      score_df <- flatten_scores(lr$scores)
      if (nrow(score_df) > 0) {
        DBI::dbAppendTable(conn, "layer_scores",
          data.frame(
            eval_id   = eval_id,
            layer     = as.integer(lr$layer),
            level     = score_df$level,
            dimension = score_df$dimension,
            score     = score_df$score,
            stringsAsFactors = FALSE
          )
        )
      }
    }

    invisible(eval_id)
  })
}


#' Load an evaluation from the database
#'
#' Queries the \code{evaluations}, \code{layer_results}, and
#' \code{layer_scores} tables for the given \code{eval_id}. When
#' \code{hydrate = FALSE} (the default), returns a lightweight list with the
#' evaluation metadata and unhydrated layer summaries. When
#' \code{hydrate = TRUE}, reconstructs full R6 objects (\code{AxiomSet},
#' \code{EvaluationTarget}, \code{LayerResult}) and returns a complete
#' \code{\link{EvaluationResult}}.
#'
#' @param eval_id Character — the evaluation identifier to load.
#' @param conn A DBI database connection.
#' @param hydrate Logical — if \code{TRUE}, rebuild full R6 objects including
#'   the incidence matrix. Default \code{FALSE}.
#'
#' @return If \code{hydrate = FALSE}: a named list with the evaluation row,
#'   layer results, and layer scores. If \code{hydrate = TRUE}: a fully
#'   reconstructed \code{\link{EvaluationResult}} R6 object. Returns
#'   \code{NULL} if the \code{eval_id} is not found.
#'
#' @export
load_evaluation <- function(eval_id, conn, hydrate = FALSE) {
  # Fetch evaluation row
  eval_row <- DBI::dbGetQuery(conn,
    "SELECT * FROM evaluations WHERE eval_id = ?",
    params = list(eval_id)
  )

  if (nrow(eval_row) == 0) {
    return(NULL)
  }

  # Fetch layer results
  lr_rows <- DBI::dbGetQuery(conn,
    "SELECT * FROM layer_results WHERE eval_id = ? ORDER BY layer",
    params = list(eval_id)
  )

  # Fetch layer scores
  ls_rows <- DBI::dbGetQuery(conn,
    "SELECT * FROM layer_scores WHERE eval_id = ? ORDER BY layer, level, dimension",
    params = list(eval_id)
  )

  if (!hydrate) {
    # Lightweight list — no R6 reconstruction
    ev <- as.list(eval_row[1, ])

    lrs <- lapply(seq_len(nrow(lr_rows)), function(i) {
      as.list(lr_rows[i, ])
    })

    scores_by_layer <- split(ls_rows, ls_rows$layer)
    lss <- lapply(scores_by_layer, function(df) {
      split(df$score, list(df$level, df$dimension))
    })

    return(list(
      evaluation = ev,
      target_id  = ev$target_id,
      axiom_set_hash = ev$axiom_set_hash,
      wci = c(
        composite      = ev$wci_composite,
        theoretical    = ev$wci_theoretical,
        empirical      = ev$wci_empirical,
        replicability  = ev$wci_replicability,
        uptake         = ev$wci_uptake,
        explanatory    = ev$wci_explanatory,
        falsifiability = ev$wci_falsifiability
      ),
      overall         = ev$overall,
      r_version       = ev$r_version,
      seed            = ev$seed,
      timestamp       = ev$timestamp,
      layer_results   = lrs,
      layer_scores    = lss
    ))
  }

  # --- Full hydration: reconstruct R6 objects ---
  # 1. AxiomSet
  ax <- load_axiom_set(eval_row$axiom_set_hash[1], conn)
  if (is.null(ax)) {
    stop("AxiomSet with hash '", eval_row$axiom_set_hash[1],
         "' not found in database", call. = FALSE)
  }

  # 2. EvaluationTarget
  target_row <- DBI::dbGetQuery(conn,
    "SELECT * FROM targets WHERE target_id = ?",
    params = list(eval_row$target_id[1])
  )

  if (nrow(target_row) == 0) {
    stop("Target with id '", eval_row$target_id[1],
         "' not found in database", call. = FALSE)
  }
  tr <- target_row[1, ]

  # Reconstruct authors
  authors <- if (is.na(tr$authors) || is.null(tr$authors)) {
    NULL
  } else {
    strsplit(tr$authors, "\n", fixed = TRUE)[[1]]
  }

  # Reconstruct domain_dims
  domain_dims <- if (is.na(tr$domain_dims) || is.null(tr$domain_dims)) {
    list()
  } else {
    jsonlite::fromJSON(tr$domain_dims, simplifyVector = FALSE)
  }

  # Reconstruct claims
  claims_rows <- DBI::dbGetQuery(conn,
    "SELECT * FROM claims WHERE target_id = ? ORDER BY local_id",
    params = list(tr$target_id)
  )

  claims <- lapply(seq_len(nrow(claims_rows)), function(i) {
    cr <- claims_rows[i, ]
    mf <- if (is.na(cr$m_failure) || is.null(cr$m_failure)) {
      NA
    } else {
      cr$m_failure
    }
    Claim$new(
      id       = cr$local_id,
      text     = cr$text,
      evidence = if (is.na(cr$evidence)) NULL else cr$evidence,
      register = cr$register,
      m_failure = mf
    )
  })

  target <- EvaluationTarget$new(
    artifact_type = tr$artifact_type,
    title         = tr$title,
    authors       = authors,
    year          = tr$year,
    doi           = if (is.na(tr$doi)) NULL else tr$doi,
    domain_dims   = domain_dims,
    claims        = claims
  )

  # 3. LayerResults
  layers <- vector("list", nrow(lr_rows))
  for (i in seq_len(nrow(lr_rows))) {
    lr <- lr_rows[i, ]
    # Filter scores for this specific eval_id + layer
    layer_scores_sub <- ls_rows[
      ls_rows$eval_id == eval_id & ls_rows$layer == lr$layer, ,
      drop = FALSE
    ]
    layers[[i]] <- hydrate_layer_result(lr, layer_scores_sub)
  }

  # 4. Reconstruct session_info
  ev <- eval_row[1, ]
  session_info <- list(
    r_version       = ev$r_version,
    seed            = ev$seed,
    timestamp       = ev$timestamp,
    inferno_version = utils::packageVersion("inferno")
  )

  # 5. WCI vector
  wci <- c(
    composite      = ev$wci_composite,
    theoretical    = ev$wci_theoretical,
    empirical      = ev$wci_empirical,
    replicability  = ev$wci_replicability,
    uptake         = ev$wci_uptake,
    explanatory    = ev$wci_explanatory,
    falsifiability = ev$wci_falsifiability
  )

  EvaluationResult$new(
    target      = target,
    axiom_set   = ax,
    layers      = layers,
    wci         = wci,
    overall     = ev$overall,
    session_info = session_info
  )
}


#' Load an AxiomSet from the database by its content-addressable hash
#'
#' Queries the \code{axiom_sets} table, deserializes the \code{incidence_blob}
#' via \code{base::unserialize()}, and returns a fully reconstructed
#' \code{\link{AxiomSet}} R6 object, including the original domain mapping.
#'
#' @param context_hash Character — the xxhash64 digest identifying the axiom
#'   set.
#' @param conn A DBI database connection.
#'
#' @return An \code{\link{AxiomSet}} R6 object, or \code{NULL} if no row with
#'   the given hash exists.
#'
#' @export
load_axiom_set <- function(context_hash, conn) {
  row <- DBI::dbGetQuery(conn,
    "SELECT * FROM axiom_sets WHERE context_hash = ?",
    params = list(context_hash)
  )

  if (nrow(row) == 0) {
    return(NULL)
  }

  r <- row[1, ]

  # Deserialize incidence matrix
  blob <- r$incidence_blob[[1]]
  if (is.list(blob)) blob <- blob[[1]]  # duckdb may wrap BLOB in a list
  incidence <- unserialize(blob)

  # Restore domain_mapping
  domain_mapping <- if (is.na(r$domain_mapping) || is.null(r$domain_mapping)) {
    NULL
  } else {
    jsonlite::fromJSON(r$domain_mapping, simplifyVector = FALSE)
  }

  AxiomSet$new(
    incidence      = incidence,
    objects        = rownames(incidence),
    attributes     = colnames(incidence),
    domain_mapping = domain_mapping,
    metric         = r$metric
  )
}