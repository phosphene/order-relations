# The Abstraction Program

**Design intent (Ed Phil, 2026-09-02).** order-relations is a place for
the *abstract*. The synergetics concepts live here as pure objects — no
substrate commitment, no directionality built in. Biology enters only at
instantiation time, as a mapping table, never inside the abstraction.

## Design law: substrate stripping

> An abstraction must be stateable with zero biological nouns. If it
> can't, it's not an abstraction yet — it's a metaphor with a formula
> attached.

Enforced structurally: every file in `R/` is noun-free except
`flytrap.R`, the mapping table where biology is allowed in.

## Design law: field, not stability

> Model the field; do not assert stability. The field is the minimal
> object the dynamics require — the space the variables move in, the
> couplings that act on them. Stability is a determinate claim (against
> what perturbation, over what horizon, for which vertex) and asserting
> it commits the abstraction to a frame it does not need.

Field and stability work at different levels. The field is the frame for
what we do not need to infer; stability is per-instance, read from the
mapping table, never intrinsic — the same move as Fix 1 (direction of
drive per-instance). Stability is relative to what a vertex views a
field as stable enough: a three-place relation — field, perturbation,
vertex — where the vertex supplies the horizon. Its quantitative form
is the integration window (row 10): a field is "stable enough" for v
when it persists over v's window, λ·W_v ≪ 1 (W_v the vertex's window,
λ the slow mode's decay rate). Critical slowing is the coincidence
λ·W_v ~ 1 — the vertex can no longer resolve stable from unstable
(observation-window collapse, T-2, read from the vertex side). Evans et
al. 2026 is the working example: "formed in a stable field" is an
observation about the instance; the abstraction needs only the field
and the crossing (α > 0).

## The flagship: slaving without directionality

In the original synergetics formulation (Haken 1983) the order parameter
enslaves the fast subsystems — one-way. The abstraction strips that:

> **Slaving = the timescale-separation fact (τ₁ ≪ τ₂) plus coupling.**
> Direction of drive is per-instance, read from f and g — never intrinsic
> to the relation.

This is the science paper's Fix 1 (post-jury revision) promoted from
paper edit to design law. The flytrap instantiates fast→slow;
anesthesia instantiates λ entering f (fast side drives); the relation
itself says neither.

| | Abstract (substrate-free) | Instance |
|---|---|---|
| **Relation** | τ₁ẋ = f(x,y); τ₂ẏ = g(x,y); ε = τ₁/τ₂ ≪ 1 | Γ = (Ca²⁺-integrator, trap program) |
| **Slaving** | slow mode persists, fast mode relaxes — timescale fact | flytrap: fast→slow |
| **Drive** | per-instance coupling read from f,g | anesthesia: λ enters f — fast side drives |

## The Jacobian: one object, many projections

The field's local linear map. Wherever f and g are differentiable,

    J = [ ∂f/∂x  ∂f/∂y ]
        [ ∂g/∂x  ∂g/∂y ]

is defined pointwise — a pure field object (design law 2: defined, not
asserted stable).

**Status of the object (Ed Phil, 2026-09-02).** Analytically and
axiomatically we assert the existence of a mathematical object we call
the Jacobian; it also exists in the record as a genealogical fact in the
history of numerical methods. But it is purely algebraic and has **no
instantiation** — any implementation is always a partial slice or
projection of this axiomatic object. The table below is a list of
projections: canonical research programs differ in *which spectral fact
of J they read*, i.e. which slice they project, not in the object. The
object itself is never instantiated; only its projections are.

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

## Discipline

- An abstraction earns its place by surviving the substrate-stripping
  test (zero biological nouns).
- Research × implementation: each inventory row is both a math result
  and a code unit. The package is the research; the research is the
  package.
- Every quantitative claim lands as a test or a ticket before it lands
  in a paper.
- **Namespace discipline (Ed Phil, 2026-09-02).** Develop each given
  research apparatus in its own namespace and reproduce its conditions —
  nothing more. Keep track of namespaces, work within a domain; no
  cross-apparatus claims, no commutation results to prove or assert.
  A field apparatus and a determinate relative stability declaration
  simply live in different namespaces; we never mix them (cf. genealogy
  tiers: reproducible math, ambiguous bracket, data-dependent fits —
  each reproduced under its own conditions). Implementations are
  projections of axiomatic objects (see the Jacobian above): never
  mistake a projection for the object.
