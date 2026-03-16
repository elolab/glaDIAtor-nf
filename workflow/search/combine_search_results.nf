process CombineSearchResults {
    publishDir "${params.outdir}/speclib"

    input:
    file xtandem_search_results
    file comet_search_results

    output:
    file "lib_iprophet.peps.xml"

    script:
    """
    InterProphetParser DECOY=DECOY_ THREADS=${task.cpus} $xtandem_search_results $comet_search_results lib_iprophet.peps.xml
    """
}
