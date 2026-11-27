from __future__ import annotations

import re


def is_valid_pattern(pattern: str) -> bool:
    try:
        re.compile(pattern)
    except re.error:
        return False

    return True
