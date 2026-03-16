process JoinFastaFiles {
    input:
    path fasta_files

    output:
    path "joined_database.fasta"

    script:
    """
    #!/usr/bin/env python3

    from Bio import SeqIO

    def join_fasta_files(input_files, output_file):
        IDs = set()
        seqRecords = []

        for filename in input_files:
            records = SeqIO.index(filename, "fasta")
            for ID in records:
                if ID not in IDs:
                    seqRecords.append(records[ID])
                    IDs.add(ID)
                else:
                    print("Found duplicated sequence ID " + str(ID) + ", skipping this sequence from file " + filename)

        SeqIO.write(seqRecords, output_file, "fasta")

    join_fasta_files("$fasta_files".split(" "), 'joined_database.fasta')
    """
}
