params {
    fragment_mass_tolerance = 0.02  // Dalton
    precursor_mass_tolerance = 10  // ppm
    max_missed_cleavages = 1

    diafiles = '.cache/dia-spectra/*.mzML'
    fastafiles = '.cache/protein-sequences/*.fasta'

    libgen_method='diaumpire'
    pyprophet_use_legacy = false

    pyprophet_fixed_seed = false
}
