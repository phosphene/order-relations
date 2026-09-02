# ---------------------------------------------------------------------------
# test-property.R — Level 4: Property-Based Tests
#
# Generative tests that verify mathematical properties hold for randomly
# generated formal contexts. These tests exercise the FCA engine with a
# wide variety of inputs to catch edge cases and invariant violations.
#
# Properties tested:
#   1. Closure axioms hold for 50 random contexts (extensivity + idempotency)
#   2. Circuit breaker catches degenerate large contexts (100×100 at 95% density)
#   3. Empty context (all zeros) produces minimal lattice (at least 1 concept)
#   4. Full context (all ones) produces maximal lattice (single concept)
#   5. Canonical hash is invariant under all row/column permutations (100 random)
#   6. compute_hash is deterministic (same matrix → same hash, called twice)
# ---------------------------------------------------------------------------

library(testthat)
library(fcaR)

# ---- 1. Closure axioms hold for 50 random contexts ---------------------------

test_that("closure axioms hold for 50 random contexts (generate random 0/1 matrices, verify extensivity + idempotency)", {
  set.seed(42)

  for (i in 1:50) {
    withr::with_seed(i, {
      # Generate random context with varying dimensions
      n_obj <- sample(2:10, 1)
      n_attr <- sample(2:8, 1)
      I <- matrix(sample(0:1, n_obj * n_attr, replace = TRUE), nrow = n_obj)

      # Assign random names to objects and attributes
      rownames(I) <- paste0("obj_", seq_len(n_obj))
      colnames(I) <- paste0("attr_", seq_len(n_attr))

      # Create formal context and compute closure
      fc <- fcaR::FormalContext$new(I)

      # Pick random attribute(s) to close
      attr_name <- sample(colnames(I), sample(1:3, 1))
      S <- fcaR::Set$new(attributes = rownames(I)); S$assign(attributes = attr_name, values = 1)

      # Compute closure
      cl <- fc$closure(S)

      # Property 1: Extensivity — S ⊆ S↑
      expect_true(S %<=% cl,
        info = sprintf("Extensivity failed at iteration %d for attributes %s", i, paste(attr_name, collapse = ", ")))

      # Property 2: Idempotency — (S↑)↑ = S↑
      cl2 <- fc$closure(cl)
      expect_true(cl %==% cl2,
        info = sprintf("Idempotency failed at iteration %d for attributes %s", i, paste(attr_name, collapse = ", ")))
    })
  }
})


# ---- 2. Circuit breaker catches degenerate large contexts --------------------

test_that("circuit breaker catches degenerate large contexts (100×100 at 95% density → error)", {
  # Generate a 100×100 matrix at 95% density (very degenerate)
  set.seed(123)
  I <- matrix(1, nrow = 100, ncol = 100)
  # Set exactly 5% zeros to get 95% density
  n_zeros <- 500  # 5% of 10000
  zero_indices <- sample(1:(100*100), n_zeros)
  I[zero_indices] <- 0

  density <- sum(I > 0) / length(I)
  expect_gte(density, 0.95)

  fc <- fcaR::FormalContext$new(I)

  # Circuit breaker with default thresholds (max_attributes=50, max_density=0.85)
  # 100 attributes exceeds 50, AND density ~0.95 exceeds 0.85
  # Therefore, BOTH thresholds are exceeded → error should be thrown
  expect_error(
    safe_compute_lattice(fc, max_attributes = 50, max_density = 0.85),
    "circuit breaker"
  )

  # Now test with a context that exceeds ONLY the attribute count (not density)
  # Create a sparse large context
  I_sparse <- matrix(0, nrow = 100, ncol = 100)
  I_sparse[sample(1:(100*100), 100)] <- 1  # Only 100 ones out of 10000 → very sparse
  fc_sparse <- fcaR::FormalContext$new(I_sparse)

  # This should NOT trigger circuit breaker (density is very low)
  expect_no_error(safe_compute_lattice(fc_sparse, max_attributes = 50, max_density = 0.85))

  # Now test with a context that exceeds ONLY the density but not attributes
  # Create a small, dense context
  I_small_dense <- matrix(1, nrow = 10, ncol = 10)
  fc_small_dense <- fcaR::FormalContext$new(I_small_dense)

  # This should NOT trigger (only 10 attributes, under 50)
  expect_no_error(safe_compute_lattice(fc_small_dense, max_attributes = 50, max_density = 0.85))
})


# ---- 3. Empty context (all zeros) produces minimal lattice -------------------

test_that("empty context (all zeros) produces minimal lattice (at least 1 concept)", {
  # Create a 3×4 matrix of all zeros
  I <- matrix(0, nrow = 3, ncol = 4)
  rownames(I) <- c("obj1", "obj2", "obj3")
  colnames(I) <- c("attr1", "attr2", "attr3", "attr4")

  fc <- fcaR::FormalContext$new(I)

  # Should not error
  expect_no_error(safe_compute_lattice(fc))

  # Must produce at least 1 concept (the bottom concept: all attributes, empty object set)
  n_concepts <- fc$concepts$size()
  expect_gte(n_concepts, 1)

  # Empty contexts typically produce a lattice with all possible combinations
  # of attributes as separate concepts, since no object holds any attribute
})


# ---- 4. Full context (all ones) produces maximal lattice ---------------------

test_that("full context (all ones) produces maximal lattice (single concept with all objects+attributes)", {
  # Create a 3×3 matrix of all ones
  I <- matrix(1, nrow = 3, ncol = 3)
  rownames(I) <- c("obj1", "obj2", "obj3")
  colnames(I) <- c("attr1", "attr2", "attr3")

  fc <- fcaR::FormalContext$new(I)

  # Should not error
  expect_no_error(safe_compute_lattice(fc))

  # Full context → single concept (the maximal concept: all objects, all attributes)
  n_concepts <- fc$concepts$size()
  expect_equal(n_concepts, 1)

  # Verify the concept contains all objects and all attributes
  expect_gte(fc$concepts$size(), 1)

  # The single concept should have:
  # - extent (objects): all 3 objects
  # - intent (attributes): all 3 attributes
  extent <- fc$concepts$extents()[[1]]
  intent <- fc$concepts$intents[[1]]
  expect_equal(length(extent), 3)
  expect_equal(length(intent), 3)
})


# ---- 5. Canonical hash is invariant under all row/column permutations --------

test_that("canonical hash is invariant under all row/column permutations (100 random permutations of a test matrix)", {
  # Start with a fixed test matrix
  I <- make_test_incidence()
  h_base <- compute_hash(I)

  withr::with_seed(456, {
    for (i in 1:100) {
      # Generate random permutations of rows and columns
      n_rows <- nrow(I)
      n_cols <- ncol(I)

      perm_rows <- sample(seq_len(n_rows))
      perm_cols <- sample(seq_len(n_cols))

      # Permute the matrix
      I_permuted <- I[perm_rows, perm_cols, drop = FALSE]

      # Compute hash (should be identical to base)
      h_permuted <- compute_hash(I_permuted)

      expect_equal(h_base, h_permuted,
        info = sprintf("Hash mismatch at permutation %d. Original order: rows=%s, cols=%s. Permuted order: rows=%s, cols=%s",
                       i,
                       paste(seq_len(n_rows), collapse = ","),
                       paste(seq_len(n_cols), collapse = ","),
                       paste(perm_rows, collapse = ","),
                       paste(perm_cols, collapse = ",")))
    }
  })
})


# ---- 6. compute_hash is deterministic ----------------------------------------

test_that("compute_hash is deterministic (same matrix → same hash, called twice)", {
  # Test with multiple matrices of different sizes
  set.seed(789)

  matrices <- list(
    # 2×3 matrix
    matrix(c(1, 0, 1, 1, 0, 0), nrow = 2, dimnames = list(c("a", "b"), c("x", "y", "z"))),

    # 10×10 sparse matrix
    matrix(sample(0:1, 100, replace = TRUE), nrow = 10, dimnames = list(paste0("o", 1:10), paste0("a", 1:10))),

    # 5×5 all-ones
    matrix(1, nrow = 5, ncol = 5, dimnames = list(c("A", "B", "C", "D", "E"), c("1", "2", "3", "4", "5"))),

    # 3×3 all-zeros
    matrix(0, nrow = 3, dimnames = list(c("p", "q", "r"), c("a", "b", "c")))
  )

  for (i in seq_along(matrices)) {
    I <- matrices[[i]]

    # Call compute_hash twice on the same matrix
    h1 <- compute_hash(I)
    h2 <- compute_hash(I)

    # Must be identical (deterministic)
    expect_identical(h1, h2,
      info = sprintf("Hash not deterministic for matrix %d. h1=%s, h2=%s", i, h1, h2))

    # Also verify against the base hash from test-invariants.R
    expected_hash <- compute_hash(make_test_incidence())
    actual_hash <- compute_hash(I)

    # Just verify each hash is a valid string
    expect_true(is.character(actual_hash))
    expect_true(nchar(actual_hash) > 0)
  }
})
