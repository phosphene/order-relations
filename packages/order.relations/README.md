# order.relations

Substrate-free implementation of the synergetics abstraction program:
two-variable systems, direction-free slaving, adiabatic elimination,
bi-exponential relaxation, threshold integration windows, critical
slowing down.

**Design law:** abstractions contain zero biological nouns; biology
enters only through instantiation mappings (see
[docs/ABSTRACTION_PROGRAM.md](../../docs/ABSTRACTION_PROGRAM.md)).

## Core formalism

Two abstract variables (x, y) on phase space Γ, timescale ratio
ε = τ₁/τ₂ ≪ 1:

```
τ₁ẋ = f(x, y)      τ₂ẏ = g(x, y)
```

**Slaving** is the timescale-separation fact plus coupling —
direction-free. Drive direction is read per-instance from the
timescale-normalized Jacobian (`drive_direction()`): fast→slow,
slow→fast, or mutual.

**Adiabatic elimination** (ε → 0): solve f(x,y) = 0 for the slow
manifold x*(y); the order parameter obeys τ₂ẏ = G(y) = g(x*(y), y).
The landscape L = −∫G dy has curvature κ at its minimum; the slow
rate constant is k₂ = κ/τ₂.

**Bi-exponential relaxation** after displacement:

```
ρ(t) = ρ∞ + A₁e^(−k₁t) + A₂e^(−k₂t)
     ⇔  dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂)
```

**Integration window** (threshold crossing of n summed channels):

```
W = τ₁ · ln(n·a / (θ − a))
```

## Modules

| Module | Abstraction | Functions |
|---|---|---|
| `system.R` | two-variable system, slaving, drive direction | `tv_system()`, `timescale_ratio()`, `slaving_holds()`, `drive_direction()`, `coupling_matrix()` |
| `adiabatic.R` | elimination, landscape, k₂ | `slow_manifold()`, `effective_dynamics()`, `landscape()`, `curvature()`, `k2_from_curvature()` |
| `relaxation.R` | bi-exponential rate law, windows | `biexp_relaxation()`, `rate_law()`, `rate_law_equilibrium()`, `integration_window()`, `window_sweep()` |
| `critical.R` | critical slowing down | `critical_slowing_rate()`, `critical_ratio()` |
| `perturbation.R` | T-1: λ-sweep loss ordering | `lambda_sweep_ordering()`, `perturbation_rates()`, `loss_times()`, `reversal_boundary()` |
| `observation.R` | T-2: window collapse | `fast_surviving()`, `resolution_delta()`, `apparent_rate_ratio()`, `window_collapse_sweep()`, `window_reading()` |
| `flytrap.R` | first instantiation (mapping table) | `flytrap_instantiation()` |

## Verified predictions

- **T-1 perturbation reversal.** Ordering matches integration depth at
  relaxation (ρ = +0.99); depth-targeted perturbation reverses it
  (ρ = −0.99 at λ = 5, boundary λ* = 1.0); shallow/uniform exposure
  never reverse rank.
- **T-2 window collapse.** Observable rate ratio: 100.0 at fine
  sampling → 1.0 at coarse (analytic, monotone). Fit-based: ΔAIC
  +154,559 → −3.9 across the sweep. The LTEE/C4 ratio gap is a
  resolution limit, not a contradiction.
- **Flytrap instantiation.** From published biophysics only:
  ε = 3.09e-5, k₁ = 0.125 s⁻¹, W = 29.4 s (two-channel) / 23.9 s
  (one-channel) — both inside the 20–30 s published bracket.

Full numbers: [docs/VERIFIED_RESULTS.md](../../docs/VERIFIED_RESULTS.md).

## Install & test

```r
devtools::load_all("packages/order.relations")
devtools::test("packages/order.relations")   # 51 assertions
```

## References

- Haken H. *Synergetics*. Springer, 1983.
- Exploration document, §2.5/§6: `work/marsyas6/papers/valence-ingress/`
  (woodchipper workspace).

## License

MIT
