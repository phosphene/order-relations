# Appendix A — LTEE two-rate fit: required evidence (PENDING)

**Status: NOT YET PRODUCED.** Referenced by the claim "The field had no
rate equation; the two-rate form supplies one" in
`docs/EVOLUTION_CHARACTERIZATION.md` (claim grade: **proof-ish —
verification pending**, downgraded 2026-09-03).

The claim's original text cited "— Appendix A" as its evidence pointer.
No such appendix existed in the repository at the time of the
math-inflation review (`drafts/math-inflation-review-order-relations-v1.md`).
This document defines what Appendix A must contain for the claim to be
re-promoted to "Established — do not relitigate."

## Required contents

Each item must be a committed, runnable, reproducible artifact. No item
may be a pointer to a results document that is itself a pointer.

1. **Data file with provenance.** The LTEE trait time series used for the
   fits (population, trait, generation, value), committed as data with
   source (publication, URL, access date). No such trait time series
   currently exists in this repo or in vi-foundry — only mutation and
   dependency data.

2. **Fit script.** The code that produced every ΔAIC reported, using the
   calibrated fitter (multi-start, off-boundary, AICc, n-reported —
   PR #2 `fix/numerical-anti-patterns`). Seeded, deterministic, with the
   sessionInfo/BLAS regime recorded.

3. **n per comparison.** Every ΔAIC must be reported with its n. ΔAIC
   without n is incommensurable across datasets (the old sweep produced
   ΔAIC +154,559 at n ≈ 20,000 — an n-scaling artifact, not an evidence
   magnitude).

4. **ΔAIC per comparison, all of them.** Not just the favorable tail. The
   empirical record is mixed: endosymbiont ΔAICc = 0.8 (unsettled),
   island-birds +4.0 (degenerate k1≈k2), r6-c4 +3.96 (mono preferred).
   The range "39.6–190" must be disaggregated into its actual comparisons.

5. **Davies' breakpoint test with a real p-value.** "Davies' p = 0" is
   precision theater — report p ≈ x (p-values are not exactly zero), the
   breakpoint estimate with uncertainty, and the search range supporting
   "breakpoint gen ~7,000".

6. **Simulacrum disclosure.** The outcome of `simulacra_9_13.py` system
   "LTEE-like (ratio=37)" reported alongside the empirical fit. Under the
   pre-calibration fitter this simulacrum FAILED (322% error, degenerate
   bound collapse). The calibrated fitter recovers ratio 37.4 vs true
   37.7 — the disclosure must state which fitter produced which number.

7. **Window-collapse reading (T-2).** The LTEE (fine sampling) vs C4
   (deep-time) contrast must be presented as the resolution-limit
   statement it is (T-2, `observation.R`), not as independent validation
   of the empirical fit.

## Definition of done

- All seven items committed and runnable. Data and fit script must be
  committed to this repository (the claim lives here); the simulacrum
  disclosure cross-references `vi-foundry/scripts/simulacra_9_13.py`
  and must report its outcome for the LTEE-like (ratio=37) system.
- The calibrated fitter's full suite passes (121 assertions, 58
  `test_that` blocks, PR #2).
- A reviewer can re-derive every number in the claim's ΔAIC range from
  committed artifacts alone, including the comparisons where mono-exp won.
- The simulacrum outcome for the LTEE regime is reported (pass or fail)
  in the same document as the empirical fit.

## History

- 2026-09-03: Created as a required-evidence stub by the math-inflation
  review disposition. Claim downgraded in
  `docs/EVOLUTION_CHARACTERIZATION.md` to "Proof-ish — verification
  pending" until this appendix passes.
