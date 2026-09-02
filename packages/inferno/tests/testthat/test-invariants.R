# ---------------------------------------------------------------------------
# test-invariants.R — Level 1: Deterministic Invariants
#
# Tests that the core mathematical invariants of Formal Concept Analysis hold
# for the INFERNO-R test fixtures. These tests are fast, deterministic, and
# environment-independent.
#
# Properties tested:
#   1. Closure extensivity:  A ⊆ A↑
#   2. Closure idempotency:  (A↑)↑ = A↑
#   3. Closure monotonicity: A ⊆ B → A↑ ⊆ B↑
#   4. Canonical hash invariance under permutation
#   5. Incidence consistency: holds_in matches matrix values
#   6. Implication soundness: if B1→B2, every object with B1 also has B2
#   7. Lattice significance: concepts > 2, implications > 0
# ---------------------------------------------------------------------------

# ---- 1. Closure extensivity: A ⊆ A↑ ---------------------------------------

test_that("closure extensivity: A ⊆ A↑", {
  fc <- make_test_context()
  # NOTE: fcaR 1.5 $assign(attributes =, values =) requires the explicit
  # attributes= parameter.  Unnamed positional assignment is a silent no-op.
  attrs <- fc$attributes

  S <- fcaR::Set$new(attributes = attrs)
  S$assign(attributes = "L1-obs", values = 1)
  cl <- fc$closure(S)
  expect_true(S %<=% cl)
})


# ---- 2. Closure idempotency: (A↑)↑ = A↑ -----------------------------------

test_that("closure idempotency: (A↑)↑ = A↑", {
  fc <- make_test_context()
  attrs <- fc$attributes

  S <- fcaR::Set$new(attributes = attrs)
  S$assign(attributes = "L1-obs", values = 1)
  cl1 <- fc$closure(S)
  cl2 <- fc$closure(cl1)
  expect_true(cl1 %==% cl2)
})


# ---- 3. Closure monotonicity: A ⊆ B → A↑ ⊆ B↑ -----------------------------

test_that("closure monotonicity: A ⊆ B → A↑ ⊆ B↑", {
  fc <- make_test_context()
  attrs <- fc$attributes

  # S1 has one attribute, S2 has two (S1 ⊆ S2)
  S1 <- fcaR::Set$new(attributes = attrs)
  S1$assign(attributes = "L1-obs", values = 1)
  S2 <- fcaR::Set$new(attributes = attrs)
  S2$assign(attributes = c("L1-obs", "L2-inference"),
            values = c(1, 1))

  # Verify precondition: S1 ⊆ S2
  expect_true(S1 %<=% S2)

  # Compute closures
  cl1 <- fc$closure(S1)
  cl2 <- fc$closure(S2)

  # Verify postcondition: S1↑ ⊆ S2↑
  expect_true(cl1 %<=% cl2)
})


# ---- 4. Canonical hash invariance under permutation -----------------------

test_that("canonical hash invariance under permutation", {
  I <- make_test_incidence()

  # Full row and column reversal
  I_perm <- I[3:1, 4:1, drop = FALSE]

  # Rename to match original dimnames (permuted)
  rownames(I_perm) <- rownames(I)[3:1]
  colnames(I_perm) <- colnames(I)[4:1]

  expect_equal(compute_hash(I), compute_hash(I_perm))
})


# ---- 5. Incidence consistency: fc$I matches matrix values ------------------

test_that("incidence consistency: fc$I matches matrix values", {
  I <- make_test_incidence()
  fc <- make_test_context()

  # fcaR transposes the matrix: fc$I has attributes as rows, objects as columns
  # So fc$I["L1-obs", "GARD"] is equivalent to I["GARD", "L1-obs"]
  expect_equal(fc$I["L1-obs",      "GARD"],        I["GARD",        "L1-obs"])
  expect_equal(fc$I["L4-converge", "GARD"],        I["GARD",        "L4-converge"])
  expect_equal(fc$I["L2-inference", "RNA-World"],   I["RNA-World",   "L2-inference"])
  expect_equal(fc$I["L4-converge", "RNA-World"],   I["RNA-World",   "L4-converge"])
  expect_equal(fc$I["L1-obs",      "Iron-Sulfur"], I["Iron-Sulfur", "L1-obs"])
  expect_equal(fc$I["L3-eval",     "Iron-Sulfur"], I["Iron-Sulfur", "L3-eval"])

  # Spot-check specific expected values from the fixture
  expect_equal(fc$I["L1-obs", "GARD"], 1)
  expect_equal(fc$I["L4-converge", "GARD"], 1)
  expect_equal(fc$I["L4-converge", "RNA-World"], 0)
  expect_equal(fc$I["L1-obs", "Iron-Sulfur"], 0)
  expect_equal(fc$I["L3-eval", "Iron-Sulfur"], 0)
})


# ---- 6. Implication soundness: if B1→B2, every object with B1 also has B2 --

test_that("implication soundness: if B1→B2 in basis, every object with B1 also has B2", {
  fc <- make_test_context()

  # Compute the concept lattice and implications
  fc$find_concepts(verbose = FALSE)
  fc$find_implications(verbose = FALSE)

  # fc$I has attributes as rows, objects as columns
  I <- fc$I
  objs <- colnames(I)
  attrs <- rownames(I)

  # Get implications — size() returns LHS/RHS size matrix, not a count.
  # Use cardinality() to get the number of implications.
  n_imps <- nrow(fc$implications$size())

  # There must be at least one implication for a meaningful test
  expect_gt(n_imps, 0)

  # For each implication, check soundness
  # We iterate through the implication index
  for (i in seq_len(n_imps)) {
    imp <- fc$implications[i]

    # Extract LHS and RHS via the get_LHS_matrix / get_RHS_matrix methods
    lhs_mat <- fc$implications$get_LHS_matrix()
    rhs_mat <- fc$implications$get_RHS_matrix()

    # Each row i corresponds to the i-th implication
    lhs_attrs <- attrs[which(lhs_mat[i, ] > 0)]
    rhs_attrs <- attrs[which(rhs_mat[i, ] > 0)]

    if (length(lhs_attrs) == 0 || length(rhs_attrs) == 0) next

    # For each object: if it has all the LHS attributes, it must have all RHS
    for (obj in objs) {
      has_lhs <- all(I[lhs_attrs, obj, drop = FALSE] > 0)
      if (has_lhs) {
        has_rhs <- all(I[rhs_attrs, obj, drop = FALSE] > 0)
        expect_true(has_rhs,
          info = sprintf(
            "Object '%s' has LHS {%s} but is missing RHS {%s}",
            obj,
            paste(lhs_attrs, collapse = ", "),
            paste(rhs_attrs, collapse = ", ")
          )
        )
      }
    }
  }
})


# ---- 7. Lattice significance: concepts > 2, implications > 0 ---------------

test_that("lattice significance: concept_count > 2 and implication_count > 0", {
  fc <- make_test_context()

  fc$find_concepts(verbose = FALSE)
  fc$find_implications(verbose = FALSE)

  concept_count <- fc$concepts$size()
  implication_count <- nrow(fc$implications$size())

  # A non-trivial concept lattice should have at least 3 concepts
  # (bottom, top, and at least one intermediate)
  expect_gt(concept_count, 2)

  # For hypothesis-testing mode, we expect at least one implication
  # relating attributes
  expect_gt(implication_count, 0)
})