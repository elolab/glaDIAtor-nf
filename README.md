# glaDIAtor


## Description

glaDIAtor-nf is a Nextflow workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.
This is programmed in a literate style in the file [notes.org](notes.org) in org-mode.
See that to learn more about the details of the program,
Common issues encountered are noted there.


## Installation
This requires [nextflow](https://nextflow.io)
 to be on the system where you launch this workflow from.
This workflow has been developed under nextflow version `21.04.3`.
For best compatibility set the environmnnt variable `NXF_VER` to this when the workflow is launched.
(see also [this blogpost](https://nextflow.io/blog/2022/evolution-of-nextflow-runtime.html))


gladiator-nf is designed to run under NextFlow bioinformatics workflow manager. The glaDIAtor-nf software is packaged as a container, so the computer environment needs to support container technology such as Docker and Podman.

Example: get glaDIAtor-nf
```
$ git clone https://github.com/elolab/gladiator-nf.git
```


## Usage:


### Pre-Usage
0. (Optional) Generate the containers using `make docker-containers`
1. If your DIA data is not yet in MZML format and your (optional) DDA data is not yet in MZXML format, convert these following the `Preprocessing Data` in [notes.org](notes.org)
2. determine the precursor 

## Analysis workflow 


## Parameters
- 
- `fastafiles`, glob pattern / path to fasta files to be used 

## Analysis Results
Once the analysis has completed successfully, the analysis results are available... 

## APPENDIX

### How to customize peptide search parameters of the spectral/pseudospectral library

The default parameters are for a nanoflow HPLC system (Easy-nLC1200, Thermo Fisher Scientific) coupled to a Q Exactive HF mass spectrometer (Thermo Fisher Scientific) equipped with a nano-electrospray ionization source. Below is the summary of the default settings:

* Precursor mass tolerance: 10 ppm
* Fragment ion tolerance: 0.02 Da
* Cleavage site: Trypsin_P
* Fixed modification: Carbamidomethyl (C)
* Variable modification: Oxidation (M)

glaDIAtor-nf provides a small set of search parameter settings that can be adjusted. 
If more settings needs to be adjusted, the default settings (`comet_settings_template.xml` and `xtandem_settings_template.xml`) can be edited from this directory, or directly in [notes.org](notes.org) if you tangle it afterwards.
### Annotate the peptide intensity matrix from command line


### Use DDA data for the library




