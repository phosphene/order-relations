# Order-Relations Prototype Suite (v1)

**Status**: Active development  
**Branch**: `prototype/marquardt-v1`  
**Repository**: phosphene/order-relations  

---

## Overview

This repository contains test-driven prototypes of numerical primitives used in the order-relations framework. Each prototype:

1. **Reproduces literature algorithms** using open-source R packages as reference implementations
2. **Uses TDD methodology** – tests written first, then implementation
3. **Includes full traceability** – every number traced to primary sources (papers, package docs)
4. **Has BDD contracts** – behavioral guarantees formalized as Given-When-Then scenarios
5. **Is fully validated** – all tests must pass for contract fulfillment

---

## ✅ Completed Prototypes

### 1. MARQUARDT Algorithm (Levenberg-Marquardt Optimization)

**Literature References:**
- Marquardt, D. W. (1963). "An algorithm for least-squares estimation of nonlinear parameters." *SIAM Journal on Applied Mathematics*, 11(2), 431-441.
- MINPACK User Guide, Argonne National Laboratory (1980).
- Numerical Recipes, 3rd ed., Chapter 15.3.

**Implementation:** Wrapper around `minpack.lm::nls.lm()` with post-processing additions (parameter ordering, diagnostic additions).

**Test Results:** 13 sub-tests green across 4 test suites
- ✅ Numerical Recipes Ch.15.3 validation (parameter recovery within tolerance)
- ✅ Degenerate case handling (physical plausibility maintained)
- ✅ LTEE-like regime testing (k1/k2 ratio ~37)
- ✅ Jacobian verification via complex-step (numDeriv precision)

**Key Findings:**
- Convergence uses `info` field (not `convergence`) – documented in traceability ledger
- No divergences from algorithm; only implementation choices (parameter ordering, diagnostics)

**Deliverables:**
- `implement-marquardt.R`
- `test-marquardt.R`
- `traceability.md`
- `contract.md` (BDD specification with 4 scenarios)
- `run-prototype.R`

---

### 2. Davies Breakpoint Test (Structural Change Detection)

**Literature References:**
- Davies, R. B. (1987). "Hypothesis testing when a nuisance parameter is present only under the alternative." *Biometrika*, 74(2), 335–346.
- Davies, R. B. (1989). "The null distribution of the likelihood ratio statistic for a mixture model with two components." *Journal of the Royal Statistical Society, Series B*, 51(1), 135–145.
- `strucchange` package (CRAN Task View: Econometrics).

**Implementation:** Wrapper around `strucchange::breakpoints()` for detecting structural breaks in bi-exponential time series.

**Test Results:** 10 sub-tests green across 4 test suites
- ✅ Known break point recovery (within 20% relative error)
- ✅ Asymptotic p-value vs naive χ² distinction
- ✅ Failure mode documentation (single-rate data false positives)
- ✅ Gradient precision verification via complex-step

**Key Findings:**
- API corrected to use `breakpointsTest()` instead of non-existent `strLRtest()`
- Asymptotic p-values correctly applied per Davies theory
- False positive rates documented empirically (to be quantified in calibration suite)

**Deliverables:**
- `implement-davies.R`
- `test-davies.R`
- `traceability.md`
- `contract.md` (BDD specification with 4 scenarios)
- `run-prototype.R`

---

## 📋 Prospective Primitives (Next Steps)

Based on our research cycle discussion, here are recommended primitives to build next, in priority order:

### Priority 1: AICc Formula Reproduction
**Goal:** Implement Akaike Information Criterion with small-sample correction
- **Literature:** Hurvich & Lin (2008), Burnham & Anderson (2002)
- **Purpose:** Validate ΔAIC calculations in window_collapse_sweep against standard reference
- **Traceability:** Must cite exact formula source, verify n-k corrections apply
- **Why First:** Critical for the LTEE/C4 regime work where ΔAIC = 190 claim appears inflated

### Priority 2: Rate Law Equilibrium Verification
**Goal:** Verify equilibrium calculations from MPI Blueprint
- **Literature:** MPI Handoff Blueprint, rate law equations in `relaxation.R`
- **Purpose:** Confirm `rate_law_equilibrium(k1, k2, rho1, rho2)` computes correct weighted mean
- **Traceability:** Analytic derivation check, numerical stability verification
- **Why Second:** Foundation for bi-exponential relaxation models, used throughout order-relations

### Priority 3: Convergence Diagnostics Extension
**Goal:** Build comprehensive convergence checking beyond minpack.lm defaults
- **Literature:** Numerical Optimization texts (Nocedal & Wright 2006), convergence literature
- **Purpose:** Extend MARQUARDT wrapper with gradient-based and bound checks
- **Traceability:** Document each diagnostic criterion, cite threshold justifications
- **Why Third:** Natural extension of MARQUARDT, improves fit reliability

### Priority 4: Davies Asymptotic P-Value Implementation
**Goal:** Implement Davies' asymptotic corrections manually (not just via strucchange)
- **Literature:** Davies (1987) Appendix, asymptotic distribution theory
- **Purpose:** Independent verification of strucchange's internal calculations
- **Traceability:** Compare implemented formulas against paper derivations
- **Why Fourth:** Deep dive into theoretical foundations once core primitives established

### Priority 5: Gradient-Based Hessian Validation
**Goal:** Validate numerical Hessians from optimization routines
- **Literature:** numDeriv package docs, automatic differentiation literature
- **Purpose:** Ensure curvature estimates reliable for confidence interval computation
- **Traceability:** Compare complex-step vs finite-difference Hessians
- **Why Fifth:** Higher-order derivatives needed for uncertainty quantification

---

## 🔧 Foundry Approach

### How We Build
1. **Select primitive** from prospective list
2. **Gather literature** → create traceability matrix
3. **Write TDD tests first** → specify expected behavior
4. **Implement minimal wrapper** → deference to reference library
5. **Run full suite** → all tests must pass
6. **Document divergence points** → "implementation choice" not "gap"
7. **Create BDD contract** → formalize behavioral guarantees
8. **Commit to branch** → tag with PR #X for review

### Traceability Rule
Every numeric value appearing in code or tests must trace to one of:
- Primary literature citation (paper, theorem, equation number)
- Package documentation (package name, function, version)
- Empirical validation (test suite result, calibration study)

No untraceable numbers allowed. Every claim requires documentation.

### Contract Fulfillment Criteria
For a contract to be marked **fulfilled**, all scenario THEN clauses must pass:
1. Reference implementation invoked correctly
2. Parameters/values recover truth within tolerances
3. Failure modes documented as empirical facts (not gaps)
4. Precision claims verified (gradient/Hessian/etc.)

If ANY clause fails → contract NOT fulfilled → return to draft state.

---

## 📊 Current Status Summary

| Prototype | Branch | Tests Green | Contract Status | PR # |
|-----------|--------|-------------|-----------------|------|
| MARQUARDT | `prototype/marquardt-v1` | 13/4 | ✅ Fulfilled | TBD |
| Davies Breakpoint | `prototype/marquardt-v1` | 10/4 | ✅ Fulfilled | TBD |

**Next milestone:** Push PR(s) to `phosphene/order-relations`, then begin Priority 1 (AICc Formula Reproduction).

---

*Last updated: 2026-09-06*  
*Author: Foundry Team (QQ, Ed Phil, Jan)*
