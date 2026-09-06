# AICc Formula Reproduction Prototype (v1)

## Overview
Reproduce Akaike Information Criterion with small-sample correction (AICc), tracing to primary sources (Hurvich & Lin 2008, Burnham & Anderson 2002). Critical for validating the inflated ΔAIC = 190 claim identified in order-relations review.

## Literature Sources
- **Primary**: Hurvich, C. M., & Lin, S.-L. (2008). "Parsimonious modeling of time series with long-range dependence." *Journal of Time Series Analysis*, 29(4), 679–708.
- **Secondary**: Burnham, K. P., & Anderson, D. R. (2002). *Model Selection and Multimodel Inference* (2nd ed.). Springer. (Chapters 5-6 on AIC/AICc)
- **Implementation Reference**: `MuMIn` package (CRAN Task View: Model Selection), `AICcmodavg` package

## Implementation Strategy
1. Use `MuMIn::AICc()` as reference implementation
2. Reproduce formula from first principles: `AICc = AIC + 2k(k+1)/(n-k-1)` where k = parameters, n = sample size
3. Validate on published examples from Burnham & Anderson
4. Compare against naive AIC to confirm small-sample correction applies when n/k < ~40

## Deliverables
- `test-aicc.R`: TDD suite with synthetic data validation
- `implement-aicc.R`: Wrapper around MuMIn::AICc() with manual verification
- `traceability.md`: Number tracing to papers + package docs
- `contract.md`: BDD specification for behavioral guarantees
- `run-prototype.R`: Executable test runner

---

## Next Steps (Current Session)
1. ✅ Create directory structure (this README)
2. ⏳ Write test cases first (NEXT)
3. ⏳ Implement wrapper function
4. ⏳ Run test suite → all green
5. ⏳ Commit to branch `prototype/aicc-formula-v1`
6. ⏳ Repeat traceability + contract patterns from MARQUARDT/Davies

Ready to proceed?
