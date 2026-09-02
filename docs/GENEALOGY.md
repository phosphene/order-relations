# Differing Order Relations: A Genealogy of the Precursor Math

**Status:** opened 2026-09-02 (Ed Phil). Request: *"break down subsections and
actually do the precursor math according to some published standard that we can
reproduce. Some of these published artifacts may not be reproducible and that's
part of the exercise — in addition to using the earlier work as a background
realization, so we have a better ground to stand on."* Extended 2026-09-02
(Ed Phil): literate documentation per unit, for decomposition and
recomposition into new arrangements.

**Method.** For each abstraction in the inventory (`docs/ABSTRACTION_PROGRAM.md`),
trace the published precursor, state the math as published, reproduce it from
first principles in a standalone script (`scripts/genealogy/`), and issue a
verdict. Verdicts are the point: a published artifact earns "reproducible"
only when we can re-derive it to a stated tolerance from the stated source —
no appeal to the authors' data.

**Verdict scale:**
- **reproducible** — re-derived from the stated source to stated tolerance
- **partially reproducible** — derivable, but the source underdetermines a
  parameter or the claim (documented)
- **not reproducible** — cannot be re-derived from the published text alone

## The differing relations, one table

The abstraction program now models **nine distinct order relations** — they
are *differing* relations, not one relation in nine costumes, and each has
its own genealogy and its own literate unit:

| Relation | Precursor | Genealogy | Verdict |
|---|---|---|---|
| Order-parameter (static) | Landau 1937, free-energy expansion | G-1 `g1_landau.R` | ✅ reproducible |
| Adiabatic elimination (canonical) | Briggs & Haldane 1925 | G-2 `g2_michaelis_menten.R` | ✅ reproducible |
| Slaving principle | Haken 1983 | G-3 `g3_haken_slaving.R` | ✅ reproducible |
| Critical slowing | Strogatz 1994, ch. 3/8 | G-4 `g4_critical_slowing.R` | ✅ reproducible |
| Order-parameter formation (dynamic) | Landau amplitude eq.; Strogatz normal form | G-5 `g5_pitchfork.R` | ✅ reproducible |
| Bi-exponential relaxation | NMR/kinetics two-rate standard | G-6 `g6_biexponential.R` | ✅ reproducible |
| Threshold window | Leaky summation (Volkov et al. on *Dionaea*) | G-7 `g7_window.R` | ⚠️ partially reproducible |
| Systematic elimination | van Kampen 1985, Phys. Rep. 124 | G-8 `g8_van_kampen.R` | ✅ reproducible |
| Center manifold reduction | Strogatz ch. 8; Guckenheimer & Holmes ch. 3 | G-9 `g9_center_manifold.R` | ✅ reproducible |

## The three tiers (a decomposition axis)

The relations decompose along one axis: **structure → elimination → dynamics**.

| Tier | Units | What the relation is |
|---|---|---|
| Structure | G-1 (order parameter), G-7 (window) | *what exists* — static branch, threshold |
| Elimination | G-2 (QSSA), G-3 (slaving O(1)), G-8 (van Kampen O(ε)), G-9 (center manifold, exact) | *how the fast dies* — four tiers of one operation |
| Dynamics | G-4 (critical slowing), G-5 (formation), G-6 (relaxation) | *how the slow lives* — approach, crossing, decay |

**Recomposition is free along the axis.** The elimination tier is a ladder:
G-2 ⊂ G-3 ⊂ G-8 ⊂ G-9, each tier tighter than the last (ε→0 limit, O(1),
O(ε), exact). Pick the tier by how tight a bound the claim needs. The
dynamics tier is a loop: G-4 approaches, G-5 crosses, G-6 decays — a
complete excursion through one instability.

## Literate units

Each relation has a self-contained literate document in `docs/genealogy/` —
narrative, published precursor, derivation, code, verified results, verdict,
and a **composition table** (provides / consumes / composes with). The
composition tables are the recomposition contract: to arrange the relations
in a new configuration, read each unit's interfaces and wire them.

| Unit | Relation | Verdict | Composition partners |
|---|---|---|---|
| `G-01.md` | order parameter (static) | ✅ | G-5 (movie of G-1's snapshot), G-4 |
| `G-02.md` | QSSA | ✅ | G-3 (generalization), G-8 (its zeroth order) |
| `G-03.md` | slaving | ✅ | G-2, G-8 (next order), G-9 (exact) |
| `G-04.md` | critical slowing | ✅ | G-5 (past the instability), T-2, C4-P1 P5 |
| `G-05.md` | formation | ✅ | G-1 (branch), G-4 (crossing), formation.R |
| `G-06.md` | bi-exponential | ✅ | T-2 (identifiability), G-5 (other face) |
| `G-07.md` | threshold window | ⚠️ | T-6 (bench discriminator), G-4/G-5 (near instability) |
| `G-08.md` | van Kampen | ✅ | G-3 (zeroth order), G-9 (exact) |
| `G-09.md` | center manifold | ✅ | G-3, G-8, G-5 (amplitude eq. from manifold) |

## Individual sections

- [G-1 — Landau: the order parameter](genealogy/G-01.md)
- [G-2 — Briggs–Haldane: canonical adiabatic elimination](genealogy/G-02.md)
- [G-3 — Haken: the slaving principle](genealogy/G-03.md)
- [G-4 — Strogatz: critical slowing down](genealogy/G-04.md)
- [G-5 — Pitchfork amplitude equation: formation](genealogy/G-05.md)
- [G-6 — Bi-exponential relaxation: the two-rate standard](genealogy/G-06.md)
- [G-7 — Threshold window: leaky summation](genealogy/G-07.md)
- [G-8 — van Kampen: systematic elimination](genealogy/G-08.md)
- [G-9 — Center manifold: the exact slaving manifold](genealogy/G-09.md)

## What the exercise buys us

1. **Grounding.** Every abstraction in the inventory now stands on a
   re-derived published result, not on the authority of a citation.
2. **Separation of artifacts.** G-1…G-6, G-8, G-9 are reproducible
   mathematics; G-7 is a partially reproducible empirical bracket; the
   LTEE/cross-kingdom fits (row 8 instantiation) are *data-dependent* and
   reproducible only from the data, not from the papers — a third class to
   keep distinct.
3. **Failure is a result.** G-7's ambiguity is now a documented finding that
   the flytrap bench re-verify (T-6) can actually resolve: measure the
   window, see which channel count the biology picks.
4. **The differing relations are now explicit and composable.** Slaving
   (G-3) is a timescale fact; formation (G-5) is an instability fact;
   relaxation (G-6) is a dissipation fact; critical slowing (G-4) is the
   hinge; the window (G-7) is a threshold fact. One inventory, nine
   genealogies, three tiers, and a recomposition contract for arranging them
   differently.

## Reproducibility ledger

| Genealogy | Tolerance stated | Result | Verdict |
|---|---|---|---|
| G-1 Landau | analytic | branch verified 1.8e−15 | ✅ reproducible |
| G-2 QSSA | max rel err | 3.7% | ✅ reproducible |
| G-3 slaving | O(ε) | ratio 9.9 | ✅ reproducible |
| G-4 critical slowing | slope −1 | −0.9964 | ✅ reproducible |
| G-5 pitchfork | max abs err | 1.5e−5 | ✅ reproducible |
| G-6 bi-exponential | max dev | 0.0086 | ✅ reproducible |
| G-7 window | bracket 20–30 s | 23.9 / 29.4 s | ⚠️ partially reproducible |
| G-8 van Kampen | O(ε) vs O(ε²) | ratios 9.95 / 99.7 | ✅ reproducible |
| G-9 center manifold | exact | 3.6e−15 / 1.7e−9 / 1.6e−10 | ✅ reproducible |

**Run them yourself:** `Rscript scripts/genealogy/g1_landau.R` … `g9_center_manifold.R`
(base R only — no package dependencies).
