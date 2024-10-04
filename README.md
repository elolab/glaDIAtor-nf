# glaDIAtor-nf


## Description

glaDIAtor-nf is a workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.

This document describes usage of the workflow, for technical documentation see [this program's literate description](https://gitlab.utu.fi/elixirdianf/gladiator-notes/-/jobs/artifacts/ci-test/raw/notes.html?job=build-html), also available as [pdf](https://gitlab.utu.fi/elixirdianf/gladiator-notes/-/jobs/artifacts/ci-test/raw/notes.pdf?job=build-pdf) or as its source [org-file](./notes.org).

glaDIAtor-nf is designed to run under the [NextFlow](https://nextflow.io) bioinformatics workflow manager. This workflow has been developed under nextflow version `21.04.3`

The glaDIAtor-nf software uses container technology, so the run environment needs to support container technology such as Docker, Podman or Singularity.

Example: get glaDIAtor-nf
```
$ git clone https://github.com/elolab/gladiator-nf.git
```


## Usage:


### Pre-Usage
1. If your DIA data is not in MZML format and your (optional) DDA data is not yet in MZXML format, convert the data to the open formats.
2. Determine the precursor (MS1 spectrum, in ppm) and fragment (MS2 spectrum, in Dalton) mass tolerances of your data (instrument specific). 

#### Preprocessing Data

Pull the pwiz container
`docker pull dockerhub:chambm/pwiz-skyline-i-agree-to-the-vendor-licenses`

###### Converting DIA raw data to mzXML
``` sh
mkdir -p MZML-pwiz
find . -iname '*.wiff' -print0 | xargs -P5 -0 -i wine msconvert {} --filter 'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"' -o MZML-pwiz/
```

### Running the analysis
Fetch and unpack the template files to your project folder, or run `make tangle` (requires emacs, GNU make).
Make sure you have nextflow installed and it is in your path when 
you run the workflow.
```
NXF_VER=21.04.3 nextflow  -c config/docker.config run gladiator.nf --fastafiles='fasta/*.fasta' --diafiles='mzML/*.mzML'  --precursor_mass_tolerance=50 --fragment_mass_tolerance=0.1 --outdir=./results
```
Once the analysis run is completed,
results can be found in the `--outdir` folder. (See the section `Analysis Results`)
Here `-c config/docker.config` specifies to use docker with the images from the remote registry, see the section `Container Backends` for more info.

If the dataset has Biognosys irt-peptides, pass `--use_irt=true` to the nextflow invocation.


*Note*: When using asterisk or question marks in file parameters (such as `--fastafiles` and `--diafiles`), the quotes are needed like shown in the example. 

## Doing DDA-assisted analysis

The DDA-assisted analysis requires DDA data to build spectral library. 

###### Converting DDA raw data to mzML
If you are using DDA-assisted DIA-analysis, convert your DDA data to mzXML format.
``` sh
mkdir -p MZXML-pwiz
for f in RAW/*.wiff; do
    wine qtofpeakpicker --resolution=2000 --area=1 --threshold=1 --smoothwidth=1.1 --in $f --out MZXML-pwiz/$(basename --suffix=.wiff $f).mzXML
done
```



The DDA-assisted analysis is specified by passing by specifying the dda files with `--ddafiles`.
For example, one would invoke the program like so:
```
NXF_VER=21.04.3 nextflow -c  config/docker.config run  gladiator.nf --fastafiles='fasta/*.fasta' --ddafiles='mzXML/*.mzXML'  --diafiles='mzML/*.mzML'  --precursor_mass_tolerance=50 --fragment_mass_tolerance=0.1 --outdir=./results
```
Once the analysis run is completed,
results can be found in the `--outdir` folder. (See the section `Analysis Results`)
Here `-c config/docker.config` specifies to use docker with the images from the remote registry, see the section [Container Backends](#container-backends) for more info.


## Analysis Results
Once the analysis run is completed,
results can be found in directory specified by the  `--outdir` parameters (defaults to `./results`)
The sub-folder `dia` contains DIA-peptide-matrix.tsv and DIA-protein-matrix.tsv,
which have peptides and proteins and their intensities (abundances) per sample.

All intermediate files (like with any other nextflow program) can be found in nextflow's working directory
, which defaults to `./work` (See https://www.nextflow.io/docs/latest/cli.html)


<a id="container-backends">

## Container Backends
</a>

Gladiator currently has support for three container backends:
docker,podman and singularity.
These can be used with both the registry provided images or local images
The nextflow config files `config/{docker,podman,singularity}.nf` are set up to 
use the respective backend with images from the registry. 

So in order to use singularity as the container backend, one would invoke nextflow as 
```
NXF_VER=21.04.3 nextflow -c config/singularity.nf run gladiator.nf ...
```

Whereas in order to use podman, one would invoke nextflow as
```
NXF_VER=21.04.3 nextflow -c config/podman.nf run gladiator.nf ... 
```

This is the most convenient way to use the pipeline.

Nextflow config files for local images are provided as `config/{docker,podman,singularity}-local.nf`.
For singularity this assumes your images are contained in the sub-directory 'containers/',
and  requires the main gladiator image `gladiator.simg`, and the pyprophet image `pyprophet-image.simg` to be located there.


If you prefer to  build the images yourself, 
run `make docker-containers` or `make singularity-containers`, 
both of which require [GNU guix](https://guix.gnu.org) or one of `docker` or `podman`.
The latter requires singularity (or Apptainer) to be installed in addition to the other tools.



See the [Makefile](./Makefile) and also the explanation of the `DOCKER_EXECUTABLE` variable for more info.

## APPENDIX
### Usage guidance on HPC 
Extensive documentation on nextflow usage various grid schedulers or cloud computing environments (Executors in nextflow parlance), is available in the [nextflow documentation on Executors](https://www.nextflow.io/docs/latest/executor.html).

It might also be desirable to launch the head job through your scheduler, for example in the slurm case,
```
NXF_VER=21.04.3 sbatch [slurm specifc paramaters...] nextflow -c config/docker.nf gladiator.nf ... 
```
where you might substitute  `[slurm specific parameters]` with e.g. `--time=30h` to give the head job 30 hours.



### How to customize peptide search parameters of the spectral/pseudo-spectral library

The default parameters are for a nanoflow HPLC system (Easy-nLC1200, Thermo Fisher Scientific) coupled to a Q Exactive HF mass spectrometer (Thermo Fisher Scientific) equipped with a nano-electrospray ionization source. Below is the summary of the default settings of that machine:

* Precursor mass tolerance: 10 ppm
* Fragment ion tolerance: 0.02 Da
* Cleavage site: Trypsin_P
* Fixed modification: Carbamidomethyl (C)
* Variable modification: Oxidation (M)

parameters that are not passed on the nextflow command-line, one can edit the templates files to adjust tool specific behavior.
See the files  [`comet_settings_template.xml`](https://uwpr.github.io/Comet/parameters/parameters_202201/) , [`xtandem_settings_template.xml`](https://www.thegpm.org/tandem/) and `diaumpireconfig.txt`,

<!-- add links to tool specific documentation  -->

### Development

This workflow has been developed under nextflow version `21.04.3`.

This is programmed in a literate style in the file [notes.org](notes.org) in org-mode.
See that to learn more about the details of the program,
Common issues encountered are noted there.
