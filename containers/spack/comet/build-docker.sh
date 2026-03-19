#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  source ../.spack/share/spack/setup-env.sh

  rm build-docker -rf

  mkdir build-docker

  (
    cp ../spack_repo build-docker -r
    cp spack.yaml.hbs build-docker/spack.yaml
    sed -i "s/{{container type}}/docker/g" build-docker/spack.yaml

    (
      cd build-docker

      spack containerize > Dockerfile
      sed -i $'4iCOPY spack_repo /opt/spack_repo' Dockerfile

      image_name="comet:2026.01.1-$(date +"%Y%m%d%H%M%S")"

      docker build -t ${image_name} .
      echo "${image_name}" > image_name.txt
    )
  )
)
