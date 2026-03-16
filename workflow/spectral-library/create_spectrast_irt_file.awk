BEGIN {FS="	"; OFS="	"}
NR==1 {
    for (i=1; i<=NF; i++) {
        f[$i] = i
    }
}
NR>1 { print $(f["PeptideSequence"]), $(f["NormalizedRetentionTime"]) }
