include { libgen_method_is_enabled } from '../params.nf'

process OpenSwathWorkflow {
    memory { 16.GB }

    input:
    file dia_mzml_file
    file openswath_transitions
    file swath_truncated_windows
    file irt_traml

    output:
    file dia_osw_file

    script:
    dia_osw_file = "${dia_mzml_file.baseName}-DIA.osw"

    to_execute =
        "OpenSwathWorkflow " +
        "-force " +
        "-in $dia_mzml_file " +
        "-tr $openswath_transitions " +
        "-threads ${task.cpus} " +
        "-min_upper_edge_dist 1 " +
        "-sort_swath_maps " +
        "-out_osw ${dia_osw_file} " + 
        "-swath_windows_file $swath_truncated_windows " +
        params.osw_extra_flags + " "
    
    if (params.use_irt) {
        to_execute +=  "-tr_irt $irt_traml "
    }

    to_execute
}
