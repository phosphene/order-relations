# AICc Formula Contract (v1)

## Overview
This contract defines the behavioral guarantees of our AICc implementation based on literature reproduction. All tests must pass for this contract to be fulfilled.

---

## Feature: Akaike Information Criterion with Small-Sample Correction

### Scenario 1: Published Example Validation
**GIVEN** example from Burnham & Anderson (2002) Example 6.1  
**AND** linear model y = a + b*x with k = 2 parameters, n = 20 observations  
**WHEN** `fit_aicc()` calls `MuMIn::AICc()`  
**THEN** AICc value matches manual calculation within tolerance (`tolerance < 1e-10`)  
**AND** correction term is significant (> 1.0 for small sample)  
**AND** both AIC and AICc are finite and positive

### Scenario 2: Small Sample Correction Significance
**GIVEN** two datasets: one with n/k = 7.5 (small), one with n/k = 250 (large)  
**WHEN** computing AIC vs AICc for each  
**THEN** small sample correction > 1.0 for n/k = 7.5 case  
**AND** small sample correction < 0.1 for n/k = 250 case  
**AND** correction magnitude decreases as n/k increases

### Scenario 3: Consistency with Naive AIC for Large Samples
**GIVEN** multiple models with increasing sample sizes (n = 50, 100, 500, 1000)  
**AND** constant number of parameters (k = 2)  
**WHEN** comparing AIC vs AICc  
**THEN** relative difference between them < 5% for all cases  
**AND** AICc converges to AIC as n → ∞

### Scenario 4: Model Selection Ranking Correctness
**GIVEN** true bi-exponential model and underfitting mono-exponential alternative  
**WHEN** computing AICc for both  
**THEN** correct model has lower AICc value  
**AND** ΔAICc > 2 units indicates meaningful improvement  
**AND** model selection correctly identifies better-fitting model

### Scenario 5: Gradient Precision Verification
**GIVEN** log-likelihood function at parameter values  
**WHEN** computing numerical gradients via complex-step method  
**AND** comparing to analytic or other numerical approximation  
**THEN** maximum element-wise difference ≤ 1e-10 × max(1, |grad_ref|)  
**AND** complex-step provides higher precision than finite-difference

---

## Contract Fulfillment Criteria

To mark this contract **fulfilled**, all scenarios must satisfy their THEN clauses:

1. ✅ Implementation uses correct reference (`MuMIn::AICc()`)
2. ✅ Manual calculation matches library output within specified tolerance
3. ✅ Small-sample correction behaves as expected (threshold validated)
4. ✅ Model ranking correctness verified on synthetic data
5. ✅ Gradient verification confirms numerical precision claims

If ANY scenario fails → contract NOT fulfilled → return to draft state

---

## Traceability Requirements

Every number in this contract must trace to:

| Number | Source Type | Citation |
|--------|-------------|----------|
| Formula `2k(k+1)/(n-k-1)` | Literature equation | Burnham & Anderson (2002) Eq. 6.3 |
| Threshold n/k < 40 | Practical guideline | Burnham & Anderson (2002) Chapter 6 |
| Correction significance (> 1.0) | Empirical validation | Test suite results |
| Delta thresholds (2, 10) | Practical guide | Burnham & Anderson (2002) Table 6.2 |
| Gradient threshold (1e-10) | Complex-step theory | numDeriv documentation |

No untraceable numbers allowed. Every claim requires documentation.

---

## Evolution Path

When adding new primitives:
1. Create new contract file (e.g., `rate-law-contract.md`)
2. Run existing contracts first (regression check)
3. Document divergence from reference as "implementation choice" only
4. Update traceability ledger with new citations

Contract versioning follows git commits (v1 = current baseline).

---

*First drafted: 2026-09-06*  
*Branch: prototype/aicc-formula-v1*  
*Status: Draft → Ready for implementation testing*

---

## Next Steps for Fulfillment

1. ✅ Created: README, test suite, implementation wrapper, traceability ledger
2. ⏳ In Progress: Write contract (done above), runner script
3. ⏳ Pending: Execute test suite → all green?
4. ⏳ Pending: Commit to branch `prototype/aicc-formula-v1`
5. ⏳ Future: Validate against order-relations ΔAIC = 190 claim

**Current status**: Awaiting test execution to verify all scenarios pass.
