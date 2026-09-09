# Davies Asymptotic P-Value Contract (v1)

## Feature: Davies Correction for Nuisance Parameter Under Alternative

### Scenario 1: Ordering Invariant
**GIVEN** any SupF statistic LR_stat >= 0 and any effective nuisance count m_eff >= 1
**WHEN** `davies_pvalue(LR_stat, m_eff)` is computed
**THEN** p_davies >= p_naive (the correction never makes rejection EASIER)
**AND** p_davies <= 1 and p_davies >= 0

### Scenario 2: Correction Grows With Nuisance Dimension
**GIVEN** fixed LR_stat = 8.0
**WHEN** comparing p_davies across m_eff in {1, 10, 100, 1000}
**THEN** p_davies is non-decreasing in m_eff (larger search space, larger correction)

### Scenario 3: Naive Anti-Conservatism Demonstrated
**GIVEN** LR_stat in the tail regime (e.g. 10.0) with large m_eff (e.g. 500)
**WHEN** comparing naive chi-square tail vs Davies-corrected tail
**THEN** p_davies > p_naive by a documented factor
**AND** the ratio is reported as an empirical fact (not claimed as exact)

### Scenario 4: Cross-Check Against strucchange Reference
**GIVEN** a linear regression with known structural break
**WHEN** strucchange::sctest(type="F") computes its SupF p-value
**AND** our davies_pvalue is applied to the same statistic at m_eff = n-1
**THEN** both p-values are the same order of magnitude (within factor 10)
**AND** neither implementation's value is treated as ground truth — both are recorded

### Scenario 5: Degenerate Inputs Handled
**GIVEN** LR_stat = 0 or m_eff = 1
**WHEN** davies_pvalue is called
**THEN** p_davies equals the naive tail (no spurious correction)
**AND** no errors are thrown

---

## Honest Limitation (part of the contract, not hidden)
This implementation provides closed-form bounds (union + extreme-value
refinement) on the Davies-corrected p-value. It does NOT perform the full
numerical quadrature of Davies' integral (his eq. 3.3). Any empirical use
must carry the caveat: "bounded Davies correction, not exact quadrature."
Contract fulfillment means the invariants and cross-checks hold — NOT that
the exact Davies integral has been reproduced.

## Traceability
| Number | Source |
|--------|--------|
| Union bound form | Bonferroni inequality; Davies 1987 §1–2 |
| sqrt(2 log m) refinement | extreme-value theory; Davies 1987 eq. (3.4) region |
| Ordering invariant | logical requirement of the correction |
| Factor-10 cross-check window | empirical comparability, not equivalence claim |

*Branch: feat/foundry-prototypes-v1 · v1 = current baseline*
