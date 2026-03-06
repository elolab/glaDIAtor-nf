import hashlib


def calculate_sha256_sum(path: str) -> str:
    with open(path, "rb") as file:
        digest = hashlib.file_digest(file, "sha256")  # Python >= 3.11

    return digest.hexdigest()
