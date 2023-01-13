# glaDIAtor-NF


## Description

glaDIAtor-nf is a workflow for analyzing mass spectrometry data acquired using *data independent acquisition* (DIA) mode.

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
Fetch and unpack the template files to your project folder.
Make sure you have nextflow installed and it is in your path when 
you run the workflow.
```
NXF_VER=21.04.3 nextflow run gladiator.nf --fastafiles='fasta/*.fasta' --diafiles='mzML/*.mzML'  --precursor_mass_tolerance=50 --fragment_mass_tolerance=0.1 --outdir=./results
```
Once the analysis run is completed,
results can be found in the `--outdir` folder.
The subfolder `dia` contains DIA-peptide-matrix.tsv and DIA-protein-matrix.tsv,
which have peptides and proteins and their intensities (abundances) per sample.

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



The DDA-assisted analysis is specified by passing `--dda_assisted=true` and then specifying the dda files with `--ddafiles`.
For example, one would invoke the program like so:
```
NXF_VER=21.04.3 nextflow run gladiator.nf --dda_assisted=true -- --fastafiles='fasta/*.fasta' --ddafiles='mzXML/*.mzXML'  --diafiles='mzML/*.mzML'  --precursor_mass_tolerance=50 --fragment_mass_tolerance=0.1 --outdir=./results
```

## Parameters
- 
- `fastafiles`, glob pattern / path to fasta files to be used 

## Analysis Results
Once the analysis has completed successfully, the analysis results are available... 

## APPENDIX

### How to customize peptide search parameters of the spectral/pseudospectral library

The default parameters are for a nanoflow HPLC system (Easy-nLC1200, Thermo Fisher Scientific) coupled to a Q Exactive HF mass spectrometer (Thermo Fisher Scientific) equipped with a nano-electrospray ionization source. Below is the summary of the default settings of that machine:

* Precursor mass tolerance: 10 ppm
* Fragment ion tolerance: 0.02 Da
* Cleavage site: Trypsin_P
* Fixed modification: Carbamidomethyl (C)
* Variable modification: Oxidation (M)

parameters that are not passed on the nextflow commandline, one can edit the templates files to adjust tool specific behaviour.
See the files  [`comet_settings_template.xml`](https://uwpr.github.io/Comet/parameters/parameters_202201/) , [`xtandem_settings_template.xml`](https://www.thegpm.org/tandem/) and `diaumpireconfig.txt`,

<!-- add links to tool specific documentation  -->

### Development

This workflow has been developed under nextflow version `21.04.3`.

This is programmed in a literate style in the file [notes.org](notes.org) in org-mode.
See that to learn more about the details of the program,
Common issues encountered are noted there.

