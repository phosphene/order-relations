# CI/CD Guide

How GitHub Actions CI works for Foundry artifacts.

## Pipeline Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Stage 1       │     │   Stage 2       │     │   Stage 3       │
│   Static        │────▶│   Test          │────▶│   Coverage      │
│   Analysis      │     │   Suite         │     │   Gate          │
│                 │     │                 │     │                 │
│ • lintr         │     │ • Unit (fast)   │     │ • covr ≥ 80%   │
│ • styler check  │     │ • Integration   │     │ • Cobertura XML │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

Each stage depends on the previous — fail fast at the cheapest check.

## Container Strategy

All jobs run inside `rocker/r-ver:4.4.0`:

```yaml
container: rocker/r-ver:4.4.0
```

This ensures:
- Identical R version everywhere (development, CI, production)
- System libraries pre-installed (libcurl, libssl, libxml2)
- Reproducible environment without "works on my laptop" drift

## Environment Variables

```yaml
env:
  R_REPOS: "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
```

PPM serves pre-compiled binaries. brms installation drops from ~10 minutes
(source compile) to ~10 seconds (binary fetch).

## Stage 1: Static Analysis

```yaml
- name: Lint package
  run: Rscript -e "lintr::lint_package()"
```

Catches:
- Style violations (line length, naming conventions)
- Syntax errors
- `browser()` statements left in code
- Logic issues (unused variables, missing returns)

## Stage 2: Test Suite

### Unit Tests First (Fail Fast)

```yaml
- name: Run unit tests
  run: Rscript -e "testthat::test_local(filter = 'unit', reporter = testthat::CheckReporter)"
```

Unit tests complete in seconds. If they fail, we skip expensive integration
tests entirely.

### Full Suite

```yaml
- name: Run full test suite
  run: Rscript -e "testthat::test_local(reporter = testthat::CheckReporter)"
```

### Integration Tests (Nightly)

For heavy model fits, use a separate nightly workflow:

```yaml
# .github/workflows/nightly.yml
on:
  schedule:
    - cron: '0 3 * * *'  # 3 AM UTC daily

env:
  RUN_INTEGRATION: "true"
```

Integration tests check `Sys.getenv("RUN_INTEGRATION")` before running
expensive operations.

## Stage 3: Coverage Gate

```yaml
- name: Check coverage (>= 80%)
  run: |
    Rscript -e "
      cov <- covr::package_coverage()
      pct <- covr::percent_coverage(cov)
      message('Coverage: ', round(pct, 2), '%')
      if (pct < 80) stop('Coverage below 80% threshold')
    "
```

The gate blocks any PR that drops coverage below 80%.

### Coverage Report Artifact

```yaml
- name: Export Cobertura report
  if: always()
  run: Rscript -e "covr::to_cobertura(covr::package_coverage())"

- uses: actions/upload-artifact@v4
  with:
    name: coverage-report
    path: cobertura.xml
```

## Package Caching

```yaml
- uses: actions/cache@v4
  with:
    path: /usr/local/lib/R/site-library
    key: ${{ runner.os }}-r-pkgs-${{ hashFiles('DESCRIPTION') }}
```

Cache invalidates when DESCRIPTION changes (new dependencies). Within
the same dependency set, installs are near-instant.

## Stan/brms CI Strategy

Stan compiles R → Stan code → C++ → binary. First compilation is slow.

### Smoke Test (Standard CI)

```r
# Compiles model without fitting — validates Stan code in ~2 seconds
fit <- brm(
  y ~ x,
  data = data.frame(y = rnorm(20), x = rnorm(20)),
  sample_prior = "only",
  iter = 2,
  chains = 1,
  silent = 2,
  refresh = 0
)
```

### Full Fit (Nightly Only)

```r
fit <- brm(
  outcome ~ predictor + (1 | group),
  data = analysis_data,
  seed = 42,
  chains = 4,
  cores = 4,
  iter = 2000
)
```

Never in standard CI — minutes per model, plus Stan compilation overhead.

## Workflow File Reference

The generated `ci.yml` follows this structure:

```yaml
name: R Artifact CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  lint:        # Stage 1 — no dependencies
  test:        # Stage 2 — needs: lint
  coverage:    # Stage 3 — needs: test
```

## Troubleshooting

### `.lintr` Parse Error

lintr expects single-line DCF format:
```
# WRONG (multi-line)
linters: linters_with_defaults(
  line_length_linter(120)
)

# RIGHT (single-line)
linters: linters_with_defaults(line_length_linter = line_length_linter(120))
```

### PPM Binary Not Available

If a package isn't available as a binary on PPM, it falls back to source
compilation. This is rare for CRAN packages but watch CI timing.

### Cache Miss on Every Run

Verify the cache key uses `hashFiles('DESCRIPTION')` not `hashFiles('renv.lock')`.
DESCRIPTION is more stable; lockfile changes on every snapshot.
