process MakeCometConfig {
    input:
    val max_missed_cleavages
    file fastadb_with_decoy
    path template

    output:
    file "comet_config.txt" // into comet_config_ch

    script:
    """
    sed 's/@DDA_DB_FILE@/$fastadb_with_decoy/g;s/@FRAGMENT_MASS_TOLERANCE@/$params.fragment_mass_tolerance/g;s/@PRECURSOR_MASS_TOLERANCE@/$params.precursor_mass_tolerance/g;s/@MAX_MISSED_CLEAVAGES@/$max_missed_cleavages/g' $template > comet_config.txt 
    """
}
