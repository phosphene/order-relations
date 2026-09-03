#!/usr/bin/env bash
set -euo pipefail

echo "=== Phosphene R Artifact Foundry Pipeline ==="
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Step 1: Restore environment
if [ -f "renv.lock" ]; then
  echo "--- Restoring renv environment ---"
  Rscript -e "renv::restore(prompt = FALSE)"
fi

# Step 2: Run test suite
echo "--- Running tests ---"
Rscript run_tests.R

# Step N: Capture session info
echo "--- Session info ---"
Rscript -e "sessioninfo::session_info()" > results/session_info.txt 2>&1 || \
  Rscript -e "sessionInfo()" > results/session_info.txt 2>&1

echo "=== Pipeline complete ==="
