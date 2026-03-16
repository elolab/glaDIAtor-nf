process BuildFastaDatabase {
    input:
    file joined_fasta_db

    output:
    file "DB_with_decoys.fasta"

    script:
    """
    DecoyDatabase -in $joined_fasta_db -out DB_with_decoys.fasta
    """
}
