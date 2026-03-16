process pyprophet_backpropagate {
    input:
    file osw_scored
    file osw_global_model

    output:
    file dscore_tsv

    script:
    base="${file(osw_scored.baseName).baseName}"
    backproposw="${base}.backprop.osw"
    dscore_tsv="${base}.tsv"
    """
    pyprophet backpropagate --in="$osw_scored" --apply_scores="$osw_global_model" --out=$backproposw
    # we supply --format=legacy_merged so that pyprophet export respect the --out parameter
    pyprophet export --in=$backproposw --format=legacy_merged --out=$dscore_tsv
    """
}
