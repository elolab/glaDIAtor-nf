import os
from statistics import mean
import pandas
from pathlib import Path

from checksum import calculate_sha256_sum
from nextflow_log import get_processes_locations_map
from size import assert_size_with_tolerance


def test_spectral_library_transitions_decoys():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    spectral_library_transitions_decoys_file_parent_locations = processes_locations_map.get("AddDecoysToOpenSwathTransitions")  # or processes_locations_map.get("{alternative name}")

    assert spectral_library_transitions_decoys_file_parent_locations is not None, "Process creating transitions decoys didn't complete"
    assert len(spectral_library_transitions_decoys_file_parent_locations) == 1, "There should be exactly one process creating transition decoys"
    spectral_library_transitions_decoys_file = Path(list(spectral_library_transitions_decoys_file_parent_locations)[0]) / "SpecLib_cons_decoys.pqp"

    assert os.path.getsize(spectral_library_transitions_decoys_file) == 4149248, "The size of transitions decoys file changed."  # 4145152
    assert calculate_sha256_sum(spectral_library_transitions_decoys_file) == "11f3dbd5fcc1e021b1706d815d00e917416c0fb323a1f41d2ab7dd0e396ad87b"


def test_open_swath_workflow_files():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    open_swath_workflow_parent_locations = processes_locations_map.get("OpenSwathWorkflow")  # or processes_locations_map.get("{alternative name}")

    assert open_swath_workflow_parent_locations is not None, "OpenSWATH Workflow process didn't complete"
    assert len(open_swath_workflow_parent_locations) == 2, "There should be exactly two OpenSWATH Workflow processes"

    open_swath_sample_a_output_file = Path(list(open_swath_workflow_parent_locations)[0]) / "210820_Grad090_LFQ_A_SubSet-DIA.osw"
    open_swath_sample_b_output_file = Path(list(open_swath_workflow_parent_locations)[1]) / "210820_Grad090_LFQ_B_SubSet-DIA.osw"

    both_dont_exist = not (open_swath_sample_a_output_file.exists() and open_swath_sample_b_output_file.exists())

    if both_dont_exist:
        open_swath_sample_a_output_file = Path(list(open_swath_workflow_parent_locations)[1]) / "210820_Grad090_LFQ_A_SubSet-DIA.osw"
        open_swath_sample_b_output_file = Path(list(open_swath_workflow_parent_locations)[0]) / "210820_Grad090_LFQ_B_SubSet-DIA.osw"

    assert open_swath_sample_a_output_file.exists(), "OpenSWATH Workflow output file is missing (sample A)"
    assert open_swath_sample_b_output_file.exists(), "OpenSWATH Workflow output file is missing (sample B)"

    assert_size_with_tolerance(os.path.getsize(open_swath_sample_a_output_file), 17997824, 0.01,
        "The size of OpenSWATH workflow output file (sample A) is {relative_size_change}% of expected size")

    assert_size_with_tolerance(os.path.getsize(open_swath_sample_b_output_file), 18014208, 0.01,
        "The size of OpenSWATH workflow output file (sample B) is {relative_size_change}% of expected size")


def test_pyprophet_subsample():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    pyprophet_subsample_parent_locations = processes_locations_map.get("pyprophet_subsample")  # or processes_locations_map.get("{alternative name}")

    assert pyprophet_subsample_parent_locations is not None, "PyProphet \"subsample\" process didn't complete"
    assert len(pyprophet_subsample_parent_locations) == 2, "There should be exactly two PyProphet \"subsample\" processes"

    pyprophet_subsample_sample_a_output_file = Path(list(pyprophet_subsample_parent_locations)[0]) / "210820_Grad090_LFQ_A_SubSet-DIA.osws"
    pyprophet_subsample_sample_b_output_file = Path(list(pyprophet_subsample_parent_locations)[1]) / "210820_Grad090_LFQ_B_SubSet-DIA.osws"

    both_dont_exist = not (pyprophet_subsample_sample_a_output_file.exists() and pyprophet_subsample_sample_b_output_file.exists())

    if both_dont_exist:
        pyprophet_subsample_sample_a_output_file = Path(list(pyprophet_subsample_parent_locations)[1]) / "210820_Grad090_LFQ_A_SubSet-DIA.osws"
        pyprophet_subsample_sample_b_output_file = Path(list(pyprophet_subsample_parent_locations)[0]) / "210820_Grad090_LFQ_B_SubSet-DIA.osws"

    assert pyprophet_subsample_sample_a_output_file.exists(), "PyProphet \"subsample\" output file is missing (sample A)"
    assert pyprophet_subsample_sample_b_output_file.exists(), "PyProphet \"subsample\" output file is missing (sample B)"

    assert_size_with_tolerance(os.path.getsize(pyprophet_subsample_sample_a_output_file), mean([5713920]), 0.02,
        "The size of PyProphet \"subsample\" output file is {relative_size_change}% of expected size")

    assert_size_with_tolerance(os.path.getsize(pyprophet_subsample_sample_b_output_file), mean([5677056]), 0.02,
        "The size of PyProphet \"subsample\" output file is {relative_size_change}% of expected size")


def test_pyprophet_learn_classifier():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    pyprophet_learn_classifier_parent_locations = processes_locations_map.get("pyprophet_learn_classifier")  # or processes_locations_map.get("{alternative name}")

    assert pyprophet_learn_classifier_parent_locations is not None, "PyProphet \"learn classifier\" process didn't complete"
    assert len(pyprophet_learn_classifier_parent_locations) == 1, "There should be exactly one PyProphet \"learn classifier\" process"
    pyprophet_learn_classifier_model_file = Path(list(pyprophet_learn_classifier_parent_locations)[0]) / "model.osw"

    assert_size_with_tolerance(os.path.getsize(pyprophet_learn_classifier_model_file), mean([16990208]), 0.02,
        "The size of PyProphet \"learn classifier\" file is {relative_size_change}% of expected size")


def test_pyprophet_control_error():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    pyprophet_control_error_parent_locations = processes_locations_map.get("pyprophet_control_error")  # or processes_locations_map.get("{alternative name}")

    assert pyprophet_control_error_parent_locations is not None, "PyProphet \"control error\" process didn't complete"
    assert len(pyprophet_control_error_parent_locations) == 1, "There should be exactly one PyProphet \"control error\" process"
    pyprophet_control_error_model_file = Path(list(pyprophet_control_error_parent_locations)[0]) / "model_global.osw"

    assert_size_with_tolerance(os.path.getsize(pyprophet_control_error_model_file), mean([16990208]), 0.02,
        "The size of PyProphet \"control error\" file is {relative_size_change}% of expected size")


def test_pyprophet_backpropagate():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    pyprophet_backpropagate_parent_locations = processes_locations_map.get("pyprophet_backpropagate")  # or processes_locations_map.get("{alternative name}")

    assert pyprophet_backpropagate_parent_locations is not None, "PyProphet \"backpropagate\" process didn't complete"
    assert len(pyprophet_backpropagate_parent_locations) == 2, "There should be exactly two PyProhet \"backpropagate\" processes"

    pyprophet_backpropagate_sample_a_output_file = Path(list(pyprophet_backpropagate_parent_locations)[0]) / "210820_Grad090_LFQ_A_SubSet-DIA.tsv"
    pyprophet_backpropagate_sample_b_output_file = Path(list(pyprophet_backpropagate_parent_locations)[1]) / "210820_Grad090_LFQ_B_SubSet-DIA.tsv"

    both_dont_exist = not (pyprophet_backpropagate_sample_a_output_file.exists() and pyprophet_backpropagate_sample_b_output_file.exists())

    if both_dont_exist:
        pyprophet_backpropagate_sample_a_output_file = Path(list(pyprophet_backpropagate_parent_locations)[1]) / "210820_Grad090_LFQ_A_SubSet-DIA.tsv"
        pyprophet_backpropagate_sample_b_output_file = Path(list(pyprophet_backpropagate_parent_locations)[0]) / "210820_Grad090_LFQ_B_SubSet-DIA.tsv"

    assert_size_with_tolerance(os.path.getsize(pyprophet_backpropagate_sample_a_output_file), mean([4736616]), 0.05,
        "The size of PyProphet \"backpropagate\" file (sample A) is {relative_size_change}% of expected size")

    assert_size_with_tolerance(os.path.getsize(pyprophet_backpropagate_sample_b_output_file), mean([5587238]), 0.05,
        "The size of PyProphet \"backpropagate\" file (sample B) is {relative_size_change}% of expected size")


def test_feature_alignment_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    feature_alignment_files_parent_locations = processes_locations_map.get("feature_alignment")  # or processes_locations_map.get("{alternative name}")

    assert feature_alignment_files_parent_locations is not None, "Feature alignment process didn't complete"
    assert len(feature_alignment_files_parent_locations) == 1, "There should be exactly one process aligning features"

    feature_alignment_file = Path(list(feature_alignment_files_parent_locations)[0]) / 'DIA-analysis-results.csv'
    reference_feature_alignment_file = Path(".cache/expected-protein-peptide-matrices/DIA-analysis-results.csv")

    assert_size_with_tolerance(os.path.getsize(feature_alignment_file), os.path.getsize(reference_feature_alignment_file), 0.05,
        "The size of the file coming from feature alignment is {relative_size_change}% of expected size")


def test_protein_matrix():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    peptide_protein_matrices_files_parent_locations = processes_locations_map.get("swath2stats")  # or processes_locations_map.get("{alternative name}")

    assert peptide_protein_matrices_files_parent_locations is not None, "Process generating peptide and protein matrices didn't complete"
    assert len(peptide_protein_matrices_files_parent_locations) == 1, "There should be exactly one process generating peptide and protein matrices"

    protein_matrix_file = Path(list(peptide_protein_matrices_files_parent_locations)[0]) / 'DIA-protein-matrix.tsv'
    reference_protein_matrix_file = Path(".cache/expected-protein-peptide-matrices/DIA-protein-matrix.tsv")

    assert_size_with_tolerance(os.path.getsize(protein_matrix_file), os.path.getsize(reference_protein_matrix_file), 0.01,
        "The size of protein matrix file is {relative_size_change}% of expected size")

    # assert calculate_sha256_sum(protein_matrix_file) == ".."  # checksum changes every run (even size does)

    protein_matrix = pandas.read_csv(protein_matrix_file, sep="\t")
    reference_protein_matrix = pandas.read_csv(reference_protein_matrix_file, sep="\t")

    #
    # Compare number of matching protein names, both the total number and a number that overlaps with the reference

    protein_count = len(set(protein_matrix["ProteinName"]))
    reference_protein_count = len(set(reference_protein_matrix["ProteinName"]))
    overlapping_protein_count = len(set(protein_matrix["ProteinName"]) & set(reference_protein_matrix["ProteinName"]))

    name_overlap_tolerance = 0.01
    name_count_tolerance = 0.01

    assert overlapping_protein_count >= reference_protein_count * (1 - name_overlap_tolerance) and protein_count <= reference_protein_count * (1 + name_count_tolerance), \
        f"Number of peptides in peptide matrix is {round(protein_count / reference_protein_count * 100)}% of expected number, reference overlaps at {round(overlapping_protein_count / reference_protein_count * 100)}%"

    #
    # Compare values per protein, per sample

    comparison = protein_matrix.merge(reference_protein_matrix, on=['ProteinName'])[["210820_Grad090_LFQ_A_SubSet.mzML_x", "210820_Grad090_LFQ_B_SubSet.mzML_x", "210820_Grad090_LFQ_A_SubSet.mzML_y", "210820_Grad090_LFQ_B_SubSet.mzML_y"]].sort_index(axis=1)
    acceptable_zeros_percentage = 0.03

    assert (comparison["210820_Grad090_LFQ_A_SubSet.mzML_x"].eq(0).sum() / comparison["210820_Grad090_LFQ_A_SubSet.mzML_x"].shape[0]) <= acceptable_zeros_percentage, "The values in protein matrix (sample A) have more zeros than expected"
    assert (comparison["210820_Grad090_LFQ_B_SubSet.mzML_x"].eq(0).sum() / comparison["210820_Grad090_LFQ_B_SubSet.mzML_x"].shape[0]) <= acceptable_zeros_percentage, "The values in protein matrix (sample B) have more zeros than expected"

    matrix_values_tolerance = 0.05

    comparison_non_zero = comparison[(comparison != 0).all(axis=1)]
    relative_error_mean = (((comparison_non_zero["210820_Grad090_LFQ_A_SubSet.mzML_x"] - comparison_non_zero["210820_Grad090_LFQ_A_SubSet.mzML_y"]) / comparison_non_zero["210820_Grad090_LFQ_A_SubSet.mzML_y"]).mean() + ((comparison_non_zero["210820_Grad090_LFQ_B_SubSet.mzML_x"] - comparison_non_zero["210820_Grad090_LFQ_B_SubSet.mzML_y"]) / comparison_non_zero["210820_Grad090_LFQ_B_SubSet.mzML_y"]).mean()) / 2
    assert relative_error_mean <= matrix_values_tolerance, f"The values in protein matrix differ from the reference, relative error mean {round(relative_error_mean * 100, 2)}%"  # this has potential to crash with zeros among values


def test_peptide_matrix():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    peptide_protein_matrices_files_parent_locations = processes_locations_map.get("swath2stats")  # or processes_locations_map.get("{alternative name}")

    assert peptide_protein_matrices_files_parent_locations is not None, "Process generating peptide and protein matrices didn't complete"
    assert len(peptide_protein_matrices_files_parent_locations) == 1, "There should be exactly one process generating peptide and protein matrices"

    peptide_matrix_file = Path(list(peptide_protein_matrices_files_parent_locations)[0]) / 'DIA-peptide-matrix.tsv'
    reference_peptide_matrix_file = Path(".cache/expected-protein-peptide-matrices/DIA-peptide-matrix.tsv")

    assert_size_with_tolerance(os.path.getsize(peptide_matrix_file), os.path.getsize(reference_peptide_matrix_file), 0.01,
        "The size of peptide matrix file is {relative_size_change}% of expected size")

    peptide_matrix = pandas.read_csv(peptide_matrix_file, sep="\t")
    reference_peptide_matrix = pandas.read_csv(reference_peptide_matrix_file, sep="\t")

    #
    # Compare number of matching peptide names, both the total number and a number that overlaps with the reference

    peptide_count = len(set(peptide_matrix["ProteinName_FullPeptideName"]))
    reference_peptide_count = len(set(reference_peptide_matrix["ProteinName_FullPeptideName"]))
    overlapping_peptide_count = len(set(peptide_matrix["ProteinName_FullPeptideName"]) & set(reference_peptide_matrix["ProteinName_FullPeptideName"]))

    name_overlap_tolerance = 0.01
    name_count_tolerance = 0.01

    assert overlapping_peptide_count >= reference_peptide_count * (1 - name_overlap_tolerance) and peptide_count <= reference_peptide_count * (1 + name_count_tolerance), \
        f"Number of peptides in peptide matrix is {round(peptide_count / reference_peptide_count * 100)}% of expected number, reference overlaps at {round(overlapping_peptide_count / reference_peptide_count * 100)}%"
