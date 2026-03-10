import os
import pandas
from pathlib import Path

# from checksum import calculate_sha256_sum
from nextflow_log import get_processes_locations_map
from size import assert_size_with_tolerance


def test_feature_alignment_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    feature_alignment_files_parent_locations = processes_locations_map.get("feature_alignment")  # or processes_locations_map.get("{alternative name}")

    assert feature_alignment_files_parent_locations is not None, "Feature alignment process didn't complete"
    assert len(feature_alignment_files_parent_locations) == 1, "There should be exactly one process aligning features"

    feature_alignment_file = Path(list(feature_alignment_files_parent_locations)[0]) / 'DIA-analysis-results.csv'
    reference_feature_alignment_file = Path(".cache/expected-protein-peptide-matrices/DIA-analysis-results.csv")

    assert_size_with_tolerance(os.path.getsize(feature_alignment_file), os.path.getsize(reference_feature_alignment_file), 0.05,
        "The size of the file coming from feature alignment is {relative_size_change}% of expected size")

    # assert calculate_sha256_sum(feature_alignment_file) == "..."  # checksum changes every run (even size does)


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

    comparison = protein_matrix.merge(reference_protein_matrix, on=['ProteinName'])[["210820_Grad090_LFQ_A_SubSet.mzML", "210820_Grad090_LFQ_B_SubSet.mzML", "A_subset5.mzML", "B_subset5.mzML"]].sort_index(axis=1)

    acceptable_zeros_percentage = 0.03

    assert (comparison["210820_Grad090_LFQ_A_SubSet.mzML"].eq(0).sum() / comparison["210820_Grad090_LFQ_A_SubSet.mzML"].shape[0]) <= acceptable_zeros_percentage, "The values in protein matrix (sample A) have more zeros than expected"
    assert (comparison["210820_Grad090_LFQ_B_SubSet.mzML"].eq(0).sum() / comparison["210820_Grad090_LFQ_B_SubSet.mzML"].shape[0]) <= acceptable_zeros_percentage, "The values in protein matrix (sample B) have more zeros than expected"

    matrix_values_tolerance = 0.07

    comparison_non_zero = comparison[(comparison != 0).all(axis=1)]
    relative_error_mean = (((comparison_non_zero["210820_Grad090_LFQ_A_SubSet.mzML"] - comparison_non_zero["A_subset5.mzML"]) / comparison_non_zero["A_subset5.mzML"]).mean() + ((comparison_non_zero["210820_Grad090_LFQ_B_SubSet.mzML"] - comparison_non_zero["B_subset5.mzML"]) / comparison_non_zero["B_subset5.mzML"]).mean()) / 2
    assert relative_error_mean <= matrix_values_tolerance, f"The values in protein matrix differ from the reference, relative error mean {round(relative_error_mean * 100, 2)}%"  # this has potential to crash with zeros among values


def test_peptide_matrix():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    peptide_protein_matrices_files_parent_locations = processes_locations_map.get("swath2stats")  # or processes_locations_map.get("{alternative name}")

    assert peptide_protein_matrices_files_parent_locations is not None, "Process generating peptide and protein matrices didn't complete"
    assert len(peptide_protein_matrices_files_parent_locations) == 1, "There should be exactly one process generating peptide and protein matrices"

    peptide_matrix_file = Path(list(peptide_protein_matrices_files_parent_locations)[0]) / 'DIA-peptide-matrix.tsv'
    reference_peptide_matrix_file = Path(".cache/expected-protein-peptide-matrices/DIA-peptide-matrix.tsv")

    assert_size_with_tolerance(os.path.getsize(peptide_matrix_file), os.path.getsize(reference_peptide_matrix_file), 0.01,
        "The size of the peptide matrix file is {relative_size_change}% of expected size")

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
