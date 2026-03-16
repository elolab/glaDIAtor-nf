process pyprophet_legacy {
    publishDir "${params.outdir}/pyprophet/", pattern: "*.csv"
    publishDir "${params.outdir}/reports/pyprophet/", pattern: "*.pdf"

    input:
    file dia_tsv

    output:
    file dscore_csv
    file "${dia_tsv.baseName}_report.pdf" 

    script:
    seed="928418756933579397"
    
    dscore_csv="${dia_tsv.baseName}_with_dscore.csv"
    """
    pyprophet --random_seed=${seed} --delim=tab --export.mayu ${dia_tsv} --ignore.invalid_score_columns
    """
}
