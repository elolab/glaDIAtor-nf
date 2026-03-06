def get_processes_locations_map(nextflow_log_file: str) -> dict[str, list[str]]:
    processes_locations_map: dict[str, list[str]] = {}

    with open(nextflow_log_file) as file:
        for raw_line in file:
            line = raw_line.rstrip()

            if "Task completed" in line and "exit: 0" in line:
                chunks = [chunk.strip() for chunk in line.split(";")]

                name_chunk = chunks[1]
                location_chunk = chunks[5]
                
                name = name_chunk.split(" ")[1]
                location = ("/").join(location_chunk.split("/")[-3:]).rstrip("]")

                if name not in processes_locations_map:
                    processes_locations_map[name] = set()

                processes_locations_map[name].add(location)

    return processes_locations_map


def get_process_names(nextflow_log_file: str) -> list[str]:
    process_names = []

    for key, value in get_processes_locations_map(nextflow_log_file).items():
        process_names.extend([key] * len(value))

    return sorted(process_names)
