import hashlib
# from pathlib import Path
import tempfile


def calculate_sha256_sum(path: str) -> str:
    with open(path, "rb") as file:
        digest = hashlib.file_digest(file, "sha256")  # Python >= 3.11

    return digest.hexdigest()


def rewrite_excluding_lines(input_file, output_file, exclude_line_beginnings: list[str]): 
    for raw_line in input_file:
        if any(raw_line.startswith(beginning) for beginning in exclude_line_beginnings):
            continue
        
        output_file.write(raw_line)


def calculate_sha256_sum_excluding_lines(path: str, exclude_line_beginnings) -> str:
    # with open(Path(path).name, "w") as output_file:  # use for inspection
    with tempfile.NamedTemporaryFile(mode='w+', delete=True, suffix=".xml") as output_file:
        with open(path, "r") as input_file:
            rewrite_excluding_lines(input_file, output_file, exclude_line_beginnings)

            return calculate_sha256_sum(output_file.name)

def calculate_sha256_sum_pep_xml(path: str):
    return calculate_sha256_sum_excluding_lines(path, [
        '<?xml-stylesheet',
        '<analysis_summary',
        '<analysis_timestamp',
        '<inputfile',
        '<interact_summary filename',
        '<msms_pipeline_analysis',
        '<msms_run_summary base_name',
        '<parameter name="process,',
        '<parameter name="timing,',
        '<search_summary base_name'
    ])
