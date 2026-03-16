process MakeXtandemConfig {
    input:
    file template
    file fastadb_with_decoy
    val max_missed_cleavages

    output:
    file "xtandem_config.xml"

    script:
    """
    sed 's/@DDA_DB_FILE@/$fastadb_with_decoy/g;s/@FRAGMENT_MASS_TOLERANCE@/$params.fragment_mass_tolerance/g;s/@PRECURSOR_MASS_TOLERANCE@/$params.precursor_mass_tolerance/g;s/@MAX_MISSED_CLEAVAGES@/$max_missed_cleavages/g' $template > xtandem_config.xml
    """
}
