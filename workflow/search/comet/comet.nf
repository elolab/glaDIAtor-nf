// Setting memory & error strategy like this prevents caching even with process.cache='lenient'.
// Maybe because the task.attempt = 1 is tried first.

process Comet {
    memory { 5.GB * 2 *  task.attempt }
    errorStrategy { task.exitStatus in 137..137 ? 'retry' : 'terminate' }
    maxRetries 2

    input:
    file comet_config
    // future dev: we can .mix with DDA here?
    // though we might need to tag for DDA / Pseudo
    // so that xinteract 
    file mzxml
    file fastadb_with_decoy

    output:
    file("${mzxml.baseName}.pep.xml")
    file mzxml

    when:
    params.search_engines.contains("comet")

    script:
    """
    if command -v command-ms; then
      comet-ms -P$comet_config $mzxml
    else
      comet -P$comet_config $mzxml
    fi
    """
}
