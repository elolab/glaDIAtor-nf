process CreateSpectrastIrtFile {
    input:
    file irt_traml
    file awk_script

    output:
    file ("irt.txt")

    script:
    intermediate_tsv="intermediate_irt.tsv"
    """
    # TargetedFileConverter from OpenMS
    TargetedFileConverter -in $irt_traml -out_type tsv -out $intermediate_tsv
    """ + """  awk "
\$(cat ${awk_script})" """ + "$intermediate_tsv > irt.txt"
}
