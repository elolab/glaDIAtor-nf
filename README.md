# glaDIAtor-nf

glaDIAtor-nf is a workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.

The package is designed to run both on workstations and HPC clusters, built with scaling in mind.

## Dependencies

* NextFlow 25.10.4 (>= 22.10 should work)
* Java 25 (>= 17 should work)
* Working installation of Docker, Podman, Apptainer, Singularity or Guix.

## Get the glaDIAtor-nf

```sh
git clone https://github.com/elolab/gladiator-nf.git
```

## Input data

1. Raw experimental DIA data in proprietary format needs to be converted to mzML before it can be used by glaDIAtor-nf.
2. Determine instrument-specific parameters that were used during experiment:
   * precursor (MS1 spectrum) mass tolerance in ppm
   * fragment (MS2 spectrum) mass tolerance in Dalton

## Example run

```sh
git clone --depth 1 https://github.com/elolab/gladiator-nf.git

mkdir example-run
cd example-run

mkdir dia-spectra
wget --no-directories --directory-prefix=dia-spectra 'ftp://massive-ftp.ucsd.edu/v05/MSV000090837/raw/Exp03_repeat_90minGradient_from_Exp02_same_Mastermix/210820_Grad090_LFQ_'{A,B}'_01.mzML'

mkdir protein-sequences
wget --directory-prefix=protein-sequences 'ftp://massive-ftp.ucsd.edu:/v05/MSV000090837/sequence/fasta/*.fasta'

gladiator_location="../gladiator-nf"
gladiator_container_type="singularity"  # singularity, podman, docker or guix

nextflow -config "${gladiator_location}/config/containers/${gladiator_container_type}.config" \
    run "${gladiator_location}/workflow/gladiator.nf" \
        --diafiles='dia-spectra/*.mzML' --fastafiles='protein-sequences/*.fasta' \
        --precursor_mass_tolerance=10 --fragment_mass_tolerance=0.02 --max_missed_cleavages=1

head results/*.{csv,tsv}
```

## Documentation

* [Getting started](https://elolab.github.io/glaDIAtor-nf/doc/getting-started.html)
* [User guide](https://elolab.github.io/glaDIAtor-nf/doc/user-guide/index.html)
  * [Input and output](https://elolab.github.io/glaDIAtor-nf/doc/user-guide/input-output.html)
  * [Configuration](https://elolab.github.io/glaDIAtor-nf/doc/user-guide/configuration/index.html)

## License

The glaDIAtor-nf workflow is licensed under [GPL-3.0](https://github.com/elolab/glaDIAtor-nf/blob/master/LICENSE) license.

Licenses of the components:

* Apache 2.0
* Artistic 1.0
* BSD 3-Clause
* GPL-2.0
* GPL-3.0
* LGPL

Comprehensive list can be found at [glaDIAtor-nf # Licenses](https://elolab.github.io/glaDIAtor-nf/#licenses).
