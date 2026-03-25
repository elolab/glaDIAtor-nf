#!/usr/bin/env bash

# The script runs E2E tests
#
# Features:
# * Safe to be called from other locations

set -euo pipefail

options=( "docker" "dsl1" "legacy-nextflow" "profiling" "singularity" "spectral-library-provided" "swath-windows-provided" )

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
  # Install PyTest

  if [ ! -e .venv ]; then
    python -m venv .venv
  fi

  source .venv/bin/activate
  pip install -r requirements.txt > /dev/null

  #
  # Prepare configuration

  if [ ! -e config ]; then
    mkdir config

    (
      cd config
      ln -s ../../config/diaumpire.params diaumpire.params
      ln -s ../../config/xtandem.xml xtandem.xml
      ln -s ../../config/comet.params comet.params
    )
  fi

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

    # Four different files with protein sequences can be found on the server
    #   $ wget -nv --directory-prefix=.cache/protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/*.fasta'
    #   210817_MaxQuantContaminants.fasta
    #   210820_Ecoli_Ref_Swiss_Can.fasta
    #   210820_Human_Ref_Swiss_Can.fasta
    #   210820_Yeast_Ref_Swiss_Can.fasta

    wget -nv --directory-prefix=.cache/protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/210817_MaxQuantContaminants.fasta'
    wget -nv --directory-prefix=.cache/protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/210820_Human_Ref_Swiss_Can.fasta'
  fi

  #
  # Download spectral library (used as input in some tests, otherwise it is an intermediate output file)

  if [ ! -e .cache/spectral-library ]; then
    mkdir .cache/spectral-library

    wget -nv -O ".cache/spectral-library/SpecLib_cons_openswath.tsv" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2Fexample_glaDIAtor_run%2Fspeclib%2Fbg_estimated%2FSpecLib_cons_openswath.tsv&dl=1"
  fi

  #
  # Download expected output

  if [ ! -e .cache/expected-protein-peptide-matrices ]; then
    mkdir .cache/expected-protein-peptide-matrices

    wget -nv -O ".cache/expected-protein-peptide-matrices/DIA-analysis-results.csv" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2Fexample_glaDIAtor_run%2Fdia%2Fbg_estimated%2FDIA-analysis-results.csv&dl=1"
    sed -i s/A_subset5.mzML/210820_Grad090_LFQ_A_SubSet.mzML/ .cache/expected-protein-peptide-matrices/DIA-analysis-results.csv
    sed -i s/B_subset5.mzML/210820_Grad090_LFQ_B_SubSet.mzML/ .cache/expected-protein-peptide-matrices/DIA-analysis-results.csv

    wget -nv -O ".cache/expected-protein-peptide-matrices/DIA-peptide-matrix.tsv" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2Fexample_glaDIAtor_run%2Fdia%2Fbg_estimated%2FDIA-peptide-matrix.tsv&dl=1"
    wget -nv -O ".cache/expected-protein-peptide-matrices/DIA-protein-matrix.tsv" "https://seafile.utu.fi/d/537124ec634347088a1a/files/?p=%2Fexample_glaDIAtor_run%2Fdia%2Fbg_estimated%2FDIA-protein-matrix.tsv&dl=1"
  fi

  #
  # Use provided SWATH windows file (otherwise it is retrieved from .mzML)
  #
  # switch: swath-windows-provided

  swath_windows_provided_switch=""

  if contains "swath-windows-provided" "$@"; then
    swath_windows_provided_switch="--swath_windows_file=inferred-swath-windows.txt"
  fi

  #
  # Use provided spectral library file (otherwise it is generated with DIA-Umpire from DIA spectral files)
  #
  # switch: spectral-library-provided

  spectral_library_provided_switch=""

  if contains "spectral-library-provided" "$@"; then
    spectral_library_provided_switch="--speclib=.cache/spectral-library/SpecLib_cons_openswath.tsv --libgen_method=custom"
  fi

  #
  # Select container type
  #
  # switch: docker or singularity

  container_configuration_switch=""

  if contains "docker" "$@"; then
    [ -z "${container_configuration_switch}" ] || false
    container_configuration_switch="-c ../config/containers/docker.config"
  else  # singularity
    [ -z "${container_configuration_switch}" ] || false
    container_configuration_switch="-c ../config/containers/singularity.config"

    if [ ! -e .cache/singularity ]; then
      mkdir .cache/singularity
    fi

    export NXF_SINGULARITY_CACHEDIR="$(pwd)/.cache/singularity"
  fi

  #
  # Select NextFlow 22 that supports both DSL1 and DSL2 instead of DSL2-only NextFlow 25
  #
  # The workflow was developed with 21.04.3, extensively tested by Balázs with 22.10.1, migrated to 25.10.4 for DSL2.
  #
  # switch: legacy-nextflow

  NXF_VER="25.10.4"

  if contains "legacy-nextflow" "$@"; then
    NXF_VER="22.10.7"
  fi

  #
  # Run DSL1 version of glaDIAtor-nf
  #
  # switch: dsl1
  #
  # Enables workarounds:
  # * '.irt' file was compulsory even when not used.
  # * 'params.libgen_method' is no longer a string.
  # * Locations of configuration files of DIA-Umpire, X! Tandem and Comet are resolved in runtime in DSL2 version.
  #   DSL1 version still needs hardcoded paths.

  workflow_file="../workflow/gladiator.nf"
  irt_workaround_switches=""
  libgen_method_workaround_switch=""
  config_files_workaround_switches=""

  if contains "dsl1" "$@"; then
    workflow_file="../workflow/legacy-gladiator.nf"
    irt_workaround_switches="--irt_traml_file=ftp://massive-ftp.ucsd.edu/x01/MSV000081829/other/SGS/assays/OpenSWATH_SM4_iRT_AssayLibrary.TraML --use_irt=false"

    if ! contains "spectral-library-provided" "$@"; then
      libgen_method_workaround_switch="--libgen_method=diaumpire"
    fi

    sed 's/@PROCESS_THREAD_COUNT@/12/' config/diaumpire.params > diaumpire.params.altered
    config_files_workaround_switches="--diaumpireconfig=diaumpire.params.altered --comet_template=config/comet.params --xtandem_template=config/xtandem.xml"
  fi

  #
  # Collect profiling data and generate reports
  #
  # * Visualise execution timeline
  # * Generate resource utilisation summary
  # * Generate workflow graph (DAG)
  # * Collect profiling information in .tsv
  #
  # switch: profiling

  produce_profiling_reports=""

  if contains "profiling" "$@"; then
    produce_profiling_reports="-with-dag dag.dot -with-report report.html -with-timeline timeline.html -with-trace trace.tsv"
    rm dag.dot -f
    rm report.html -f
    rm timeline.html -f
    rm trace.tsv -f
  fi

  NXF_VER="${NXF_VER}" nextflow -c e2e-conf.nf ${container_configuration_switch} \
      run ${produce_profiling_reports} "${workflow_file}" ${swath_windows_provided_switch} ${spectral_library_provided_switch} ${irt_workaround_switches} ${libgen_method_workaround_switch} ${config_files_workaround_switches}
      # hint: add -resume and delete work directory related to Spectrast2OpenSwathTsv process to start from the middle

  echo "Checking the output with PyTest"

  if contains "spectral-library-provided" "$@"; then
    pytest -k "not test_protein_sequences_file" --ignore output-checks/test_search_results.py --ignore output-checks/test_spectral_library_files.py
  else
    pytest
  fi
)
