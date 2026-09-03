# Behavior-Driven Development (BDD) in R

BDD bridges the gap between technical implementation, mathematical behavior,
and user-facing requirements. In the R ecosystem, BDD is practiced using
two paradigms:

1. **Internal DSL** (developer-focused): `describe()` / `it()` blocks in
   testthat
2. **External Gherkin** (stakeholder-focused): `.feature` files executed
   via the `cucumber` package

## Table of Contents

1. [When to Use Which](#1-when-to-use-which)
2. [Paradigm 1: Native Developer BDD](#2-paradigm-1-native-developer-bdd)
3. [Paradigm 2: Gherkin Acceptance Specs](#3-paradigm-2-gherkin-acceptance-specs)
4. [Integration with the Foundry](#4-integration-with-the-foundry)
5. [Production Rules](#5-production-rules)

---

## 1. When to Use Which

| | Unit TDD (`test_that()`) | Internal BDD (`describe()`) | Gherkin BDD (`cucumber`) |
|---|---|---|---|
| **Audience** | Developers, engineers | Developers, senior architects | Product owners, analysts, regulators |
| **Test level** | Low-level unit (pure algorithms, helpers) | Medium-level integration (class behaviors, edge cases) | High-level system / feature acceptance |
| **Setup cost** | Extremely low | Low | Medium (feature/step mapping) |
| **Best for** | Math formulas, data munging, matrix wrappers | Multi-method S3 classes, nested validation logic | Complex business pipelines, full data processing workflows |

### The Foundry Default

Foundry artifacts use `test_that()` for Tier 1 unit tests and `describe()`
blocks for Tier 2 integration tests that map to statistical specifications.

Gherkin (cucumber) is reserved for:
- End-to-end pipeline specifications shared with non-technical stakeholders
- Clinical/regulatory workflows where requirements are externally defined
- Handoff documentation where the feature file IS the acceptance contract

---

## 2. Paradigm 1: Native Developer BDD

### describe() + it() in testthat

`describe()` and `it()` are built into testthat. No extra dependencies.
They compose into readable specifications:

```r
# tests/testthat/test-bdd-posterior-sampler.R

describe("Normal Distribution PDF Evaluator", {

  describe("Handling standard conditions", {
    it("evaluates the density of a standard normal at x = 0", {
      result <- evaluate_normal_pdf(0, mean = 0, sd = 1)
      expect_equal(result, 0.3989423, tolerance = 1e-6)
    })

    it("is symmetrical around the specified mean", {
      left_tail  <- evaluate_normal_pdf(-1.96, mean = 0, sd = 1)
      right_tail <- evaluate_normal_pdf(1.96, mean = 0, sd = 1)
      expect_equal(left_tail, right_tail, tolerance = 1e-7)
    })
  })

  describe("Handling boundary and error conditions", {
    it("throws an error when standard deviation is zero", {
      expect_error(
        evaluate_normal_pdf(0, mean = 0, sd = 0),
        regexp = "strictly positive"
      )
    })

    it("throws an error when standard deviation is negative", {
      expect_error(
        evaluate_normal_pdf(0, mean = 0, sd = -5),
        regexp = "strictly positive"
      )
    })
  })
})
```

### Mapping Statistical Specifications

When translating a paper's methods section into tests, `describe()` blocks
map naturally to statistical claims:

```r
describe("Body-Grammar Caucasus Model", {

  describe("Data preparation contract", {
    it("produces a binary bpdr predictor from source typing", {
      result <- prepare_analysis_data(mock_grambank, mock_source_typed)
      expect_true(all(result$bpdr %in% c(0L, 1L)))
    })

    it("codes Caucasus membership from geographic bounds", {
      result <- prepare_analysis_data(mock_grambank, mock_source_typed)
      # Lat 39-44, Lon 38-50
      caucasus_rows <- result[result$caucasus == 1L, ]
      expect_true(all(caucasus_rows$lat_c >= -2))  # centered
    })
  })

  describe("Model convergence", {
    it("achieves R-hat < 1.05 on all parameters", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      rhat_vals <- brms::rhat(fitted_model)
      expect_true(all(rhat_vals < 1.05))
    })

    it("achieves ESS > 400 on all parameters", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      ess_vals <- brms::neff_ratio(fitted_model) * 8000
      expect_true(all(ess_vals > 400))
    })
  })

  describe("Posterior inference", {
    it("estimates Caucasus OR > 1 (enrichment signal)", {
      skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")
      or_est <- exp(brms::fixef(fitted_model)["caucasus", "Estimate"])
      expect_gt(or_est, 1.0)
    })
  })
})
```

This is **the paper's methods section as executable code**. Each `it()` block
is a statistical claim that the test suite proves.

---

## 3. Paradigm 2: Gherkin Acceptance Specs

### When to Use Gherkin

Use Gherkin when:
- Stakeholders need to read and approve test specifications
- Requirements are externally defined (regulatory, clinical)
- The feature file serves as a handoff acceptance contract
- End-to-end pipelines cross multiple system boundaries

### The cucumber Package

`cucumber` is on CRAN. It parses `.feature` files and maps
Given/When/Then steps to R functions.

### Feature File

```gherkin
# inst/features/bayesian_update.feature

Feature: Bayesian Parameter Estimation
  As an analyst
  I want a sampler to ingest data and update prior beliefs
  So that I can make decisions based on posterior parameters

  Scenario: Conjugate Beta-Binomial Update
    Given a Binomial likelihood and a Beta(2, 2) prior
    When the sampler observes 8 successes and 2 failures
    Then the calculated posterior should have a mean parameter of 0.714
    And the posterior variance should be approximately 0.014
```

This file can be shared directly with researchers, stakeholders, or
quality assurance teams. No R knowledge required to read it.

### Step Definitions

```r
# tests/testthat/step-definitions/steps.R

library(cucumber)
library(testthat)

# Shared state environment
world <- new.env()

# Given: Set up initial prior parameters
given("a Binomial likelihood and a Beta\\({int}, {int}\\) prior",
  function(alpha, beta) {
    world$alpha_prior <- alpha
    world$beta_prior  <- beta
  }
)

# When: Ingest observed experiment data
when("the sampler observes {int} successes and {int} failures",
  function(successes, failures) {
    world$results <- calculate_beta_binomial_posterior(
      alpha_prior = world$alpha_prior,
      beta_prior  = world$beta_prior,
      successes   = successes,
      failures    = failures
    )
  }
)

# Then: Assert the mathematical expectation
then("the calculated posterior should have a mean parameter of {double}",
  function(expected_mean) {
    expect_equal(world$results$mean, expected_mean, tolerance = 1e-3)
  }
)

# And: Assert secondary metrics
then("the posterior variance should be approximately {double}",
  function(expected_variance) {
    expect_equal(world$results$variance, expected_variance, tolerance = 1e-3)
  }
)
```

### Runner Integration

Wire cucumber into the standard testthat suite:

```r
# tests/testthat/test-cucumber.R

test_that("Run all Gherkin acceptance specifications", {
  cucumber::run()
})
```

This runs automatically during `devtools::test()`, `R CMD check`, and CI.

### Directory Structure

```
artifact/
├── inst/
│   └── features/                    # Gherkin feature files
│       ├── bayesian_update.feature
│       └── data_pipeline.feature
├── tests/
│   └── testthat/
│       ├── step-definitions/        # Step mapping code
│       │   └── steps.R
│       ├── test-cucumber.R          # Runner
│       ├── test-unit-*.R            # Standard unit tests
│       └── test-bdd-*.R             # describe/it BDD tests
```

---

## 4. Integration with the Foundry

### Testing Pyramid with BDD

The Foundry testing pyramid expands to include BDD layers:

```
                  / \
                 /   \     Gherkin Acceptance (cucumber)
                /     \    Stakeholder-readable feature files
               /-------\
              /         \  BDD Integration (describe/it)
             /           \ Statistical specs as executable code
            /-------------\
           /               \ Unit Tests (test_that)
          /                 \ Pure math, contracts, mocked side-effects
         └───────────────────┘
```

| Layer | File Pattern | Framework | Audience |
|-------|-------------|-----------|----------|
| Unit | `test-unit-*.R` | `test_that()` | Developers |
| BDD Integration | `test-bdd-*.R` | `describe()` / `it()` | Developers + senior researchers |
| Gherkin Acceptance | `test-cucumber.R` + `.feature` files | `cucumber` | Stakeholders + regulators |

### Scaffolding Support

When scaffolding with `foundry_scaffold()`, BDD support is included by
default — `describe()` / `it()` is built into testthat, no extra deps.

For Gherkin (cucumber), add it as a Suggests dependency:

```r
# In DESCRIPTION
Suggests:
    testthat (>= 3.0.0),
    cucumber,
    covr
```

---

## 5. Production Rules

### Rule 1: Never Use Gherkin for Unit Calculations

Do not write feature files for individual math operations. It creates
massive parsing overhead and makes tests fragile.

```gherkin
# WRONG — this is a unit test, not a feature
Scenario: Add two numbers
  Given a value of 2
  And another value of 3
  Then the sum should be 5
```

```r
# RIGHT — just use test_that
test_that("addition works", {
  expect_equal(2 + 3, 5)
})
```

### Rule 2: Use describe() to Map Statistical Specifications

When translating a paper's statistical requirements, write them as
`describe` / `it` blocks first. This ensures code self-documents its
scientific intents:

```r
describe("Posterior sampler", {
  it("recovers parameter theta within 95% credible interval", {
    # ...
  })
})
```

### Rule 3: Use cucumber for End-to-End Pipelines

When a data processing script or analysis engine moves into production,
write the high-level business rules as Gherkin scenarios to align the
development team with stakeholders:

```gherkin
Feature: Grambank Analysis Pipeline
  As a research collaborator
  I want to run the full analysis from raw data to results
  So that I can verify the statistical claims independently

  Scenario: Full pipeline produces validation report
    Given the Grambank languages CSV in data/
    And the source-typed reflexives CSV in data/
    When I run the analysis pipeline
    Then results/validation_report.json should exist
    And all tests should pass
    And the Caucasus odds ratio should exceed 1.0
```

### Rule 4: BDD Blocks Are Living Documentation

`describe()` block names should read as section headings in a methods paper.
`it()` block names should read as testable claims. Together, the test file
IS the specification:

```r
describe("Body-Part Reflexive Distribution", {
  describe("Geographic enrichment", {
    it("shows HEAD→SELF enrichment in the Caucasus region")
    it("controls for phylogenetic non-independence via random intercepts")
    it("reports odds ratio with 95% credible interval")
  })
  describe("Robustness checks", {
    it("maintains signal under leave-one-family-out cross-validation")
    it("converges with R-hat < 1.05 across all parameters")
  })
})
```

A reviewer reading this test file understands the claims without reading
the implementation. That's the power of BDD in scientific R.
