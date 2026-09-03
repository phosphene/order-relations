# Unit tests for gene_category_spearman and sensitivity_analysis

test_that("gene_category_spearman returns expected structure", {
  fc <- c(RPL5 = -0.1, RPL10 = -0.2, CDK1 = -0.5, MKI67 = -0.6,
          MAPK1 = -0.3, KRT5 = -0.8, KRT10 = -0.9)
  rks <- c(RPL5 = 1L, RPL10 = 1L, CDK1 = 3L, MKI67 = 3L,
           MAPK1 = 4L, KRT5 = 5L, KRT10 = 5L)

  result <- gene_category_spearman(fc, rks, n_permutations = 100)

  expect_type(result, "list")
  expect_named(result, c("spearman_rho", "p_value", "permutation_p",
                         "category_means", "category_sizes"))
  expect_length(result$category_means, 4L)
})

test_that("gene_category_spearman excludes unclassified genes", {
  fc <- c(G1 = -0.1, G2 = -0.5, G3 = -0.8, UNKNOWN = -0.3)
  rks <- c(G1 = 1L, G2 = 3L, G3 = 5L, UNKNOWN = 0L)

  result <- gene_category_spearman(fc, rks, n_permutations = 50)
  expect_equal(length(result$category_means), 3L)
  expect_false(0 %in% names(result$category_means))
})

test_that("gene_category_spearman warns with fewer than 3 categories", {
  fc <- c(G1 = -0.1, G2 = -0.5)
  rks <- c(G1 = 1L, G2 = 3L)

  expect_warning(gene_category_spearman(fc, rks, n_permutations = 0))
})

test_that("gene_category_spearman is deterministic with seed", {
  fc <- c(G1 = -0.1, G2 = -0.2, G3 = -0.3, G4 = -0.5, G5 = -0.8)
  rks <- c(G1 = 1L, G2 = 2L, G3 = 3L, G4 = 4L, G5 = 5L)

  r1 <- gene_category_spearman(fc, rks, n_permutations = 100, seed = 42L)
  r2 <- gene_category_spearman(fc, rks, n_permutations = 100, seed = 42L)

  expect_equal(r1$permutation_p, r2$permutation_p)
})

test_that("sensitivity_analysis returns expected structure", {
  counts <- make_test_counts()
  result <- sensitivity_analysis(counts, VINCRISTINE_TARGETS)

  expect_type(result, "list")
  expect_named(result, c("cdi", "n_genes", "detection_correlation",
                         "n_excluded", "n_remaining", "excluded_genes"))
  expect_true(result$n_excluded > 0)
  expect_true(result$n_remaining < nrow(counts))
})

test_that("sensitivity_analysis excludes specified genes", {
  counts <- make_test_counts()
  exclude <- c("MKI671", "MKI672")

  result <- sensitivity_analysis(counts, exclude)
  expect_true(all(c("MKI671", "MKI672") %in% result$excluded_genes))
  expect_false(any(c("MKI671", "MKI672") %in% rownames(
    counts[counts != 0, , drop = FALSE]
  )))
})

test_that("sensitivity_analysis warns when no genes match", {
  counts <- make_test_counts()
  expect_warning(sensitivity_analysis(counts, c("NONEXISTENT")))
})

test_that("sensitivity_analysis with metabolic genes", {
  counts <- make_test_counts()
  result <- sensitivity_analysis(counts, METABOLIC_GENES)

  # Should exclude some genes if the test data contains them
  # Our test data doesn't contain metabolic genes, so n_excluded may be 0
  expect_true(result$n_remaining > 0)
})
