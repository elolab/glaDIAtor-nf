#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  for container_type in "docker" "apptainer"; do
    ./build-container.sh "${container_type}" comet 2026.01.1
    ./build-container.sh "${container_type}" comet 2022.01.0

    ./build-container.sh "${container_type}" x-tandem 2017.02.01-4

    ./build-container.sh "${container_type}" dia-umpire-se 2.3.4
    ./build-container.sh "${container_type}" dia-umpire-se 2.2.8
  done

  echo "Docker"
  echo
  echo "  withName: Comet { container = 'localhost/$(cat docker/comet/2026.01.1/image-name.txt)' }"
  echo "  withName: Comet { container = 'localhost/$(cat docker/comet/2022.01.0/image-name.txt)' }"
  echo "  withName: Xtandem { container = 'localhost/$(cat docker/x-tandem/2017.02.01-4/image-name.txt)' }"
  echo "  withName: GeneratePseudoSpectra { container = 'localhost/$(cat docker/dia-umpire-se/2.3.4/image-name.txt)' }"
  echo "  withName: GeneratePseudoSpectra { container = 'localhost/$(cat docker/dia-umpire-se/2.2.8/image-name.txt)' }"
  echo
  echo "Apptainer"
  echo
  echo "  withName: Comet { container = 'file://../containers/spack/$(ls apptainer/comet/2026.01.1/*.sif)' }"
  echo "  withName: Comet { container = 'file://../containers/spack/$(ls apptainer/comet/2022.01.0/*.sif)' }"
  echo "  withName: Xtandem { container = 'file://../containers/spack/$(ls apptainer/x-tandem/2017.02.01-4/*.sif)' }"
  echo "  withName: GeneratePseudoSpectra { container = 'file://../containers/spack/$(ls apptainer/dia-umpire-se/2.3.4/*.sif)' }"
  echo "  withName: GeneratePseudoSpectra { container = 'file://../containers/spack/$(ls apptainer/dia-umpire-se/2.2.8/*.sif)' }"
  echo
)
