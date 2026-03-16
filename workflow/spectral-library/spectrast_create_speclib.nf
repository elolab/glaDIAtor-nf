// spectrast will create *.splib, *.spidx, *.pepidx, 
// note that where-ever a splib goes, so must its spidx and pepidx
///and they must have the same part
process SpectrastCreateSpecLib {
    input:
    file irtfile
    file combined_search_results
    file fastadb_with_decoy
    val cutoff

    output:
    // tuple file ("${prefix}_cons.splib"), file("${prefix}_cons.spidx")
    file("${prefix}_cons.sptxt")

    script:
    prefix = "SpecLib"
    to_run = "spectrast -cN${prefix} -cIHCD -cf\"Protein! ~ DECOY_\" -cP$cutoff -c_IRR "
    
    if (params.use_irt) {
    	to_run += "-c_IRT$irtfile "
    }

    to_run +=  "$combined_search_results" // spectrast really wants its input-files last.
    to_run += "\n spectrast -cN${prefix}_cons -cD$fastadb_with_decoy -cIHCD -cAC ${prefix}.splib"
}
