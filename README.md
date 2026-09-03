# order-relations

A research space for **dynamical order relations**: with each research program
apparatus developed in its own namespace,  and its conditions reproduced.
Rooted in synergetics (Haken: slaving, order parameters, adiabatic
elimination), implemented as production-grade R packages.

## Namespaces

| Namespace | Domain | Conditions reproduced |
|---|---|---|
| `packages/order.relations` | The abstraction program — two-variable systems, direction-free slaving, elimination, relaxation, windows, critical slowing, formation. | T-1/T-2 verified, 51 assertions; flytrap first instantiation |
| `packages/phosphene.foundry` | Scaffolding + STDD + contract system | CI on every package |
| `packages/inferno` | INFERNO 7-layer evaluation protocol (WCI scoring) | Suite tests |
| `packages/vi.stats` | Vestigial Information statistics: CDI, integration-depth rank, paired tests, sensitivity | Suite tests |
| `scripts/genealogy/` | Precursor math per published standard (G-1…G-9), literate units in `docs/genealogy/` | 8/9 reproducible; G-7 ambiguous bracket |


## Documentation

- [docs/ABSTRACTION_PROGRAM.md](docs/ABSTRACTION_PROGRAM.md) — design laws, the Jacobian (one object, many projections), abstraction inventory
- [docs/GENEALOGY.md](docs/GENEALOGY.md) — nine precursor relations, tiers, recomposition map
- [docs/RECOMPOSITION.md](docs/RECOMPOSITION.md) — recomposition machinery, first verified arrangement A-1
- [docs/EVOLUTION_CHARACTERIZATION.md](docs/EVOLUTION_CHARACTERIZATION.md) — evolution as sequences of commitments (displacement → relaxation)
- [docs/INBOUND_OUTBOUND.md](docs/INBOUND_OUTBOUND.md) — formation side: inbound as the α > 0 regime
- [docs/RESEARCH_SPACE.md](docs/RESEARCH_SPACE.md) — packages mapped onto exploration claims
- [docs/VERIFIED_RESULTS.md](docs/VERIFIED_RESULTS.md) — T-1/T-2 numeric results
- [TICKETS.md](TICKETS.md) — test queue + foundry backlog

## Standards

All packages follow the [Phosphene R Engineering Standards](docs/PHOSPHENE_R_STANDARDS.md): MPI Handoff Blueprint, testthat edition 3, lintr + styler, renv, Rocker + PPM, 80% coverage gate. CI is path-scoped per package (`ci-*` workflows).

## Quick Start

```r
devtools::load_all("packages/order.relations")
ft <- flytrap_instantiation()   # first mapping table
ft$window_two_channel           # 29.4 s (published bracket 20–30 s)

devtools::test("packages/order.relations")
```

## License

MIT
