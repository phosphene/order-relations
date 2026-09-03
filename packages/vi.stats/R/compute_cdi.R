#' Compute the Capacity Depletion Index (CDI)
#'
#' Computes CDI as the negative Shannon entropy of normalized gene expression
#' for each sample. Higher CDI (more negative) indicates a broader
#' transcriptome (less committed). Lower CDI (closer to zero) indicates a
#' narrower transcriptome (more committed).
#'
#' CDI = -(-sum(p_i * log(p_i))) = sum(p_i * log(p_i))
#'
#' where p_i is the proportion of total expression allocated to gene i
#' after within-sample normalization.
#'
#' @param counts Numeric matrix (genes x samples). Raw or normalized counts.
#'   Must have rownames (gene IDs) and colnames (sample IDs).
#' @param normalize Character. Normalization method: \code{"size_factor"}
#'   (DESeq2-style median-of-ratios, default) or \code{"none"} (use as-is).
#'
#' @return A list with:
#'   \item{cdi}{Named numeric vector of CDI values per sample.}
#'   \item{n_genes}{Named integer vector of genes detected (count > 0) per sample.}
#'   \item{detection_correlation}{Spearman rho between CDI and n_genes.}
#'
#' @export
#'
#' @examples
#' counts <- matrix(c(100, 50, 0, 200,
#'                    80, 40, 10, 150,
#'                    90, 60, 5, 180), nrow = 4, ncol = 3,
#'                  dimnames = list(c("G1", "G2", "G3", "G4"),
#'                                  c("S1", "S2", "S3")))
#' result <- compute_cdi(counts)
#' print(result$cdi)
compute_cdi <- function(counts, normalize = c("size_factor", "none")) {
  normalize <- match.arg(normalize)
  validate_count_matrix(counts)

  # Normalization
  if (normalize == "size_factor") {
    counts <- .size_factor_normalize(counts)
  }

  # Compute CDI per sample
  n_samples <- ncol(counts)
  cdi_vals <- numeric(n_samples)
  n_genes <- integer(n_samples)
  names(cdi_vals) <- colnames(counts)
  names(n_genes) <- colnames(counts)

  for (j in seq_len(n_samples)) {
    x <- counts[, j]
    n_genes[j] <- sum(x > 0)
    x <- x[x > 0]
    if (length(x) == 0) {
      cdi_vals[j] <- NA_real_
      next
    }
    p <- x / sum(x)
    H <- -sum(p * log(p))
    cdi_vals[j] <- -H  # CDI = -H (negative entropy)
  }

  # Detection correlation
  valid <- !is.na(cdi_vals) & n_genes > 0
  det_cor <- if (sum(valid) >= 3) {
    cor(cdi_vals[valid], n_genes[valid], method = "spearman")
  } else {
    NA_real_
  }

  list(
    cdi = cdi_vals,
    n_genes = n_genes,
    detection_correlation = det_cor
  )
}

#' DESeq2-style size factor normalization
#'
#' Computes size factors via the median-of-ratios method (Anders & Huber, 2010)
#' and divides each column by its size factor.
#'
#' @param counts Numeric matrix (genes x samples).
#' @return Numeric matrix, size-factor normalized.
#' @keywords internal
.size_factor_normalize <- function(counts) {
  # Geometric mean per gene
  log_counts <- log(counts)
  log_counts[!is.finite(log_counts)] <- NA_real_
  geo_means <- exp(rowMeans(log_counts, na.rm = TRUE))
  valid <- is.finite(geo_means) & geo_means > 0

  if (sum(valid) == 0) {
    return(counts)  # fallback: no normalization
  }

  # Size factor = median(counts / geo_mean) per sample
  filtered <- counts[valid, , drop = FALSE]
  ratios <- sweep(filtered, 1, geo_means[valid], "/")
  size_factors <- apply(ratios, 2, stats::median, na.rm = TRUE)

  # Avoid division by zero
  size_factors[size_factors == 0] <- 1

  sweep(counts, 2, size_factors, "/")
}
