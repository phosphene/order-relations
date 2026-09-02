#!/usr/bin/env Rscript
# CTVT Test 1 — R Analysis using vi.stats package functions
# Follows MPI Handoff Blueprint: pure data munging -> analysis -> pure result extraction

suppressWarnings({
  library(stats)
  library(utils)
})

# --- Source vi.stats functions (dev mode - no install needed) ---
pkg_dir <- "../../../../packages/vi.stats"
for (f in list.files(file.path(pkg_dir, "R"), pattern = "\\.R$", full.names = TRUE)) {
  source(f)
}

# --- Constants ---
QUANT_DIR <- "/home/node/.openclaw/workspace/ctvt-pipeline/quant"
MAPPING_FILE <- "/home/node/.openclaw/workspace/ctvt-pipeline/gene_id_to_symbol.tsv"
RESULTS_FILE <- "/home/node/.openclaw/workspace/ctvt-pipeline/ctvt_results_R.json"

SAMPLES <- list(
  ERR2044811 = list(dog = "CTVT-761", age = 5L, sex = "F", time = 0L, grading = "progressive"),
  ERR2044812 = list(dog = "CTVT-761", age = 5L, sex = "F", time = 28L, grading = "progressive"),
  ERR2044813 = list(dog = "CTVT-765", age = 4L, sex = "F", time = 0L, grading = "progressive"),
  ERR2044814 = list(dog = "CTVT-765", age = 4L, sex = "F", time = 28L, grading = "regressive"),
  ERR2044815 = list(dog = "CTVT-766", age = 7L, sex = "F", time = 0L, grading = "progressive"),
  ERR2044816 = list(dog = "CTVT-766", age = 7L, sex = "F", time = 28L, grading = "regressive"),
  ERR2044817 = list(dog = "CTVT-772", age = 5L, sex = "M", time = 0L, grading = "progressive"),
  ERR2044818 = list(dog = "CTVT-772", age = 5L, sex = "M", time = 28L, grading = "regressive"),
  ERR2044819 = list(dog = "CTVT-774", age = 4L, sex = "M", time = 0L, grading = "progressive"),
  ERR2044820 = list(dog = "CTVT-774", age = 4L, sex = "M", time = 28L, grading = "progressive"),
  ERR2044821 = list(dog = "CTVT-775", age = 3L, sex = "M", time = 0L, grading = "progressive"),
  ERR2044822 = list(dog = "CTVT-775", age = 3L, sex = "M", time = 28L, grading = "progressive")
)

cat("=" , rep("=", 68), "\n", sep = "")
cat("CTVT TEST 1 — R Analysis via vi.stats\n")
cat("=", rep("=", 68), "\n", sep = "")

# --- Step 1: Load gene ID -> symbol mapping ---
cat("\n## Step 1: Loading gene mapping\n")
id_map <- read.table(MAPPING_FILE, sep = "\t", stringsAsFactors = FALSE,
                     col.names = c("transcript_id", "gene_symbol"))
cat(sprintf("  Mapping entries: %d\n", nrow(id_map)))

# --- Step 2: Load Salmon quantifications ---
cat("\n## Step 2: Loading 12 Salmon quant files\n")
gene_lists <- list()
for (err_id in names(SAMPLES)) {
  qf <- file.path(QUANT_DIR, err_id, "quant.sf")
  df <- read.table(qf, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
  # Map transcript IDs to gene symbols
  df$gene <- id_map$gene_symbol[match(df$Name, id_map$transcript_id)]
  df$gene[is.na(df$gene)] <- df$Name[is.na(df$gene)]
  # Aggregate by gene symbol
  agg <- tapply(df$NumReads, df$gene, sum)
  gene_lists[[err_id]] <- agg
  cat(sprintf("  %s: %d genes\n", err_id, length(agg)))
}

# Build count matrix
all_genes <- sort(unique(unlist(lapply(gene_lists, names))))
counts <- matrix(0, nrow = length(all_genes), ncol = length(gene_lists),
                 dimnames = list(all_genes, names(gene_lists)))
for (err_id in names(gene_lists)) {
  counts[names(gene_lists[[err_id]]), err_id] <- gene_lists[[err_id]]
}
cat(sprintf("\n  Matrix: %d genes x %d samples\n", nrow(counts), ncol(counts)))

# --- Step 3: Compute CDI via vi.stats ---
cat("\n## Step 3: CDI (via compute_cdi)\n")
cdi_result <- compute_cdi(counts, normalize = "size_factor")
cdi <- cdi_result$cdi
for (s in sort(names(cdi))) {
  m <- SAMPLES[[s]]
  cat(sprintf("  %-10s D%2d %-11s  CDI = %.4f  genes = %d\n",
              m$dog, m$time, m$grading, cdi[s], cdi_result$n_genes[s]))
}
cat(sprintf("\n  Detection correlation (rho): %.4f\n", cdi_result$detection_correlation))

# --- Step 4: Build metadata ---
dog_response <- sapply(unique(sapply(SAMPLES, function(s) s$dog)), function(d) {
  d28 <- names(SAMPLES)[sapply(SAMPLES, function(s) s$dog == d && s$time == 28)]
  if (SAMPLES[[d28]]$grading == "regressive") "responder" else "non_responder"
})
meta <- data.frame(
  sample_id = names(SAMPLES),
  pair_id = sapply(SAMPLES, function(s) s$dog),
  condition = ifelse(sapply(SAMPLES, function(s) s$time) == 0, "day0", "day28"),
  response_group = dog_response[sapply(SAMPLES, function(s) s$dog)],
  stringsAsFactors = FALSE
)

# --- Step 5: Paired CDI test ---
cat("\n## Step 5: Paired CDI Test (via paired_cdi_test)\n")
paired_result <- paired_cdi_test(cdi, meta, c("day0", "day28"))
cat(sprintf("  Paired Wilcoxon: W = %.1f, p = %.4f\n", paired_result$statistic, paired_result$p_value))
cat(sprintf("  Effect size (median delta): %.4f\n", paired_result$effect_size))
cat(sprintf("  N pairs: %d\n", paired_result$n_pairs))
for (p in names(paired_result$paired_diffs)) {
  cat(sprintf("    %s: delta = %+.4f\n", p, paired_result$paired_diffs[[p]]))
}

# --- Step 6: Responder split test ---
cat("\n## Step 6: Responder Split Test (via responder_split_test)\n")
resp_result <- responder_split_test(cdi, meta, c("day0", "day28"),
                                     c("responder", "non_responder"))
cat(sprintf("  Mann-Whitney U = %.1f, p = %.4f\n", resp_result$statistic, resp_result$p_value))
cat(sprintf("  Responders (n=%d): %s\n", resp_result$n_responder,
            paste(sprintf("%+.4f", resp_result$responder_diffs), collapse = " ")))
cat(sprintf("  Non-responders (n=%d): %s\n", resp_result$n_non_responder,
            paste(sprintf("%+.4f", resp_result$non_responder_diffs), collapse = " ")))

# --- Step 7: Integration-depth category analysis ---
cat("\n## Step 7: Integration-Depth Category Analysis (via gene_category_spearman)\n")
ranks <- integration_depth_rank(rownames(counts))
cat(sprintf("  Classified: %d / %d genes\n", sum(ranks > 0), length(ranks)))
for (r in 1:5) {
  cat(sprintf("    Rank %d: %d genes\n", r, sum(ranks == r)))
}

# Compute fold changes
pairs <- list()
dogs <- sort(unique(sapply(SAMPLES, function(s) s$dog)))
for (dog in dogs) {
  d0 <- names(SAMPLES)[sapply(SAMPLES, function(s) s$dog == dog && s$time == 0)]
  d28 <- names(SAMPLES)[sapply(SAMPLES, function(s) s$dog == dog && s$time == 28)]
  pairs[[dog]] <- c(d0, d28)
}

# Mean log2FC across all pairs
fc_all <- numeric(length(rownames(counts)))
names(fc_all) <- rownames(counts)
for (dog in dogs) {
  d0 <- pairs[[dog]][1]
  d28 <- pairs[[dog]][2]
  fc_all <- fc_all + log2((counts[, d28] + 0.5) / (counts[, d0] + 0.5))
}
fc_all <- fc_all / length(dogs)

spearman_result <- gene_category_spearman(fc_all, ranks, n_permutations = 10000L, seed = 42L)
cat(sprintf("\n  Spearman rho = %.4f, p = %.4f, perm_p = %.4f\n",
            spearman_result$spearman_rho, spearman_result$p_value, spearman_result$permutation_p))
cat("  Category means:\n")
for (c in names(spearman_result$category_means)) {
  cat(sprintf("    Rank %s (n=%d): %+.4f\n", c, spearman_result$category_sizes[[c]],
              spearman_result$category_means[[c]]))
}

# Responders only
resp_dogs <- dogs[sapply(dogs, function(d) SAMPLES[[pairs[[d]][2]]]$grading == "regressive")]
fc_resp <- numeric(length(rownames(counts)))
names(fc_resp) <- rownames(counts)
for (dog in resp_dogs) {
  d0 <- pairs[[dog]][1]
  d28 <- pairs[[dog]][2]
  fc_resp <- fc_resp + log2((counts[, d28] + 0.5) / (counts[, d0] + 0.5))
}
fc_resp <- fc_resp / length(resp_dogs)

spearman_resp <- gene_category_spearman(fc_resp, ranks, n_permutations = 10000L, seed = 42L)
cat(sprintf("\n  Responders only (n=%d):\n", length(resp_dogs)))
cat(sprintf("  Spearman rho = %.4f, p = %.4f\n", spearman_resp$spearman_rho, spearman_resp$p_value))
cat("  Category means:\n")
for (c in names(spearman_resp$category_means)) {
  cat(sprintf("    Rank %s (n=%d): %+.4f\n", c, spearman_resp$category_sizes[[c]],
              spearman_resp$category_means[[c]]))
}

# --- Step 8: Vincristine sensitivity analysis ---
cat("\n## Step 8: Vincristine Sensitivity (via sensitivity_analysis)\n")
sens_result <- sensitivity_analysis(counts, VINCRISTINE_TARGETS, normalize = "size_factor")
cat(sprintf("  Excluded: %d genes, Remaining: %d genes\n", sens_result$n_excluded, sens_result$n_remaining))
cat(sprintf("  Excluded genes: %s\n", paste(sens_result$excluded_genes, collapse = ", ")))

# Paired test on vincristine-excluded CDI
paired_nv <- paired_cdi_test(sens_result$cdi, meta, c("day0", "day28"))
cat(sprintf("  Paired Wilcoxon (no vinc): W = %.1f, p = %.4f\n", paired_nv$statistic, paired_nv$p_value))

resp_nv <- responder_split_test(sens_result$cdi, meta, c("day0", "day28"),
                                c("responder", "non_responder"))
cat(sprintf("  Mann-Whitney (no vinc, R vs NR): U = %.1f, p = %.4f\n", resp_nv$statistic, resp_nv$p_value))

# --- Summary ---
cat("\n", "=", rep("=", 68), "\n", sep = "")
cat("CTVT TEST 1 — SUMMARY\n")
cat("=", rep("=", 68), "\n", sep = "")
cat(sprintf("""
CDI Values:
  CTVT-761 (non-responder): D0=%.4f -> D28=%.4f (delta=%+.4f)
  CTVT-765 (responder):     D0=%.4f -> D28=%.4f (delta=%+.4f)
  CTVT-766 (responder):     D0=%.4f -> D28=%.4f (delta=%+.4f)
  CTVT-772 (responder):     D0=%.4f -> D28=%.4f (delta=%+.4f)
  CTVT-774 (non-responder): D0=%.4f -> D28=%.4f (delta=%+.4f)
  CTVT-775 (non-responder): D0=%.4f -> D28=%.4f (delta=%+.4f)

Paired Wilcoxon (all 6):              W=%.1f, p=%.4f
Mann-Whitney (responders vs non):     U=%.1f, p=%.4f
Integration-depth Spearman (all 6):   rho=%.4f, p=%.4f, perm_p=%.4f
Integration-depth Spearman (responders): rho=%.4f, p=%.4f
Vincristine-excluded Wilcoxon:        W=%.1f, p=%.4f
Vincristine-excluded Mann-Whitney:    U=%.1f, p=%.4f
""",
  cdi["ERR2044811"], cdi["ERR2044812"], cdi["ERR2044812"]-cdi["ERR2044811"],
  cdi["ERR2044813"], cdi["ERR2044814"], cdi["ERR2044814"]-cdi["ERR2044813"],
  cdi["ERR2044815"], cdi["ERR2044816"], cdi["ERR2044816"]-cdi["ERR2044815"],
  cdi["ERR2044817"], cdi["ERR2044818"], cdi["ERR2044818"]-cdi["ERR2044817"],
  cdi["ERR2044819"], cdi["ERR2044820"], cdi["ERR2044820"]-cdi["ERR2044819"],
  cdi["ERR2044821"], cdi["ERR2044822"], cdi["ERR2044822"]-cdi["ERR2044821"],
  paired_result$statistic, paired_result$p_value,
  resp_result$statistic, resp_result$p_value,
  spearman_result$spearman_rho, spearman_result$p_value, spearman_result$permutation_p,
  spearman_resp$spearman_rho, spearman_resp$p_value,
  paired_nv$statistic, paired_nv$p_value,
  resp_nv$statistic, resp_nv$p_value
))

cat("\nSession info:\n")
print(sessionInfo())
cat("\nDone.\n")
