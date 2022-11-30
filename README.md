# glaDIAtor


## Description

glaDIAtor-nf is a Nextflow workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.

## Installation

gladiator-nf is designed to run under NextFlow bioinformatics workflow manager. The glaDIAtor-nf software is packaged as a container, so the computer environment needs to support container technology such as Docker and Podman.

Example: Install glaDIAtor-nf
```
$ git clone https://github.com/elolab/gladiator-nf.git
```

The following folders are required...
1) A folder for input files such as raw data and sequence database files (/data here).
2) A folder for storing analysis results and intermediate files (/run-files here)

## Analysis workflow

1. raw file conversion... 
2. 
3. 
4. 
5. Optional

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

glaDIAtor-nf provides a small set of search parameter settings that can be adjusted. If more settings needs to be adjusted, the default settings (comet_settings_template.xml and xtandem_settings_template.xml) can be accessed at the container image location /opt/gladiator/. 

### Annotate the peptide intensity matrix from command line


### Use DDA data for the library




