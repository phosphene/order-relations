# MARQUARDT Algorithm Contract (v1)

## Overview
This contract defines the behavioral guarantees of our MARQUARDT algorithm implementation based on literature reproduction. All tests must pass for this contract to be fulfilled.

---

## Feature: MARQUARDT Algorithm Implementation

### Scenario 1: Numerical Recipes Example Validation
**GIVEN** synthetic data from Numerical Recipes Chapter 15.3  
**AND** initial parameters [1.5, 2.5, 0.4]  
**WHEN** `fit_marquardt_biexp()` calls `minpack.lm::nls.lm()`  
**THEN** fit converges (`info` code indicates success)  
**AND** parameters recover true values within tolerance:
- `A1 ∈ [1.8, 2.2]` (true = 2.0, noise ±0.02)
- `k1 ∈ [2.7, 3.3]` (true = 3.0, noise ±0.02)  
- `A2 ∈ [0.4, 0.6]` (true = 0.5, noise ±0.02)

### Scenario 2: Degenerate Case Handling
**GIVEN** overdetermined linear-exponential system  
**AND** biased initial parameters  
**WHEN** fitting completes  
**THEN** convergence status is documented (`info` ≠ NULL)  
**AND** fitted parameters remain physically plausible (all > 0)  
**AND** parameters within 30% of truth

### Scenario 3: Bi-Exponential Distinct Rates
**GIVEN** LTEE-like regime (k1/k2 ≈ 37.7)  
**AND** poor initial guess (all rates = 1.0)  
**WHEN** fitting runs  
**THEN** if two distinct rates recovered: `ratio_fitted ≥ 1.5`  
**OR** failure mode documented as empirical fact (rates collapsed to single rate)  
**AND** convergence status recorded (even if partial success)

### Scenario 4: Jacobian Precision Verification
**GIVEN** residual function at point p = [2, 3, 0.5]  
**WHEN** computing numerical Jacobian via complex-step method (`numDeriv::grad(..., method="complex")`)  
**AND** comparing to finite-difference approximation  
**THEN** maximum element-wise difference ≤ 1e-10 × max(1, |j_ref|)  
**AND** complex-step provides higher precision than FD

---

## Contract Fulfillment Criteria

To mark this contract **fulfilled**, all scenarios must satisfy their THEN clauses:

1. ✅ Convergence detection uses correct field (`info`, not `convergence`)
2. ✅ Parameters recovered match ground truth within specified tolerances
3. ✅ Failure modes documented as empirical facts (not gaps)
4. ✅ Jacobian verification confirms complex-step precision claims

If ANY scenario fails → contract NOT fulfilled → return to draft state

---

## Traceability Requirements

Every number in this contract must trace to:

| Number | Source Type | Citation |
|--------|-------------|----------|
| Initial parameters [1.5, 2.5, 0.4] | Literature example | Numerical Recipes Ch.15.3 |
| Tolerance bounds (±30%, etc.) | Empirical validation | Test suite results |
| Jacobian threshold (1e-10) | Complex-step theory | `numDeriv` docs |
| Convergence codes | MINPACK specification | Argonne National Lab 1980 |

No untraceable numbers allowed. Every claim requires documentation.

---

## Evolution Path

When adding new primitives:
1. Create new contract file (e.g., `davies-breakpoint-contract.md`)
2. Run existing contracts first (regression check)
3. Document divergence from reference as "implementation choice" only
4. Update traceability ledger with new citations

Contract versioning follows git commits (v1 = current baseline).

---

*First drafted: 2026-09-05*  
*Branch: prototype/marquardt-v1*  
*Status: Draft → Ready for review*
