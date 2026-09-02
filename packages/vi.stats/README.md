# vi.stats — Vestigial Information Statistical Methods

Statistical methods for testing VI predictions about integration-depth-ordered transcriptomic commitment.

## What is this?

R package providing the Capacity Depletion Index (CDI), gene-category integration-depth ranking, paired and group statistical tests, sensitivity analyses, and natural-experiment responder/non-responder designs. Scaffolded by the [Phosphene R Artifact Foundry](https://github.com/phosphene/order-relations), following the MPI Handoff Blueprint.

## Quick Start

```bash
cd packages/vi.stats
Rscript -e "remotes::install_deps(dependencies = TRUE)"
Rscript -e "testthat::test_local()"
```

## Functions

| Function | Description |
|----------|-------------|
| `compute_cdi(counts)` | Capacity Depletion Index (negative Shannon entropy) per sample |
| `integration_depth_rank(gene_ids)` | Classify genes into 5 integration-depth categories |
| `paired_cdi_test(cdi, metadata)` | Paired Wilcoxon signed-rank test for CDI differences |
| `gene_category_spearman(fc, ranks)` | Spearman ρ between depth rank and fold-change + permutation p |
| `sensitivity_analysis(counts, exclude_genes)` | Recompute CDI excluding a gene set (drug/metabolic) |
| `responder_split_test(cdi, metadata)` | Natural-experiment delta-CDI comparison |
| `VINCRISTINE_TARGETS` | Predefined cell-cycle gene exclusion set |
| `METABOLIC_GENES` | Predefined metabolic gene exclusion set |

## Architecture

- **MPI Handoff Blueprint**: pure functions, contract validation, no global state
- **Testing**: testthat edition 3, two-tier (unit + integration)
- **Quality gates**: lintr (120 char, snake_case), 80% coverage, styler
- **Deterministic**: all stochastic operations under explicit seed via `withr::with_seed()`

## Data Provenance

No data bundled. Analysis scripts that use this package must document data sources in `data/README.md`.

## License

MIT
