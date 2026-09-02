# order-relations

**Dynamical order relations under test and simulation.** The mathematical
and computational program abstracted out of synergetics (Haken's slaving
principle, order parameters, adiabatic elimination), implemented as
production-grade R packages and pointed at the valence-ingress exploration
corpus.

This repository is the *implementation and research* home for the
exploration document (`work/marsyas6/papers/valence-ingress/` in the
woodchipper workspace). It carries the engineering basis of the Phosphene R
Artifact Foundry — scaffolding, standards, CI, the INFERNO evaluation
engine, and the VI statistics package — so the abstract program and its
empirical tests live together under one roof.

## Packages

| Package | Purpose |
|---|---|
| `packages/order.relations` | **The abstraction program** — two-variable systems, slaving without directionality, adiabatic elimination, bi-exponential relaxation, threshold windows, critical slowing. Substrate-free by design law; T-1/T-2 verified; flytrap as first instantiation |
| `packages/phosphene.foundry` | Scaffolding + STDD + contract system for production-grade scientific R packages (the foundry basis) |
| `packages/inferno` | INFERNO 7-layer evaluation protocol — deterministic evaluation of research artifacts (papers, models, claims, programs) |
| `packages/vi.stats` | Vestigial Information statistics: CDI, integration-depth ranking, paired tests, sensitivity analysis, natural-experiment designs |

## Documentation

- [docs/ABSTRACTION_PROGRAM.md](docs/ABSTRACTION_PROGRAM.md) — the design law, slaving without directionality, the abstraction inventory
- [docs/VERIFIED_RESULTS.md](docs/VERIFIED_RESULTS.md) — T-1/T-2 numeric results, 51 assertions green
- [docs/RESEARCH_SPACE.md](docs/RESEARCH_SPACE.md) — how the packages map onto the exploration's claims
- [TICKETS.md](TICKETS.md) — test queue (T-1…T-6) + carried-over foundry backlog

## CI

Four independent workflows, path-scoped to their packages:
- `ci-foundry.yml` — phosphene.foundry (lint → test → coverage ≥ 80%)
- `ci-inferno.yml` — inferno
- `ci-vi-stats.yml` — vi.stats
- `ci-order-relations.yml` — order.relations

## Standards

All packages follow the [Phosphene R Engineering Standards](docs/PHOSPHENE_R_STANDARDS.md): MPI Handoff Blueprint, testthat edition 3, lintr + styler, renv isolation, Rocker containers + PPM, 80% coverage gate.

## Quick Start

```r
devtools::load_all("packages/order.relations")
ft <- flytrap_instantiation()   # first mapping table
ft$window_two_channel           # 29.4 s (published bracket 20–30 s)

devtools::test("packages/order.relations")
```

## License

MIT
