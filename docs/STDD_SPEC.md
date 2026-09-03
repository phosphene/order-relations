# Stochastic Test-Driven Development (STDD) Specification

## Problem

Standard TDD relies on deterministic assertions: `expect_equal(f(x), y)`.
This fails for probabilistic systems (MCMC, Bayesian inference, bootstrap)
where outputs are inherently stochastic.

## Solution: Decouple Math from Simulation

Break algorithms into:
- **Deterministic functions**: log-likelihoods, prior evaluations, matrix
  transforms. Tested with exact assertions.
- **Stochastic transitions**: sampling draws, proposal steps. Tested under
  controlled seeds with structural + statistical assertions.

## Seed Discipline

```r
# ALWAYS: withr for localized, auto-teardown seeds
test_that("sampler produces expected structure", {
  withr::with_seed(1234, {
    result <- my_sampler(data, n_iter = 100)
    expect_type(result, "double")
    expect_length(result, 100)
  })
})

# Or use the Foundry wrapper
stdd_seed_env(1234, {
  result <- my_sampler(data, n_iter = 100)
})
```

### Cross-Platform Reproducibility

Specify RNG kind explicitly:
```r
stdd_seed_env(42, code, .rng_kind = "Mersenne-Twister", .rng_normal_kind = "Inversion")
```

The `"Inversion"` normal method is deterministic across platforms. The default
`"Kinderman-Ramage"` can differ between R versions.

## Statistical Assertions

### 1. Parameter Recovery

Generate data from known θ*, fit model, check θ̂ falls in credible interval:

```r
test_that("model recovers known parameters", {
  result <- stdd_param_recovery(
    true_params = c(intercept = 2.0, slope = 0.5),
    generate_fn = function(params) {
      x <- rnorm(500)
      y <- params["intercept"] + params["slope"] * x + rnorm(500, sd = 0.3)
      data.frame(x = x, y = y)
    },
    fit_fn = function(data) lm(y ~ x, data = data),
    extract_fn = function(fit) {
      ci <- confint(fit, level = 0.95)
      data.frame(
        parameter = c("intercept", "slope"),
        mean = coef(fit),
        lower = ci[, 1],
        upper = ci[, 2]
      )
    }
  )
  expect_true(result$all_recovered)
})
```

### 2. Distributional Verification

For conjugate models, compare empirical draws to analytical posterior:

```r
test_that("conjugate sampler matches analytical posterior", {
  withr::with_seed(42, {
    draws <- my_conjugate_sampler(data, n = 10000)
    ks_result <- ks.test(draws, "pnorm", mean = known_mean, sd = known_sd)
    expect_gt(ks_result$p.value, 0.05)
  })
})
```

### 3. Convergence Assertions

```r
test_that("MCMC chains converge", {
  check <- stdd_convergence_check(
    rhat_values = extract_rhat(fit),
    ess_values = extract_ess(fit),
    rhat_threshold = 1.05,
    ess_threshold = 400
  )
  expect_true(check$all_converged)
})
```

## Two-Tiered Testing Strategy

### Tier 1: Unit Tests (Local, Fast)

- File pattern: `test-unit-*.R`
- Data: toy datasets (n ≈ 50)
- Model iterations: 5 warmup, 10 sampling (compilation check only)
- Runtime: <1 second per test
- When: every commit, local dev

```r
test_that("brms model compiles", {
  withr::with_seed(42, {
    fit <- brms::brm(
      y ~ x, data = data.frame(y = rnorm(20), x = rnorm(20)),
      family = gaussian(),
      sample_prior = "only", iter = 2, chains = 1,
      silent = 2, refresh = 0
    )
    expect_s3_class(fit, "brmsfit")
  })
})
```

### Tier 2: Integration Tests (CI, Nightly)

- File pattern: `test-integration-*.R`
- Data: realistic-scale datasets
- Model iterations: full chains (2000+ iterations, 4 chains)
- Runtime: minutes
- When: CI pipeline, nightly builds

```r
test_that("full model recovers parameters on simulated data", {
  skip_on_cran()
  skip_if_not(Sys.getenv("RUN_INTEGRATION") == "true")

  result <- stdd_param_recovery(
    true_params = c(intercept = 2.0, slope = 0.5, sigma = 0.3),
    generate_fn = generate_synthetic_brms_data,
    fit_fn = fit_full_brms_model,
    extract_fn = extract_brms_summary,
    seed = 42
  )
  expect_true(result$all_recovered)
})
```

## Anti-Patterns

| Don't | Do |
|-------|-----|
| `set.seed()` at script top | `withr::with_seed()` per test block |
| `expect_equal(mcmc_draw, 1.234)` | `expect_gt(ks_result$p.value, 0.05)` |
| Skip stochastic tests | Two-tier: fast unit + slow integration |
| Test model fit in unit tests | Test compilation only; fit in integration |
| Unseeded randomness | Every stochastic call under explicit seed |
