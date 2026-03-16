process pyprophet_learn_classifier {
    input:
    file subsampled_osws
    file openswath_transitions

    output:
    file osw_model

    script:
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    osw_model="model.osw"
    """
    pyprophet merge --template=$openswath_transitions --out=$osw_model $subsampled_osws
    pyprophet score  $pyprophet_seed_flag --in=$osw_model --level=ms1ms2
    """
}
