# Davies Breakpoint Test Prototype (v1)

## Overview
Reproduce Davies' tests for detecting breakpoints (structural change points) in bi-exponential time series. Key for validating regime shifts in LTEE-like data.

## Literature Sources
- Davies, R. B. (1987). "Hypothesis testing when a nuisance parameter is present only under the alternative." Biometrika, 74(2), 335–346.
- Davies, R. B. (1989). "The null distribution of the likelihood ratio statistic for a mixture model with two components." Journal of the Royal Statistical Society, Series B, 51(1), 135–145.
- Implemented via: `strucchange` package (CRAN Task View: Econometrics)

## Implementation Strategy
1. Use `strucchange::breakpoints()` as reference implementation
2. Reproduce Davies' asymptotic p-value corrections (not standard χ²)
3. Generate synthetic datasets with known break points
4. Validate recovery rate across k1/k2 regimes

## Deliverables
- `test-davies.R`: TDD suite with synthetic data validation
- `implement-davies.R`: Wrapper around `strucchange::breakpoints()`
- `traceability.md`: Number tracing to Davies papers + package docs
- `contract.md`: BDD specification for behavioral guarantees

---

## Next Steps (Current Session)
1. Create file structure (this README) ✅
2. Write test cases first → NEXT
3. Implement wrapper function
4. Run test suite → all green
5. Commit to branch `prototype/davies-breakpoint-v1`
6. Repeat traceability + contract patterns from MARQUARDT

Ready to proceed?
