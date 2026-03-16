// create mzxml
process MzmlToMzxml {
    input:
    file diafile

    output:
    file "*.mzXML"

    script:
    """
    msconvert $diafile --32 --zlib --filter "peakPicking false 1-" --mzXML
    """
}
