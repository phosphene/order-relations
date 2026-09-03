#!/usr/bin/env bash
set -euo pipefail

echo "=== Beta-Binomial Demo Pipeline ==="
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "--- Running tests ---"
Rscript run_tests.R

echo "--- Running analysis ---"
Rscript R/main.R

echo "--- Session info ---"
mkdir -p results
Rscript -e "sessionInfo()" > results/session_info.txt 2>&1

echo "=== Pipeline complete ==="
