# MPI Handoff Blueprint

Architecture specification for production-grade R scientific analysis packages.

## Core Contract

Every R artifact follows three rules:

1. **Pure functions**: accept data frames, return data frames. No side effects.
2. **Contract enforcement**: validate inputs at entry, outputs at exit.
3. **Guarded main**: `main()` only runs under `Rscript`, never under `source()`.

## Three Pillars

### Pillar A: Data Munging (Pure)

```r
prepare_analysis_data <- function(grambank_df, source_typed_df) {
  # Input contract
  validate_contract(grambank_df, required_cols = c("Language_ID", "Latitude"))
  validate_contract(source_typed_df, required_cols = c("lang_id", "source_type"))

  # Transform (pure — no I/O, no global state)
  result <- grambank_df %>%
    left_join(source_typed_df, by = c("Language_ID" = "lang_id")) %>%
    mutate(bpdr = as.integer(source_type == "HEAD"))

  # Output contract
  validate_contract(result, required_cols = c("Language_ID", "bpdr"))
  result
}
```

### Pillar B: Model Fitting (Seed-Locked)

```r
fit_bayesian_model <- function(analysis_df, seed = 42L, chains = 4L, cores = 4L) {
  validate_contract(analysis_df, required_cols = c("bpdr", "caucasus", "Family"))

  brms::brm(
    bpdr ~ caucasus + (1 | Family),
    data = analysis_df,
    family = bernoulli(),
    seed = seed,
    chains = chains,
    cores = cores,
    iter = 2000
  )
}
```

### Pillar C: Result Extraction (Pure)

```r
extract_results <- function(model_fit) {
  summary_df <- as.data.frame(brms::fixef(model_fit))
  # Return structured data, not printed output
  summary_df
}
```

## Guard Pattern

```r
main <- function() {
  # Load data (impure — isolated here)
  data <- read_csv("data/input.csv")

  # Transform (pure)
  analysis <- prepare_analysis_data(data)

  # Fit (seed-locked)
  model <- fit_bayesian_model(analysis)

  # Extract (pure)
  results <- extract_results(model)

  # Write (impure — isolated here)
  write_csv(results, "results/model_summary.csv")
}

# Only run when called via Rscript, not source()
if (sys.nframe() == 0) {
  main()
}
```

## Testing Strategy

See `docs/STDD_SPEC.md` for the Stochastic TDD framework.
