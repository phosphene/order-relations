# Unit tests for compute_cdi

test_that("compute_cdi returns expected structure", {
  counts <- make_test_counts()
  result <- compute_cdi(counts)

  expect_type(result, "list")
  expect_named(result, c("cdi", "n_genes", "detection_correlation"))
  expect_length(result$cdi, ncol(counts))
  expect_length(result$n_genes, ncol(counts))
  expect_named(result$cdi, colnames(counts))
})

test_that("compute_cdi values are negative (entropy is positive)", {
  counts <- make_test_counts()
  result <- compute_cdi(counts)

  # CDI = -H, H > 0, so CDI < 0
  expect_true(all(result$cdi < 0))
})

test_that("compute_cdi handles zero-expression samples", {
  counts <- matrix(c(0, 0, 0, 100, 50, 200), nrow = 3, ncol = 2,
                   dimnames = list(c("G1", "G2", "G3"), c("zero", "normal")))
  result <- compute_cdi(counts)

  expect_true(is.na(result$cdi["zero"]))
  expect_false(is.na(result$cdi["normal"]))
})

test_that("compute_cdi normalizes correctly", {
  # Same proportions, different library sizes → same CDI
  counts <- matrix(c(10, 20, 30,
                     100, 200, 300), nrow = 3, ncol = 2,
                   dimnames = list(c("G1", "G2", "G3"), c("s1", "s2")))
  result <- compute_cdi(counts, normalize = "size_factor")

  # After normalization, proportions are identical → CDI should be ~equal
  expect_equal(result$cdi["s1"], result$cdi["s2"], tolerance = 1e-6)
})

test_that("compute_cdi validates input", {
  expect_error(compute_cdi("not a matrix"), "must be a matrix")
  expect_error(compute_cdi(matrix(-1, nrow = 100, ncol = 1)), "non-negative")
  expect_error(compute_cdi(matrix(1, nrow = 10, ncol = 1)), "at least 100")
})

test_that("n_genes counts non-zero entries", {
  counts <- matrix(c(100, 0, 50, 0,
                     80, 10, 40, 5), nrow = 4, ncol = 2,
                   dimnames = list(c("G1", "G2", "G3", "G4"), c("S1", "S2")))
  result <- compute_cdi(counts, normalize = "none")

  expect_equal(result$n_genes["S1"], 2L)
  expect_equal(result$n_genes["S2"], 4L)
})

test_that("detection_correlation is computed", {
  counts <- make_test_counts()
  result <- compute_cdi(counts)

  expect_type(result$detection_correlation, "double")
})

test_that("size factor normalization handles all-zero genes", {
  counts <- matrix(c(0, 0, 100, 200,
                     0, 0, 50, 100), nrow = 4, ncol = 2,
                   dimnames = list(c("G1", "G2", "G3", "G4"), c("S1", "S2")))
  result <- compute_cdi(counts, normalize = "size_factor")

  expect_false(any(is.na(result$cdi)))
})
