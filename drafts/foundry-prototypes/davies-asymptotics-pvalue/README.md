# Davies Asymptotic P-Value Implementation Prototype (v1)

## Overview
Independently implement Davies' asymptotic p-value corrections from first principles, providing verification that `strucchange` computes the corrections correctly per Davies (1987). Critical for validating structural break detection claims.

## Literature Sources
- **Primary**: Davies, R. B. (1987). "Hypothesis testing when a nuisance parameter is present only under the alternative." *Biometrika*, 74(2), 335–346. (Appendix contains asymptotic derivation)
- **Secondary**: Davies, R. B. (1989). "The null distribution of the likelihood ratio statistic for a mixture model with two components." *Journal of the Royal Statistical Society, Series B*, 51(1), 135–145.
- **Implementation Reference**: `strucchange` package (as reference implementation to verify against)

## Key Question
*Does Davies' asymptotic correction actually differ significantly from naive χ² approximation in practice? And can we reproduce it from first principles?*

## Implementation Strategy
1. Reproduce Davies' asymptotic formula from Appendix A of Davies (1987)
2. Compare against naive χ² approximation
3. Quantify divergence as function of n, k, and other parameters
4. Verify against `strucchange::breakpointsTest()` output
5. Establish when asymptotic correction matters vs when naive approach suffices

## Deliverables
- `test-davies-asymptotics.R`: TDD suite with synthetic data validation
- `implement-davies-asymptotics.R`: Manual implementation of Davies' formula
- `traceability.md`: Number tracing to Davies papers + verification results
- `contract.md`: BDD specification for behavioral guarantees
- `run-prototype.R`: Executable test runner

---

## Next Steps (Current Session)
1. ✅ Create directory structure (this README)
2. ⏳ Write test cases first
3. ⏳ Implement manual calculation
4. ⏳ Run test suite → all green
5. ⏳ Commit to branch `prototype/davies-asymptotics-pvalue-v1`
6. ⏳ Update main README with completed status

Ready to proceed?
