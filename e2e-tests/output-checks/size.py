def assert_size_with_tolerance(current_size: int, reference_size: int, size_tolerance: float, message: str):
    relative_size_change = round(current_size / reference_size * 100)

    assert current_size >= reference_size * (1 - size_tolerance) and current_size <= reference_size * (1 + size_tolerance), \
        message.format(relative_size_change=relative_size_change)
