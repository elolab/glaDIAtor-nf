# Workflow

## Overview

:::{graphviz} ./workflow-overview.dot
:::

## Software dependencies

* NextFlow 25.10.4 (>= 22.10)
* Java 17 (>= 17, <= 25)

Experimental spectra in proprietary formats need to be converted to .mzML or .mzXML with tools like [ProteoWizard msconvert](https://hub.docker.com/r/proteowizard/pwiz-skyline-i-agree-to-the-vendor-licenses) 3.0.21354.

(development-workflow-software-components)=
## Software components

Following software packages are used internally

* Biopython [SeqIO](https://biopython.org/docs/latest/api/Bio.SeqIO.html#module-Bio.SeqIO) – for reading and writing of .fasta files.
* [OpenMS](https://openms.readthedocs.io) 3.4.1
  * [DecoyDatabase](https://openms.de/doxygen/release/3.4.1/html/TOPP_DecoyDatabase.html) – adds decoys to peptide sequence file database.
  * [TargetedFileConverter](https://openms.de/doxygen/release/3.5.0/html/TOPP_TargetedFileConverter.html) – performs bi-directional conversion between .traML and .tsv.
  * [OpenSwathDecoyGenerator](https://openms.de/documentation/TOPP_OpenSwathDecoyGenerator.html) – adds decoy transitions to the spectral library
* [ProteoWizard](https://github.com/ProteoWizard/pwiz) msconvert 3.0.22088 – performs conversion between .mgf, .mzML and .mzXML.
* [Trans-Proteomic Pipeline (TPP)](http://www.tppms.org) 6.1.9
  * [Comet 2022.01](https://uwpr.github.io/Comet/releases/release_202201.html)
  * [X! Tandem](https://www.thegpm.org/tandem) 2017.02.01.4
  * InteractParser – combines multiple files produced by Comet and X! Tandem
  * InterProphetParser – combines results from Comet and X! Tandem
  * [SpectraST](http://tools.proteomecenter.org/wiki/index.php?title=Software:SpectraST)
  * Comet and X! Tandem predict spectra from a database of peptide sequences and try to match experimental MS/MS spectra to them. Search results (PSMs) from both tools are combined and passed to SpectraST that performs search on experimental spectra database again, validating the search results and building a _spectral database_.
* [DIA-Umpire](https://diaumpire.nesvilab.org) SE 2.2.8 – performs deconvolution of raw spectra into pseudospectra.
* [Mayu](https://github.com/proteomics-mayu/mayu) – determines protein and peptide identification false discovery rates.
* [specrast2tsv.py](https://github.com/msproteomicstools/msproteomicstools/blob/master/analysis/spectral_libs/spectrast2tsv.py) from <https://github.com/msproteomicstools/msproteomicstools> – converts spectral library into .tsv accepted by OpenSWATH Workflow
* [OpenSWATH Workflow](http://www.openswath.org/en/latest/docs/openswath.html)
* [SWATH2stats](https://github.com/peterblattmann/SWATH2stats) 1.31.0 – _transforms extracted SWATH/DIA data into a format directly-usable by statistics packages_.
* [PyProphet](https://openswath.org/en/latest/docs/pyprophet.html) 2.2.5 and 0.24.1 – performs statistical validation of the results, version selected based on `pyprophet_use_legacy` switch.
* Python 3.9.9
* Java OpenJDK 11.0.15
