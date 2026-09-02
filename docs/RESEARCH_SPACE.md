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

### `packages/order.relations` *(planned)* — the abstraction program
The mathematical core of this repo: two-variable slaving models, adiabatic
elimination, bi-exponential rate laws, and derived quantitative predictions
(the flytrap integration window W = τ₁·ln(2a/(θ−a)) is the prototype).
This is the "abstract, mathematical and coding program as research and
implementation both" — the reason the repo exists.

## Test queue (from the exploration's §6 / Appendix E)

| §6 item | Test | Package target | Status |
|---|---|---|---|
| 1 perturbation reversal | T-1: λ-sweep ordering | order.relations | designed |
| 2 window collapse | T-2: apparent rate vs sampling interval | order.relations | designed |
| 3 sorting (expression) | T-3a: Vmem → expression-sorting | vi.stats + order.relations | designed |
| 3 sorting (genome) | T-3b: second rootless lineage (COX) | vi.stats | C4-P2 extension |
| 4 re-access | T-4: re-emergence in reverse loss order | vi.stats | designed |
| 5 discrete vs continuous | T-5: endosymbiont logistic-vs-biphasic | vi.stats | **priority** |
| — flytrap window | 24 s vs 29.5 s read-point re-verify | order.relations | **bench pending** |

## Working rules

- Named branches, PR before merge (no direct main commits).
- `uv`/renv dependency discipline; MPI Handoff Blueprint (pure functions,
  guarded main, no global state).
- Every quantitative claim lands as a test or a ticket before it lands in a
  paper.
