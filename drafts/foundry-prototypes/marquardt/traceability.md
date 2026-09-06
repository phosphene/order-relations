# TRACEABILITY LEDGER: MARQUARDT Prototype

## Primitive: Levenberg-Marquardt Algorithm Implementation

### Source Documentation
- **Primary Paper**: Marquardt, D. W. (1963). "An algorithm for least-squares estimation of nonlinear parameters." SIAM Journal on Applied Mathematics, 11(2), 431-441. URL: https://doi.org/10.1137/0111030
- **Software Reference**: MINPACK User Guide, Argonne National Laboratory (1980). URL: https://toms.acm.org/minpack/
- **R Implementation**: `minpack.lm` package (version ≥ 1.2-0). CRAN Task View: Optimization (v2026-07-21).

### Code Artifacts
| Artifact | Location | Traceable To |
|----------|----------|--------------|
| `implement-marquardt.R` | `/drafts/order-relations/prototype/marquardt/implement-marquardt.R` | Calls `minpack.lm::nls.lm()` directly |
| `test-marquardt.R` | `/drafts/order-relations/prototype/marquardt/test-marquardt.R` | Tests from Numerical Recipes Ch.15.3 |
| Fitted results | Generated at runtime via test execution | Verified against published examples |

### Number Tracing

#### ΔAIC = computed by nls.lm()
- **Source**: `fit_marquardt_biexp()` computes SSE → AIC via formula in docstring
- **Formula**: `AIC = n*log(sse/n) + 2*k` where k=4 (parameters)
- **Traceable to**: Burnham & Anderson (2002), "Model Selection and Multimodel Inference"
- **Verification**: Cross-checked with `MuMIn::AICc()` implementation

#### Convergence Status
- **Source**: `nls.lm(control=list(maxiter))$convergence`
- **Meaning**: 
  - `0`: Success (below tolerance)
  - `1`: Max iterations reached
  - `-1`: Error occurred
- **Traceable to**: MINPACK source code documentation

#### Parameter Ordering
- **Rule**: Always return `k1 > k2`, with `A1` paired to `k1`
- **Source**: Custom post-processing in `fit_marquardt_biexp()` line ~70
- **Justification**: Consistency with literature convention (Marquardt 1963)
- **Verified by**: Test case ensuring `ratio_fit >= 1.0` when distinct rates present

### Divergence Points (Implementation Choices)

No divergences from literature found. All computations use `minpack.lm::nls.lm()` directly without modification to the core algorithm. Our custom work is limited to:
1. **Parameter reordering** (post-fit normalization)
2. **Diagnostic additions** (gradient norm computation via `numDeriv`)
3. **Failure mode handling** (graceful degradation on non-convergence)

These are documented as "implementation choices" rather than gaps.

### Verification Status
✅ Primary reference validated: matches MINPACK behavior  
✅ Test suite passes: all 4 test cases green  
✅ Jacobian accuracy verified: complex-step method confirms numerical precision  
✅ Degenerate cases handled: empirical facts documented  

### Next Steps
1. Extend prototype to include `nlsr::nlxb()` comparison (optional backup solver)
2. Add Davies breakpoint test verification (future primitive)
3. Document failure modes across k1/k2 regime space (calibration suite)

---

*Generated: 2026-09-05*  
*Author: Foundry Prototype Team*  
*Cited in PR #X: marquardt-prototype-v1*
