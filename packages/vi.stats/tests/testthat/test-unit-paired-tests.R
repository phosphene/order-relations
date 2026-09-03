# Unit tests for paired_cdi_test and responder_split_test

test_that("paired_cdi_test returns expected structure", {
  counts <- make_test_counts()
  cdi_result <- compute_cdi(counts)
  meta <- make_test_metadata()

  result <- paired_cdi_test(cdi_result$cdi, meta, c("day0", "day28"))

  expect_type(result, "list")
  expect_named(result, c("statistic", "p_value", "effect_size",
                         "paired_diffs", "n_pairs"))
  expect_equal(result$n_pairs, 3L)
  expect_length(result$paired_diffs, 3L)
})

test_that("paired_cdi_test warns with fewer than 3 pairs", {
  cdi <- c(s1 = -7, s2 = -6.8, s3 = -7.1, s4 = -6.9)
  meta <- data.frame(
    sample_id = c("s1", "s2", "s3", "s4"),
    pair_id = c("p1", "p2", "p1", "p2"),
    condition = c("day0", "day0", "day28", "day28"),
    stringsAsFactors = FALSE
  )

  expect_warning(paired_cdi_test(cdi, meta, c("day0", "day28")))
})

test_that("paired_cdi_test computes correct differences", {
  cdi <- c(a1 = -7.0, a2 = -6.5, b1 = -7.2, b2 = -6.8)
  meta <- data.frame(
    sample_id = c("a1", "a2", "b1", "b2"),
    pair_id = c("p1", "p2", "p1", "p2"),
    condition = c("pre", "pre", "post", "post"),
    stringsAsFactors = FALSE
  )

  result <- paired_cdi_test(cdi, meta, c("pre", "post"))
  expect_equal(result$paired_diffs["p1"], cdi["b1"] - cdi["a1"])
  expect_equal(result$paired_diffs["p2"], cdi["b2"] - cdi["a2"])
})

test_that("responder_split_test returns expected structure", {
  counts <- make_test_counts()
  cdi_result <- compute_cdi(counts)
  meta <- make_test_metadata()

  result <- responder_split_test(cdi_result$cdi, meta,
                                  c("day0", "day28"),
                                  c("responder", "non_responder"))

  expect_type(result, "list")
  expect_named(result, c("statistic", "p_value",
                         "responder_diffs", "non_responder_diffs",
                         "n_responder", "n_non_responder"))
})

test_that("responder_split_test separates groups correctly", {
  counts <- make_test_counts()
  cdi_result <- compute_cdi(counts)
  meta <- make_test_metadata()

  result <- responder_split_test(cdi_result$cdi, meta,
                                  c("day0", "day28"),
                                  c("responder", "non_responder"))

  expect_equal(result$n_responder, 2L)  # p1, p3
  expect_equal(result$n_non_responder, 1L)  # p2
})

test_that("contracts validate correctly", {
  expect_error(validate_count_matrix("not a matrix"), "must be a matrix")
  expect_error(validate_count_matrix(matrix(1, 2, 2)), "rownames")
  expect_error(validate_metadata(data.frame(x = 1)), "sample_id")

  good_counts <- matrix(1, 100, 2, dimnames = list(paste0("G", 1:100), c("S1", "S2")))
  expect_invisible(validate_count_matrix(good_counts))

  good_meta <- data.frame(sample_id = c("S1", "S2"))
  expect_invisible(validate_metadata(good_meta, c("S1", "S2")))
})
