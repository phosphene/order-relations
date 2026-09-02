#' Sensitivity analysis: recompute CDI excluding a gene set
#'
#' Removes specified genes from the count matrix and recomputes CDI. Used to
#' test whether observed CDI patterns are driven by specific gene classes
#' (e.g., vincristine-target cell-cycle genes, metabolic genes for starvation
#' control).
#'
#' If the pattern survives exclusion, it is not an artifact of the excluded
#' gene set.
#'
#' @param counts Numeric matrix (genes x samples).
#' @param exclude_genes Character vector of gene symbols to exclude.
#' @param normalize Character. Normalization method passed to
#'   \code{\link{compute_cdi}}.
#'
#' @return A list with:
#'   \item{cdi}{CDI values computed without excluded genes.}
#'   \item{n_genes}{Genes detected per sample after exclusion.}
#'   \item{n_excluded}{Number of genes excluded.}
#'   \item{n_remaining}{Number of genes remaining.}
#'
#' @export
#'
#' @examples
#' counts <- matrix(c(100, 50, 0, 200, 300,
#'                    80, 40, 10, 150, 250), nrow = 5, ncol = 2,
#'                  dimnames = list(c("G1", "MKI67", "G3", "TOP2A", "G5"),
#'                                  c("S1", "S2")))
#' result <- sensitivity_analysis(counts, c("MKI67", "TOP2A"))
#' print(result$cdi)
sensitivity_analysis <- function(counts, exclude_genes,
                                  normalize = c("size_factor", "none")) {
  normalize <- match.arg(normalize)
  validate_count_matrix(counts)
  stopifnot(is.character(exclude_genes))

  # Find matching genes
  all_genes <- rownames(counts)
  to_exclude <- all_genes[all_genes %in% exclude_genes]

  if (length(to_exclude) == 0L) {
    warning("No genes matched the exclusion set", call. = FALSE)
  }

  # Subset
  keep <- setdiff(all_genes, to_exclude)
  filtered <- counts[keep, , drop = FALSE]

  # Recompute CDI
  result <- compute_cdi(filtered, normalize = normalize)

  list(
    cdi = result$cdi,
    n_genes = result$n_genes,
    detection_correlation = result$detection_correlation,
    n_excluded = length(to_exclude),
    n_remaining = nrow(filtered),
    excluded_genes = to_exclude
  )
}
