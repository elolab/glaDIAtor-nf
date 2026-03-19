#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  if [ ! -e .spack ]; then
    git -c advice.detachedHead false clone --depth 1 --branch v1.1.1 https://github.com/spack/spack.git .spack
  fi

  if [ ! -e ./comet/build-docker/image_name.txt ]; then
    ./comet/build-docker.sh
  fi

  if [ ! -e ./comet/build-apptainer/*.sif ]; then
    ./comet/build-apptainer.sh
  fi

  echo "Comet"
  echo "  Docker: "
  echo "    withName: Comet { container = 'localhost/$(cat ./comet/build-docker/image_name.txt)' }"
  echo "  Apptainer: "
  echo "    withName: Comet { container = 'file://../containers/spack/$(ls comet/build-apptainer/*.sif)' }"
)
