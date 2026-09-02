# Phosphene R Engineering Standards

Consolidated production-grade R development standards for the Phosphene
platform. This document codifies two source specifications:

1. **Professional R DevEx Best Practices** — enterprise scaffolding, dependency
   isolation, quality gates, CI/CD, CRAN governance
2. **Academic to Production R Engineering** — STDD, double-repository
   architecture, idiomatic interfaces, high-performance backends

## Table of Contents

1. [Deterministic Environments](#1-deterministic-environments)
2. [Quality Gates](#2-quality-gates)
3. [Testing Strategy](#3-testing-strategy)
4. [CI/CD Pipeline Architecture](#4-cicd-pipeline-architecture)
5. [Code Organization](#5-code-organization)
6. [Dependency Management](#6-dependency-management)
7. [S3 Class Design](#7-s3-class-design)
8. [Documentation Standards](#8-documentation-standards)
9. [Repository Architecture](#9-repository-architecture)
10. [Anti-Patterns](#10-anti-patterns)

---

## 1. Deterministic Environments

### The Three-Tier Dependency Pyramid

```
┌────────────────────────────────────────────────────────┐
│ 1. Immutable Container (Docker / Rocker base image)    │
├────────────────────────────────────────────────────────┤
│ 2. Team package mirror (Posit Package Manager - PPM)   │
├────────────────────────────────────────────────────────┤
│ 3. Project-specific lockfile (renv.lock)               │
└────────────────────────────────────────────────────────┘
```

**Layer 1 — System (Docker):** Standardize on `rocker/r-ver:4.4.0` to pin R
minor version and system libraries (`libxml2`, `libssl-dev`, `libcurl4`).

**Layer 2 — Repository Mirror (PPM):** All repos point to Posit Package
Manager instead of public CRAN. PPM serves frozen snapshots and pre-compiled
Linux binaries. This reduces CI compile times from hours to seconds for
heavy dependencies (brms, Stan).

```r
# Environment configuration
R_REPOSITORIES="CRAN=https://packagemanager.posit.co/cran/__linux__/jammy/latest"
```

**Layer 3 — Project Isolation (renv):** Every project uses `renv` in
explicit-install mode. Committed files:

- `renv.lock` — the lockfile (MUST be committed)
- `renv/activate.R` — bootstrap script (MUST be committed)
- `renv/settings.json` — project settings (committed)
- `renv/library/` — NOT committed (`.gitignored`, rebuilt from lockfile)

### Global Package Cache

Configure a shared cache to prevent duplicate disk usage:

```bash
# /etc/R/Renviron or ~/.Renviron
RENV_PATHS_CACHE=/opt/r-package-cache
```

First collaborator pays compilation cost; everyone after gets symlinks.

### Session Fingerprint

Every pipeline run MUST capture the full environment:

```r
# At end of pipeline
sessioninfo::session_info() > "results/session_info.txt"
# Fallback
sessionInfo() > "results/session_info.txt"
```

This records R version, package versions, OS, locale — the full fingerprint
for reproducibility verification.

---

## 2. Quality Gates

### Pre-Commit Hooks

Enforce quality before code enters version control:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/lorenzwalthert/precommit
    rev: v0.4.3.9003
    hooks:
      - id: style-files
        args: [--style_transformer=styler::tidyverse_style]
      - id: lintr
      - id: parsable-R
      - id: no-browser-statement
```

### Linter Configuration

```
# .lintr (single-line DCF format required)
linters: linters_with_defaults(line_length_linter = line_length_linter(120), object_name_linter = object_name_linter("snake_case"))
```

Standard: 120-character lines, `snake_case` naming.

### Security Audits

Audit dependencies against the OSS Index before any release:

```r
audit_results <- oysteR::audit_deps()
if (any(audit_results$vulnerable)) {
  stop("Vulnerabilities detected: ",
       paste(audit_results[audit_results$vulnerable, ]$package, collapse = ", "))
}
```

### Coverage Threshold

Hard gate: **80% minimum coverage**. PRs that drop coverage below this
threshold are automatically blocked in CI.

```r
cov <- covr::package_coverage()
pct <- covr::percent_coverage(cov)
if (pct < 80) stop("Coverage below 80%: ", round(pct, 2), "%")
```

---

## 3. Testing Strategy

### The R Testing Pyramid

```
              / \
             /   \     System / E2E Tests (5%)
            /     \    Full pipeline execution
           /-------\
          /         \  Integration & Contract Tests (15%)
         /           \ Model fits, parameter recovery, convergence
        /-------------\
       /               \ Deterministic Unit Tests (80%)
      /                 \ Pure math, contracts, mocked side-effects
     └───────────────────┘
```

### Two-Tiered Strategy

**Tier 1 — Unit Tests (Local, Fast):**
- File pattern: `test-unit-*.R`
- Data: toy datasets (n ≈ 50)
- Model iterations: `sample_prior="only", iter=2` (compilation check)
- Runtime: <1 second per test
- When: every commit, local dev

**Tier 2 — Integration Tests (CI, Nightly):**
- File pattern: `test-integration-*.R`
- Data: realistic-scale datasets
- Model iterations: full chains (2000+, 4 chains)
- Runtime: minutes
- When: CI pipeline, nightly builds
- Guard: `skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")`

### Stochastic Test-Driven Development (STDD)

For Bayesian/probabilistic code, standard deterministic assertions fail.
STDD decouples math from simulation:

**Deterministic functions** (log-likelihoods, transforms): exact assertions.

**Stochastic transitions** (samplers): controlled-seed + statistical assertions:

1. **Parameter recovery** — generate from known θ*, verify θ̂ in credible interval
2. **Distributional verification** — KS test against analytical posterior (p > 0.05)
3. **Convergence assertions** — R̂ < 1.05, ESS > 400

### Seed Discipline

```r
# ALWAYS use withr for localized, auto-teardown seed isolation
withr::with_seed(42, {
  result <- my_sampler(data)
})

# Or the Foundry wrapper with cross-platform RNG specification
stdd_seed_env(42, my_sampler(data),
  .rng_kind = "Mersenne-Twister",
  .rng_normal_kind = "Inversion"   # deterministic across platforms
)
```

For brms models:
```r
brm(..., seed = 42, chains = 4, cores = 4)  # pin everything
```

### Mocking External Interfaces

Unit tests NEVER connect to databases, APIs, or filesystems:

```r
# HTTP mocking with httptest
httptest::with_mock_dir("mock_api", {
  result <- fetch_data(endpoint = "/api/v1/languages")
  expect_type(result, "list")
})

# Database mocking with mockery
mockery::stub(get_records, "DBI::dbGetQuery",
  data.frame(id = 1:2, val = c(10, 20)))
```

---

## 4. CI/CD Pipeline Architecture

### Modular GitHub Actions

Three-stage pipeline with explicit dependencies:

```
lint (Static Analysis) → test (Test Suite) → coverage (Coverage Gate)
```

**Stage 1 — Lint:** lintr + styler dry-run. Zero tolerance for violations.

**Stage 2 — Test:** Unit tests first (fail fast), then full suite.

**Stage 3 — Coverage:** `covr::package_coverage()` with 80% hard gate.
Cobertura XML export for integrations.

### Container Strategy

All CI runs in `rocker/r-ver:4.4.0` containers. This ensures:
- Identical R version across all environments
- System libraries pre-installed
- No "works on my machine" failures

### Caching

Cache R packages keyed on `DESCRIPTION` hash:

```yaml
- uses: actions/cache@v4
  with:
    path: /usr/local/lib/R/site-library
    key: ${{ runner.os }}-r-pkgs-${{ hashFiles('DESCRIPTION') }}
```

### Stan/brms in CI

brms generates Stan → C++ compilation. First-run compile is slow.

- **CI smoke test:** `sample_prior="only", iter=2` — compiles + validates in ~2s
- **Full fit:** local or nightly only, never in standard CI
- **Pre-compiled binaries:** PPM eliminates source compilation entirely

---

## 5. Code Organization

### The MPI Handoff Blueprint

Three pillars of separation:

**Pillar A — Data Munging (Pure):**
```r
prepare_data <- function(raw_df, coding_df) {
  validate_contract(raw_df, required_cols = c("id", "lat", "lon"))
  # transform...
  validate_contract(result, required_cols = c("id", "predictor", "outcome"))
  result
}
```

**Pillar B — Model Fitting (Seed-Locked):**
```r
fit_model <- function(data, seed = 42L, chains = 4L) {
  brm(outcome ~ predictor + (1 | group), data = data,
      family = bernoulli(), seed = seed, chains = chains)
}
```

**Pillar C — Result Extraction (Pure):**
```r
extract_results <- function(fit) {
  as.data.frame(fixef(fit))  # structured data, not printed output
}
```

### Guard Pattern

```r
main <- function() {
  data <- read_csv("data/input.csv")    # impure: isolated
  clean <- prepare_data(data)            # pure
  model <- fit_model(clean)              # seed-locked
  results <- extract_results(model)      # pure
  write_csv(results, "results/out.csv")  # impure: isolated
}

if (sys.nframe() == 0) main()  # Rscript runs, source() loads
```

### Naming Conventions

- R files: `snake_case.R`
- Test files: `test-snake_case.R` (testthat edition 3 hyphen convention)
- Data files: `descriptive_name.csv`
- No spaces in filenames anywhere
- Functions: `snake_case`
- S3 classes: `snake_case`
- Constants: `SCREAMING_SNAKE`

### Import Strategy

```r
# YES: surgical imports
library(dplyr)
library(readr)
library(brms)

# NO: meta-package bloat
library(tidyverse)  # loads 30+ packages
```

---

## 6. Dependency Management

### CRAN Only

All dependencies from CRAN. No GitHub dev versions. No Bioconductor
unless explicitly justified with a graceful fallback.

### CRAN Intelligence

Before writing custom functions, query the ecosystem:

```r
# Semantic search
pkgsearch::pkg_search("Bayesian structural time series", size = 30)

# Curated domain landscape
ctv::read.views("Bayesian")

# Multi-criterion discovery
packagefinder::findPackage("phylogenetic AND comparative")
```

### The DESCRIPTION File

Even analysis repos (not CRAN packages) use DESCRIPTION for structured
metadata:

```
Type: Package
Package: my.analysis
Depends: R (>= 4.4.0)
Imports: brms, dplyr, readr
Suggests: testthat (>= 3.0.0), covr, lintr
Config/testthat/edition: 3
```

### What to Never Do

- `install.packages()` anywhere in the repo — renv handles this
- `setwd()` — use project-relative paths
- `attach()` — explicit namespacing
- Mix Python and R in the same directory
- Commit `renv/library/` (rebuilt from lockfile)
- Commit `.rds` model files (reproducible from script)

---

## 7. S3 Class Design

### Three-Layer Pattern

```
Constructor  →  Validator  →  Public Helper
new_class()     validate_class()    class()
```

**Constructor** (`new_classname`): bare-metal, zero type checking, assigns class:
```r
new_bayesian_forecast <- function(point_forecasts, credible_intervals) {
  stopifnot(is.numeric(point_forecasts))
  structure(
    list(mean = point_forecasts, intervals = credible_intervals),
    class = "bayesian_forecast"
  )
}
```

**Validator** (`validate_classname`): schema checks, dimension validation:
```r
validate_bayesian_forecast <- function(x) {
  if (length(x$mean) != nrow(x$intervals))
    stop("Dimensional mismatch", call. = FALSE)
  x
}
```

**Helper** (`classname`): public API, coercion, runs constructor + validator:
```r
bayesian_forecast <- function(point_forecasts, credible_intervals) {
  res <- new_bayesian_forecast(point_forecasts, credible_intervals)
  validate_bayesian_forecast(res)
}
```

### Standard S3 Generics

Implement these for any custom class:

- `summary()` → tidy data.frame with mean, sd, CIs, ESS, R̂
- `print()` → human-readable console output
- `plot()` → returns ggplot2 object (never draws directly to device)
- `predict()` → posterior predictive draws (for model objects)

---

## 8. Documentation Standards

### Roxygen2 Docstrings

All exported functions use `#'` documentation with:

```r
#' Prepare analysis data from joined sources
#'
#' Joins language data with source-typed coding, standardizes
#' coordinates, and codes binary predictors.
#'
#' @param grambank_df Data frame with Grambank languages.
#' @param source_typed_df Data frame with source-typed coding.
#' @return Clean data frame ready for modeling.
#' @export
#' @examples
#' \dontrun{
#' result <- prepare_analysis_data(grambank, source_typed)
#' }
```

### README Structure

Every artifact README answers:

1. **What is this?** — one paragraph
2. **How to reproduce?** — three commands max
3. **What are the results?** — key findings with CIs
4. **What data does it use?** — named sources with versions
5. **How is it tested?** — test count, validation report
6. **Who wrote it?** — authors, affiliations
7. **License**

### Data Provenance

`data/README.md` documents every input file:

| File | Source | Version | Downloaded |
|------|--------|---------|-----------|
| grambank_languages.csv | Grambank CLDF | v1.0.3 | 2026-06-29 |
| source_typed.csv | Generated by prepare.py | v1 | 2026-07-01 |

## 8b. Literate Documentation

Beyond roxygen2 and README structure, every foundry package includes
**literate documentation** that connects code to scientific theory.
See [`LITERATE_DOCS.md`](LITERATE_DOCS.md) for the full specification.

Three layers:

1. **Function-level**: `@section Theoretical Context:` in every exported
   function — what prediction, what competitor, what supports/refutes
2. **Package-level**: vignette with scientific motivation, function map,
   worked example, limitations, interpretation guide
3. **Analysis-level**: literate report (.Rmd) interleaving code, results,
   and interpretation for each analysis script

A package is not foundry-complete until all three layers exist.

---

## 9. Repository Architecture

### Double-Repository Pattern

Separate reusable tools from paper-specific analysis:

**Repo 1 — Core Tool Package:**
- Pure algorithms, unit tests, DESCRIPTION, NAMESPACE
- No paper-specific plots, raw data, or manuscripts
- Version-controlled, continuously integrated
- Upstream dependency for companion repos

**Repo 2 — Companion Publication:**
- Manuscript source, simulation pipelines, empirical data
- Declares exact Core Package version in `renv.lock`
- Reproducible environment frozen forever

### Standard Artifact Structure

```
artifact/
├── DESCRIPTION
├── NAMESPACE
├── R/                          # Pure functional library
├── tests/
│   └── testthat/
│       ├── test-unit-*.R       # Tier 1: fast
│       └── test-integration-*.R # Tier 2: full fits
├── data/                       # Input data (committed)
│   └── README.md               # Provenance
├── data-raw/                   # Scripts that produced data/
├── results/                    # Outputs
│   ├── validation_report.json  # Committed
│   └── model_summary.txt       # Committed
├── docs/
│   └── METHODS.md              # Statistical methods
├── .github/workflows/ci.yml
├── .lintr
├── .pre-commit-config.yaml
├── run_pipeline.sh
├── run_tests.R
├── renv.lock
└── README.md
```

---

## 10. Anti-Patterns

| Don't | Do |
|-------|-----|
| `set.seed()` at script top | `withr::with_seed()` per block |
| `library(tidyverse)` | `library(dplyr)` surgically |
| `install.packages()` in scripts | `renv::restore()` from lockfile |
| `setwd("/absolute/path")` | Project-relative paths |
| `attach(data)` | Explicit `data$column` |
| `source("/absolute/path.R")` | Relative `source("R/utils.R")` |
| Print results to console as output | Return structured data frames |
| Commit `.rds` model files | Reproduce from script |
| Test model fit in unit tests | Compile-only smoke test |
| `expect_equal(mcmc_draw, 1.234)` | Statistical hypothesis assertions |
| `browser()` in committed code | Pre-commit hook blocks it |
| GitHub dev package deps | CRAN releases only |
| Skip stochastic tests | Two-tier: fast unit + slow integration |
| Unseeded randomness in tests | Every call under explicit seed |
| Manual project scaffolding | `foundry_scaffold()` from template |
