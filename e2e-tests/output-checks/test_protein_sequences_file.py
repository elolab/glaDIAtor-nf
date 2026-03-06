import os
from pathlib import Path

from checksum import calculate_sha256_sum
from nextflow_log import get_processes_locations_map


def test_protein_sequences_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    protein_sequences_files_parent_locations = processes_locations_map.get("BuildFastaDatabase")  # or processes_locations_map.get("{alternative name}")

    assert protein_sequences_files_parent_locations is not None, "The final process producing protein sequence database didn't complete"
    assert len(protein_sequences_files_parent_locations) == 1, "There should be exactly one process that produces protein sequence database (decoys included)"
    protein_sequence_database = Path(list(protein_sequences_files_parent_locations)[0]) / 'DB_with_decoys.fasta'

    assert os.path.getsize(protein_sequence_database) == 27533268, "Size of the protein database changed"
    assert calculate_sha256_sum(protein_sequence_database) == "d5ca85bed379846b5196332de528cde745d016e8a4138ed0afe449249c771bb8", "Checksum of the protein database changed"
