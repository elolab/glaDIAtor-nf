BEGIN {FS="	"; OFS="	"}
# we set the column names so that we can look them up later
NR==1 {
    for (i=1; i<=NF; i++) {
        f[$i] = i
    }
}
# use only the last entry in the table per peptide sequence
NR>1 {
    irt_by_sequence[$(f["PeptideSequence"])] = $(f["NormalizedRetentionTime"])
    peptide_sequences[$(f["PeptideSequence"])]=$(f["PeptideSequence"])
}
END {
    for (sequence in peptide_sequences)
	print(sequence,irt_by_sequence[sequence])
}
