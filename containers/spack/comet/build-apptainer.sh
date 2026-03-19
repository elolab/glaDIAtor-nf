#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  source ../.spack/share/spack/setup-env.sh

  rm build-apptainer -rf

  mkdir build-apptainer

  (
    cp ../spack_repo build-apptainer -r
    cp spack.yaml.hbs build-apptainer/spack.yaml
    sed -i "s/{{container type}}/singularity/g" build-apptainer/spack.yaml

    (
      cd build-apptainer

      spack containerize > comet.def
      sed -i $'5i%files' comet.def
      sed -i $'6i\ \ spack_repo /opt' comet.def
      sed -i $'7i\n' comet.def 

      apptainer build comet.sif comet.def
      mv comet.sif comet-2026.01.1-$(date +"%Y%m%d%H%M%S").sif
    )
  )
)
