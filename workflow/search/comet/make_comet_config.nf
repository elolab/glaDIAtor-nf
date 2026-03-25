process MakeCometConfig {
    cpus { task.executor == 'local' ? Runtime.runtime.availableProcessors() / sample_count : Runtime.runtime.availableProcessors() }

    input:
    val max_missed_cleavages
    file fastadb_with_decoy
    path template
    val sample_count

    output:
    file "comet_config.txt" // into comet_config_ch

    script:
    """
    sed 's/@DDA_DB_FILE@/$fastadb_with_decoy/g;s/@FRAGMENT_MASS_TOLERANCE@/$params.fragment_mass_tolerance/g;s/@PRECURSOR_MASS_TOLERANCE@/$params.precursor_mass_tolerance/g;s/@MAX_MISSED_CLEAVAGES@/$max_missed_cleavages/g;s/@PROCESS_THREAD_COUNT@/${task.cpus}/g' $template > comet_config.txt 
    """
}
