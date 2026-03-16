process feature_alignment {
    publishDir "${params.outdir}/dia/"

    input:
    file dscore_csvs

    output:
    file outfile

    script:
    outfile = "DIA-analysis-results.csv"
    if (params.use_irt) {
        realign_method = "diRT" 
    } else {
        realign_method = "linear"
    }

    if (params.no_realignment) {
        realignment_string = ""
    } else {
       realignment_string = "--realign_method $realign_method "
    }
    
    "feature_alignment.py " +
        "--method best_overall " +
        "--max_rt_diff 90 " +
        "--target_fdr $params.tric_target_fdr " +
        "--max_fdr_quality $params.tric_max_fdr " +
        "--in $dscore_csvs " +         // will this break on filenames with spaces
        realignment_string +
        params.feature_alignment_args + " " +
        "--out $outfile"
}
