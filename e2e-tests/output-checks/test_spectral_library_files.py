import os
from pathlib import Path

from checksum import calculate_sha256_sum, calculate_sha256_sum_excluding_lines
from nextflow_log import get_processes_locations_map
from size import assert_size_with_tolerance


def test_spectral_library_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    spectral_library_files_parent_locations = processes_locations_map.get("SpectrastCreateSpecLib")  # or processes_locations_map.get("{alternative name}")

    assert spectral_library_files_parent_locations is not None, "Process creating spectral library didn't complete"
    assert len(spectral_library_files_parent_locations) == 1, "There should be exactly one process creating spectral library"
    spectral_library_file = Path(list(spectral_library_files_parent_locations)[0]) / 'SpecLib.splib'

    spectral_library_file_size = os.path.getsize(spectral_library_file)

    assert_size_with_tolerance(
        spectral_library_file_size, reference_size=34102009, size_tolerance=0.01,
        message="The size of spectral library file is {relative_size_change}% of expected size"
    )

    spectral_library_summary = Path(list(spectral_library_files_parent_locations)[0]) / 'SpecLib.sptxt'

    assert calculate_sha256_sum_excluding_lines(spectral_library_summary, [
        "### IMPORT FROM PepXML",
        "Comment: "
    ]) == "de2ca63a6b78fb53a15cd493255e9698ad2ce8c67f32bc5b001aad89f0c3d270"


def test_spectral_library_tsv_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    spectral_library_tsv_file_parent_locations = processes_locations_map.get("Spectrast2OpenSwathTsv")  # or processes_locations_map.get("{alternative name}")

    assert spectral_library_tsv_file_parent_locations is not None, "Process creating spectral library didn't complete"
    assert len(spectral_library_tsv_file_parent_locations) == 1, "There should be exactly one process creating spectral library"
    spectral_library_tsv_file = Path(list(spectral_library_tsv_file_parent_locations)[0]) / "SpecLib_cons_openswath.tsv"

    assert os.path.getsize(spectral_library_tsv_file) == 3709748, "The size of spectral library .tsv file changed."
    assert calculate_sha256_sum(spectral_library_tsv_file) == "f0de1fe92693eca9e8cc0bae357bb847670289cac066a18b86cd7da44b33a694"
