# The Inbound/Outbound Asymmetry

**Status:** opened 2026-09-02 (Jan). The exploration document's deepest
tension (§2.4): the framework is strongest for *outbound* trajectories
(capacity loss) and weakest for *inbound* (capacity gain). C4
convergence, Cambrian radiation, exaptation are inbound events where VI
says "qualitatively consistent" but has no bi-exponential fit.

**Thesis of this pass.** The asymmetry is partly real and partly ours.
Three moves dissolve most of the tension; what remains is the theory's
spine, not a blemish.

## Move 1 — Change reference frame (the big one)

The rate law is a *relaxation* law, and relaxation is only "loss"
relative to the old niche. Relative to the committed niche, everything
is relaxation:

- The "gain" of C4 machinery is the **displacement** (fast,
  electrome-side act of commitment).
- The genome change after it is **relaxation in the new frame** — shown
  in time already (C4-P2 dated tree: 275 → 154 → 64 Mb, reduction
  continuous *after* the commitment node).

We were measuring gain of the new (displacement, fast) against loss of
the old (relaxation, slow) and calling it one process. In the committed
frame, inbound is outbound-shaped. The bi-exponential is symmetric
after a change of reference; the asymmetry is the observer's.

## Move 2 — Implement the other half of g (done, verified)

We only ever instantiated g as relaxation. Synergetics has the other
half built in: Haken's order-parameter **formation** — the slow mode is
born at the instability, growing from fluctuations via the amplitude
equation (pitchfork):

```
τ₂·ẏ = α(λ)·y − β·y³,    α(λ) = k₂·(λ/λ_c − 1)
```

- λ < λ_c (α < 0): single stable point y\* = 0 — relaxation only.
- λ > λ_c (α > 0): zero state destabilized, branches at
  y\* = ±√(α/β) — the order parameter FORMS.

Implemented in `formation.R` (`amplitude_dynamics`,
`growth_coefficient`, `order_parameter_equilibria`,
`order_parameter_growth`, `critical_fluctuations`, `g_regime`).

**Verified (14 assertions):**
- Growth is logistic-shaped, saturates at √(α/β); S-curve with
  inflection (acceleration then deceleration).
- **Inbound-as-relaxation:** log-distance to the new attractor decays
  linearly with slope −2α = −0.399 (fit, expect −0.4) — the SAME law
  as loss, read toward the other fixed point.
- **Fluctuation signature:** Var(y) ~ σ₀²/|α| diverges at λ_c
  (200 → 10,000 at λ = 0.5 → 0.99; ∞ at λ_c).

C4/Cambrian stop being "qualitatively consistent, no fit": they are the
α > 0 regime of the same g. The hinge between regimes is critical
slowing (T-2, already in the repo) — same λ sweep, other side of λ_c.
The flytrap dissociation band λ\* ∈ (0.475, 0.58) is where the two
regimes meet.

## Move 3 — Split the taxonomy

"Inbound" is three different things in one bucket:

| Kind | What it is | Status |
|---|---|---|
| **Re-access** | re-emergence of lost capacity in reverse loss order | framework PREDICTS it — T-4 (reframed as re-deployment) |
| **De novo innovation** | genuinely new capacity | pitchfork regime (Move 2) — formation, not relaxation |
| **Reversal** | apparent loss-order reversal | T-1 strong-perturbation boundary (already mapped, λ\* = 1.0) |

Part of the tension is a lexicon problem — same species as the
sponge-ctenophore debate: we caught it there, apply it here.

## The residue — possible whys

**Thermodynamic.** Loss is downhill (entropy-favored); gain is uphill,
funded by the electrome's free energy. The arrow of time shows up in
evolutionary dynamics; a relaxation theory is loss-shaped by
construction. `ΔG` asymmetry is the physical referent.

**Information.** Loss is forgetting (generic relaxation, has a universal
rate law); gain is learning (needs variation + selection + a teacher).
The two faces of g are not thermodynamically symmetric.

**Observational bias — where OUR characterization blocks us.** Gain is
fast-variable-dominated: behavior, ephemeral, no fossil record unless
recorded. Loss is slow-variable-dominated: genome, permanent. We search
for gain in the record where gain is least likely to be preserved. The
asymmetry of the literature is the asymmetry of the variables — a
sampling artifact of the two-timescale structure itself.

**The genuine boundary.** What *creates* new commitments is not
described by the rate law — but that is the electrome act, already
named as the root (§1.4 of the exploration doc). The asymmetry IS the
two-variable architecture: electrome commits/gains (fast), metabolic
layer relaxes/loses (slow). The rate law describes the consequence of
the act, not the act.

## Novel, checkable

1. **Fluctuation signature (tagged onto C4-P1).** Near λ\*, response
   variance should blow up BEFORE failure — a measurable precursor. The
   dissociation band becomes a variance peak, not just a threshold.
   Implementation: `critical_fluctuations()`.
2. **Exaptation fuel.** Co-option should preferentially draw on
   intermediate integration depth (retained but cheap). Checkable
   against existing Orobanchaceae/cavefish depth data.
3. **C4 arc.** Module gain = displacement (fast), subsequent genome
   reduction = relaxation (slow). The data may already be held
   (C4-P2). Fit the two phases separately.
4. **Loss/gain ratio as a depth meter.** Across lineages, the
   ratio of outbound to inbound rate should track integration depth —
   a new cross-kingdom statistic.

## Referents for the pattern

- **Ediacaran second wave as formation** (Evans et al. 2026, Sci. Adv. 12,
  eaed9916 — extract in paper-extracts/) — deep-water White Sea assemblage
  at ~567 Ma, Laurentia; steady progression, not turnover (A-1
  single-trajectory claim); behavior-first anchor (oldest motile
  bilaterians precede morphological diversification); formed in a
  stable field (observed instance, not a requirement); redox null
  undercuts oxygenation. Full placement in
  [EVOLUTION_CHARACTERIZATION.md](EVOLUTION_CHARACTERIZATION.md) (layer
  4.5, claim 6). Also a differing order relation: Ediacaran
  offshore→onshore vs Phanerozoic onshore→offshore — direction is a
  per-instance read of the λ landscape, never intrinsic.
- **Dollo's law and its violations** (Collin & Miglietta 2008) —
  violations cluster behaviorally, consistent with fast-variable gain.
- **Relaxed selection** (Lahti et al. 2009) — the null for loss.
- **Symbiont genome reduction** (McCutcheon & Moran 2011) — the one-way
  street; loss with no return.
- **Cost of complexity** (Orr 2000) — why gain is rare and loss cheap.
- **Genotype networks** (Wagner 2005) — innovation as rare, punctuated
  crossing; radiation-shaped, not exponential.
- **Learning curves** (Heathcote, Brown & Mewhort 2000) — exponential
  approach to asymptote: inbound read as relaxation toward the new
  attractor. Same law, other side.

## Status

- [x] Move 1 (frame) — documented; C4-P2 dated tree already supports it.
- [x] Move 2 (pitchfork) — implemented, 14 assertions green.
- [x] Move 3 (taxonomy) — documented; T-4 reframed as re-deployment.
- [ ] Fluctuation signature onto C4-P1 bench spec (tag: use
  `critical_fluctuations`).
- [ ] Exaptation-depth check against existing data.
- [ ] C4 two-phase refit.
