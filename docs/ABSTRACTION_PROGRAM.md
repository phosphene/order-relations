# The Abstraction Program

**Design intent (Ed Phil, 2026-09-02).** order-relations is a place for
the *abstract*. The synergetics concepts live here as pure objects — no
substrate commitment, no directionality built in. Biology enters only at
instantiation time, as a mapping table, never inside the abstraction.

## Design law: substrate stripping

> An abstraction must be stateable with zero biological nouns. If it
> can't, it's not an abstraction yet — it's a metaphor with a formula
> attached.

Enforced structurally in the package: every file in `R/` is noun-free
except `flytrap.R`, which is the mapping table where biology is allowed
in.

## The flagship: slaving without directionality

In the original synergetics formulation (Haken 1983) the order parameter
enslaves the fast subsystems — one-way. The abstraction strips that:

> **Slaving = the timescale-separation fact (τ₁ ≪ τ₂) plus coupling.**
> Direction of drive is per-instance, read from f and g — never intrinsic
> to the relation.

This is the science paper's Fix 1 (post-jury revision) promoted from
paper edit to design law. The flytrap instantiates fast→slow;
anesthesia instantiates λ entering f (fast side drives); but the
relation itself says neither.

| | Abstract (substrate-free) | Instance |
|---|---|---|
| **Relation** | τ₁ẋ = f(x,y); τ₂ẏ = g(x,y); ε = τ₁/τ₂ ≪ 1 | Γ = (Ca²⁺-integrator, trap program) |
| **Slaving** | slow mode persists, fast mode relaxes — timescale fact | flytrap: fast→slow |
| **Drive** | per-instance coupling read from f,g | anesthesia: λ enters f — fast side drives |

## Abstraction inventory

Each row is an implementation unit: a math result (derivation, theorem,
regime map) and a code unit (function, test, simulation) at once.

| # | Abstraction | Synergetics source | Formal content | Functions | First instantiation |
|---|---|---|---|---|---|
| 1 | Two-variable system | Haken 1983 | τ₁ẋ=f, τ₂ẏ=g, ε=τ₁/τ₂ | `tv_system()`, `timescale_ratio()`, `slaving_holds()` | flytrap Level 0′ |
| 2 | Slaving relation | Haken; Landau control–order | timescale separation + coupling, direction-free | `drive_direction()`, `coupling_matrix()` | §2 science paper |
| 3 | Adiabatic elimination | Haken; van Kampen | eliminate fast variable → effective dynamics G on slow manifold | `slow_manifold()`, `effective_dynamics()`, `landscape()`, `curvature()`, `k2_from_curvature()` | Level 0′ → G → L → k₂=κ/τ₂ |
| 4 | Order parameter | Landau; Haken | slow collective mode; the record | (instantiation-level) | metabolic layer / carbon-chemical record |
| 5 | Control parameter | Haken | external parameter sweeping instability | (instantiation-level) | λ = anesthesia dose; W(λ) narrowing |
| 6 | Circular causality | Haken | order parameter ↔ subsystems loop | (instantiation-level) | bidirectional coupling f,g |
| 7 | Critical slowing down | Haken; Strogatz | relaxation time diverges at instability | `critical_slowing_rate()`, `critical_ratio()` | window collapse T-2 |
| 8 | Bi-exponential relaxation | generic two-timescale result | dρ/dt = −k₁(ρ−ρ₁) − k₂(ρ−ρ₂) | `biexp_relaxation()`, `rate_law()`, `rate_law_equilibrium()` | LTEE, HRR/sleep fits |
| 9 | Displacement–relaxation | ours, via the above | displacement then relaxation = the two-phase signature | (composition) | E-series |
| 10 | Threshold window derivation | ours, via the above | W = τ₁·ln(n·a/(θ−a)) family | `integration_window()`, `window_sweep()` | flytrap 29.5 s (T-6 bench) |
| 11 | Order-parameter formation | Haken; pitchfork amplitude equation | τ₂ẏ = α(λ)y − βy³; order parameter born at instability; the inbound half of g | `amplitude_dynamics()`, `growth_coefficient()`, `order_parameter_equilibria()`, `order_parameter_growth()`, `critical_fluctuations()`, `g_regime()` | C4 convergence, Cambrian radiation (INBOUND_OUTBOUND.md Move 2) |

## Discipline

- An abstraction earns its place by surviving the substrate-stripping
  test (zero biological nouns).
- Research × implementation: each inventory row is both a math result
  and a code unit. The package is the research; the research is the
  package.
- Every quantitative claim lands as a test or a ticket before it lands
  in a paper.
