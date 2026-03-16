process XinteractXTandem {
    memory '16 GB'

    input:
    file pepxmls
    file fastadb_with_decoy
    file mzxmls

    output: 
    file "interact_xtandem.pep.xml"

    when:
    pepxmls.size() > 0 

    script:
    """
    xinteract -a\$PWD -OARPd -dDECOY_ -Ninteract_xtandem.pep.xml $pepxmls
    """
}
