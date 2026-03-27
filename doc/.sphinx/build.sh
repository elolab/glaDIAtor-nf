#!/usr/bin/env bash

# The script builds documentation of the project using Sphinx generator
#
# Features:
# * Safe to be called from other locations
# * Creates sphinx/.venv if not present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  if [ ! -e .venv ]; then
    python -m venv .venv
  fi

  source .venv/bin/activate
  pip install -r requirements.txt > /dev/null

  sphinx-build --conf-dir . --builder html ../.. ../dist
)
