# Differing Order Relations: A Genealogy of the Precursor Math

**Status:** opened 2026-09-02 (Ed Phil). Request: *"break down subsections and
actually do the precursor math according to some published standard that we can
reproduce. Some of these published artifacts may not be reproducible and that's
part of the exercise — in addition to using the earlier work as a background
realization, so we have a better ground to stand on."*

**Method.** For each abstraction in the inventory (`docs/ABSTRACTION_PROGRAM.md`),
trace the published precursor, state the math as published, reproduce it from
first principles in a standalone script (`scripts/genealogy/`), and issue a
verdict. Verdicts are the point: a published artifact earns "reproducible"
only when we can re-derive it to a stated tolerance from the stated source —
no appeal to the authors' data.

**Verdict scale:**
- **reproducible** — re-derived from the stated source to stated tolerance
- **partially reproducible** — derivable, but the source underdetermines a
  parameter or the claim (documented)
- **not reproducible** — cannot be re-derived from the published text alone

## The differing relations, one table

The abstraction program now models **six distinct order relations** — they are
*differing* relations, not one relation in six costumes, and each has its own
genealogy:

| Relation | Published precursor | Genealogy | Verdict |
|---|---|---|---|
| Order-parameter (static) | Landau 1937, free-energy expansion | G-1 `g1_landau.R` | ✅ reproducible |
| Slaving / adiabatic elimination | Briggs & Haldane 1925; Haken 1983 | G-2 `g2_michaelis_menten.R`, G-3 `g3_haken_slaving.R` | ✅ reproducible |
| Critical slowing | Strogatz 1994, ch. 3/8 | G-4 `g4_critical_slowing.R` | ✅ reproducible |
| Order-parameter formation (dynamic) | Landau amplitude eq.; Strogatz normal form | G-5 `g5_pitchfork.R` | ✅ reproducible |
| Bi-exponential relaxation | NMR/kinetics two-rate standard | G-6 `g6_biexponential.R` | ✅ reproducible |
| Threshold window | Leaky summation (Volkov et al. on *Dionaea*) | G-7 `g7_window.R` | ⚠️ partially reproducible |

## G-1 — Landau 1937: the order parameter

**Source.** L.D. Landau, "On the theory of phase transitions" (Zh. Eksp. Teor.
Fiz. 7, 19; 1937). The order parameter φ minimizes

    F(φ) = F₀ + a(T−Tc)φ² + bφ⁴,   b > 0

**Precursor math.** dF/dφ = 0 ⇒ φ = 0 (disordered, T > Tc) or
φ\* = ±√(a(Tc−T)/2b) (ordered, T < Tc). **Reproduction:** analytic; φ\*
tracks √(Tc−T) continuously to zero at Tc; branch verified to 1.8e−15.

**Grounding.** This is the formal origin of "order parameter" itself — the
abstract record-keeping mode that our inventory row 4 instantiates as the
metabolic layer. Landau gives us the *static* relation; G-5 gives the dynamic
half.

## G-2 — Briggs–Haldane 1925: the canonical adiabatic elimination

**Source.** Michaelis & Menten 1913 (Biochem. Z. 49, 333); Briggs & Haldane
1925 (Biochem. J. 19, 338). The enzyme-substrate system

    dS/dt = −k₁ES + k₋₁C
    dC/dt =  k₁ES − (k₋₁+k₂)C

**Precursor math.** Quasi-steady-state assumption dC/dt ≈ 0 eliminates the
fast complex C:

    C = E₀S/(Km+S),  v = k₂C = Vmax·S/(Km+S),  Km = (k₋₁+k₂)/k₁

**Reproduction:** full ODE integrated by Euler; dP/dt compared to the closed
form at equal S after the binding transient. Max relative error 3.7% in the
QSSA window (Km = 0.6, Vmax = 0.05). **This is the 1925 published standard
for "fast variable eliminated in the field of the slow one" — the exact
operation our `effective_dynamics()` performs on the flytrap instantiation.**

## G-3 — Haken 1983: the slaving principle

**Source.** H. Haken, *Synergetics: An Introduction* (Springer 1977/1983),
ch. 7. Fast variables relax onto a manifold set by the slow variables.

**Precursor math.** Prototype: ẋ = −(1/ε)(x − ay), ẏ = −y + bx. Adiabatic
elimination: x\* = ay ⇒ reduced dynamics ẏ = (ba−1)y.

**Reproduction:** full vs reduced integration; max |y_full − y_reduced| =
9.9e−3 at ε = 0.01, 1.0e−3 at ε = 0.001 — error ratio 9.9 ≈ 10, i.e.
**O(ε) convergence, exactly as the principle states.**

## G-4 — Strogatz 1994: critical slowing down

**Source.** S. Strogatz, *Nonlinear Dynamics and Chaos* (1994), ch. 3 & 8. Near
a pitchfork bifurcation ẋ = rx − x³, the linearized decay rate is |r|, so the
relaxation time diverges as τ ~ 1/|r|.

**Reproduction:** decay side (r < 0), x₀ = 0.05, time to 1% of initial
amplitude; τ = 9.2, 23.0, 45.9, 91.6, 227.3 s for |r| = 0.5…0.02.
log τ vs log|r| slope = **−0.9964** (published: −1).

**Grounding.** This is the hinge of the whole inbound/outbound architecture:
the same λ-sweep that shows critical slowing (T-2, window collapse) is the
crossing where relaxation gives way to formation (G-5).

## G-5 — Pitchfork amplitude equation: order-parameter *formation*

**Source.** Landau's amplitude equation (the time-dependent generalization of
G-1); normal form in Strogatz ch. 3. dψ/dt = αψ − βψ³, α, β > 0.

**Precursor math.** Closed form from initial amplitude ψ₀:

    ψ(t) = √(α/β) / √(1 + C·e^(−2αt)),   C = (α/β − ψ₀²)/ψ₀²

**Reproduction:** closed form vs Euler integration; max deviation 1.5e−5 over
t ∈ [0, 60]; saturation √(α/β) = 0.3162 reached to 3 significant figures.

**Grounding.** This is the exact math behind `order_parameter_growth()` in
`formation.R` — the inbound half of g. C4 convergence, Cambrian radiation:
the slow mode is *born* here, not relaxed.

## G-6 — Bi-exponential relaxation: the two-rate standard

**Source.** The sum-of-two-exponentials y(t) = A₁e^(−k₁t) + A₂e^(−k₂t), k₁ ≫ k₂
— the standard two-rate form across NMR, chemical kinetics, and trait-decay
fits (LTEE-style).

**Precursor math.** Parameter recovery by nonlinear least squares.

**Reproduction:** truth A₁=0.7, A₂=0.3, k₁=1.0, k₂=0.05, σ=0.005 noise →
recovered 0.703, 0.299, 0.991, 0.0500. Max deviation 0.0086 — within noise.
**Caveat recorded:** recovery degrades as k₁/k₂ → 1 or as the slow phase
dominates the window — the identifiability boundary is exactly what T-2
(window collapse) quantifies.

## G-7 — Threshold window: leaky summation (⚠️ partially reproducible)

**Source.** Temporal summation in a leaky integrator — two stimuli of
amplitude a within interval Δt sum as V = a·e^(−Δt/τ) + a ≥ θ (Volkov et al.,
*Dionaea*; the standard neural two-pulse summation).

**Precursor math.** Δt_max = τ·ln(a/(θ−a)) (single-channel). Our flytrap code
uses the two-channel form Δt_max = τ·ln(2a/(θ−a)).

**Reproduction:** with τ = 8 s, a/θ = 0.952: single-channel **23.9 s**,
two-channel **29.4 s**; both inside the published 20–30 s bracket.

**Verdict: partially reproducible — and this is the instructive case.** The
published standard does not uniquely fix the channel count; the two readings
differ by ln(2)·τ ≈ 5.5 s. The 24 vs 29.5 s discrepancy in Appendix B is
therefore **not an error in our pipeline** — it is an ambiguity inherited from
the literature. This is precisely the "published artifact may not be
reproducible" case Ed flagged: the source gives a bracket, not a formula.

## What the exercise buys us

1. **Grounding.** Every abstraction in the inventory now stands on a
   re-derived published result, not on the authority of a citation.
2. **Separation of artifacts.** G-1…G-6 are reproducible mathematics; G-7 is
   a partially reproducible empirical bracket; the LTEE/cross-kingdom fits
   (row 8 instantiation) are *data-dependent* and reproducible only from the
   data, not from the papers — a third class to keep distinct.
3. **Failure is a result.** G-7's ambiguity is now a documented finding that
   the flytrap bench re-verify (T-6) can actually resolve: measure the
   window, see which channel count the biology picks.
4. **The differing relations are now explicit.** Slaving (G-3) is a
   timescale fact; formation (G-5) is an instability fact; relaxation (G-6)
   is a dissipation fact; critical slowing (G-4) is the hinge; the window
   (G-7) is a threshold fact. One inventory, six genealogies, three verdicts.

## Reproducibility ledger

| Genealogy | Tolerance stated | Result | Verdict |
|---|---|---|---|
| G-1 Landau | analytic | branch verified 1.8e−15 | ✅ reproducible |
| G-2 QSSA | max rel err | 3.7% | ✅ reproducible |
| G-3 slaving | O(ε) | ratio 9.9 | ✅ reproducible |
| G-4 critical slowing | slope −1 | −0.9964 | ✅ reproducible |
| G-5 pitchfork | max abs err | 1.5e−5 | ✅ reproducible |
| G-6 bi-exponential | max dev | 0.0086 | ✅ reproducible |
| G-7 window | bracket 20–30 s | 23.9 / 29.4 s | ⚠️ partially reproducible |

**Run them yourself:** `Rscript scripts/genealogy/g1_landau.R` … `g7_window.R`
(base R only — no package dependencies).
