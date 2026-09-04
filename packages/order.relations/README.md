# order.relations

The abstraction program: two-variable systems, direction-free slaving,
adiabatic elimination, bi-exponential relaxation, threshold windows,
critical slowing, order-parameter formation. Substrate-free by design
law — zero biological nouns; biology enters only through instantiation
mappings ([design laws](../../docs/ABSTRACTION_PROGRAM.md)).

## Core formalism

Two abstract variables (x, y), timescale ratio ε = τ₁/τ₂ ≪ 1:

```
τ₁ẋ = f(x, y)      τ₂ẏ = g(x, y)
```

- **Slaving** = the timescale-separation fact plus coupling, direction-free.
  Drive direction is per-instance, read from the Jacobian
  (`drive_direction()`): fast→slow, slow→fast, or mutual.
- **Adiabatic elimination** (ε → 0): solve f(x,y) = 0 for the slow
  manifold x*(y); the order parameter obeys τ₂ẏ = G(y) = g(x*(y), y).
  Landscape L = −∫G dy; curvature κ at its minimum; k₂ = κ/τ₂.
- **Bi-exponential relaxation** after displacement:
  ρ(t) = ρ∞ + A₁e^(−k₁t) + A₂e^(−k₂t) ⇔ dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂)
- **Integration window** (threshold crossing of n summed channels):
  W = τ₁ · ln(n·a / (θ − a))
- **Formation** (the other half of g): τ₂ẏ = α(λ)y − βy³; order
  parameter born at the instability, α > 0.

## Modules

| Module | Abstraction | Functions |
|---|---|---|
| `system.R` | two-variable system, slaving, drive direction | `tv_system()`, `timescale_ratio()`, `slaving_holds()`, `drive_direction()`, `coupling_matrix()` |
| `adiabatic.R` | elimination, landscape, k₂ | `slow_manifold()`, `effective_dynamics()`, `landscape()`, `curvature()`, `k2_from_curvature()` |
| `relaxation.R` | bi-exponential rate law, windows | `biexp_relaxation()`, `rate_law()`, `rate_law_equilibrium()`, `integration_window()`, `window_sweep()` |
| `critical.R` | critical slowing down | `critical_slowing_rate()`, `critical_ratio()` |
| `formation.R` | order-parameter formation | `amplitude_dynamics()`, `growth_coefficient()`, `order_parameter_equilibria()`, `order_parameter_growth()`, `critical_fluctuations()`, `g_regime()` |
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
devtools::test("packages/order.relations")   # 64 assertions (57 + 7 calibration)
```

### Numerical TDD Framework

This repository implements a **five-tier numerical verification protocol** derived from established literature (Higham 2002; Wilkinson 1963; Acton 1994; Squire & Trapp 1998). See [drafts/math-inflation-meditation-*.md](../../drafts/) for full genealogy and standards.

#### Test Organization

| Suite | Location | Purpose |
|-------|----------|---------|
| Relational topology | `tests/testthat/test-relational-transitivity-hedgehog.R` | Hedgehog property-based testing of poset axioms under FP noise |
| Numerical calibration | `tests/testthat/test-numerical-calibration.R` | MMS, convergence-order, backward-residual checks on core functions |
| Anti-pattern detection | `scripts/check-numerical-anti-patterns.R` | Pre-commit hook scans for 7 canonical anti-patterns |

#### Five-Tier Verification Protocol

1. **MMS (Method of Manufactured Solutions)**: Synthetic data with known exact solutions
2. **Convergence-order verification**: Empirical error reduction matches theoretical rate
3. **Manifold invariance + spectral gap**: Timescale separation validation
4. **Backward residual bounds**: Scale-independent equation satisfaction
5. **Poset/topological invariants**: Transitivity, antisymmetry, reflexivity under FP limits

**Status:** All gates passing:
- Reflexivity: 100% (hedgehog randomized)
- Antisymmetry: ≥90% with tol=1.5e-8
- Transitivity: 0% violations near reversal boundary λ* ≈ 1.0
- Landscape convergence: p̂ = 1.827 (expected 2.0)
- Complex-step derivatives: machine precision achieved
- Backward residuals: η < 1e-5 for well-behaved problems

**Anti-pattern catalog documented in:** [Math Inflation Control — Meditation 4 & 5](../../drafts/math-inflation-meditation-4.md), [Math Inflation Control — Meditation 5](../../drafts/math-inflation-meditation-5.md)

## References

- Haken H. *Synergetics*. Springer, 1983.
- Exploration document, §2.5/§6: `work/marsyas6/papers/valence-ingress/`
  (woodchipper workspace).

## License

MIT
