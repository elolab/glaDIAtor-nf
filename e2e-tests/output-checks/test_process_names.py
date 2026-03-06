import difflib
from nextflow_log import get_process_names


def show_difference_multiple(expected, given, message):
    for name, expected_entry in expected.items():
        print(message.format(name=name))

        for line in difflib.ndiff(expected_entry, given):
            if line.startswith("+") or line.startswith("-"):
                print(line)

        print()


expected_process_names_variants = {
    "Mats' DSL1 glaDIAtor-nf": [
        'AddDecoysToOpenSwathTransitions', 'BuildFastaDatabase', 'CombineSearchResults', 'Comet', 'Comet', 'Comet', 'Comet', 'Comet', 'Comet', 'CreateSpectrastIrtFile', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'FindMinimumPeptideProbability', 'GeneratePseudoSpectra', 'GeneratePseudoSpectra', 'InferNonOverlappingSwathWindows', 'InferSwathWindows', 'JoinFastaFiles', 'MakeCometConfig', 'MakeXtandemConfig', 'MzmlToMzxml', 'MzmlToMzxml', 'OpenSwathWorkflow', 'OpenSwathWorkflow', 'Spectrast2OpenSwathTsv', 'SpectrastCreateSpecLib', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XinteractComet', 'XinteractXTandem', 'feature_alignment', 'pyprophet_apply_classifier', 'pyprophet_apply_classifier', 'pyprophet_backpropagate', 'pyprophet_backpropagate', 'pyprophet_control_error', 'pyprophet_learn_classifier', 'pyprophet_reduce', 'pyprophet_reduce', 'pyprophet_subsample', 'pyprophet_subsample', 'swath2stats'
    ],
    "Mats' DSL1 glaDIAtor-nf (SWATH windows provided)": [
        'AddDecoysToOpenSwathTransitions', 'BuildFastaDatabase', 'CombineSearchResults', 'Comet', 'Comet', 'Comet', 'Comet', 'Comet', 'Comet', 'CreateSpectrastIrtFile', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'DiaUmpireMgfToMzxml', 'FindMinimumPeptideProbability', 'GeneratePseudoSpectra', 'GeneratePseudoSpectra', 'InferNonOverlappingSwathWindows', 'JoinFastaFiles', 'MakeCometConfig', 'MakeXtandemConfig', 'MzmlToMzxml', 'MzmlToMzxml', 'OpenSwathWorkflow', 'OpenSwathWorkflow', 'RegularizeUserSwathWindow', 'Spectrast2OpenSwathTsv', 'SpectrastCreateSpecLib', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XTandem', 'XinteractComet', 'XinteractXTandem', 'feature_alignment', 'pyprophet_apply_classifier', 'pyprophet_apply_classifier', 'pyprophet_backpropagate', 'pyprophet_backpropagate', 'pyprophet_control_error', 'pyprophet_learn_classifier', 'pyprophet_reduce', 'pyprophet_reduce', 'pyprophet_subsample', 'pyprophet_subsample', 'swath2stats'
    ]
}


def test_process_names():
    process_names = get_process_names(".nextflow.log")

    assert any(process_names == expected_process_names for expected_process_names in expected_process_names_variants.values()), \
        show_difference_multiple(expected_process_names_variants, process_names, "List of processes doesn't match variant {name}")
