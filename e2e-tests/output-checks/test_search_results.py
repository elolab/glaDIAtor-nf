import os
from pathlib import Path

from nextflow_log import get_processes_locations_map
from size import assert_size_with_tolerance


def test_comet_search_results_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    comet_search_results_files_parent_locations = processes_locations_map.get("XinteractComet")  # or processes_locations_map.get("{alternative name}")

    assert comet_search_results_files_parent_locations is not None, "Process combining Comet search results into a single file didn't complete"
    assert len(comet_search_results_files_parent_locations) == 1, "There should be exactly one process that produces final results from Comet"
    comet_search_results_file = Path(list(comet_search_results_files_parent_locations)[0]) / 'interact_comet.pep.xml'

    assert_size_with_tolerance(os.path.getsize(comet_search_results_file), 24904216, 0.01,
        "The size of Comet search results file is {relative_size_change}% of a reference")  # size is consistent when run locally, but changes in the pipeline

    # assert calculate_sha256_sum_pep_xml(comet_search_results_file) == "..."


def test_tandem_search_results_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    tandem_search_results_files_parent_locations = processes_locations_map.get("XinteractXTandem")  # or processes_locations_map.get("{alternative name}")

    assert tandem_search_results_files_parent_locations is not None, "Process combining X! Tandem search results into a single file didn't complete"
    assert len(tandem_search_results_files_parent_locations) == 1, "There should be exactly one process that produces final results from X! Tandem"
    tandem_search_results_file = Path(list(tandem_search_results_files_parent_locations)[0]) / 'interact_xtandem.pep.xml'

    assert_size_with_tolerance(os.path.getsize(tandem_search_results_file), 6149964, 0.01,
        "The size of X! Tandem search results file is {relative_size_change}% of a reference")  # size is consistent when run locally, but changes in the pipeline

    # assert calculate_sha256_sum_pep_xml(tandem_search_results_file) == "..."


def test_combined_search_results_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    combined_search_results_files_parent_locations = processes_locations_map.get("CombineSearchResults")  # or processes_locations_map.get("{alternative name}")

    assert combined_search_results_files_parent_locations is not None, "Process combining search results into a single file didn't complete"
    assert len(combined_search_results_files_parent_locations) == 1, "There should be exactly one process that produces final search results"
    combined_search_results_file = Path(list(combined_search_results_files_parent_locations)[0]) / 'lib_iprophet.peps.xml'

    assert_size_with_tolerance(os.path.getsize(combined_search_results_file), 32415672, 0.01,
        "The size of combined search results file is {relative_size_change}% of a reference")  # size is consistent when run locally, but changes in the pipeline

    # assert calculate_sha256_sum_pep_xml(combined_search_results_file) == "..."
