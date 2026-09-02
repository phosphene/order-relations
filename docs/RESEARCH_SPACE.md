# Research Space — order-relations

This repo is the implementation and research home for the order-relations
program: the mathematical and computational abstraction drawn out of
synergetics (Haken's slaving principle, order parameters, adiabatic
elimination, timescale separation) and applied to the valence-ingress
exploration.

## Source of truth

The reasoning trail lives in the woodchipper workspace:
`work/marsyas6/papers/valence-ingress/exploration-document.md` (and its
companion corpus — E3, E12, C4-P2, tier2-flytrap-elimination, etc.).
This repository is where that thinking becomes *implemented, tested, and
evaluated*: packages, simulations, and CI-verified artifacts.

The public-facing distillation of the same work is the science paper
(`valence-ingress-science-paper.md`, rev 2), which cites out to the
exploration corpus.

**Design + results:**
- [ABSTRACTION_PROGRAM.md](ABSTRACTION_PROGRAM.md) — the design law,
  slaving without directionality, the abstraction inventory
- [VERIFIED_RESULTS.md](VERIFIED_RESULTS.md) — T-1/T-2 numeric results,
  51 assertions green

## How the packages map onto the exploration

### `packages/vi.stats` — the empirical core
Implements the statistics behind the exploration's quantitative claims:
- **CDI** (`compute_cdi`) — Capacity Depletion Index for integration-depth-ordered commitment
- **Integration-depth ranking** (`integration_depth_rank`) — gene-category ordering
- **Paired tests** (`paired_cdi_test`) — CDI differences (Claim 2 ordering)
- **Spearman + permutation** (`gene_category_spearman`) — cross-kingdom transfer ρ (Claim 3)
- **Sensitivity** (`sensitivity_analysis`) — drug-target/metabolic exclusion robustness
- **Natural-experiment responder split** (`responder_split_test`) — the C4-P2 / *Genlisea* COX design

### `packages/inferno` — the evaluation engine
The 7-layer protocol used to score the Cambrian books (F&M, G&J), the GARD
model, and the Levin program (WCI on the 0–100 scale). Runs the
claim-by-claim audit and the four-party decoder-ring comparisons.

### `packages/phosphene.foundry` — the engineering basis
Scaffolding + STDD + contract system; what makes every artifact here
production-grade and reproducible.

### `packages/order.relations` — the abstraction program
The mathematical core of this repo: two-variable slaving models, adiabatic
elimination, bi-exponential rate laws, and derived quantitative predictions
(the flytrap integration window W = τ₁·ln(2a/(θ−a)) is the prototype).
This is the "abstract, mathematical and coding program as research and
implementation both" — the reason the repo exists. Scaffolded from the
foundry basis 2026-09-02; 29 assertions green locally (unit + instantiation).

## The abstraction program — synergetics, substrate-free

**Design intent (Ed Phil, 2026-09-02):** order-relations is a place for the
*abstract*. The synergetics concepts live here as pure objects — no
substrate commitment, no directionality built in. Biology enters only at
instantiation time, as a mapping table, never inside the abstraction.

### The flagship: slaving WITHOUT directionality

In the original synergetics formulation the order parameter enslaves the
fast subsystems (one-way). The abstraction strips that: **slaving = the
timescale-separation fact (τ₁ ≪ τ₂) plus coupling.** Direction of drive is
per-instance, read from f and g — never intrinsic to the relation. This is
exactly the paper's Fix 1 made into a design law:

| | Abstract (substrate-free) | Instance |
|---|---|---|
| **Relation** | τ₁ẋ = f(x,y); τ₂ẏ = g(x,y); ε = τ₁/τ₂ ≪ 1 | Γ = (Ca²⁺-integrator, trap program); (electrome, metabolic layer) |
| **Slaving** | slow mode persists, fast mode relaxes — timescale fact | flytrap: fast→slow |
| **Drive** | per-instance coupling read from f,g | anesthesia: λ enters f — fast side drives |

### The abstraction inventory (each = an implementation unit)

| Abstraction | Synergetics source | Formal content | First instantiation target |
|---|---|---|---|
| Two-variable system | Haken 1983 | τ₁ẋ=f, τ₂ẏ=g, ε=τ₁/τ₂ | flytrap Level 0′ mapping |
| Slaving relation | Haken; Landau control–order | timescale separation + coupling, direction-free | §2 of science paper |
| Adiabatic elimination | Haken; van Kampen | eliminate fast variable → effective dynamics G on slow manifold | Level 0′ → G → L → k₂=κ/τ₂ |
| Order parameter | Landau; Haken | slow collective mode; the record | metabolic layer / carbon-chemical record |
| Control parameter | Haken | external parameter sweeping instability | λ = anesthesia dose; W(λ) narrowing |
| Circular causality | Haken | order parameter ↔ subsystems loop | bidirectional coupling f,g |
| Critical slowing down | Haken; Strogatz | relaxation time diverges at instability | window collapse T-2 |
| Bi-exponential relaxation | generic two-timescale result | dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂) | LTEE, HRR/sleep fits |
| Displacement–relaxation | ours, via the above | displacement then relaxation = the two-phase signature | E-series |
| Threshold window derivation | ours, via the above | W = τ₁·ln(2a/(θ−a)) family | flytrap 29.5 s (T-6 bench) |

**Discipline:** an abstraction earns its place by surviving the
substrate-stripping test — it must be stateable with zero biological
nouns. If it can't, it's not an abstraction yet; it's a metaphor with a
formula attached.

**Research × implementation:** each inventory row is both a math result
(derivation, theorem, regime map) and a code unit (function, test,
simulation). The package is the research; the research is the package.

## Test queue (from the exploration's §6 / Appendix E)

| §6 item | Test | Package target | Status |
|---|---|---|---|
| 1 perturbation reversal | T-1: λ-sweep ordering | order.relations | designed |
| 2 window collapse | T-2: apparent rate vs sampling interval | order.relations | designed |
| 3 sorting (expression) | T-3a: Vmem → expression-sorting | vi.stats + order.relations | designed |
| 3 sorting (genome) | T-3b: second rootless lineage (COX) | vi.stats | C4-P2 extension |
| 4 re-deployment | T-4: re-access in reverse loss order (inbound taxonomy: re-access vs de novo vs reversal — see INBOUND_OUTBOUND.md) | vi.stats + order.relations | designed |
| 5 discrete vs continuous | T-5: endosymbiont logistic-vs-biphasic | vi.stats | **priority** |
| — flytrap window | 24 s vs 29.5 s read-point re-verify | order.relations | **bench pending** |
| — genealogy | precursor math per published standard (G-1…G-7) | order.relations | **done 2026-09-02** — see GENEALOGY.md |

## Working rules

- Named branches, PR before merge (no direct main commits).
- `uv`/renv dependency discipline; MPI Handoff Blueprint (pure functions,
  guarded main, no global state).
- Every quantitative claim lands as a test or a ticket before it lands in a
  paper.
