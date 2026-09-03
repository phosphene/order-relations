# Dependency Strategy

How we select, manage, and audit R package dependencies.

## Decision Framework

Before adding any dependency, answer these questions:

### 1. Does CRAN already solve this?

```r
# Semantic search — find what exists
pkgsearch::pkg_search("your problem description", size = 30)

# Filter for reliable, actively maintained packages
results[results$downloads_last_month > 1000, c("package", "title", "downloads_last_month")]
```

### 2. Is there a Task View?

CRAN Task Views are curated expert-reviewed package collections:

```r
# Browse the Bayesian inference landscape
bayesian_view <- ctv::read.views("Bayesian")
bayesian_view[[1]]$packagelist$name

# Other relevant views:
# - Phylogenetics
# - Spatial
# - TimeSeries
# - MachineLearning
```

### 3. Multi-criterion search

```r
# Combine search terms
packagefinder::findPackage("phylogenetic AND comparative AND Bayesian")
```

### 4. Evaluation Criteria

| Criterion | Minimum | Preferred |
|-----------|---------|-----------|
| CRAN status | Published | Published, no NOTEs |
| Monthly downloads | > 500 | > 5,000 |
| Last update | < 2 years | < 6 months |
| Dependencies | < 20 | < 10 |
| License | OSI-approved | MIT or GPL-2/3 |
| Test coverage | Has tests | > 80% |
| Vignettes | At least one | Comprehensive |

### 5. Security Audit

Before finalizing any dependency set:

```r
# Audit against OSS Index vulnerability database
audit <- oysteR::audit_deps()

if (any(audit$vulnerable)) {
  print(audit[audit$vulnerable, c("package", "version", "vulnerability")])
  stop("Fix vulnerable dependencies before proceeding")
}
```

## Package Tiers

### Tier 1: Core Infrastructure (Always Available)

These are standard across all Foundry artifacts:

| Package | Purpose | Why |
|---------|---------|-----|
| `testthat` | Testing | Edition 3, standard framework |
| `withr` | Seed/env isolation | STDD foundation |
| `covr` | Coverage | CI gate |
| `lintr` | Static analysis | Quality gate |
| `styler` | Code formatting | Pre-commit hook |

### Tier 2: Data Manipulation (Common)

| Package | Purpose | When |
|---------|---------|------|
| `dplyr` | Data frame verbs | Most analysis |
| `readr` | CSV/TSV reading | Data ingestion |
| `tidyr` | Reshaping | Wide ↔ long transforms |
| `jsonlite` | JSON I/O | Validation reports |

### Tier 3: Statistical Modeling (Domain-Specific)

| Package | Purpose | When |
|---------|---------|------|
| `brms` | Bayesian GLMMs | Body-grammar, phylo models |
| `ape` | Phylogenetics | Tree-based analyses |
| `loo` | Model comparison | LOO-IC, WAIC |
| `rstan`/`cmdstanr` | Stan interface | Custom samplers |

### Tier 4: Reporting (Optional)

| Package | Purpose | When |
|---------|---------|------|
| `sessioninfo` | Environment fingerprint | Pipeline output |
| `knitr` | Vignette rendering | Documentation builds |

## What We Don't Use

| Package/Category | Reason |
|------------------|--------|
| `tidyverse` meta-package | Loads 30+ packages; import surgically |
| Shiny | No interactive apps in artifacts |
| R Markdown / Quarto | Papers built in our pipeline, not knitted |
| Packrat | Dead, replaced by renv |
| devtools (in artifacts) | We're not building CRAN packages in artifacts |
| S4 classes | Overengineered for analysis scripts |
| Bioconductor | Not needed unless justified + graceful fallback |
| GitHub-only packages | CRAN releases only for reproducibility |

## renv Workflow

### Initialize

```r
renv::init()          # First time — creates lockfile
renv::snapshot()      # After adding/removing packages
```

### Restore (Collaborator / CI)

```r
renv::restore(prompt = FALSE)
```

### Add a Package

```r
renv::install("brms")   # Install
renv::snapshot()         # Lock
```

### Audit Lock Drift

```r
renv::status()  # Shows what's out of sync
```

## Posit Package Manager (PPM)

All environments point to PPM for binary installs:

```r
options(repos = c(
  CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
))
```

Benefits:
- Pre-compiled Linux binaries (no source compilation in CI)
- Frozen CRAN snapshots (deterministic across time)
- Dramatically faster CI runs (brms install: seconds, not minutes)

## Version Pinning

`renv.lock` pins exact versions. For DESCRIPTION, use minimum versions only:

```
Imports:
    brms (>= 2.21.0),
    dplyr (>= 1.1.0)
```

Never pin exact versions in DESCRIPTION — that's renv's job.
