process XTandem {
    input:
    file mzxml
    file tandem_config
    path taxonomy_template
    path xtandem_input_template
    file fastadb_with_decoy

    output:
    file("${mzxml.baseName}.tandem.pep.xml")
    file mzxml

    when:
    params.search_engines.contains("xtandem")

    script:
    """
    printf "
\$(cat $taxonomy_template)
" $fastadb_with_decoy | tail -n+2 > xtandem_taxonomy.xml
    
    printf "
\$(cat $xtandem_input_template)
" $tandem_config xtandem_taxonomy.xml $mzxml ${mzxml.baseName}.TANDEM.OUTPUT.xml | tail -n+2 > input.xml

    tandem input.xml
    Tandem2XML ${mzxml.baseName}.TANDEM.OUTPUT.xml ${mzxml.baseName}.tandem.pep.xml 
    """
}
