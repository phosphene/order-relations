# The Abstraction Program

**Design intent (Ed Phillips, 2026-09-02).** order-relations is a place for
the *abstract*. The synergetics concepts live here as pure objects — no
concrete commitment, no directionality built in.
## Design: 

> An abstraction as without concrete reference

Enforced structurally: every file in `R/` is noun-free except
`flytrap.R`, the mapping table where abstraction is mapped to empirical.


## slaving without directionality

In the original synergetics formulation (Haken 1983) the order parameter
enslaves the fast subsystems — one-way. The abstraction strips that:

> **Slaving = the timescale-separation fact (τ₁ ≪ τ₂) plus coupling.**
> Direction of drive is per-instance, read from f and g — never intrinsic
> to the relation.

This is the original paper's Fix 1 (post-jury revision) promoted from
paper edit to design law. The flytrap instantiates fast→slow;
anesthesia instantiates λ entering f (fast side drives); the relation
itself says neither.

| | Abstract (substrate-free) | Instance |
|---|---|---|
| **Relation** | τ₁ẋ = f(x,y); τ₂ẏ = g(x,y); ε = τ₁/τ₂ ≪ 1 | Γ = (Ca²⁺-integrator, trap program) |
| **Slaving** | slow mode persists, fast mode relaxes — timescale fact | flytrap: fast→slow |
| **Drive** | per-instance coupling read from f,g | anesthesia: λ enters f — fast side drives |

## The Jacobian

The field's local linear map. Wherever f and g are differentiable,

    J = [ ∂f/∂x  ∂f/∂y ]
        [ ∂g/∂x  ∂g/∂y ]

is defined pointwise — a pure field object (design law 2: defined, not
asserted stable).


| # | Read from J | Spectral fact | Canonical programs | Our row |
|---|---|---|---|---|
| a | eigenvalues at a fixed point | stability classification (Hartman–Grobman) | nonlinear dynamics; ecology (community matrix); neuroscience; control; macro (correspondence principle) | 1 |
| b | leading eigenvalue → 0 | critical slowing; relaxation time diverges | critical transitions / early-warning signals; phase transitions | 7 |
| c | Re(λ) crossing 0 | instability onset; order parameter born (α > 0) | synergetics; Landau theory; adaptive dynamics (branching points) | 11 |
| d | eigenvector split | slow vs fast modes; slaving; adiabatic elimination | synergetics; neural fields; metabolic control | 2, 3 |
| e | off-diagonal entries | coupling; direction of drive (per-instance) | community ecology (sign structure); systems biology (elasticities); Granger-style inference | 2 (Fix 1) |
| f | J⁻¹ and parameter derivatives | sensitivity; control coefficients; comparative statics | metabolic control analysis; economics | (open) |

The research program supplies the point (which fixed state), the fact
(which row), and the frame (which noun-world); the abstraction owns none
of those — it owns J and its spectral facts. Stability (row a) is the
special case the field-not-stability law warned about: a per-instance
eigenvalue claim about a specific fixed point, never intrinsic — and the
classification is vertex-relative: "stable enough" is λ·W_v ≪ 1, the
eigenvalue compared against the vertex's own window (row 10). Critical
slowing (row b) is the same comparison collapsing: λ·W_v ~ 1.

Row f is open: the sensitivity/control-coefficient family (J⁻¹ reads)
is the one canonical use not yet in the inventory — a candidate for a
row 12 once a first instantiation shows up.

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


- Every quantitative claim lands as a test or a ticket
  mistake a projection for the object.
