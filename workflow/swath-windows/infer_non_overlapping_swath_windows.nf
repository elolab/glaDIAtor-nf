process InferNonOverlappingSwathWindows {
    input:
    file swath_windows
    path awk_script

    output:
    file truncated_swath_windows

    script:
    truncated_swath_windows="truncated_swath_windows.txt"
    """ awk "\$(cat $awk_script)" """ + "$swath_windows > $truncated_swath_windows"
}
