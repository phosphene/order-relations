# TRACEABILITY LEDGER: Davies Asymptotic P-Value Implementation

## Primitive: Davies correction for nuisance-parameter-only-under-alternative

### Source Documentation
- **Primary**: Davies, R. B. (1987). "Hypothesis testing when a nuisance
  parameter is present only under the alternative." *Biometrika* 74(1):33–43.
  https://doi.org/10.1093/biomet/74.1.33
- **Cross-reference**: Davies, R. B. (1989). *JRSS-B* 51(1):135–145.
- **Software reference**: `strucchange` (Zeileis, Leisch, Hornik, Kleiber) —
  implements the SupF family with Davies-type asymptotics.

### Code Artifacts
| Artifact | Traceable To |
|----------|--------------|
| `implement-davies-asymptotics.R` | Davies 1987 boundary-crossing argument; union bound + sqrt(2 log m) extreme-value refinement |
| `test-davies-asymptotics.R` | Invariants from Davies §3 + cross-check vs strucchange::sctestF |
| `contract.md` | BDD spec |

### Number Tracing

#### Union bound (m × p_single)
- **Source**: Bonferroni/union inequality — P(max of m) <= m·P(single).
- **Traceable to**: Davies (1987) §1–2 argument that naive chi-square ignores
  the supremum; the union bound is the elementary conservative version.

#### sqrt(2 log m) extreme-value refinement
- **Source**: max of ~m unit-variance chi2(1) evaluations concentrates at
  scale 2·log(m); boundary crossing rate gives the sqrt(2 log m) denominator.
- **Traceable to**: Davies (1987) eq. (3.4) region; classical extreme-value
  theory for Gaussian processes (Bickel & Rosenblatt family).
- **Caveat recorded honestly**: the sqrt(2 log m) factor is a tail-regime
  approximation. It is NOT claimed as the exact Davies integral. Exact
  evaluation of Davies' integral (his eq. 3.3) requires numerical quadrature
  over the nuisance parameter — that is an implementation choice noted as
  future work, NOT a claim of exactness.

#### Ordering invariant
- **Rule**: p_davies >= p_naive always (correction FOR maximization).
- **Verification**: asserted in contract Scenario 1.

#### m_eff convention
- **Choice**: m_eff = number of candidate breakpoints evaluated = n-1 for a
  SupF sweep over all positions (conservative).
- **Traceable to**: Davies (1987) §3; strucchange documentation on SupF.

### Divergence Points (Implementation Choices)
1. We implement two closed-form bounds (union + EVC) rather than Davies'
   full integral — recorded as an implementation choice with explicit caveat.
2. Cross-check against strucchange::sctest(fit, type="F") where available —
   documented as reference, not equivalence claim.

### Verification Status
- Tests: invariants + empirical comparison vs strucchange (see test file)
- Honest limitation: closed-form bounds, not exact Davies quadrature

*Generated: 2026-09-06 · Foundry Prototype Team*
