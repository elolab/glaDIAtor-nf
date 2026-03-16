process swath2stats {
    publishDir "${params.outdir}/dia/"

    input:
    file dia_score
    file r_script
    
    output:
    file peptide_matrix
    file protein_matrix
    
    script:
    strict_checking = params.swath2stats_strict_checking
    peptide_matrix = "DIA-peptide-matrix.tsv"
    protein_matrix = "DIA-protein-matrix.tsv"
    """
    #!/usr/bin/env Rscript
    
    source("${r_script}")
    
    main(
        "${dia_score}",
        strict_checking = as.logical("$strict_checking"),
        peptideoutputfile="${peptide_matrix}",
        proteinoutputfile="${protein_matrix}",
        decoyprefix="DECOY_"
    )
    """
}
