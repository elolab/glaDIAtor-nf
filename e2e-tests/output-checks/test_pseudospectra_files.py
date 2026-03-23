import os
from pathlib import Path

from checksum import calculate_sha256_sum
from nextflow_log import get_processes_locations_map


def test_protein_sequences_file():
    processes_locations_map = get_processes_locations_map(".nextflow.log")
    pseudospectra_files_parent_locations = processes_locations_map.get("GeneratePseudoSpectra")  # or processes_locations_map.get("{alternative name}")

    assert pseudospectra_files_parent_locations is not None, "DIA-Umpire process didn't complete"
    assert len(pseudospectra_files_parent_locations) == 2, "There should be one DIA-Umpire process per sample (two in total)"

    unsorted_mgfs: list[Path] = []

    for location in pseudospectra_files_parent_locations:
        unsorted_mgfs.extend(list(Path(location).rglob("*.mgf")))

    mgfs = sorted(unsorted_mgfs, key=lambda path: path.name)

    mgfs_sizes = { str(mgf).split("/")[-1]: os.path.getsize(mgf) for mgf in mgfs }
    mgfs_sha256_sums = { str(mgf).split("/")[-1]: calculate_sha256_sum(mgf) for mgf in mgfs }

    assert (mgfs_sizes == {
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': 22096869,
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': 35680476,
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': 29449361,
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': 23372512,
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': 36848427,
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': 29760442
    }), "Sizes of the pseudospectra files changed"

    assert (mgfs_sha256_sums == {
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': '59bb2d30f54e4ebc5eae48f81bd8a146a76a5bacc20ef2a4b954e0de545d0f0d',
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': 'ae9d72b158d0453646110ab4748f8958abf0639589179749ad47158b4d582291',
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': 'c67fbdb7423d067a797f8bf8874980ca7ff00c6cc0e967b3251d9663ca6a18c8',
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': '99d95349a1618f4d8d90e5123c76352edef8f2f43528abf0ac36b56a6e63d859',
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': '7de333075eb4741bf52f1e272e1be6b39917e387357e532bfe4c843dd857604b',
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': '9818f7d15093240b96fa09033b561cbbcefa23e48e9d210d7eded9771346c4b7'
    }), "Checksums of the pseudospectra files changed"
