#!/usr/bin/env bash

# Features:
# * Safe to be called from other locations

set -euo pipefail

[ -n "$1" ] || { echo "Pass container type 'docker' or 'apptainer' as the first argument" ; false ; }
[ -n "$2" ] || { echo "Pass package name as the second argument, for example 'comet'" ; false ; }
[ -n "$3" ] || { echo "Pass package version as the third argument, for example 2.3.4" ; false ; }

container_type="$1"
package_name="$2"
package_version="$3"

if [[ -v 4 ]]; then
  package_dependencies="$4"
else
  package_dependencies=""
fi

[[ "${container_type}" == "apptainer" || "${container_type}" == "docker" ]] || { echo "Container type needs to be either 'apptainer' or 'docker'"; false ; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  ./setup-spack.sh
  source ./activate-spack.bash

  build_location="${container_type}/${package_name}/${package_version}"

  if [ -e "${build_location}" ]; then
    if [ "${container_type}" == "apptainer" ]; then
      if [ -e "${build_location}/"*.sif ]; then
        exit 0
      fi
    fi

    if [ "${container_type}" == "docker" ]; then
      if [ -e "${build_location}/image-name.txt" ]; then
        exit 0
      fi
    fi
  fi

  rm "${build_location}" -rf
  mkdir -p "${build_location}"

  cp spack_repo "${build_location}" -r
  cp spack.yaml.hbs "${build_location}/spack.yaml"

  sed -i "s/{{name}}/${package_name}/g" "${build_location}/spack.yaml"
  sed -i "s/{{version}}/${package_version}/g" "${build_location}/spack.yaml"
  sed -i "s/{{dependencies}}/${package_dependencies}/g" "${build_location}/spack.yaml"

  if [ "${container_type}" == "apptainer" ]; then
    sed -i "s/{{container type}}/singularity/g" "${build_location}/spack.yaml"
  else
    sed -i "s/{{container type}}/docker/g" "${build_location}/spack.yaml"
  fi

  (
    cd "${build_location}"

    if [ "${container_type}" == "apptainer" ]; then
      spack containerize > container.def
      sed -i $'5i%files' container.def
      sed -i $'6i\ \ spack_repo /opt' container.def
      sed -i $'7i\n' container.def 

      apptainer build container.sif container.def > build.log 2>&1
      mv container.sif ${package_name}-${package_version}-$(date +"%Y%m%d%H%M%S").sif
    fi

    if [ "${container_type}" == "docker" ]; then
      spack containerize > Dockerfile
      sed -i $'4iCOPY spack_repo /opt/spack_repo' Dockerfile

      image_name="${package_name}:${package_version}-$(date +"%Y%m%d%H%M%S")"

      docker build -t ${image_name} .
      echo "${image_name}" > image-name.txt
    fi
  )
)
