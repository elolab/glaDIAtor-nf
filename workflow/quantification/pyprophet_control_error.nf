process pyprophet_control_error {
    input:
    file reduced_scored_osws
    file osw_model

    output:
    file osw_global_model

    script:
    osw_global_model="model_global.osw"
    """
    pyprophet merge --template=$osw_model --out=$osw_global_model $reduced_scored_osws
    pyprophet peptide --context=global --in=$osw_global_model
    pyprophet protein --context=global --in=$osw_global_model
    """
}
