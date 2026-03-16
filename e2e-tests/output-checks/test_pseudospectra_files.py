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
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': 34118454,
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': 54889313,
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': 46850393,
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': 36570735,
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': 57920294,
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': 47095893
    } or mgfs_sizes == {
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': 34118454,
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': 54889313,
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': 46850393,
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': 36570735,
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': 57925529,
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': 47095893
    }), "Sizes of the pseudospectra files changed"

    assert (mgfs_sha256_sums == {
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': '5b46a4d381bb2f3f72ec7467c64993e933b713da8cd2dbd5de3e697ace3da102',
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': '60534c8e478d18c052ed952b58970c0567409d88c0065f3dc08c6fa25fe0f7d0',
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': '51ac2698fdcb5fa99376624744297ddefdb92c301a7067411814255019f9a9dd',
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': '556a9b6f20d9ce3379d4b278cb5845a4638dd47669316612273e792ea264bd70',
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': '03c281ed913e8b8f1104238c62a67e14a51f7fca9c9dc2d534ff8faed0c212ba',
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': 'acfebba7465a48675f990f7b822d365d87d67be5bcf468f7c909d03d46e5a7ca'
    } or mgfs_sha256_sums == {
        '210820_Grad090_LFQ_A_SubSet_Q1.mgf': '5b46a4d381bb2f3f72ec7467c64993e933b713da8cd2dbd5de3e697ace3da102',
        '210820_Grad090_LFQ_A_SubSet_Q2.mgf': '60534c8e478d18c052ed952b58970c0567409d88c0065f3dc08c6fa25fe0f7d0',
        '210820_Grad090_LFQ_A_SubSet_Q3.mgf': '51ac2698fdcb5fa99376624744297ddefdb92c301a7067411814255019f9a9dd',
        '210820_Grad090_LFQ_B_SubSet_Q1.mgf': '556a9b6f20d9ce3379d4b278cb5845a4638dd47669316612273e792ea264bd70',
        '210820_Grad090_LFQ_B_SubSet_Q2.mgf': '0055d7417bcfb430e4d763da36c2e8445f7bbb159eaf522ae9c7c172c74b4dbf',
        '210820_Grad090_LFQ_B_SubSet_Q3.mgf': 'acfebba7465a48675f990f7b822d365d87d67be5bcf468f7c909d03d46e5a7ca'
    }), "Checksums of the pseudospectra files changed"
