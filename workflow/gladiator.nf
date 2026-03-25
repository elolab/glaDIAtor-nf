include { readSDRF } from './input-metadata/sdrf-params.nf'

include { DiaUmpireMgfToMzxml } from './input-spectra/dia_umpire_mgf_to_mzxml.nf'
include { GeneratePseudoSpectra } from './input-spectra/generate_pseudo_spectra.nf'
include { MzmlToMzxml } from './input-spectra/mzml_to_mzxml.nf'

include { BuildFastaDatabase } from './protein-sequences/build_fasta_database.nf'
include { JoinFastaFiles } from './protein-sequences/join_fasta_files.nf'

include { AddDecoysToOpenSwathTransitions } from './quantification/add_decoys_to_openswath_transitions.nf'
include { feature_alignment } from './quantification/feature_alignment.nf'
include { OpenSwathWorkflow_legacy } from './quantification/openswathworkflow_legacy.nf'
include { OpenSwathWorkflow } from './quantification/openswathworkflow.nf'
include { pyprophet_legacy } from './quantification/pyprophet_legacy.nf'
include { pyprophet_subsample } from './quantification/pyprophet_subsample.nf'
include { pyprophet_apply_classifier } from './quantification/pyprophet_apply_classifier.nf'
include { pyprophet_backpropagate } from './quantification/pyprophet_backpropagate.nf'
include { pyprophet_control_error } from './quantification/pyprophet_control_error.nf'
include { pyprophet_learn_classifier } from './quantification/pyprophet_learn_classifier.nf'
include { pyprophet_reduce } from './quantification/pyprophet_reduce.nf'
include { Spectrast2OpenSwathTsv } from './quantification/spactrast2openswath_tsv.nf'
include { swath2stats } from './quantification/swath2stats.nf'

include { Comet } from './search/comet/comet.nf'
include { MakeCometConfig } from './search/comet/make_comet_config.nf'
include { XinteractComet } from './search/comet/xinteract_comet.nf'
include { MakeXtandemConfig } from './search/tandem/make_xtandem_config.nf'
include { XinteractXTandem } from './search/tandem/xinteract_xtandem.nf'
include { XTandem } from './search/tandem/xtandem.nf'
include { CombineSearchResults } from './search/combine_search_results.nf'

include { CreateSpectrastIrtFile } from './spectral-library/create_spectrast_irt_file.nf'
include { FindMinimumPeptideProbability } from './spectral-library/find_minium_peptide_probability.nf'
include { SpectrastCreateSpecLib } from './spectral-library/spectrast_create_speclib.nf'

include { InferNonOverlappingSwathWindows } from './swath-windows/infer_non_overlapping_swath_windows.nf'
include { InferSwathWindows } from './swath-windows/infer_swath_windows.nf'
include { RegularizeUserSwathWindow } from './swath-windows/regularize_user_swath_window.nf'

def ensureList(param) {
    if (!param) { return [] }
    if (param instanceof String) { return param.split(",") }

    return param
}

workflow {
    //
    // SDRF metadata
    //
    // Retrieve 'precursor_mass_tolerance', 'fragment_mass_tolerance' and 'diafiles' parameters from '.sdr' metadata file.

    if (params.sdrf) {
        params = readSDRF(params.sdrf, params) + params
    }

    //
    // Protein sequences
    //
    // Concatenate .fasta files with sequences and add decoys

    fasta_files_ch = channel.fromPath(params.fastafiles)
        .ifEmpty { error("No sequence files found at ${params.fastafiles}") }
        .toSortedList()
        .flatMap()

    combined_fasta_file_ch = JoinFastaFiles(fasta_files_ch.collect())

    joined_fasta_with_decoys_ch = BuildFastaDatabase(combined_fasta_file_ch)

    //
    // DIA spectra

    dia_mzml_files_ch = channel.fromPath(params.diafiles)
        .ifEmpty { error("No DIA files found at ${params.diafiles}") }
        .toSortedList()
        .flatMap()

    //
    // SWATH windows
    //
    // SWATH windows can be found in mzML under '/mzML/run/spectrumList/spectrum[cvParam]'.
    // FAIMS-split (Field Asymmetric Ion Mobility Spectrometry) mzML files might be missing information about SWATH windows.
    // In such case user can provide own tab-separated file of SWATH windows.

    if (params.swath_windows_file) {
        if (!file(params.swath_windows_file).exists()) {
            error("No SWATH windows file found at ${params.swath_windows_file}")
        }

        user_swath_windows_file_ch = channel.fromPath(params.swath_windows_file)
        swath_windows_file_ch = RegularizeUserSwathWindow(user_swath_windows_file_ch)
    } else {
        // SWATH windows are read from the first sample file
        swath_windows_file_ch = InferSwathWindows(dia_mzml_files_ch.first())
    }


    infer_non_overlapping_swath_windows_awk_script = channel.fromPath("${workflow.projectDir}/swath-windows/infer_non_overlapping_swath_windows.awk")
    truncated_swath_windows_ch = InferNonOverlappingSwathWindows(swath_windows_file_ch, infer_non_overlapping_swath_windows_awk_script)

    //
    // Spectral library
    //
    // The default behavior of glaDIAtor-nf is to build spectral library from DIA data with DIA-Umpire through deconvolution.
    // Optionally DDA spectra can be used together or instead of deconvoluted DIA spectra.
    //
    // Alternatively a spectral library can be provided. This disables library generation.

    if (ensureList(params.libgen_method).contains('custom')) {
        speclib_tsv_for_decoys = channel.fromPath(params.speclib)
    } else {
        dda_files_ch = channel.empty()
        diaumpire_pseudospectra_ch = channel.empty()

        if (ensureList(params.libgen_method).contains('dda')) {
            dda_files_ch = channel.fromPath(params.ddafiles)
        }

        if (ensureList(params.libgen_method).contains('diaumpire')) {
            dia_mzml_files_for_diaumpire_ch = channel.fromPath(params.diafiles)
            diaumpire_config_ch = channel.fromPath(params.diaumpireconfig ? params.diaumpireconfig : "${workflow.projectDir}/../config/diaumpire.params")

            dia_mzxml_files_for_diaumpire_ch = MzmlToMzxml(dia_mzml_files_for_diaumpire_ch)
            dia_mzxml_sample_count = dia_mzxml_files_for_diaumpire_ch.toList().size()

            diaumpire_pseudospectra_mgf_ch = GeneratePseudoSpectra(
                dia_mzxml_files_for_diaumpire_ch,
                diaumpire_config_ch.combine(dia_mzxml_files_for_diaumpire_ch).map { it -> it[0] },
                dia_mzxml_sample_count
            ).flatten()  // single .mzXML gives multiple .mgf files

            diaumpire_pseudospectra_ch = DiaUmpireMgfToMzxml(diaumpire_pseudospectra_mgf_ch)
        }

        // Deconvoluted DIA pseudospectra and input DDA spectra
        spectra_files_ch = dda_files_ch.concat(diaumpire_pseudospectra_ch)

        //
        // MS/MS spectra vs sequences database search engines
        //
        // Comet and X! Tandem

        max_missed_cleavages_val = channel.value(params.max_missed_cleavages)

        // Comet

        comet_template_ch = channel.fromPath(params.comet_template ? params.comet_template : "${workflow.projectDir}/../config/comet.params")
        spectra_files_count = spectra_files_ch.toList().size()
        comet_config_ch = MakeCometConfig(max_missed_cleavages_val, joined_fasta_with_decoys_ch, comet_template_ch, spectra_files_count)

        (comet_pepxml_ch, xinteract_comet_mzxml_ch) = Comet(
            comet_config_ch.combine(spectra_files_ch).map { it -> it[0] },
            spectra_files_ch,
            joined_fasta_with_decoys_ch.combine(spectra_files_ch).map { it -> it[0] }
        )

        comet_search_results_ch = XinteractComet(comet_pepxml_ch.toSortedList(), joined_fasta_with_decoys_ch, xinteract_comet_mzxml_ch.toSortedList())

        // X! Tandem

        xtandem_template_ch = channel.fromPath(params.xtandem_template ? params.xtandem_template : "${workflow.projectDir}/../config/xtandem.xml")
        xtandem_config_ch = MakeXtandemConfig(xtandem_template_ch, joined_fasta_with_decoys_ch, max_missed_cleavages_val, spectra_files_count)

        taxonomy_template = channel.fromPath("${workflow.projectDir}/search/tandem/taxonomy-template.xml")
        xtandem_input_template = channel.fromPath("${workflow.projectDir}/search/tandem/xtandem-input-template.xml")

        (xtandem_pepxml_ch, xinteract_xtandem_mzxml_ch) = XTandem(
            spectra_files_ch,
            xtandem_config_ch.combine(spectra_files_ch).map { it -> it[0] },
            taxonomy_template.combine(spectra_files_ch).map { it -> it[0] },
            xtandem_input_template.combine(spectra_files_ch).map { it -> it[0] },
            joined_fasta_with_decoys_ch.combine(spectra_files_ch).map { it -> it[0] }
        )

        xtandem_search_results_ch = XinteractXTandem(
            xtandem_pepxml_ch.collect(),
            joined_fasta_with_decoys_ch,
            xinteract_xtandem_mzxml_ch.collect()
        )

        // Combine search results

        if (params.search_engines.size() > 1) {  
            combined_search_results_ch = CombineSearchResults(xtandem_search_results_ch, comet_search_results_ch)
        } else if (params.search_engines.contains("comet")) {
            combined_search_results_ch = comet_search_results_ch
        } else if (params.search_engines.contains("xtandem")) {
            combined_search_results_ch = xtandem_search_results_ch
        } else {
            combined_search_results_ch = channel.empty()
        }

        //
        // Build spectral library

        minimum_peptide_probability_val = FindMinimumPeptideProbability(combined_search_results_ch, joined_fasta_with_decoys_ch, max_missed_cleavages_val).map { it -> it.text.trim() }

        if (params.use_irt) {
            irt_traml_ch = channel.fromPath(params.irt_traml_file)
            create_spectrast_irt_file_awk_script = channel.fromPath("${workflow.projectDir}/spectral-library/create_spectrast_irt_file.awk")

            irt_txt_ch = CreateSpectrastIrtFile(irt_traml_ch, create_spectrast_irt_file_awk_script)
        } else {
            irt_txt_ch = channel.fromPath("${workflow.projectDir}/dummy")
        }

        consensus_lib_sptxt_ch = SpectrastCreateSpecLib(irt_txt_ch, combined_search_results_ch, joined_fasta_with_decoys_ch, minimum_peptide_probability_val)
        speclib_tsv_for_decoys = Spectrast2OpenSwathTsv(swath_windows_file_ch, consensus_lib_sptxt_ch)
    }

    //
    // Quantification
    //

    if(params.oswdg_min_decoy_fraction != null) { 
        oswdg_args = channel.value("-min_decoy_fraction ${params.oswdg_min_decoy_fraction}")
    } else {
        oswdg_args = channel.value("")
    }

    if (params.use_irt) {
        irt_traml_for_prophet_ch = channel.fromPath(params.irt_traml_file)
    } else {
        irt_traml_for_prophet_ch = channel.fromPath("${workflow.projectDir}/dummy")
    }

    openswath_transitions_ch = AddDecoysToOpenSwathTransitions(speclib_tsv_for_decoys, oswdg_args)

    if (params.pyprophet_use_legacy) {
        openswath_tsv_ch = OpenSwathWorkflow_legacy(dia_mzml_files_ch, openswath_transitions_ch, truncated_swath_windows_ch, irt_traml_for_prophet_ch)
    } else {
        openswath_osw_ch = OpenSwathWorkflow(
            dia_mzml_files_ch,
            openswath_transitions_ch.combine(dia_mzml_files_ch).map { it -> it[0] },
            truncated_swath_windows_ch.combine(dia_mzml_files_ch).map { it -> it[0] },
            irt_traml_for_prophet_ch.combine(dia_mzml_files_ch).map { it -> it[0] }
        )
    }

    if (params.pyprophet_use_legacy) {
        (pyprophet_legacy_ch, _pyprophet_report_ch) = pyprophet_legacy(openswath_tsv_ch)
    } else {
        if (params.pyprophet_subsample_ratio == null) {
            subsample_ratio = channel.fromPath(params.diafiles).count().map { n -> 1 / Math.max(n, 1) }
        } else {
            subsample_ratio = channel.value(params.pyprophet_subsample_ratio)
        }

        subsampled_osw = pyprophet_subsample(openswath_osw_ch, subsample_ratio)
        osw_model = pyprophet_learn_classifier(subsampled_osw.toSortedList(), openswath_transitions_ch.toSortedList())

        scored_osw_ch = pyprophet_apply_classifier(
            osw_model.combine(openswath_osw_ch).map { it -> it[0] },
            openswath_osw_ch
        )

        reduced_scored_osw = pyprophet_reduce(scored_osw_ch)
        osw_global_model = pyprophet_control_error(reduced_scored_osw.toSortedList(), osw_model)

        pyprophet_nonlegacy_ch = pyprophet_backpropagate(
            scored_osw_ch,
            osw_global_model.combine(scored_osw_ch).map { it -> it[0] }
        )
    }

    if (params.pyprophet_use_legacy) {
        pyprophet_ch = pyprophet_legacy_ch
    } else {
        pyprophet_ch = pyprophet_nonlegacy_ch
    }

    feature_alignment_ch = feature_alignment(pyprophet_ch.toSortedList())

    swath2stats_r_script = channel.fromPath("${workflow.projectDir}/quantification/swath2stats.R")
    (peptide_matrix, protein_matrix) = swath2stats(feature_alignment_ch, swath2stats_r_script)

    peptide_matrix.view()
    protein_matrix.view()
}
