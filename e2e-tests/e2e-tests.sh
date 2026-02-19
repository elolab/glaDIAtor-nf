#!/usr/bin/env bash

# The script runs E2E tests
#
# Features:
# * Safe to be called from other locations

set -euo pipefail

options=( "dag" "docker" "singularity" "swath-windows-provided" "timeline" )

contains() {
  local val="$1"; shift

  for item in "$@"; do
    [[ "$item" == "$val" ]] && return 0
  done

  return 1
}

for arg in "$@"; do
  if contains "${arg}" "${options[@]}"; then
    true
  else
    echo "${arg} is not a valid parameter"
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

(
  cd "${SCRIPT_DIR}"

  #
  # Prepare configuration


  ln -sf ../diaumpireconfig.txt diaumpireconfig.txt
  ln -sf ../xtandem-template.xml xtandem-template.xml
  ln -sf ../comet_template.txt comet_template.txt

  #
  # Prepare input files

  if [ ! -e .cache ]; then
    mkdir .cache
  fi

  if [ ! -e .cache/dia-spectra ]; then
    mkdir .cache/dia-spectra
    wget -nv -O ".cache/dia-spectra/210820_Grad090_LFQ_A_SubSet.mzML" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2F210820_Grad090_LFQ_A_SubSet.mzML&dl=1"
    wget -nv -O ".cache/dia-spectra/210820_Grad090_LFQ_B_SubSet.mzML" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2F210820_Grad090_LFQ_B_SubSet.mzML&dl=1"
  fi

  if [ ! -e .cache/protein-sequences ]; then
    mkdir .cache/protein-sequences
    wget -nv --directory-prefix=.cache/protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/*.fasta'
  fi

  #
  # Use provided SWATH windows file (or generate one)
  #
  # switch: swath-windows-provided

  swath_windows_provided_switch=""

  if contains "swath-windows-provided" "$@"; then
    swath_windows_provided_switch="--swath_windows_file=inferred-swath-windows.txt"
  fi

  #
  # Select container type
  #
  # switch: docker or singularity

  container_configuration_switch=""

  if contains "docker" "$@"; then
    [ -z "${container_configuration_switch}" ] || false
    container_configuration_switch="-c ../config/docker.nf"
  fi

  if contains "singularity" "$@"; then
    [ -z "${container_configuration_switch}" ] || false
    container_configuration_switch="-c ../config/singularity.nf"

    if [ ! -e .cache/singularity ]; then
      mkdir .cache/singularity
    fi

    export NXF_SINGULARITY_CACHEDIR="$(pwd)/.cache/singularity"
  fi

  #
  # Generate execution timeline report
  #
  # switch: timeline

  report_timeline_switch=""

  if contains "timeline" "$@"; then
    report_timeline_switch="-with-timeline timeline.html"
    rm timeline.html -f
  fi

  # .irt file is compulsory even when not used

  workflow_file="../gladiator.nf"
  irt_workaround_switches="--irt_traml_file=ftp://massive-ftp.ucsd.edu/x01/MSV000081829/other/SGS/assays/OpenSWATH_SM4_iRT_AssayLibrary.TraML --use_irt=false"

  #
  # Generate workflow graph (DAG)
  #
  # switch: dag

  generate_dag_switch=""

  if contains "dag" "$@"; then
    generate_dag_switch="-with-dag dag.dot"
    rm dag.dot -f
  fi

  NXF_VER="22.10.1" nextflow -c e2e-conf.nf ${container_configuration_switch} \
      run ${report_timeline_switch} ${generate_dag_switch} "${workflow_file}" ${swath_windows_provided_switch} ${irt_workaround_switches}
)
