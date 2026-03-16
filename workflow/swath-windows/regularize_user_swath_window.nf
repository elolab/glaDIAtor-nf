process RegularizeUserSwathWindow {
    input:
    path user_swath_windows, stageAs: "user-swath-windows.txt"

    output:
    path "swath-windows.txt"

    script:
    """
    # The input columns can be separated by spaces or tabs, but the output file is always tab-separated.
    sort -n $user_swath_windows | awk 'BEGIN {OFS="	"} {print \$1,\$2}' > "swath-windows.txt"
    """
}
