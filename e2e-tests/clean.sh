#!/usr/bin/env bash

# The script cleans after E2E tests
#
# Features:
# * Safe to be called from other locations
# 
# Notes:
# * It might require to be run with 'sudo' when cleaning after Docker (files created as root)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  rm __pycache__ -rf
  rm .cache -rf
  rm .nextflow -rf
  rm .nextflow.log* -f
  rm .pytest_cache -rf
  rm .venv -rf
  rm config -rf
  rm dag.dot -f
  rm report.html -f
  rm results -rf
  rm timeline.html -f
  rm trace.tsv -f
  rm work -rf
)
