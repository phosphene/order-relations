# Test data fixtures for vi.stats

# Toy count matrix: 100 genes x 6 samples
# Genes include known patterns for testing
make_test_counts <- function() {
  set.seed(42)
  genes <- c(
    paste0("RPL", 1:10),    # Rank 1 - housekeeping
    paste0("ACTB", 1:5),     # Rank 1 - structural
    paste0("POLR", 1:8),     # Rank 2 - core machinery
    paste0("CDK1", 1:3),     # Rank 3 - cell cycle
    paste0("MKI67", 1:2),    # Rank 3 - proliferation
    paste0("MAPK", 1:7),     # Rank 4 - signaling
    paste0("KRT", 1:10),     # Rank 5 - tissue-specific
    paste0("COL", 1:5),      # Rank 5 - extracellular
    paste0("UNKNOWN", 1:50)  # Unclassified
  )

  samples <- c("s1_d0", "s2_d0", "s3_d0", "s1_d28", "s2_d28", "s3_d28")
  counts <- matrix(rpois(length(genes) * length(samples), lambda = 50),
                   nrow = length(genes), ncol = length(samples))
  rownames(counts) <- genes
  colnames(counts) <- samples
  counts
}

make_test_metadata <- function() {
  data.frame(
    sample_id = c("s1_d0", "s2_d0", "s3_d0", "s1_d28", "s2_d28", "s3_d28"),
    pair_id = c("p1", "p2", "p3", "p1", "p2", "p3"),
    condition = c("day0", "day0", "day0", "day28", "day28", "day28"),
    response_group = c("responder", "non_responder", "responder",
                       "responder", "non_responder", "responder"),
    stringsAsFactors = FALSE
  )
}
