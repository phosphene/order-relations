#' Canonicalize an incidence matrix for content-addressable hashing
#'
#' Sorts both row names and column names to ensure that matrices which are
#' row/column permutations of one another produce identical canonical forms.
#' Rounds numeric values to the given precision (trivially a no-op for crisp
#' 0/1 matrices).
#'
#' @param mat A numeric matrix, typically a binary (0/1) incidence matrix.
#' @param digits Integer number of decimal places for rounding. Default 8.
#'
#' @return A canonicalized matrix with sorted dimnames and rounded values.
#'
#' @examples
#' I <- matrix(c(1, 0, 0, 1), nrow = 2, dimnames = list(c("b", "a"), c("y", "x")))
#' canonicalize_matrix(I)
#'
#' # Permutations produce identical canonical form
#' I1 <- matrix(c(1, 0, 0, 1), nrow = 2,
#'              dimnames = list(c("a", "b"), c("x", "y")))
#' I2 <- matrix(c(0, 1, 1, 0), nrow = 2,
#'              dimnames = list(c("b", "a"), c("y", "x")))
#' identical(canonicalize_matrix(I1), canonicalize_matrix(I2))
#'
#' @export
canonicalize_matrix <- function(mat, digits = 8) {
  stopifnot(is.matrix(mat))

  # Supply default dimnames when missing
  if (is.null(rownames(mat))) {
    rownames(mat) <- as.character(seq_len(nrow(mat)))
  }
  if (is.null(colnames(mat))) {
    colnames(mat) <- as.character(seq_len(ncol(mat)))
  }

  # Canonical order: sort both dimensions
  rn <- sort(rownames(mat))
  cn <- sort(colnames(mat))
  mat <- mat[rn, cn, drop = FALSE]

  # Round for fuzzy-matrix support (no-op for crisp 0/1)
  round(mat, digits)
}


#' Compute a content-addressable hash of an incidence matrix
#'
#' Canonicalizes the matrix internally via \code{\link{canonicalize_matrix}},
#' then computes an xxhash64 digest. Two matrices that differ only by row or
#' column permutation will produce identical hashes.
#'
#' @param mat A numeric matrix (typically binary incidence). Will be
#'   canonicalized before hashing.
#'
#' @return A character string containing the xxhash64 digest.
#'
#' @examples
#' I <- matrix(c(1, 0, 0, 1), nrow = 2,
#'             dimnames = list(c("b", "a"), c("y", "x")))
#' h <- compute_hash(I)
#' print(h)
#'
#' # Permuted matrix produces the same hash
#' I_perm <- matrix(c(0, 1, 1, 0), nrow = 2,
#'                  dimnames = list(c("a", "b"), c("x", "y")))
#' identical(compute_hash(I), compute_hash(I_perm))
#'
#' @export
compute_hash <- function(mat) {
  c_mat <- canonicalize_matrix(mat)
  digest::digest(c_mat, algo = "xxhash64")
}