process pyprophet_reduce {
    input:
    file scored_osw

    output:
    file reduced_scored_osw 

    script:
    reduced_scored_osw="${file(scored_osw.baseName).baseName}.${scored_osw.Extension}r"
    """
    pyprophet reduce --in=$scored_osw --out=$reduced_scored_osw
    """
}
