#' vi.stats: Vestigial Information Statistical Methods
#'
#' Statistical methods for testing Vestigial Information (VI) predictions
#' about integration-depth-ordered transcriptomic commitment.
#'
#' The package provides:
#' \itemize{
#'   \item \code{\link{compute_cdi}} — Capacity Depletion Index (negative
#'         Shannon entropy of normalized gene expression)
#'   \item \code{\link{integration_depth_rank}} — classify genes into
#'         integration-depth categories (Rank 1 deepest to Rank 5 shallowest)
#'   \item \code{\link{paired_cdi_test}} — paired Wilcoxon signed-rank test
#'         for CDI differences between two conditions
#'   \item \code{\link{gene_category_spearman}} — Spearman correlation between
#'         integration-depth rank and expression fold-change with permutation
#'         p-values
#'   \item \code{\link{sensitivity_analysis}} — recompute CDI excluding a
#'         specified gene set (drug-target or metabolic genes)
#'   \item \code{\link{responder_split_test}} — natural-experiment analysis
#'         comparing delta-CDI between responders and non-responders
#' }
#'
#' All functions follow the MPI Handoff Blueprint: pure inputs, pure outputs,
#' no side effects, no global state. Contract validation via
#' \code{\link{validate_count_matrix}} and \code{\link{validate_metadata}}.
#'
#' @docType package
#' @name vi.stats
NULL

#' Gene sets for sensitivity analyses
#'
#' Predefined gene exclusion sets for controlling known confounds.
#'
#' \itemize{
#'   \item \code{VINCRISTINE_TARGETS} — cell-cycle genes directly targeted by
#'     vincristine chemotherapy (MKI67, TOP2A, BUB1, AURKA, CCNB1, etc.)
#'   \item \code{METABOLIC_GENES} — glycolysis, TCA cycle, and OXPHOS genes
#'     for starvation sensitivity analysis
#' }
#'
#' @format Named character vectors of gene symbols.
#' @name gene_sets
NULL

#' @rdname gene_sets
#' @export
VINCRISTINE_TARGETS <- c(
  "MKI67", "TOP2A", "BUB1", "AURKA", "CCNB1", "CDC20", "PLK1",
  "CDK1", "PCNA", "MCM2", "MCM3", "MCM4", "MCM5", "MCM6",
  "CHEK1", "CHEK2", "ATR", "ATM", "WEE1", "TYMS", "DHFR"
)

#' @rdname gene_sets
#' @export
METABOLIC_GENES <- c(
  # Glycolysis
  "HK1", "HK2", "PFKL", "PFKP", "PFKM", "PKM", "PKLR", "LDHA", "LDHB",
  "GPI", "FBP1", "FBP2", "ALDOA", "ALDOB", "ALDOC", "GAPDH", "PGK1",
  "PGAM1", "PGAM2", "ENO1", "ENO2", "ENO3",
  # Gluconeogenesis
  "PCK1", "PCK2", "G6PC1", "G6PC2",
  # TCA cycle
  "IDH1", "IDH2", "IDH3A", "IDH3B", "IDH3G",
  "SDHA", "SDHB", "SDHC", "SDHD", "OGDH", "DLST", "DLD",
  "PDHA1", "PDHA2", "PDHB", "CS", "ACO1", "ACO2", "MDH1", "MDH2",
  # OXPHOS
  "NDUFA1", "NDUFA2", "NDUFB1", "COX4I1", "COX5A", "COX5B",
  "COX6A1", "COX6B1", "COX7A1", "COX8A",
  "ATP5F1A", "ATP5F1B", "ATP5F1C", "ATP5F1D", "ATP5F1E"
)
