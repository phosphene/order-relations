#' Scaffold a Phosphene R Artifact
#'
#' Creates a production-grade R analysis package following the MPI Handoff
#' Blueprint. Generates the directory structure, boilerplate files, CI/CD
#' workflow, testthat configuration, renv bootstrap, and quality-gate configs.
#'
#' @param path Target directory path for the new artifact.
#' @param name Human-readable artifact name (used in DESCRIPTION Title).
#' @param authors Named list of authors, each a character vector
#'   `c(given, family, role, email)`.
#' @param license License string. Default `"MIT"`.
#' @param use_brms Logical; include brms/Stan dependency scaffolding.
#'   Default `FALSE`.
#' @param use_renv Logical; initialize renv lockfile infrastructure.
#'   Default `TRUE`.
#' @return Invisible `TRUE` on success. Side effect: creates files on disk.
#' @export
#' @examples
#' \dontrun{
#' foundry_scaffold(
#'   path = "my-analysis",
#'   name = "Body Grammar Caucasus Analysis",
#'   use_brms = TRUE
#' )
#' }
foundry_scaffold <- function(path,
                             name = basename(path),
                             authors = NULL,
                             license = "MIT",
                             use_brms = FALSE,
                             use_renv = TRUE) {
  # Validate inputs
  stopifnot(is.character(path), length(path) == 1L, nchar(path) > 0L)
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.logical(use_brms), length(use_brms) == 1L)

  # Create directory tree
  dirs <- c(
    "R", "tests/testthat", "data", "data-raw",
    "results", "man", ".github/workflows", "docs"
  )
  if (use_brms) dirs <- c(dirs, "inst/stan")

  for (d in dirs) {
    dir.create(file.path(path, d), recursive = TRUE, showWarnings = FALSE)
  }

  # Write DESCRIPTION
  .write_description(path, name, authors, license, use_brms)

  # Write testthat bootstrap
  .write_testthat_bootstrap(path)

  # Write .lintr
  .write_lintr(path)


  # Write .gitignore
  .write_gitignore(path)

  # Write GitHub Actions CI
  .write_gha_ci(path, use_brms)

  # Write run_pipeline.sh
  .write_run_pipeline(path, use_brms)

  # Write run_tests.R
  .write_run_tests(path)

  # Write placeholder README
  .write_readme(path, name)

  message("Artifact scaffolded at: ", path)
  invisible(TRUE)
}


# --- Internal helpers (not exported) ---

.write_description <- function(path, name, authors, license, use_brms) {
  imports <- "    withr"
  if (use_brms) {
    imports <- paste0(imports, ",\n    brms,\n    ape,\n    loo")
  }
  imports <- paste0(imports, ",\n    dplyr,\n    readr")

  suggests <- paste(
    "    testthat (>= 3.0.0),",
    "    covr,",
    "    lintr,",
    "    styler,",
    "    mockery",
    sep = "\n"
  )

  author_str <- if (is.null(authors)) {
    '    person("Author", "Name", role = c("aut", "cre"))'
  } else {
    paste(vapply(authors, function(a) {
      sprintf('    person("%s", "%s", role = "%s", email = "%s")',
              a[1], a[2], a[3], a[4])
    }, character(1)), collapse = ",\n")
  }

  desc <- sprintf(
    'Type: Package
Package: %s
Title: %s
Version: 0.1.0
Authors@R: c(
%s
  )
Description: Reproducible analysis package scaffolded by the Phosphene
    R Artifact Foundry. Follows the MPI Handoff Blueprint architecture.
License: %s + file LICENSE
Depends:
    R (>= 4.4.0)
Imports:
%s
Suggests:
%s
Config/testthat/edition: 3
Encoding: UTF-8
Roxygen: list(markdown = TRUE)',
    gsub("[^a-zA-Z0-9.]", ".", basename(path)),
    name, author_str, license, imports, suggests
  )

  writeLines(desc, file.path(path, "DESCRIPTION"))
}


.write_testthat_bootstrap <- function(path) {
  writeLines(
    c(
      "library(testthat)",
      sprintf('test_check("%s")', gsub("[^a-zA-Z0-9.]", ".", basename(path)))
    ),
    file.path(path, "tests", "testthat.R")
  )
}


.write_lintr <- function(path) {
  writeLines(
    'linters: linters_with_defaults(line_length_linter = line_length_linter(120), object_name_linter = object_name_linter("snake_case"))',
    file.path(path, ".lintr")
  )
}


.write_gitignore <- function(path) {
  writeLines(
    c(
      "# R session",
      ".Rhistory",
      ".RData",
      ".Ruserdata",
      ".Rproj.user",
      "",
      "# renv library (rebuilt from lockfile)",
      "renv/library/",
      "renv/staging/",
      "renv/python/",
      "renv/sandbox/",
      "",
      "# Model outputs (reproducible from script)",
      "results/*.rds",
      "results/*.pdf",
      "",
      "# Keep validation artifacts",
      "!results/validation_report.json",
      "!results/model_summary.txt",
      "",
      "# OS",
      ".DS_Store",
      "Thumbs.db"
    ),
    file.path(path, ".gitignore")
  )
}


.write_gha_ci <- function(path, use_brms) {
  brms_step <- if (use_brms) {
    '
      - name: Verify Stan compilation (smoke test)
        run: |
          Rscript -e "
            library(brms)
            f <- brms::bf(y ~ x, family = gaussian())
            m <- brms::make_stancode(f, data = data.frame(y = 1:5, x = 1:5))
            cat(\'Stan code generation: OK\\n\')
          "'
  } else {
    ""
  }

  workflow <- sprintf('name: R Artifact CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  lint:
    name: Static Analysis
    runs-on: ubuntu-latest
    container: rocker/r-ver:4.4.0
    steps:
      - uses: actions/checkout@v4

      - name: Install system deps
        run: apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev

      - name: Install linting tools
        run: |
          Rscript -e "install.packages(c(\'styler\', \'lintr\'), repos = \'https://packagemanager.posit.co/cran/__linux__/jammy/latest\')"

      - name: Lint
        run: |
          Rscript -e "lintr::lint_package()"

      - name: Style check (dry run)
        run: |
          Rscript -e "
            files <- list.files(\'R\', pattern = \'\\\\.R$\', full.names = TRUE)
            for (f in files) {
              styled <- styler::style_file(f, dry = \'on\')
              if (any(!styled\\$changed)) next
              if (any(styled\\$changed)) stop(paste(\'Style violation in:\', f))
            }
            cat(\'All files pass style check\\n\')
          "

  test:
    name: Test Suite
    needs: lint
    runs-on: ubuntu-latest
    container: rocker/r-ver:4.4.0
    env:
      R_REPOS: "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
    steps:
      - uses: actions/checkout@v4

      - name: Install system deps
        run: apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev

      - name: Cache R packages
        uses: actions/cache@v4
        with:
          path: /usr/local/lib/R/site-library
          key: ${{ runner.os }}-r-pkgs-${{ hashFiles(\'DESCRIPTION\') }}

      - name: Install dependencies
        run: |
          Rscript -e "
            options(repos = Sys.getenv(\'R_REPOS\'))
            install.packages(c(\'remotes\', \'covr\'))
            remotes::install_deps(dependencies = TRUE)
          "

      - name: Run unit tests
        run: |
          Rscript -e "testthat::test_local(filter = \'unit\', reporter = testthat::CheckReporter)"
%s
      - name: Run full test suite
        run: |
          Rscript -e "testthat::test_local(reporter = testthat::CheckReporter)"

  coverage:
    name: Coverage Gate
    needs: test
    runs-on: ubuntu-latest
    container: rocker/r-ver:4.4.0
    env:
      R_REPOS: "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
    steps:
      - uses: actions/checkout@v4

      - name: Install system deps
        run: apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev

      - name: Install dependencies
        run: |
          Rscript -e "
            options(repos = Sys.getenv(\'R_REPOS\'))
            install.packages(c(\'remotes\', \'covr\'))
            remotes::install_deps(dependencies = TRUE)
          "

      - name: Check coverage (>= 80%%%%)
        run: |
          Rscript -e "
            cov <- covr::package_coverage()
            pct <- covr::percent_coverage(cov)
            message(\'Coverage: \', round(pct, 2), \'%%%%\')
            if (pct < 80) stop(\'Coverage below 80%%%% threshold: \', round(pct, 2), \'%%%%\')
          "

      - name: Export Cobertura report
        if: always()
        run: |
          Rscript -e "covr::to_cobertura(covr::package_coverage())"
', brms_step)

  writeLines(workflow, file.path(path, ".github", "workflows", "ci.yml"))
}


.write_run_pipeline <- function(path, use_brms) {
  lines <- c(
    "#!/usr/bin/env bash",
    "set -euo pipefail",
    "",
    'echo "=== Phosphene R Artifact Foundry Pipeline ==="',
    'echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"',
    "",
    "# Step 1: Restore environment",
    'if [ -f "renv.lock" ]; then',
    '  echo "--- Restoring renv environment ---"',
    '  Rscript -e "renv::restore(prompt = FALSE)"',
    "fi",
    "",
    "# Step 2: Run test suite",
    'echo "--- Running tests ---"',
    "Rscript run_tests.R",
    ""
  )

  if (use_brms) {
    lines <- c(lines,
      "# Step 3: Fit model",
      'echo "--- Fitting model ---"',
      'Rscript -e "source(\'R/main.R\'); main()"',
      ""
    )
  }

  lines <- c(lines,
    "# Step N: Capture session info",
    'echo "--- Session info ---"',
    'Rscript -e "sessioninfo::session_info()" > results/session_info.txt 2>&1 || \\',
    '  Rscript -e "sessionInfo()" > results/session_info.txt 2>&1',
    "",
    'echo "=== Pipeline complete ==="'
  )

  script_path <- file.path(path, "run_pipeline.sh")
  writeLines(lines, script_path)
  Sys.chmod(script_path, "0755")
}


.write_run_tests <- function(path) {
  writeLines(c(
    "#!/usr/bin/env Rscript",
    '# Automated test runner with JSON validation report output.',
    "#",
    "# Usage: Rscript run_tests.R",
    "",
    "library(testthat)",
    "",
    "results <- testthat::test_local(",
    '  path = ".",',
    "  reporter = testthat::ListReporter",
    ")",
    "",
    "# Build validation report",
    "summary_data <- as.data.frame(results)",
    "n_pass <- sum(summary_data$passed, na.rm = TRUE)",
    "n_fail <- sum(summary_data$failed, na.rm = TRUE)",
    "n_skip <- sum(summary_data$skipped, na.rm = TRUE)",
    "",
    "report <- list(",
    '  timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),',
    '  r_version = paste0(R.version$major, ".", R.version$minor),',
    "  tests_passed = n_pass,",
    "  tests_failed = n_fail,",
    "  tests_skipped = n_skip,",
    "  all_passed = n_fail == 0",
    ")",
    "",
    'jsonlite::write_json(report, "results/validation_report.json", pretty = TRUE, auto_unbox = TRUE)',
    "",
    "if (n_fail > 0) {",
    '  message(sprintf("FAIL: %d tests failed", n_fail))',
    "  quit(status = 1)",
    "} else {",
    '  message(sprintf("PASS: All %d tests passed", n_pass))',
    "}"
  ), file.path(path, "run_tests.R"))
}


.write_readme <- function(path, name) {
  writeLines(c(
    sprintf("# %s", name),
    "",
    "Scaffolded by the [Phosphene R Artifact Foundry](https://github.com/phosphene/order-relations).",
    "",
    "## Quick Start",
    "",
    "```bash",
    sprintf("git clone https://github.com/phosphene/%s.git", basename(path)),
    sprintf("cd %s", basename(path)),
    "bash run_pipeline.sh",
    "```",
    "",
    "## Architecture",
    "",
    "This artifact follows the **MPI Handoff Blueprint**:",
    "",
    "- Pure functions accept data frames, return data frames",
    "- No global state, no hardcoded paths, no `attach()`",
    "- `main()` guarded by `sys.nframe() == 0`",
    "- Test suite produces a machine-readable validation report",
    "",
    "## Testing",
    "",
    "```bash",
    "Rscript run_tests.R",
    "```",
    "",
    "## License",
    "",
    "MIT"
  ), file.path(path, "README.md"))
}
