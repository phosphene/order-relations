# Getting Started

How to use the R Artifact Foundry to create production-grade scientific
R packages.

## Prerequisites

- R >= 4.4.0
- Git
- GitHub account with Actions enabled

## Installation

```r
# From GitHub
remotes::install_github("phosphene/order-relations")
```

## Your First Artifact

### 1. Scaffold

```r
library(phosphene.foundry)

foundry_scaffold(
  path = "my-analysis",
  name = "My Research Analysis",
  authors = list(
    c("Jane", "Doe", "aut", "jane@university.edu"),
    c("John", "Smith", "cre", "john@university.edu")
  ),
  use_brms = TRUE   # include Bayesian modeling scaffolding
)
```

This creates:

```
my-analysis/
├── DESCRIPTION
├── R/                          # Put your functions here
├── tests/testthat/             # Put your tests here
├── data/                       # Put your input data here
├── results/                    # Pipeline outputs go here
├── .github/workflows/ci.yml   # CI runs automatically
├── .lintr                      # Linting config
├── run_pipeline.sh             # Single-command reproduction
├── run_tests.R                 # Test runner + report
└── README.md                   # Customize this
```

### 2. Add Your Analysis Code

Create a pure functional analysis script in `R/`:

```r
# R/analysis.R

#' Prepare analysis data
#'
#' @param raw_df Raw input data frame.
#' @return Clean data frame ready for modeling.
#' @export
prepare_data <- function(raw_df) {
  validate_contract(raw_df, required_cols = c("id", "x", "y"))

  result <- raw_df |>
    dplyr::filter(!is.na(x), !is.na(y)) |>
    dplyr::mutate(x_centered = scale(x)[, 1])

  validate_contract(result, required_cols = c("id", "x_centered", "y"))
  result
}


#' Fit the Bayesian model
#'
#' @param data Prepared data frame from [prepare_data()].
#' @param seed Random seed for reproducibility.
#' @return A brmsfit object.
#' @export
fit_model <- function(data, seed = 42L) {
  validate_contract(data, required_cols = c("x_centered", "y"))

  brms::brm(
    y ~ x_centered,
    data = data,
    family = gaussian(),
    seed = seed,
    chains = 4,
    cores = 4,
    iter = 2000
  )
}


#' Run the full analysis pipeline
#'
#' @export
main <- function() {
  raw <- readr::read_csv("data/input.csv")
  clean <- prepare_data(raw)
  model <- fit_model(clean)

  results <- as.data.frame(brms::fixef(model))
  readr::write_csv(results, "results/model_summary.csv")
  message("Pipeline complete.")
}

if (sys.nframe() == 0) main()
```

### 3. Add Tests

```r
# tests/testthat/test-unit-analysis.R

test_that("prepare_data validates input contract", {
  bad_df <- data.frame(wrong = 1:5)
  expect_error(prepare_data(bad_df), "Missing required columns")
})

test_that("prepare_data produces expected output", {
  input <- data.frame(id = 1:10, x = rnorm(10), y = rnorm(10))
  result <- prepare_data(input)

  expect_true("x_centered" %in% names(result))
  expect_equal(mean(result$x_centered), 0, tolerance = 1e-10)
})

test_that("fit_model compiles Stan code", {
  skip_if_not_installed("brms")

  data <- data.frame(x_centered = rnorm(20), y = rnorm(20))
  fit <- brms::brm(
    y ~ x_centered,
    data = data,
    family = gaussian(),
    sample_prior = "only",
    iter = 2,
    chains = 1,
    silent = 2,
    refresh = 0,
    seed = 42
  )
  expect_s3_class(fit, "brmsfit")
})
```

### 4. Validate Your Artifact

```r
foundry_validate("my-analysis", strict = TRUE)
```

### 5. Initialize Git and Push

```bash
cd my-analysis
git init
git add -A
git commit -m "feat: initial analysis scaffold"
git remote add origin https://github.com/yourname/my-analysis.git
git push -u origin main
```

CI runs automatically on push — lint, test, coverage.

### 6. Initialize renv (For Collaborators)

```r
renv::init()
renv::snapshot()
git add renv.lock renv/activate.R renv/settings.json .Rprofile
git commit -m "chore: add renv lockfile"
git push
```

Now anyone can reproduce your environment:

```bash
git clone https://github.com/yourname/my-analysis.git
cd my-analysis
bash run_pipeline.sh   # restores renv, runs tests, fits model
```

## Using Contracts

### Input Validation

```r
# Check columns exist
validate_contract(df, required_cols = c("id", "value"))

# Check column types
validate_contract(df,
  required_cols = c("id", "value"),
  col_types = list(id = "character", value = "double")
)

# Reject NAs
validate_contract(df,
  required_cols = c("id", "value"),
  allow_na = FALSE
)
```

### Pure Transforms

```r
# Wrap a transform with automatic contract enforcement
result <- pure_transform(
  df,
  transform_fn = function(d) {
    d$log_value <- log(d$value)
    d
  },
  input_cols = "value",
  output_cols = c("value", "log_value")
)
```

## Using STDD

### Seed Isolation in Tests

```r
test_that("stochastic operation is reproducible", {
  r1 <- stdd_seed_env(42, rnorm(100))
  r2 <- stdd_seed_env(42, rnorm(100))
  expect_identical(r1, r2)
})
```

### Parameter Recovery

```r
test_that("model recovers known parameters", {
  result <- stdd_param_recovery(
    true_params = c(intercept = 3.0, slope = -0.5),
    generate_fn = function(p) {
      x <- rnorm(300)
      y <- p["intercept"] + p["slope"] * x + rnorm(300, sd = 0.4)
      data.frame(x = x, y = y)
    },
    fit_fn = function(d) lm(y ~ x, data = d),
    extract_fn = function(fit) {
      ci <- confint(fit)
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

### Convergence Checks

```r
# After a brms fit
rhat_vals <- brms::rhat(fit)
ess_vals <- brms::neff_ratio(fit) * 4000  # total draws

check <- stdd_convergence_check(
  rhat_values = rhat_vals,
  ess_values = ess_vals,
  param_names = names(rhat_vals)
)
stopifnot(check$all_converged)
```

## Next Steps

- Read [PHOSPHENE_R_STANDARDS.md](PHOSPHENE_R_STANDARDS.md) for the full
  engineering specification
- Read [STDD_SPEC.md](STDD_SPEC.md) for the stochastic testing framework
- Read [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for CI pipeline details
- Read [DEPENDENCY_STRATEGY.md](DEPENDENCY_STRATEGY.md) for package selection
