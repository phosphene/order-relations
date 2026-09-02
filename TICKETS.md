# order-relations — Ticket Backlog

**Status:** Local tracking until GitHub App has `issues:write` scope
**Last updated:** 2026-09-02
**Repo:** phosphene/order-relations

---

## Research Space — Valence-Ingress Test Queue

Source: exploration document §6 / Appendix E (`work/marsyas6/papers/valence-ingress/`). Every quantitative claim lands as a test or ticket before it lands in a paper.

| ID | Claim | Status | Target package |
|-----|-------|--------|----------------|
| T-1 | Perturbation reversal — λ-sweep ordering matches loss order | **implemented, verified 2026-09-02** — depth exposure reverses past λ*≈1.0; shallow/uniform never reverse; uniform collapses rate ratio 24.6→1.18 (T-2 window fact); 9 assertions green | order.relations (`perturbation.R`) |
| T-2 | Window collapse — apparent rate constant vs sampling interval | **implemented, verified 2026-09-02** — analytic resolution-limit curve (fast phase unresolvable past δ≈3/k₁; ratio fully collapsed by 10/k₁); fit-based: recovers 100.0 at δ=0.01, fails to recover at δ=1000 (unidentifiable); ΔAIC +154,559 → −3.9 (indistinguishable); LTEE/C4 reading 100 → 1.0, 100× collapse; 12 assertions green | order.relations (`observation.R`) |
| T-3a | Sorting (expression) — Vmem → expression-sorting coupling | designed | vi.stats + order.relations |
| T-3b | Sorting (genome) — second rootless lineage (COX, C4-P2) | C4-P2 extension | vi.stats |
| T-4 | Re-deployment — re-access of lost capacity in reverse loss order (reframed 2026-09-02: inbound taxonomy split — re-access is predicted by the framework; de novo is the pitchfork/formation regime, order.relations `formation.R`) | designed | vi.stats + order.relations |
| T-5 | Discrete vs continuous — endosymbiont logistic-vs-biphasic | **priority** | vi.stats |
| T-6 | Flytrap integration window — 24 s vs 29.5 s read-point re-verify | **bench pending** | order.relations |
| T-7 | Genealogy — reproduce precursor math per published standard (G-1…G-9, `scripts/genealogy/`, literate units in `docs/genealogy/`) | **done 2026-09-02** — 8/9 reproducible, G-7 partially (channel-count ambiguity); extended with van Kampen (G-8) + center manifold (G-9) tiers + composition tables | order.relations |
| T-8 | Recomposition — registry + arrangements (A-1 excursion loop verified; A-2 ladder, A-3 window-near-instability, A-4 inbound/outbound, A-5 empirical referents queued) | **A-1 done 2026-09-02** | order.relations |

---

## Foundry Backlog (carried over from r-artifact-foundry)

---

## Labels

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | red | Something isn't working |
| `enhancement` | blue | New feature or improvement |
| `package:inferno` | green | INFERNO-R 7-layer evaluation engine |
| `package:vi.stats` | yellow | Vestigial Information statistical methods |
| `package:phosphene.foundry` | green | Scaffolding + STDD + contracts |
| `sprint` | purple | Current sprint work |

---

## Open Tickets

### #19 — Fix INFERNO-R L6 test expectation mismatches
**Labels:** `bug`, `package:inferno`, `sprint`
**Priority:** High

L6 tests expect "admissible" but implementation returns "admissible_with_caveats" for most cases. Either fix the test expectations to match implementation behavior, or tune the scoring thresholds in `evaluate_layer6()` so that strong analogies get "admissible".

Also fix:
- 2 `vapply` errors in multi-analogy path (`vapply(matching_data, function(d) d$claim$id, character(1))` — values must be length 1)
- 1 S4 subscript error in GARD fixture test (`fc_attributes[attr_vec == 1]` — invalid subscript type 'S4')

**5 test failures + 3 errors.**

**Acceptance criteria:**
- [ ] All test-unit-layer6.R tests pass or skip gracefully
- [ ] No vapply errors on multi-analogy path
- [ ] No S4 subscript errors on GARD fixture
- [ ] L6 BDD specs in test-bdd-inferno.R pass

---

### #20 — Fix INFERNO-R property test fcaR API
**Labels:** `bug`, `package:inferno`, `sprint`
**Priority:** High

`test-property.R` has 3 failures:

1. Closure axioms for 50 random contexts — `fc$closure(S)` still uses wrong Set type in some code paths. Use `fc$uparrow(S)` + `fc$downarrow()` chain instead of `fc$closure()`.
2. `fc$concepts$extents` is a method, not a field — needs `extents()` call. Error: "object of type 'closure' is not subsettable"
3. `matrix()` dimnames length mismatch — `matrix(0, nrow=3, dimnames=list(c("p","q","r"), c("a","b","c")))` works but `matrix(1, nrow=5, dimnames=list(c("A"..."E"), c("1"..."5")))` has wrong dimnames vector length.

**Acceptance criteria:**
- [ ] Closure axioms pass for all 50 random contexts
- [ ] Full context (all ones) produces correct concept count
- [ ] Hash determinism test passes
- [ ] Empty context test passes

---

### #21 — Fix INFERNO-R L4 empty-claims edge case
**Labels:** `bug`, `package:inferno`, `sprint`
**Priority:** Medium

`test-unit-layer4.R:279` — `evaluate_layer4()` on empty claims returns non-zero scores. Should return all-zero scores when target has no claims.

Fix either:
- Implementation: short-circuit `evaluate_layer4()` to return zero scores when `target$n_claims() == 0`
- Test: adjust expectation if non-zero is intentional (unlikely)

**1 test failure.**

**Acceptance criteria:**
- [ ] Empty claims input → zero compression scores
- [ ] Empty claims input → zero counter-RL flags
- [ ] Test passes

---

### #22 — Fix INFERNO-R invariants implication soundness
**Labels:** `bug`, `package:inferno`, `sprint`
**Priority:** Medium

`test-invariants.R:153` — implication soundness check fails. The test checks: "if B1→B2 is in the implication basis, every object with B1 attributes also has B2 attributes."

The failure: "Object 'Iron-Sulfur' has LHS {L2-inference} but is missing RHS {L3-eval}"

This is a test logic error. The implication basis says `{L1-obs, L3-eval} → {L2-inference}`, not the reverse. The test is checking the wrong direction — it's looking at whether objects with L2-inference also have L3-eval, but no implication says they should.

Fix: the test should check that for each implication `lhs → rhs`, every object that has ALL attributes in `lhs` also has ALL attributes in `rhs`. Not the reverse.

**1 test failure.**

**Acceptance criteria:**
- [ ] Implication soundness test checks correct direction
- [ ] Test passes for the 3 implications in the test context

---

### #23 — Fix INFERNO-R BDD expectation alignment
**Labels:** `bug`, `package:inferno`, `sprint`
**Priority:** Medium

`test-bdd-inferno.R` has 3 failures:

1. L2 M-failure BDD expects "M1" in `result$flags$m_failures` but implementation stores differently — check actual structure of `flags$m_failures` and align BDD test
2. L4 compression BDD expects `vocabulary_transfer` in `result$scores` but the scores structure may use different naming — align with actual implementation
3. L6 analogy BDD has `evidence = None` (Python leak) instead of `evidence = NULL` — already partially fixed, verify

**3 test failures.**

**Acceptance criteria:**
- [ ] All BDD specs pass or skip gracefully
- [ ] No Python syntax leaks (`None`, `True`, `False`)
- [ ] BDD expectations match implementation output structure

---

### #24 — Verify vi.stats CI pipeline
**Labels:** `enhancement`, `package:vi.stats`, `sprint`
**Priority:** Medium

`ci-vi-stats.yml` exists but hasn't been verified. The package has 7 R files (602 lines) and 4 test files (319 lines).

Tasks:
- [ ] Install vi.stats dependencies (withr, dplyr, readr)
- [ ] Run `lintr::lint_package()` — fix violations
- [ ] Run `testthat::test_local()` — fix failures
- [ ] Run `covr::package_coverage()` — verify ≥ 80%
- [ ] Verify CI workflow file is syntactically correct YAML

**Acceptance criteria:**
- [ ] Lint passes
- [ ] All unit tests pass
- [ ] Coverage ≥ 80%
- [ ] CI workflow valid

---

### #25 — Run vi.stats against real CTVT data
**Labels:** `enhancement`, `package:vi.stats`
**Priority: Low**

`inst/examples/run_ctvt_analysis.R` exists but hasn't been run against real data. This is the first real-world test of the vi.stats package.

Tasks:
- [ ] Locate CTVT dataset (check workspace for transcriptomic data)
- [ ] Run the analysis script
- [ ] Verify CDI computation, integration-depth ranking, paired tests
- [ ] Write results summary

**Acceptance criteria:**
- [ ] Script runs without errors on real data
- [ ] Results are biologically interpretable
- [ ] Results summary written to `inst/examples/ctvt-results.md`

---

### #26 — Verify INFERNO-R nightly CI passes
**Labels:** `enhancement`, `package:inferno`
**Priority: Low** (blocked by #19-#23)

Once #19-#23 are resolved, verify that the nightly CI workflow (`nightly-inferno.yml`) passes all integration + BDD + property tests with `RUN_INTEGRATION=true`.

Currently the nightly workflow exists but has never run green because of the test failures.

**Acceptance criteria:**
- [ ] All #19-#23 resolved
- [ ] `RUN_INTEGRATION=true` all tests pass
- [ ] Nightly badge green on README

---

## Closed Tickets

| # | Title | Closed |
|---|-------|--------|
| #2 | Epic: Full Test Pyramid Implementation | 2026-07-18 |
| #3 | Tier 2: Integration tests | 2026-07-18 |
| #4 | BDD layer: describe/it specs | 2026-07-18 |
| #5 | Gherkin acceptance layer | 2026-07-18 |
| #6 | Demo analysis artifact | 2026-07-18 |
| #7 | Nightly CI workflow | 2026-07-18 |
| #8 | Coverage expansion to 90% | 2026-07-18 |

---

## Sprint Board

```
TODO                    IN PROGRESS           DONE
─────────────────────────────────────────────────────
#19 L6 expectations     (none)               #2-#8 Test pyramid
#20 Property API                              #19-#23 (partially fixed)
#21 L4 empty claims
#22 Invariants logic
#23 BDD alignment
#24 vi.stats CI
#25 CTVT data run
#26 Nightly CI green
```
