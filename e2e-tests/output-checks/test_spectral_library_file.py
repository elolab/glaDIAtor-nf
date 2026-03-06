import os
from pathlib import Path

# from checksum import calculate_sha256_sum
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
        spectral_library_file_size, reference_size=50143255, size_tolerance=0.01,
        message="The size of spectral library file is {relative_size_change}% of expected size"
    )

    # assert os.path.getsize(spectral_library_file) == 50143255  # size is consistent locally, but varies sligtly in the pipelines
    # assert calculate_sha256_sum(spectral_library_file) == "..."  # checksum changes every run
