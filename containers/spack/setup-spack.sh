#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  if [ ! -e spack ]; then
    git -c advice.detachedHead=false clone --depth 1 --branch v1.1.1 https://github.com/spack/spack.git spack
  fi

  source spack/share/spack/setup-env.sh

  { spack repo ls | grep gladiator_nf > /dev/null ; } || spack repo add spack_repo/gladiator_nf
)
