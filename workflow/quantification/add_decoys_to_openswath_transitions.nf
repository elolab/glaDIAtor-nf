process AddDecoysToOpenSwathTransitions {
    input:
    file speclib_tsv
    val oswdg_args

    output:
    file outputfile

    script:
    outputfile="SpecLib_cons_decoys.pqp"
    """
    TargetedFileConverter -in $speclib_tsv -out SpecLib_cons.TraML
    OpenSwathDecoyGenerator -decoy_tag DECOY_ -in SpecLib_cons.TraML -out $outputfile -method reverse $oswdg_args
    """
}
