# Verified Results

Deterministic, seeded, reproducible. All runs: `packages/order.relations`,
51 assertions green (29 abstraction core + 9 T-1 + 13 T-2). Every
simulation uses `set.seed()`; identical inputs → identical outputs
(MPI Handoff Blueprint).

## T-1 — Perturbation reversal, λ-sweep ordering

**Claim.** Loss ordering matches integration depth in the relaxation
regime; the R1/R7/lesion "reversed ordering" is a strong-perturbation
regime boundary, not a refutation.

**Setup.** 20 subsystems, depths d_i ~ U(0.02, 0.98). Intrinsic rates
k_i = k₁ + (k₂ − k₁)·d_i with k₁ = 1, k₂ = 0.01. Perturbation adds
λ·s_i with exposure profile s_i ∈ {depth, shallow, uniform}:
- **depth:** s_i ∝ d_i (perturbation hits the integrated core — lesion scenario)
- **shallow:** s_i ∝ (1 − d_i) (periphery hit)
- **uniform:** s_i = const

Loss time t_i = −ln(θ)/k_i^eff, θ = 0.5, lognormal noise σ = 0.05,
100 replicates per λ. Metric: Spearman ρ(depth, loss-time).

**Results.**

| Exposure | ρ(λ=0) | ρ(λ=5) | Reversal | λ* |
|---|---|---|---|---|
| depth | +0.993 | −0.985 | yes | 1.00 |
| shallow | +0.99 | +0.88 | never | — |
| uniform | +0.993 | +0.691 | never (rank preserved) | — |

Uniform exposure additionally collapses the **relative rate separation**
k_max/k_min: 24.6 → 1.18 (the T-2 window-collapse fact, distinct from
rank reversal).

**Reading.** The lesion/knockout reversals flagged by the review team are
what the model *predicts* when perturbation targets the deeply integrated
core. The reversal boundary λ* is a measurable: bench work on which
exposure profile a real system has becomes the discriminator.

## T-2 — Observation-window collapse

**Claim.** k₁/k₂ → 1 at deep time is a model-predicted *resolution
limit*, not a contradiction. The observable two-rate ratio depends on
the sampling interval.

**Setup.** True process: bi-exponential with k₁ = 1, k₂ = 0.01
(true ratio 100). Analytic curve: `apparent_rate_ratio(δ, k₁, k₂)`.
Fit-based: sample at interval δ (noise σ = 0.001, seeded), fit
bi-exp vs mono-exp, compare ΔAIC.

**Results (analytic).** δ ≪ 1/k₁ → ratio 100.0; δ ≫ 1/k₁ → ratio
1.000; monotone non-increasing; fully collapsed by δ = 10/k₁.
Resolution anchor δ* = −ln(0.05)/k₁ = 3.0 (fast phase 95% decayed
between samples).

**Results (fit-based).**

| δ | fitted ratio | ΔAIC (mono − bi) | reading |
|---|---|---|---|
| 0.01 | 100.0 | +154,559 | bi-exp strongly supported |
| 1000 | 10.0 (unidentifiable) | −3.9 | models indistinguishable |

**LTEE/C4 reading.** Same process, two windows:
- LTEE (δ fine, ~15 yr): ratio ~ 37.7 — physiological window
- C4 (δ geological, ~10 Myr): ratio ~ 1.0 — resolution ceiling

100× collapse between windows. The scale problem is a sampling fact,
not a model failure.

## Flytrap instantiation (abstraction inventory row 1 on a real system)

Published biophysics only — no fitting. ε = 3.09e-5, k₁ = 0.125 s⁻¹,
k₂ = κ/τ₂ ≈ 3.0 d. Integration window:
- two-channel form (pipeline code): **W = 29.4 s**
- one-channel form (stated derivation): **W = 23.9 s**
- published bracket (Di Palma): **20–30 s** — both inside

The 24 s vs 29.5 s read-point discrepancy is an explicit parameter of
`integration_window()` (`n = 1` vs `n = 2`), flagged for bench
re-verification (C4-P1) before paper submission.
