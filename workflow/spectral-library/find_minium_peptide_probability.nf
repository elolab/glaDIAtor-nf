// > Mayu is a software package for the analysis of (large) mass spectrometry-based shotgun proteomics data sets. Mayu determines protein identification false discovery rates (protFDR), peptide identification false discovery rates (pepFDR) and peptide-spectrum match false discovery rates (mFDR) [...].
// https://github.com/proteomics-mayu/mayu
// doi:10.5167/uzh-28712, doi:10.1074/mcp.M900317-MCP200

// Here is what happens in mayu:
// For a pepxml file with peptide-spectrum-matches 'PSM'
// (type of '(spectrum,peptide,probability)', where the probality is based on the similarity of the theoratical spectrum,
// mayu determines the peptide-spectrum-match False Detection Rate ('mFDR'),
// and protein identification false discovery rates ('protFDR').
// We select a 'protFDR' for which mayu finds a matching 'mFDR' level (no higher than the '-G' flag) and it will filter
// everything with a higher mFDR level
// In the output csv the 'score' column is the the 'probability' in PSM (in mayu documentation "discrimant")

// We find the lowest 'probability' that still has an 'mFDR' that matched the above,
// and that is what we use as the filtering criterian in spectrast

// This is what we will than filter on with specrtrast

// Hmhf why can't mayu return deterministic filenames.
// (It incorporates the mayu version number in the filename grumbl),
// it follows the pattern

// ```perl
// my $psm_file_base = $out_base . '_psm_';
// my $id_csv_file = $psm_file_base
//                 . $fdr_type
//                 . $fdr_value . '_'
//                 . $target_decoy . '_'
//                 . $version . '.csv';
// ```

// Note that sort requires '$TMPDIR' to actually exists and be writable,
// '$TMPDIR' (the envvar) is inherited from the parent env when run in a container,
// but not mounted (at least not in Singularity), so if '$TMPDIR' does not exist in the container, this will crash.

process FindMinimumPeptideProbability {
    input: 
    file combined_search_results
    file fastadb_with_decoy
    val max_missed_cleavages

    output:
    file "minimum_peptide_probability.txt"

    /* explanation of paramaters
     -G  $params.protFDR            | maximum allowed mFDR of $params.protFDR 
     -P protFDR=$params.protFDR:t   |  print out PSMs of targets who have a protFDR of $params.protFDR
     -
     -H | defines the resolution of error analysis (mFDR steps)
     -I number of missed cleavages used for database search
     -M | file name base */
    script:
    prefix="filtered"
    // you can change this to a glob-pattern (e.g. "*") for future-proofing
    mayu_version="1.07"
    psm_csv="${prefix}_psm_protFDR${params.protFDR}_t_${mayu_version}.csv"
    """
    Mayu.pl -verbose -A $combined_search_results -C $fastadb_with_decoy -E DECOY_ -G $params.protFDR -P protFDR=${params.protFDR}:t -H 51 -I $max_missed_cleavages -M $prefix

    # test if psm_csv was made
    test -e $psm_csv || exit 1

    # test if the results arent empty
    test \$(wc -l $psm_csv | cut -d' ' -f1) -gt 1 || exit 1 
    PEPTIDEPROBABILITY=\$(cat $psm_csv | cut -f 5 -d ',' |tail -n+2 |sort -u | head -n1)

    echo "\${PEPTIDEPROBABILITY}" > minimum_peptide_probability.txt
    """
}
