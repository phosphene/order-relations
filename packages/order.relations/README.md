# order.relations — Synergetics Abstraction Program

Substrate-free implementations of the synergetics abstraction inventory.
**Design law (Ed Phil, 2026-09-02):** a place for the *abstract* — every
object is stateable with zero biological nouns. Biology enters only at
instantiation time, via mapping tables.

## The flagship: slaving WITHOUT directionality

The original synergetics formulation is one-way (order parameter enslaves
fast subsystems). The abstraction strips that:

> **Slaving = the timescale-separation fact (τ₁ ≪ τ₂) plus coupling.**
> Direction of drive is per-instance, read from f and g — never intrinsic
> to the relation.

| | Abstract (substrate-free) | Instance |
|---|---|---|
| **Relation** | τ₁ẋ = f(x,y); τ₂ẏ = g(x,y); ε = τ₁/τ₂ ≪ 1 | Γ = (Ca²⁺-integrator, trap program) |
| **Slaving** | slow mode persists, fast mode relaxes | flytrap: fast→slow |
| **Drive** | per-instance coupling read from f,g | anesthesia: λ enters f |

## Abstraction inventory

| Row | Abstraction | Function | First instantiation |
|---|---|---|---|
| 1 | Two-variable system | `tv_system()`, `timescale_ratio()`, `slaving_holds()` | flytrap Level 0′ |
| 2 | Slaving relation (direction-free) | `drive_direction()`, `coupling_matrix()` | §2 science paper |
| 3 | Adiabatic elimination | `slow_manifold()`, `effective_dynamics()`, `landscape()`, `curvature()`, `k2_from_curvature()` | Level 0′ → G → L → k₂ = κ/τ₂ |
| 7 | Critical slowing down | `critical_slowing_rate()`, `critical_ratio()` | window collapse T-2 |
| 8 | Bi-exponential relaxation | `biexp_relaxation()`, `rate_law()`, `rate_law_equilibrium()` | LTEE, HRR/sleep |
| 10 | Threshold window derivation | `integration_window()`, `window_sweep()` | flytrap W = τ₁·ln(2a/(θ−a)) |
| T-1 | Perturbation sweep + loss ordering | `lambda_sweep_ordering()`, `perturbation_rates()`, `loss_times()`, `reversal_boundary()` | §6 item 1: reversal is a strong-perturbation boundary, not a refutation |
| T-2 | Observation-window collapse | `apparent_rate_ratio()`, `fast_surviving()`, `resolution_delta()`, `window_collapse_sweep()`, `window_reading()`, `sample_process()`, `fit_biexp()`, `fit_monoexp()` | §6 item 2: k₁/k₂ → 1 at deep time = resolution limit, not contradiction |

## Quick Start

```r
devtools::load_all(".")        # or: source R/ files
ft <- flytrap_instantiation()  # the first mapping table
ft$k1                          # 0.125 s^-1  (derived, not fitted)
ft$window_two_channel          # 29.5 s (Di Palma bracket 20-30 s)
```

## Test

```bash
Rscript run_tests.R            # or: testthat::test_local()
```

## Architecture

MPI Handoff Blueprint: pure functions, contract validation, no global
state. 17 tests across the inventory + instantiation, including the
flagged flytrap read-point discrepancy (24 s vs 29.5 s — both inside the
published bracket; bench C4-P1 is the final word).

## License

MIT
