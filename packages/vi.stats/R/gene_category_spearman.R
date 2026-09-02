#' Gene-category Spearman correlation
#'
#' Computes the Spearman rank correlation between integration-depth category
#' and mean expression fold-change across gene categories. VI predicts a
#' negative correlation: deeper integration (Rank 1) should show less
#' expression decrease (more retention) than shallow integration (Rank 5).
#'
#' Permutation p-values are computed by permuting the category labels.
#'
#' @param fold_changes Named numeric vector of log2 fold-changes per gene.
#' @param ranks Named integer vector of integration-depth ranks (1-5) per gene.
#'   Must match names of \code{fold_changes}.
#' @param n_permutations Integer. Number of permutations for p-value. Default 10000.
#' @param seed Integer. Random seed for reproducibility. Default 42.
#'
#' @return A list with:
#'   \item{spearman_rho}{Spearman correlation between category rank and mean
#'     fold-change.}
#'   \item{p_value}{Asymptotic p-value.}
#'   \item{permutation_p}{Permutation-based p-value.}
#'   \item{category_means}{Named numeric vector of mean fold-change per category.}
#'   \item{category_sizes}{Named integer vector of gene count per category.}
#'
#' @export
#'
#' @examples
#' fc <- c(G1 = -0.5, G2 = -0.3, G3 = 0.1, G4 = 0.5, G5 = -0.2, G6 = 0.3)
#' rks <- c(G1 = 1L, G2 = 1L, G3 = 3L, G4 = 5L, G5 = 2L, G6 = 4L)
#' result <- gene_category_spearman(fc, rks, n_permutations = 100)
#' print(result$spearman_rho)
gene_category_spearman <- function(fold_changes, ranks,
                                    n_permutations = 10000L, seed = 42L) {
  stopifnot(is.numeric(fold_changes), is.integer(ranks))
  common <- intersect(names(fold_changes), names(ranks))
  if (length(common) < 2L) {
    stop("Need at least 2 genes with both fold-change and rank", call. = FALSE)
  }

  fc <- fold_changes[common]
  rk <- ranks[common]

  # Remove unclassified (rank 0)
  classified <- rk[rk > 0]
  fc <- fc[names(classified)]
  rk <- classified

  # Aggregate by category
  categories <- sort(unique(rk))
  cat_means <- vapply(categories, function(c) mean(fc[rk == c]), numeric(1))
  cat_sizes <- vapply(categories, function(c) sum(rk == c), integer(1))
  names(cat_means) <- categories
  names(cat_sizes) <- categories

  # Spearman correlation
  if (length(categories) >= 3L) {
    sc <- stats::cor.test(categories, cat_means, method = "spearman")
    rho <- unname(sc$estimate)
    p_val <- sc$p.value
  } else {
    rho <- NA_real_
    p_val <- NA_real_
    warning("Need >= 3 categories for Spearman test", call. = FALSE)
  }

  # Permutation p-value
  perm_p <- NA_real_
  if (length(categories) >= 3L && n_permutations > 0L) {
    withr::with_seed(seed, {
      count <- 0L
      for (i in seq_len(n_permutations)) {
        perm_cats <- sample(categories)
        rho_perm <- stats::cor(perm_cats, cat_means, method = "spearman")
        if (!is.na(rho_perm) && abs(rho_perm) >= abs(rho)) {
          count <- count + 1L
        }
      }
      perm_p <- count / n_permutations
    })
  }

  list(
    spearman_rho = rho,
    p_value = p_val,
    permutation_p = perm_p,
    category_means = cat_means,
    category_sizes = cat_sizes
  )
}
