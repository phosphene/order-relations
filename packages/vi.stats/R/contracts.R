#' Validate a count matrix
#'
#' Contract validation for gene expression count matrices. Checks that the
#' input is a numeric matrix with non-negative values, gene names as rownames,
#' and sample names as colnames.
#'
#' @param counts Numeric matrix (genes x samples). Must have rownames (gene
#'   IDs) and colnames (sample IDs).
#' @param min_genes Integer. Minimum number of genes required. Default 100.
#' @param min_samples Integer. Minimum number of samples required. Default 1.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#' @keywords internal
#' @export
validate_count_matrix <- function(counts, min_genes = 100L, min_samples = 1L) {
  if (!is.matrix(counts) && !is.data.frame(counts)) {
    stop("counts must be a matrix or data.frame", call. = FALSE)
  }
  if (is.data.frame(counts)) {
    counts <- as.matrix(counts)
  }
  if (!is.numeric(counts)) {
    stop("counts must be numeric", call. = FALSE)
  }
  if (any(counts < 0, na.rm = TRUE)) {
    stop("counts must be non-negative", call. = FALSE)
  }
  if (is.null(rownames(counts))) {
    stop("counts must have rownames (gene IDs)", call. = FALSE)
  }
  if (is.null(colnames(counts))) {
    stop("counts must have colnames (sample IDs)", call. = FALSE)
  }
  if (nrow(counts) < min_genes) {
    stop(sprintf("counts has %d genes, need >= %d", nrow(counts), min_genes),
         call. = FALSE)
  }
  if (ncol(counts) < min_samples) {
    stop(sprintf("counts has %d samples, need >= %d", ncol(counts), min_samples),
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate sample metadata
#'
#' Contract validation for sample metadata. Checks that metadata is a data.frame
#' with a sample ID column matching count matrix colnames.
#'
#' @param metadata Data frame with at least a \code{sample_id} column.
#' @param expected_ids Character vector of sample IDs that must be present.
#'
#' @return Invisible TRUE if valid. Stops with error if invalid.
#' @keywords internal
#' @export
validate_metadata <- function(metadata, expected_ids = NULL) {
  if (!is.data.frame(metadata)) {
    stop("metadata must be a data.frame", call. = FALSE)
  }
  if (!"sample_id" %in% names(metadata)) {
    stop("metadata must have a 'sample_id' column", call. = FALSE)
  }
  if (!is.null(expected_ids)) {
    missing <- setdiff(expected_ids, metadata$sample_id)
    if (length(missing) > 0) {
      stop(sprintf("metadata missing sample IDs: %s",
                   paste(missing, collapse = ", ")), call. = FALSE)
    }
  }
  invisible(TRUE)
}
