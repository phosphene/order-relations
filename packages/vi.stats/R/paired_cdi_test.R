#' Paired CDI test
#'
#' Paired Wilcoxon signed-rank test comparing CDI between two conditions
#' (e.g., Day 0 vs Day 28) for matched sample pairs.
#'
#' @param cdi Named numeric vector of CDI values per sample.
#' @param metadata Data frame with columns: \code{sample_id}, \code{pair_id}
#'   (matching identifier for paired samples), \code{condition} (two levels).
#' @param condition_levels Character vector of length 2 specifying the two
#'   conditions to compare (e.g., \code{c("day0", "day28")}).
#'
#' @return A list with:
#'   \item{statistic}{Wilcoxon W statistic.}
#'   \item{p_value}{Two-sided p-value.}
#'   \item{effect_size}{Median of paired differences (condition[2] - condition[1]).}
#'   \item{paired_diffs}{Named numeric vector of per-pair differences.}
#'   \item{n_pairs}{Number of pairs.}
#'
#' @export
#'
#' @examples
#' cdi <- c(s1 = -7.1, s2 = -6.9, s3 = -7.0, s4 = -6.8)
#' meta <- data.frame(
#'   sample_id = c("s1", "s2", "s3", "s4"),
#'   pair_id = c("dog1", "dog2", "dog1", "dog2"),
#'   condition = c("day0", "day0", "day28", "day28")
#' )
#' result <- paired_cdi_test(cdi, meta, c("day0", "day28"))
#' print(result$p_value)
paired_cdi_test <- function(cdi, metadata, condition_levels) {
  stopifnot(is.numeric(cdi), length(condition_levels) == 2L)
  validate_metadata(metadata, names(cdi))

  # Split by condition
  meta_cond1 <- metadata[metadata$condition == condition_levels[1], ]
  meta_cond2 <- metadata[metadata$condition == condition_levels[2], ]

  # Match pairs
  common_pairs <- intersect(meta_cond1$pair_id, meta_cond2$pair_id)
  if (length(common_pairs) < 1L) {
    stop("No matching pairs found", call. = FALSE)
  }

  cdi1 <- vapply(common_pairs, function(p) {
    sid <- meta_cond1$sample_id[meta_cond1$pair_id == p]
    cdi[sid]
  }, numeric(1))

  cdi2 <- vapply(common_pairs, function(p) {
    sid <- meta_cond2$sample_id[meta_cond2$pair_id == p]
    cdi[sid]
  }, numeric(1))

  paired_diffs <- cdi2 - cdi1
  names(paired_diffs) <- common_pairs

  # Wilcoxon signed-rank (needs >= 3 pairs for meaningful test)
  if (length(common_pairs) >= 3L) {
    wt <- stats::wilcox.test(cdi2, cdi1, paired = TRUE, exact = FALSE)
    statistic <- unname(wt$statistic)
    p_value <- wt$p.value
  } else {
    statistic <- NA_real_
    p_value <- NA_real_
    warning("Fewer than 3 pairs — no inferential test performed", call. = FALSE)
  }

  list(
    statistic = statistic,
    p_value = p_value,
    effect_size = stats::median(paired_diffs),
    paired_diffs = paired_diffs,
    n_pairs = length(common_pairs)
  )
}

#' Responder / non-responder split test
#'
#' Natural-experiment analysis comparing delta-CDI between responders and
#' non-responders. Both groups received the same treatment; only responders
#' showed phenotypic change. This isolates treatment effects from biological
#' effects.
#'
#' @param cdi Named numeric vector of CDI values per sample.
#' @param metadata Data frame with columns: \code{sample_id}, \code{pair_id},
#'   \code{condition} (two levels), \code{response_group} (e.g., "responder",
#'   "non_responder").
#' @param condition_levels Character vector of length 2 (pre, post).
#' @param response_groups Character vector of length 2 (responder, non_responder).
#'
#' @return A list with:
#'   \item{statistic}{Mann-Whitney U statistic.}
#'   \item{p_value}{Two-sided p-value.}
#'   \item{responder_diffs}{Delta-CDI for responders.}
#'   \item{non_responder_diffs}{Delta-CDI for non-responders.}
#'
#' @export
responder_split_test <- function(cdi, metadata, condition_levels,
                                  response_groups) {
  stopifnot(length(condition_levels) == 2L, length(response_groups) == 2L)
  validate_metadata(metadata, names(cdi))

  .compute_deltas <- function(group) {
    meta_g <- metadata[metadata$response_group == group, ]
    deltas <- vapply(unique(meta_g$pair_id), function(p) {
      s_pre <- meta_g$sample_id[meta_g$pair_id == p &
                                 meta_g$condition == condition_levels[1]]
      s_post <- meta_g$sample_id[meta_g$pair_id == p &
                                  meta_g$condition == condition_levels[2]]
      if (length(s_pre) == 0 || length(s_post) == 0) return(NA_real_)
      cdi[s_post] - cdi[s_pre]
    }, numeric(1))
    deltas[!is.na(deltas)]
  }

  resp <- .compute_deltas(response_groups[1])
  non_resp <- .compute_deltas(response_groups[2])

  if (length(resp) >= 1L && length(non_resp) >= 1L) {
    wt <- stats::wilcox.test(resp, non_resp, exact = FALSE)
    statistic <- unname(wt$statistic)
    p_value <- wt$p.value
  } else {
    statistic <- NA_real_
    p_value <- NA_real_
    warning("Insufficient samples in one or both groups", call. = FALSE)
  }

  list(
    statistic = statistic,
    p_value = p_value,
    responder_diffs = resp,
    non_responder_diffs = non_resp,
    n_responder = length(resp),
    n_non_responder = length(non_resp)
  )
}
