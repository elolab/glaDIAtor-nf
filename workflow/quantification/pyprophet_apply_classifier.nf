process pyprophet_apply_classifier {
    input:
    file osw_model
    file osw

    output:
    file scored_osw

    script:
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    scored_osw="${osw.baseName}.scored.${osw.Extension}"
    """
    pyprophet score $pyprophet_seed_flag --in=$osw --out=$scored_osw --apply_weights=$osw_model --level=ms1ms2
    """
}
