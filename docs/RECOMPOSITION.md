# Recomposition: Arranging the Relations

**Status:** opened 2026-09-02 (Ed Phil). *"We're going to want to decompose and
recompose"* — the genealogy units (`docs/genealogy/G-*.md`) are the decomposed
parts; this directory is the recomposition machinery: a machine-readable
registry, a convention for declaring arrangements, and worked arrangements
with verification.

## The contract

`docs/genealogy/registry.csv` is the machine-readable index of every unit:

| Column | Meaning |
|---|---|
| `id` | G-01 … G-09 |
| `tier` | structure / elimination / dynamics |
| `verdict` | reproducible / partially |
| `provides` | what the unit outputs |
| `consumes` | what the unit needs as input |
| `composes_with` | units that wire into it (the recomposition edges) |

An **arrangement** is a declared composition of units — a script in
`scripts/recompose/` that wires the provides/consumes edges and validates
each composed phase against its source unit's own prediction. Arrangements
are numbered A-1, A-2, … and logged below.

## Arrangement ledger

| # | Arrangement | Units composed | Verification | Status |
|---|---|---|---|---|
| A-1 | Full excursion loop | G-4 + G-5 + G-6 | phase 1 rate 0.0353 vs 0.035; phase 2 α→0 (var Inf); phase 3 slope −0.0384 vs −0.04; final y = y_inf exactly | ✅ verified |

## A-1 — the full excursion loop

**Decompose:** G-4 (critical slowing) + G-5 (formation) + G-6 (relaxation).
**Recompose:** ONE equation with a sweeping control parameter,

    dy/dt = α(λ(t))·y − β·y³,   α(λ) = k₂·(λ/λ_c − 1)

As λ sweeps 0.6 → 1.2 and holds, a single trajectory passes through all
three units:

1. **λ < λ_c:** α < 0 → exponential relaxation toward the old attractor
   (G-6 shape). Verified: fitted rate 0.0353 vs predicted |α| 0.035.
2. **λ ≈ λ_c:** α → 0 → critical slowing; decay rate vanishes, variance
   diverges (G-4). Verified: min |α| = 0 exactly at the crossing;
   variance enhancement → ∞.
3. **λ > λ_c (held):** α > 0 → S-shaped growth to √(α/β); the order
   parameter FORMS (G-5). Verified: log-distance slope −0.0384 vs
   predicted −2α = −0.04; final y = 0.1414 = √(0.02) exactly.

**What the arrangement means biologically:** a lineage whose control
parameter crosses its commitment threshold shows all three faces in one
history — old-capacity decay (loss), a critical slow point (the hinge, where
fluctuation variance peaks — the C4-P1 P5 precursor), and new-capacity
growth (gain). The inbound/outbound "asymmetry" is not two laws; it is two
phases of one trajectory on either side of the crossing.

**Run it:** `Rscript scripts/recompose/a1_excursion_loop.R`

## Declaring a new arrangement

1. Pick the units from `registry.csv`; wire their provides/consumes edges.
2. Write `scripts/recompose/aN_name.R` — a self-contained base-R script.
3. For each composed phase, validate against its source unit's prediction
   (same tolerance discipline as the genealogy scripts).
4. Log the arrangement in the ledger above with the verification numbers.

## Candidate arrangements (queued)

- **A-2 — elimination ladder:** G-2 → G-3 → G-8 → G-9 on the same system;
  show the reduction error tightening ε→0 ⊂ O(1) ⊂ O(ε) ⊂ exact as the
  tier rises (flytrap ε ≈ 1/40: quantify the O(ε) correction ~2.5%).
- **A-3 — window near instability:** G-7 + G-4 + G-5 — how the decision
  window W behaves as λ → λ_c (the C4-P1 P5 fluctuation precursor).
- **A-4 — inbound/outbound duality:** G-5 + G-6 on one axis — the same law
  read toward the other fixed point (INBOUND_OUTBOUND.md Move 2, verified
  numerically).
- **A-5 — empirical referents:** Dollo (loss-only), relaxed selection
  (random loss), cost of complexity (gain rarity) as falsifiable claims
  against composed trajectories.
