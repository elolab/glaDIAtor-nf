process pyprophet_subsample {
    input:
    file dia_osw_file
    val subsample_ratio

    output:
    file subsampled_osw

    script:
    subsampled_osw="${dia_osw_file.baseName}.osws"
    pyprophet_seed_flag=(params.pyprophet_fixed_seed ? "--test" : "--no-test")
    """
    pyprophet subsample $pyprophet_seed_flag --in=$dia_osw_file --out=$subsampled_osw --subsample_ratio=$subsample_ratio
    """
}
