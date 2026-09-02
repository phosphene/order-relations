# Developer Experience (DevEx) Approach

The Phosphene philosophy on R developer experience: why we build this way,
who we build for, and how we eliminate friction between scientific insight
and production-grade code.

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [The Friction Problem](#2-the-friction-problem)
3. [Service Model](#3-service-model)
4. [Developer Workflows](#4-developer-workflows)
5. [The Forge Transformation](#5-the-forge-transformation)
6. [Quality as DevEx](#6-quality-as-devex)
7. [Toolchain Integration](#7-toolchain-integration)
8. [Metrics That Matter](#8-metrics-that-matter)

---

## 1. Philosophy

### R as a Compile-Time Dependency Engine

R is not part of our runtime application stack. It is a **scientific
compilation target** — an isolated, versioned engine that encapsulates:

- Statistical algorithms
- Hypothesis tests and model fits
- Data-provenance assets
- Reproducibility proofs

The output of an R artifact is not "R code that runs somewhere." The output
is a **tested, versioned, self-proving package** that other systems can
consume, cite, and verify.

### The Foundry Metaphor

A foundry casts from molds. The mold is the test suite. The casting is the
analysis pipeline. The output is the proof — a validation report, a
reproducible result, a package that another scientist can install and verify.

We don't ship scripts. We ship artifacts.

### Zero-Friction Principle

Every decision in this system optimizes for one thing: **reducing the distance
between a scientific idea and a production-grade, reproducible package.**

If a scientist has to:
- Manually configure CI → friction (solved: `foundry_scaffold()`)
- Debug dependency conflicts → friction (solved: renv + PPM)
- Learn testing from scratch → friction (solved: STDD framework + generated test files)
- Set up linting → friction (solved: pre-commit hooks, `.lintr` generated)
- Figure out project structure → friction (solved: MPI Blueprint template)

The goal is that a researcher's next step after "I have an analysis idea"
is never "figure out tooling." It's "write the function."

---

## 2. The Friction Problem

### Academic R Code: The Typical State

Most academic R code looks like this:

```r
# analysis.R
setwd("C:/Users/researcher/Desktop/my_project")
library(tidyverse)
data <- read.csv("data.csv")
attach(data)
result <- lm(y ~ x1 + x2)
summary(result)
# TODO: fix this later
# source("helper.R")  # doesn't work on Jake's machine
```

Problems:
- **Hardcoded paths** — won't run on any other machine
- **No isolation** — `library(tidyverse)` loads 30+ packages, any could conflict
- **Global state** — `attach()` pollutes the namespace
- **No tests** — "it ran without errors" is the only verification
- **No version pinning** — breaks when packages update
- **No documentation** — the author can explain it; nobody else can

### The Cost of This State

- Papers retracted because results couldn't be reproduced
- Collaborators spend days debugging environment differences
- Reviews delayed because reviewers can't run the code
- Institutional knowledge lost when the postdoc leaves

### What Production-Grade Means

| Academic Script | Production Artifact |
|----------------|-------------------|
| Runs on one machine | Runs anywhere with `bash run_pipeline.sh` |
| "I tested it manually" | 52 automated tests, validation report |
| `library(tidyverse)` | `renv.lock` with exact versions |
| Emailed as .zip | Git repo with CI badge |
| "See my thesis for methods" | Docstrings on every function |
| "Works if you source it right" | `sys.nframe() == 0` guard pattern |

---

## 3. Service Model

### Who We Serve

**Primary: Research scientists** who produce statistical analyses but don't
have production engineering backgrounds. They know their domain. They don't
know (and shouldn't need to know) CI/CD, dependency isolation, or test
architecture.

**Secondary: Platform teams** at research institutions who need to integrate
R analyses into larger systems — data pipelines, paper submission workflows,
reproducibility archives.

**Tertiary: The future** — the reviewer who checks the work in 2028, the
student who extends it in 2030, the replication study that depends on it.

### How We Serve

```
Scientist hands us:          We deliver:
─────────────────            ─────────
messy_analysis.R      →      production R package
"it works on my laptop" →    renv.lock + Rocker container
"I tested it"          →     52 automated tests + validation report
README.txt             →     roxygen2 docstrings + methods docs
email attachment       →     GitHub repo with CI green
```

The transformation is the service. The scientist keeps ownership of the
science. We handle the engineering.

### The Handoff Contract

Every artifact we produce meets this contract:

1. **Clone → run → result.** Three commands max.
2. **Test suite proves the claims.** Statistical assertions, not just "no errors."
3. **Validation report is machine-readable.** JSON, committed to repo.
4. **Code reads as a document.** Docstrings, named constants, no magic numbers.
5. **Environment is frozen.** `renv.lock` + `sessionInfo()` fingerprint.
6. **CI enforces quality.** No merge without lint + test + coverage gates.

---

## 4. Developer Workflows

### The Local Development Loop

```
┌──────────────────────────┐
│  1. Write/Edit R function │ ← Pure function, data in / data out
│     in R/                 │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│  2. Write failing test    │ ← Red phase: test-unit-*.R
│     in tests/testthat/    │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│  3. Make it pass          │ ← Green phase: minimal code
│     devtools::test()      │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│  4. Refactor + style      │ ← Refactor phase
│     styler::style_file()  │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│  5. Commit                │ ← Pre-commit hooks run:
│     git commit            │    lintr, styler, parsable-R
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│  6. Push → CI runs        │ ← lint → test → coverage gate
└──────────────────────────┘
```

### File Watcher (Optional)

For interactive development, `testthat::auto_test_package()` monitors `R/`
and `tests/testthat/` and re-runs relevant tests on save. Useful for IDE
workflows but not required — our pipeline is headless-first.

### The Pre-Commit Safety Net

Before code enters version control, pre-commit hooks enforce:

| Hook | What It Catches |
|------|----------------|
| `style-files` | Inconsistent formatting |
| `lintr` | Code quality issues |
| `parsable-R` | Syntax errors |
| `no-browser-statement` | Debug artifacts left in code |

These run locally in <2 seconds. No CI round-trip needed for basic quality.

### Branch Workflow

```
main (protected)
  └── feature/add-spatial-model      ← development happens here
        └── PR → CI runs → review → merge
```

No direct commits to `main`. Every change goes through:
1. Branch
2. CI pipeline (lint + test + coverage)
3. Review
4. Merge

---

## 5. The Forge Transformation

### From Script to Artifact

The typical engagement:

**Step 1: Intake.** Scientist provides their analysis script(s) and data.
We read the code, understand the statistical claims, identify the pure
functions hiding inside the imperative script.

**Step 2: Scaffold.** `foundry_scaffold()` generates the target structure:

```r
foundry_scaffold(
  path = "body-grammar-analysis",
  name = "Body-Grammar Caucasus Analysis",
  use_brms = TRUE
)
```

**Step 3: Decompose.** Extract pure functions from the script:

| Script Pattern | Foundry Pattern |
|---------------|----------------|
| Top-level data loading | `prepare_data()` with contracts |
| Inline transformations | Named pure functions |
| `brm()` call somewhere | `fit_model(data, seed=42)` |
| `summary()` at the end | `extract_results()` returning data frame |
| `source("helpers.R")` | Proper imports via package NAMESPACE |

**Step 4: Test.** Write tests that encode the statistical claims:

- Unit tests for every pure function (Tier 1)
- Parameter recovery test for the model (Tier 2)
- Convergence assertions for MCMC diagnostics (Tier 2)

**Step 5: Validate.** `foundry_validate()` checks the structure is complete:

```r
foundry_validate("body-grammar-analysis", strict = TRUE)
# $valid: TRUE
# $errors: character(0)
# $warnings: character(0)
```

**Step 6: Ship.** Push to GitHub, CI goes green, hand back the repo URL.

### What the Scientist Gets Back

```
✅ GitHub repo with CI badge (green)
✅ run_pipeline.sh — reproduces everything in one command
✅ Validation report (JSON) — machine-readable proof
✅ Session info — full environment fingerprint
✅ Every function documented with roxygen2
✅ renv.lock — exact dependency versions
✅ Tests that encode their statistical claims
```

### What the Scientist Doesn't Need to Learn

- GitHub Actions YAML syntax
- Docker / Rocker configuration
- renv internals
- testthat API
- lintr rules
- How to structure DESCRIPTION files
- CI caching strategies

`foundry_scaffold()` generates all of this. The scientist writes functions
and tests. Everything else is infrastructure.

---

## 6. Quality as DevEx

### Why Quality Gates Are a DevEx Feature

Quality gates are usually framed as "governance" or "compliance." We frame
them as **developer experience**: they catch problems early, when fixing is
cheap, instead of late, when it's expensive.

| Gate | What It Prevents | Cost If Missed |
|------|-----------------|----------------|
| Pre-commit lint | Style inconsistency | Code review friction |
| Unit tests | Logic errors | Debugging in production |
| Coverage gate (80%) | Untested code paths | Silent failures |
| CI on every PR | Integration breakage | "Works on my machine" |
| `renv.lock` | Dependency drift | Irreproducible results |

### The 80% Coverage Threshold

We chose 80% — not 90%, not 100%.

- **100%** is counterproductive for analysis packages (testing boilerplate
  import/export code adds noise, not signal)
- **90%** is aspirational but blocks practical work on new features
- **80%** ensures core logic is tested while allowing reasonable exclusions
  (I/O wrappers, main() orchestrators, generated code)

Coverage is measured by `covr::package_coverage()` and enforced as a CI gate.

### Lint as Documentation

A clean lint report isn't just "style compliance." It's a signal that:
- Naming is consistent (snake_case enforced)
- Lines are readable (120 char limit)
- No debug artifacts in code
- No unused variables hiding logic errors

When a collaborator opens the code for the first time, they see consistent,
idiomatic R. That's a DevEx win.

---

## 7. Toolchain Integration

### The Phosphene R Toolchain

```
┌─────────────────────────────────────────────────────────┐
│ Developer Machine / CI Runner                           │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ R 4.4.0  │  │ renv     │  │ Git +    │             │
│  │ (Rocker  │  │ (project │  │ pre-     │             │
│  │  in CI)  │  │  lockfile)│  │ commit)  │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │              │              │                    │
│  ┌────▼──────────────▼──────────────▼─────┐             │
│  │            Foundry Package              │             │
│  │  • foundry_scaffold()                   │             │
│  │  • validate_contract()                  │             │
│  │  • pure_transform()                     │             │
│  │  • stdd_seed_env()                      │             │
│  │  • stdd_param_recovery()                │             │
│  │  • stdd_convergence_check()             │             │
│  └────────────────┬───────────────────────┘             │
│                   │                                      │
│  ┌────────────────▼───────────────────────┐             │
│  │         GitHub Actions CI               │             │
│  │  lint → test (tiered) → coverage gate   │             │
│  └─────────────────────────────────────────┘             │
│                                                         │
│  ┌─────────────────────────────────────────┐             │
│  │         Posit Package Manager            │             │
│  │  Frozen CRAN snapshots                   │             │
│  │  Pre-compiled Linux binaries             │             │
│  └─────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────┘
```

### IDE Support

The Foundry is IDE-agnostic. It works with:

- **RStudio** — standard R project (`.Rproj` recognized)
- **VS Code + R extension** — terminal-first workflow
- **Headless / CLI** — `Rscript` + `bash`, no GUI required
- **Positron** — Posit's new IDE (RStudio successor)

No IDE-specific configuration is generated. The project structure is
standard enough that any R-aware editor provides full support.

### Integration Points

| System | How It Connects |
|--------|----------------|
| GitHub Actions | `.github/workflows/ci.yml` generated by scaffold |
| Rocker containers | CI runs in `rocker/r-ver:4.4.0` |
| Posit Package Manager | Pre-compiled binaries in CI and local dev |
| renv | Per-project dependency isolation |
| testthat | Test framework (edition 3) |
| covr | Coverage measurement + Cobertura export |
| lintr + styler | Static analysis + formatting |
| pre-commit | Local quality gates before push |
| oysteR | Dependency security auditing |

---

## 8. Metrics That Matter

### DevEx Metrics

| Metric | Target | Why |
|--------|--------|-----|
| Time from idea to first CI-green commit | < 30 minutes | Scaffold + write first function + test + push |
| Time for new collaborator to reproduce | < 5 minutes | Clone + `bash run_pipeline.sh` |
| CI pipeline duration (unit tests) | < 2 minutes | Fast feedback loop |
| CI pipeline duration (full suite) | < 10 minutes | Includes lint + coverage |
| Test failure diagnosis time | < 30 seconds | Clear names, isolated tests, good errors |
| New dependency evaluation | < 10 minutes | CRAN intelligence + audit tools |

### Quality Metrics

| Metric | Threshold | Enforcement |
|--------|-----------|-------------|
| Test coverage | ≥ 80% | CI gate |
| Lint violations | 0 | CI gate |
| R-hat convergence | < 1.05 | STDD assertion |
| Effective sample size | ≥ 400 | STDD assertion |
| Parameter recovery | All in CI | Integration test |

### What We Don't Measure

- Lines of code (irrelevant — clarity over brevity)
- Number of dependencies (managed by renv, not counted)
- Build time for model fits (inherently variable, not a DevEx signal)
- Test count (quality over quantity — one good parameter recovery test
  beats twenty trivial assertions)
