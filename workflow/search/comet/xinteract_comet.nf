process XinteractComet {
    memory '16 GB'
    time '5h'

    input:
    file pepxmls
    file fastadb_with_decoy
    file mzxmls

    output: 
    file "interact_comet.pep.xml"

    when:
    pepxmls.size() > 0

    script:
    """
    xinteract -a\$PWD -OARPd -dDECOY_ -Ninteract_comet.pep.xml $pepxmls
    """
}
