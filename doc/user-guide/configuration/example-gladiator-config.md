```nextflow
params {
    fragment_mass_tolerance = 0.02  // fragment mass tolerance in Dalton, 0.02 is a sensible default
    precursor_mass_tolerance = 10  // in ppm (parts per million)
    protFDR = 0.01  // passed to mayu as cutoffrate for finding the peptide probability
    max_missed_cleavages = 1 
    pyprophet_subsample_ratio = null  // when set to null, it resolves to subsample ratio of 1 / {number of samples}

    // DIA-Umpire, Comet and X! Tandem configuration can be customized by making copies
    // of 'config/diaumpire.params', 'config/comet.params' or 'config/xtandem.xml'.
    //
    // The custom files are not used until their location is specified, for example:
    //
    //   diaumpireconfig = "./diaumpire.params"
    //   comet_template = "./comet.params"
    //   xtandem_template = "./xtandem.xml"
}
```
