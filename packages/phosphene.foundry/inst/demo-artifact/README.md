# Beta-Binomial Bayesian Analysis Demo

Forged by the [Phosphene R Artifact Foundry](https://github.com/phosphene/order-relations).

## What This Demonstrates

A complete analysis artifact with all four tiers of the testing pyramid:

| Tier | What | File |
|------|------|------|
| **Unit** | Exact posterior math, input validation | `test-unit-posterior.R` |
| **BDD** | Statistical claims as executable specs | `test-bdd-analysis.R` |
| **Integration** | Parameter recovery across probability range | `test-integration-recovery.R` |
| **Gherkin** | Stakeholder-readable pipeline acceptance | `analysis_pipeline.feature` |

## The Analysis

Conjugate Beta-Binomial Bayesian updating:
- **Prior**: Beta(2, 2) — weakly informative, centered at 0.5
- **Data**: 10 observations (8 successes, 2 failures)
- **Posterior**: Beta(10, 4) — mean = 0.714, 95% CI [0.452, 0.908]

## Quick Start

```bash
cd inst/demo-artifact
Rscript R/main.R
```

## Architecture

Follows the MPI Handoff Blueprint:
- `R/posterior.R` — pure functions (data in, data out)
- `R/main.R` — guarded orchestrator (`sys.nframe() == 0`)
- `data/observations.csv` — input data (committed)
- `results/` — output (validation report committed)

## Testing

```bash
# Unit + BDD (fast)
Rscript -e "testthat::test_dir('tests/testthat', filter = 'unit|bdd')"

# Integration (needs RUN_INTEGRATION=true)
RUN_INTEGRATION=true Rscript -e "testthat::test_dir('tests/testthat')"
```
