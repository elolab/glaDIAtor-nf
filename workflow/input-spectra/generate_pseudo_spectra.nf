// MGF = Mascot Generic Format
// https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3518119

process GeneratePseudoSpectra  {
    memory '16 GB'

    input:
    file diafile
    path diaumpireconfig

    output:
    file "*.mgf"

    script:
    """
    # we set \$1 to the number of gigs of memory
    set -- $task.memory

    if command -v diaumpire-se; then
        diaumpire-se  -Xmx\$1g -Xms\$1g $diafile $diaumpireconfig
    else 
        java -Xmx\$1g -Xms\$1g -jar /opt/dia-umpire/DIA_Umpire_SE.jar $diafile $diaumpireconfig
    fi
    """
}
