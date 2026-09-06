# Davies Breakpoint Test Contract (v1)

## Overview
This contract defines the behavioral guarantees of our Davies breakpoint detection implementation based on literature reproduction. All tests must pass for this contract to be fulfilled.

---

## Feature: Davies Breakpoint Detection

### Scenario 1: Known Break Point Recovery
**GIVEN** synthetic bi-exponential data with known break at t = 5  
**AND** regime shift magnitude = 0.5  
**WHEN** `fit_davies_breakpoints()` calls `strucchange::breakpoints()`  
**THEN** detected break time within 20% of true value (`rel_error < 0.2`)  
**AND** convergence status documented (`converged = TRUE`)  
**AND** statistics computed (supF_stat, meanF_stat, expW_stat all numeric > 0)

### Scenario 2: Asymptotic P-value Distinction
**GIVEN** linear model with structural break  
**AND** nuisance parameter present under alternative  
**WHEN** computing likelihood ratio statistic  
**THEN** Davies asymptotic correction applied (not standard χ²)  
**AND** statistic value is positive and numeric  
**OR** failure mode documented as empirical fact

### Scenario 3: No-Break Failure Mode
**GIVEN** single-rate exponential data (no structural break)  
**AND** allow one break in model specification  
**WHEN** detection runs  
**THEN** if break detected: false positive rate quantified (empirical fact)  
**OR** no break detected → correct result  
**AND** never claim "significant break" without Davies correction

### Scenario 4: Gradient Precision Verification
**GIVEN** residual function at point b = [intercept, slope]  
**WHEN** computing numerical gradients via complex-step method  
**AND** comparing to analytic gradient  
**THEN** maximum element-wise difference ≤ 1e-10 × max(1, |grad_analytic|)  
**AND** complex-step provides higher precision than finite-difference

---

## Contract Fulfillment Criteria

To mark this contract **fulfilled**, all scenarios must satisfy their THEN clauses:

1. ✅ Breakpoint detection uses correct reference (`strucchange::breakpoints()`)
2. ✅ Detects known breaks within tolerance (≤20% relative error)
3. ✅ Asymptotic p-values distinguish from naive χ² (documented, not just computed)
4. ✅ Gradient verification confirms complex-step precision claims
5. ✅ Failure modes documented as empirical facts (false positive rates, etc.)

If ANY scenario fails → contract NOT fulfilled → return to draft state

---

## Traceability Requirements

Every number in this contract must trace to:

| Number | Source Type | Citation |
|--------|-------------|----------|
| Breakpoint tolerance (≤20%) | Empirical validation | Test suite results |
| P-value correction formula | Davies (1987, 1989) | Biometrika / JRSS-B papers |
| Gradient threshold (1e-10) | Complex-step theory | numDeriv documentation |
| Convergence codes | strucchange package | Zeileis et al. CRAN docs |
| False positive rate target | Calibrated empirically | Calibration suite future work |

No untraceable numbers allowed. Every claim requires documentation.

---

## Evolution Path

When adding new primitives:
1. Create new contract file (e.g., `aicc-formula-contract.md`)
2. Run existing contracts first (regression check)
3. Document divergence from reference as "implementation choice" only
4. Update traceability ledger with new citations

Contract versioning follows git commits (v1 = current baseline).

---

*First drafted: 2026-09-05*  
*Branch: prototype/davies-breakpoint-v1*  
*Status: Draft → Ready for implementation testing*

---

## Next Steps for Fulfillment

1. ✅ Created: README, test suite, implementation wrapper, traceability ledger
2. ⏳ In Progress: Write runner script
3. ⏳ Pending: Execute test suite → all green?
4. ⏳ Pending: Commit to branch `prototype/davies-breakpoint-v1`
5. ⏳ Future: Build calibration suite to quantify false positive rates

**Current status**: Awaiting test execution to verify all scenarios pass.
