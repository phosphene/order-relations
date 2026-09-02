# order-relations

**Dynamical order relations under test and simulation.** A research space
unto itself: the mathematical and computational program abstracted out of
synergetics (Haken's slaving principle, order parameters, adiabatic
elimination), implemented as production-grade R packages and pointed at the
valence-ingress exploration corpus.

This repository is the *implementation and research* home for the
exploration document (`work/marsyas6/papers/valence-ingress/` in the
woodchipper workspace). It carries the engineering basis of the Phosphene R
Artifact Foundry — scaffolding, standards, CI, the INFERNO evaluation
engine, and the VI statistics package — so the abstract program and its
empirical tests live together under one roof.

## Packages

| Package | Purpose |
|---|---|
| `packages/phosphene.foundry` | Scaffolding + STDD + contract system for production-grade scientific R packages (the foundry basis) |
| `packages/inferno` | INFERNO 7-layer evaluation protocol — deterministic evaluation of research artifacts (papers, models, claims, programs) |
| `packages/vi.stats` | Vestigial Information statistics: CDI, integration-depth ranking, paired tests, sensitivity analysis, natural-experiment designs |
| `packages/order.relations` | **The abstraction program** — slaving without directionality, two-variable systems, adiabatic elimination, bi-exponential relaxation, threshold windows, critical slowing. Substrate-free by design law; flytrap instantiation as first mapping |

## Research Space

See [docs/RESEARCH_SPACE.md](docs/RESEARCH_SPACE.md) for how the packages
map onto the exploration's claims, test queue (T-1…T-5), and the
order-relations abstraction program. Tickets/backlog: [TICKETS.md](TICKETS.md).

## CI

Three independent workflows, path-scoped to their packages:
- `ci-foundry.yml` — phosphene.foundry (lint → test → coverage ≥ 80%)
- `ci-inferno.yml` — inferno
- `ci-vi-stats.yml` — vi.stats

## Standards

All packages follow the [Phosphene R Engineering Standards](docs/PHOSPHENE_R_STANDARDS.md): MPI Handoff Blueprint, testthat edition 3, lintr + styler, renv isolation, Rocker containers + PPM, 80% coverage gate.

## Quick Start

```r
devtools::load_all("packages/phosphene.foundry")
devtools::load_all("packages/inferno")
devtools::load_all("packages/vi.stats")

devtools::test("packages/vi.stats")
```

## License

MIT
