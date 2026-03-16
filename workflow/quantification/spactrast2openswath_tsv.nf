process Spectrast2OpenSwathTsv {
 /*
     Choice parts of sprectrast2.tsv --help
     
     spectrast2tsv.py
     ---------------
     This script is used as filter from spectraST files to swath input files.
     python spectrast2tsv.py [options] spectrast_file(s)
     
     -d                  Remove duplicate masses from labeling
     -e                  Use theoretical mass
     -k    output_key    Select the output provided. Keys available: openswath, peakview. Default: peakview
     -l    mass_limits   Lower and upper mass limits of fragment ions. Example: -l 400,2000
     -s    ion_series    List of ion series to be used. Example: -s y,b

     -w    swaths_file   File containing the swath ranges. This is used to remove transitions with Q3 falling in the swath mass range. (line breaks in windows/unix format)
     -n    int           Max number of reported ions per peptide/z. Default: 20
     -o    int           Min number of reported ions per peptide/z. Default: 3
     -a    outfile       Output file name (default: appends _peakview.txt)
     ,*/
    input:
    file swath_windows  // from swath_windows_ch.first()
    file sptxt  // from consensus_lib_sptxt_ch.first()

    output:
    file consensus_pseudospectra_openswath_library_tsv

    script:
    consensus_pseudospectra_openswath_library_tsv="SpecLib_cons_openswath.tsv"
    """
    MINWINDOW=`head -n1 $swath_windows | cut -d'	' -f1`
    MAXWINDOW=`tail -n1 $swath_windows | cut -d'	' -f2`
    spectrast2tsv.py -l \$MINWINDOW,\$MAXWINDOW -s y,b -d -e -o 6 -n 6 -w $swath_windows -k openswath -a $consensus_pseudospectra_openswath_library_tsv $sptxt
    """
}
