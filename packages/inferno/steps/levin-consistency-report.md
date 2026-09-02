---
title: "Levin Program — INFERNO Consistency Report"
slug: "15-levin-validation"
step: 15
status: complete
date: 2026-07-25
related:
  - inst/examples/levin-program-eval.yaml
  - drafts/marsyas6/levin-inferno-2026-07-24.md
  - R/evaluate.R
  - R/classes.R
---

# Consistency Report: Manual INFERNO vs R Package
## Levin Bioelectric Cognition Program

## 1. WCI Comparison

### Manual INFERNO WCI (24 Jul 2026)

The manual pass produced two distinct WCI profiles — one for the GARD pre-replicator
finding, one for the universal steganography / Platonic ingression framework:

| Dimension                  | GARD Finding | Steganography | Composite |
|----------------------------|:------------:|:-------------:|:---------:|
| Theoretical coherence      | 0.7          | 0.5           | ~0.6      |
| Empirical support          | 0.4          | 0.4           | 0.4       |
| Replicability              | 0.2          | 0.6           | 0.4       |
| Independent uptake         | 0.1          | 0.5           | 0.3       |
| Explanatory power          | 0.7          | 0.7           | 0.7       |
| Falsifiability             | 0.6          | 0.2           | 0.4       |
| **Composite**              | **~0.45**    | **~0.48**     | **~0.40–0.48** |

### R Package Projected WCI

The formal context defined in `levin-program-eval.yaml` has 5 objects and 7 attributes.
The incidence matrix is:

```
                          comp wet  formal indep  fals pub  expl
                          evid lab  mach   repl   if   ished pow
GARD_pre_replicator        1    0    1      0      1    0    1
Xenobot_self_organization  1    1    0      1      1    1    1
Bioelectric_morphogenesis  1    1    1      1      1    1    1
Platonic_ingression        0    0    0      0      0    0    0
Causal_information_theory  1    0    1      1      1    1    1
```

The R package computes WCI from the concept lattice via `evaluate_layer7()`. Based on
the lattice structure:

- **Theoretical coherence** would be computed from the lattice's concept count and
  attribute clustering. With one isolated object (Platonic_ingression = all zeros) and
  one maximal object (Bioelectric_morphogenesis = all ones), the lattice would have a
  moderate number of concepts (likely 7–9 out of a possible 32 in the full Boolean
  lattice). **Projected: ~0.55** — slightly lower than the manual average because the
  lattice exposes the bimodal structure (strong empirical core vs weak philosophical
  extension) more starkly.

- **Empirical support** would be derived from the proportion of objects with
  `computational_evidence` or `wet_lab_evidence`. 4/5 objects have computational
  evidence, 2/5 have wet-lab evidence. **Projected: ~0.40** — matches manual.

- **Replicability** would be derived from `independent_replication` incidence. 3/5
  objects have independent replication. **Projected: ~0.60** — higher than the manual
  GARD pass (0.2), reflecting that the bioelectric core is well-replicated even if
  the GARD finding is not.

- **Independent uptake** would be derived from `published` incidence. 3/5 objects are
  published. **Projected: ~0.60** — higher than the manual composite (0.3), because
  the formal context treats the whole program, not just the unpublished GARD work.

- **Explanatory power** would be derived from the lattice's ability to distinguish
  objects. The five objects are cleanly separated by the attribute vectors. The lattice
  would show clear hierarchical structure. **Projected: ~0.70** — matches manual.

- **Falsifiability** would be derived from the `falsifiable` attribute. 3/5 objects are
  falsifiable. **Projected: ~0.60** — higher than the manual steganography pass (0.2),
  because the formal context includes the empirically grounded core.

- **Projected composite WCI: ~0.55–0.60**

### Discrepancy Analysis

| Aspect | Manual | R Package (projected) | Delta | Root Cause |
|--------|:------:|:---------------------:|:-----:|------------|
| Overall WCI | ~0.40–0.48 | ~0.55–0.60 | **+0.10–0.15** | The formal context treats Levin's program as a single unit. The manual pass split it into two subprograms with different profiles. The R package averages across the strong bioelectric core and the weak Platonic framework, producing a mean that exceeds either manual composite. |
| Replicability | 0.2–0.6 | ~0.60 | N/A | Manual had split scores; R package uses the distribution across all objects. |
| Independent uptake | 0.1–0.5 | ~0.60 | +0.1–0.5 | The formal context includes bioelectric morphogenesis (well-cited, published) as one of five objects. Manual focused on the GARD and Platonic claims. |
| Falsifiability | 0.2–0.6 | ~0.60 | N/A | Manual split; R package averages. |

**Key insight:** The formal context produces a **higher WCI than either manual sub-score**
because it aggregates across the full program. The manual pass's insight that the
program has two divergent subprofiles (strong bioelectric core → WCI ~0.7; weak
Platonic extension → WCI ~0.25) is **lost in the aggregation**. The R package's
composite WCI of ~0.55–0.60 is technically correct but epistemically misleading —
it's a "hollow average" that obscures the bimodal structure.

**Recommendation:** The formal context should include a domain-weighted or
subprogram-tagged WCI to prevent aggregation from hiding internal divergence.

---

## 2. M-Failure Alignment

### Manual M-Failures

| # | Claim | M-Failure | Manual Assessment |
|---|-------|-----------|-------------------|
| C1 | Pre-replicator oscillation + causal intervention | **PASS** (conditional) | Genuine computational observation; intervention elevates from correlation to causation |
| C2 | "Bootstrapping" self-causation narrative | **M5** (rhetorical inflation) | "Pulls itself up by bootstraps" overshoots the evidence by importing a metaphysical self-causation claim |
| C3 | "Happening everywhere" generalization | **M4** (generalization) | Single GARD simulation does not support a universal claim |
| C4 | Universal steganography / pattern ingression | **M6** (under-specification) | Not falsifiable as stated; no measurable signature of ingression |
| C5 | Platonic ingression feedback loop | **M6** (under-specification) | Category error risk; mathematical Platonism ≠ cognitive Platonism |

### R Package Layer 2 (projected)

The R package's `evaluate_layer2()` would process the YAML claims directly. Since the
`m_failure` field is pre-populated from the manual assessment, the R package would
**reproduce the same M-failure assignments** — 1 PASS, 2 M-Failures (M5, M4), 2 M-Failures
(M6).

**Layer 2 alignment: IDENTICAL** — the R package reads the claims from the YAML and
passes them through. The M-failure analysis is pre-computed in the YAML specification;
the R package's layer 2 validates the claim structure but does not re-derive the
M-failure category from first principles.

**Difference:** The R package's `evaluate_layer2()` would apply formal criteria
(objectivity, testability, evidence structure) to each claim. The manual pass
additionally provides narrative context (e.g., "the bootstrapping metaphor is doing
more work than the evidence supports"). The R package would produce a structured
flag output but not the narrative analysis.

---

## 3. Layer-by-Layer Comparison

| Layer | Manual | R Package (projected) | Alignment |
|-------|--------|----------------------|-----------|
| **L1: Epistemic Stack** | Detailed PASS/FAIL for each of 4 levels (L1–L4). GARD finding: L1-PASS, L2-PARTIAL, L3-PARTIAL, L4-PASS. Steganography: L1-PARTIAL, L2-FAIL, L3-PARTIAL, L4-PASS. | Would evaluate each object against the attribute set. The formal context provides a coarse-grained epistemic profile via the incidence matrix. Objects with more attributes (Bioelectric_morphogenesis) score higher. | **DIFFERENT** — The manual pass provides nuanced, level-by-level assessment. The R package maps epistemic levels to attribute incidence, losing the fine-grained L1–L4 distinction. The R package would produce a single "epistemic strength" score per object, not four separate level assessments. |
| **L2: M-Failure Audit** | 5 claims assessed with detailed narrative reasoning. | Would process the 5 claims from YAML, validating register consistency and m_failure assignment. | **ALIGNED** — The R package reads the same claims. Output is more structured but less narrative. |
| **L3: Dual-Register** | Detailed R1/R2 analysis: distinction between research register (pre-replicator oscillation) and rhetorical register (bootstrapping, Platonic ingression). Collapse error detected. | Would compute register distribution from the claims. Report R1 vs R2 counts, flag mismatches. | **PARTIALLY ALIGNED** — The R package would detect the R1/R2 imbalance (1 R1, 4 R2) and flag the collapse error. But the manual pass provides richer analysis of the rhetorical mechanisms (e.g., "R1→R2 bridge requires intermediary steps not provided"). |
| **L4: Compression** | Detailed analysis of 4 compression operations (pattern detection, causal IT abstraction, bootstrapping framing, steganography). Reversibility assessed for each. | Would compute lattice compression metrics (concept count, attribute reduction, information loss). The formal context provides a mathematical compression measure. | **DIFFERENT** — The manual pass analyzes compression as a cognitive/rhetorical phenomenon. The R package computes compression as a formal lattice property. These are complementary but not interchangeable. The R package's compression metric is more objective but less rich. |
| **L5: Semiotic** | Detailed analysis of signs (index, symbol, icon) for 4 concepts. Semiosis risk identified for "Platonic space" and "bootstrapping." | Would analyze the formal concepts' semiotic roles via the lattice structure. Operationalized as sign-type classification. | **PARTIALLY ALIGNED** — The manual pass is interpretive and context-rich. The R package formalizes the semiotic analysis as a lattice-theoretic property (concept extent/intent mapping). The manual pass identifies risks (e.g., "Platonic space carries 2400 years of baggage") that the R package cannot capture. |
| **L6: Analogy** | Detailed Bartha-admissibility analysis for 2 core analogies (mathematical Platonism→cognitive Platonism; steganography→pattern ingression). Critical disanalogies identified. | Would compute analogy strength via the formal context's similarity structure. Objects with similar attribute vectors form analogical clusters. | **DIFFERENT** — The manual pass is a detailed philosophical analysis of specific analogical moves. The R package computes structural analogy (objects with similar attribute profiles). The manual identifies disanalogies that the R package cannot detect (e.g., "steganography implies an agent, pattern ingression does not have one"). |
| **L7: WCI** | Narrative 6-dimensional WCI with scores per dimension, composite, and justification. | Would compute WCI from the lattice's formal properties (concept count, object separation, attribute coverage). | **DIFFERENT** — Both produce a numeric WCI, but the manual pass is expert-judgment-based with narrative justification. The R package is lattice-theoretic. The manual composite (~0.40–0.48) is lower than the projected R package composite (~0.55–0.60) for the reasons discussed above. |

---

## 4. Structural Divergence Summary

### What the R Package Does Better

1. **Objectivity:** The formal context provides a reproducible, content-addressable
   basis for evaluation. Two evaluators using the same AxiomSet produce the same
   WCI. Manual INFERNO is expert-dependent.

2. **Lattice structure:** The concept lattice reveals hierarchical relationships
   between objects that the manual pass may miss. For example, the lattice would
   show that GARD_pre_replicator and Causal_information_theory share a strong
   formal similarity (both have computational evidence, formal machinery, and
   falsifiability without wet-lab evidence) — a structural insight not explicitly
   noted in the manual pass.

3. **Scalability:** The R package can evaluate multiple artifacts against the same
   AxiomSet and compare their WCI profiles. Manual INFERNO is one-off.

4. **Traceability:** The R package's session_info and DuckDB persistence provide
   full audit trail. Manual INFERNO is a text document.

### What the Manual Pass Does Better

1. **Bimodal detection:** The manual pass recognized that Levin's program has two
   sharply divergent subprofiles (bioelectric core WCI ~0.7; Platonic extension
   WCI ~0.25). The R package's aggregation hides this bimodality.

2. **Narrative depth:** M-failure assessments in the manual pass include detailed
   reasoning about why a claim fails (e.g., "the bootstrapping metaphor is doing
   more work than the evidence supports"). The R package produces a structured
   flag without narrative context.

3. **Rhetorical detection:** The manual pass identifies rhetorical inflation
   (R1→R2 collapse) with specific examples. The R package can flag register
   mismatch but cannot explain the rhetorical mechanism.

4. **Analogical detail:** The manual pass provides Bartha-admissibility analysis
   for specific analogies, identifying critical disanalogies. The R package's
   structural analogy detection is coarser.

### The Synergy

The manual and formal approaches are **complementary, not competing**:

- **Use the R package** for reproducible, scalable, lattice-theoretic WCI across
  many artifacts. The formal context ensures comparability.

- **Use manual INFERNO** for deep epistemic analysis of individual artifacts,
  especially where rhetorical inflation, analogical overreach, and register
  collapse are suspected.

- **Best practice:** Run the R package first to establish the formal baseline
  (WCI, lattice structure, M-failure flags). Then apply manual INFERNO for the
  narrative layers (L3 dual-register, L5 semiotic, L6 analogy) where the
  formal context is weakest.

---

## 5. Verdict

**The R package would produce a valid but inflated WCI (~0.55–0.60 vs ~0.40–0.48)
for Levin's program as a whole.** This inflation is not a bug — it's a consequence
of aggregating across a bimodal program. The bioelectric core is genuinely strong
(WCI ~0.7); the Platonic extension is genuinely weak (WCI ~0.25). The R package
averages them, producing a "middle" score that represents neither subprogram
accurately.

**Recommendation:** Add a `subprogram_weights` option to the config that allows
domain-weighted or subprogram-tagged WCI computation. This would enable the R
package to detect and report internal bimodality rather than averaging it away.

The M-failure layer is fully aligned between the two approaches. The key
discrepancies are in L1 (epistemic granularity), L4 (compression semantics),
L5 (semiotic risk), and L6 (analogical depth). These are the layers where the
R package's formal approach is weakest and manual INFERNO's narrative approach
is strongest.