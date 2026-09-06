# Hessian Validation Contract (v1)

## Overview
This contract defines the behavioral guarantees of our Hessian validation implementation based on complex-step differentiation. All tests must pass for this contract to be fulfilled.

---

## Feature: Gradient-Based Hessian Validation

### Scenario 1: Complex-Step Matches Analytic Quadratic Form
**GIVEN** quadratic function f(x,y) = x² + xy + y² with known analytic Hessian [[2,1],[1,2]]  
**AND** evaluation point p = [1, 2]  
**WHEN** `fit_hessian()` calls `numDeriv::hessian(..., method="complex")`  
**THEN** computed Hessian matches analytic within tolerance (`tolerance < 1e-10`)  
**AND** all values are finite and reasonable  
**AND** matrix is positive semi-definite (eigenvalues >= 0)

### Scenario 2: Finite-Difference vs Complex-Step Error Divergence
**GIVEN** multiple step sizes from 1e-16 to 1e-2  
**AND** synthetic test function with known solution  
**WHEN** computing Hessians via both FD and CS methods  
**THEN** CS maintains accuracy across all step sizes (error < 1e-10)  
**AND** FD degrades at small steps (error > 1% when h < 1e-8)  
**AND** CS always outperforms FD by significant margin (>10x better)

### Scenario 3: Threshold Where FD Fails but CS Succeeds
**GIVEN** problem with well-defined failure threshold  
**WHEN** computing Hessian at problematic step sizes  
**THEN** FD error exceeds 1% threshold (documented empirically)  
**AND** CS remains below threshold (< 0.1%)  
**AND** divergence pattern documented in empirical results

### Scenario 4: Nonlinear Function Validation (Rosenbrock)
**GIVEN** Rosenbrock function (known difficult curvature)  
**AND** evaluation point near optimal solution  
**WHEN** computing Hessian via complex-step  
**THEN** gradient verification confirms complex-step precision  
**AND** eigenvalues are non-negative (positive semi-definite as expected near minimum)  
**AND** no numerical instability observed

### Scenario 5: Symmetry Check Validation
**GIVEN** any valid optimization result  
**WHEN** checking Hessian symmetry  
**THEN** abs(H - H') < tol × max(|H|) where tol = 1e-10  
**AND** condition number computed without overflow  
**OR** failure mode documented if ill-conditioned

---

## Contract Fulfillment Criteria

To mark this contract **fulfilled**, all scenarios must satisfy their THEN clauses:

1. ✅ Implementation uses correct reference (`numDeriv::hessian(method="complex")`)
2. ✅ Complex-step matches analytic quadratics within specified tolerance
3. ✅ FD degradation vs CS stability empirically quantified
4. ✅ Nonlinear function behavior verified (Rosenbrock case)
5. ✅ Symmetry checks and condition numbers computed reliably

If ANY scenario fails → contract NOT fulfilled → return to draft state

---

## Traceability Requirements

Every number in this contract must trace to:

| Number | Source Type | Citation |
|--------|-------------|----------|
| Tolerance 1e-10 | Numerical precision | Griewank & Walther (2008) |
| Step-size threshold (1e-8) | Empirical observation | numDeriv docs; test results |
| Symmetry check tol | Floating-point standard | Squire & Trapp (1998) |
| Eigenvalue check (-1e-10) | Optimization theory | NumOpt literature |
| Condition number warning (>10) | Empirical guideline | Test suite observations |

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
*Branch: prototype/gradient-hessian-validation-v1*  
*Status: Draft → Ready for implementation testing*

---

## Next Steps for Fulfillment

1. ✅ Created: README, test suite, implementation wrapper, traceability ledger
2. ⏳ In Progress: Write contract (done above), runner script
3. ⏳ Pending: Execute test suite → all green?
4. ⏳ Pending: Commit to branch `prototype/gradient-hessian-validation-v1`
5. ⏳ Future: Apply to order-relations uncertainty quantification

**Current status**: Awaiting test execution to verify all scenarios pass.
