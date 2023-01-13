# glaDIAtor-NF


## Description

glaDIAtor-nf is a workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.

glaDIAtor-nf is designed to run under NextFlow ((https://nextflow.io)) bioinformatics workflow manager. This workflow has been developed under nextflow version `21.04.3`

The glaDIAtor-nf software uses container technology, so the run environment needs to support container technology such as Docker, Podman or Singularity.

Example: get glaDIAtor-nf
```
$ git clone https://github.com/elolab/gladiator-nf.git
```


## Usage:


### Pre-Usage
1. If your DIA data is not in MZML format and your (optional) DDA data is not yet in MZXML format, convert the data to the open formats.
2. Determine the precursor (MS1 spectrum, in ppm) and fragment (MS2 spectrum, in Dalton) mass tolerances of your data (instrument specific). 

### Preprocessing Data

Pull the pwiz container

`docker pull dockerhub:chambm/pwiz-skyline-i-agree-to-the-vendor-licenses`


#### Converting DIA raw data to mzXML
``` sh
mkdir -p MZML-pwiz
find . -iname '*.wiff' -print0 | xargs -P5 -0 -i wine msconvert {} --filter 'titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState> File:"<SourcePath>", NativeID:"<Id>"' -o MZML-pwiz/
```

#### Optional: Converting DDA raw data to mzML
If you are using DDA-assisted DIA-analysis, convert your DDA data to mzXML format.
``` sh
mkdir -p MZXML-pwiz
for f in RAW/*.wiff; do
    wine qtofpeakpicker --resolution=2000 --area=1 --threshold=1 --smoothwidth=1.1 --in $f --out MZXML-pwiz/$(basename --suffix=.wiff $f).mzXML
done
```


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


### Development

This workflow has been developed under nextflow version `21.04.3`.

This is programmed in a literate style in the file [notes.org](notes.org) in org-mode.
See that to learn more about the details of the program,
Common issues encountered are noted there.

