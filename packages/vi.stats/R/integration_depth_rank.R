#' Classify genes into integration-depth categories
#'
#' Assigns each gene to one of five ranked integration-depth categories based
#' on functional hierarchy. Rank 1 (deepest integration) includes housekeeping
#' and structural genes. Rank 5 (shallowest) includes tissue-specific, immune,
#' and recently acquired genes.
#'
#' VI predicts that transcriptomic narrowing follows this ordering: Rank 5
#' genes are shed first, Rank 1 genes are most resistant.
#'
#' @param gene_ids Character vector of gene symbols.
#'
#' @return Integer vector of ranks (1-5) named by gene. 0 = unclassified.
#'
#' @export
#'
#' @examples
#' genes <- c("RPL5", "ACTB", "MKI67", "MAPK1", "KRT5", "UNKNOWN1")
#' ranks <- integration_depth_rank(genes)
#' print(ranks)
integration_depth_rank <- function(gene_ids) {
  stopifnot(is.character(gene_ids))

  upper <- toupper(gene_ids)
  ranks <- integer(length(gene_ids))
  names(ranks) <- gene_ids

  # Rank 1 — Housekeeping/structural (deepest integration)
  r1_patterns <- c("^RPL", "^RPS", "^EEF1", "^EEF2", "^ACTB", "^TUBA",
                   "^TUBB", "^HSPA", "^HSP90", "^UBB", "^UBC")
  # Rank 2 — Core machinery (replication, transcription, translation)
  r2_patterns <- c("^POLR", "^GTF", "^TFII", "^CDK7$", "^CDK9$",
                   "^MED", "^POLA", "^POLE", "^POLB")
  # Rank 3 — Cell cycle / proliferation
  r3_patterns <- c("^CDK1$", "^CDK2$", "^CDK4$", "^CDK6$", "^CCN",
                   "^MKI", "^TOP2", "^BUB", "^AUR", "^PLK",
                   "^CDC", "^WEE", "^CHEK", "^ATR$", "^ATM$")
  # Rank 4 — Signaling / regulation
  r4_patterns <- c("^MAPK", "^AKT", "^PIK3", "^RAS", "^RAF", "^MEK",
                   "^ERK", "^JAK", "^STAT", "^SRC", "^ABL", "^PTEN")
  # Rank 5 — Tissue-specific / immune / novel (shallowest)
  r5_patterns <- c("^KRT", "^COL", "^MYH", "^ACTN",
                   "^CD3", "^CD4", "^CD8", "^IGH", "^IGL",
                   "^HLA", "^IL", "^TNF", "^IFN", "^CXCL", "^CCR", "^TLR")

  for (i in seq_along(gene_ids)) {
    g <- upper[i]
    if (.matches_any(g, r1_patterns)) {
      ranks[i] <- 1L
    } else if (.matches_any(g, r2_patterns)) {
      ranks[i] <- 2L
    } else if (.matches_any(g, r3_patterns)) {
      ranks[i] <- 3L
    } else if (.matches_any(g, r4_patterns)) {
      ranks[i] <- 4L
    } else if (.matches_any(g, r5_patterns)) {
      ranks[i] <- 5L
    } else {
      ranks[i] <- 0L  # unclassified
    }
  }

  ranks
}

#' Check if a gene name matches any pattern
#' @keywords internal
.matches_any <- function(gene, patterns) {
  any(vapply(patterns, function(p) grepl(p, gene), logical(1)))
}
