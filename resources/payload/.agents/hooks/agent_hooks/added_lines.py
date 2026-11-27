from __future__ import annotations

import os
import re
import subprocess
import tempfile
from collections import Counter
from dataclasses import dataclass

MAXIMUM_COMPARED_BYTES = 2_000_000
HUNK_HEADER = re.compile(r"^@@ -\S+ \+(\d+)")


@dataclass(frozen=True)
class AddedLine:
    number: int
    text: str


@dataclass(frozen=True)
class AddedLines:
    all: list[AddedLine]
    not_moved: list[AddedLine]


def read_text(path: str) -> str:
    try:
        with open(path, errors="replace") as source:
            return source.read(MAXIMUM_COMPARED_BYTES)
    except OSError:
        return ""


def between(before: str, after_path: str) -> AddedLines:
    is_too_large = len(before) >= MAXIMUM_COMPARED_BYTES or os.path.getsize(after_path) >= MAXIMUM_COMPARED_BYTES

    if is_too_large:
        return AddedLines([], [])

    with tempfile.NamedTemporaryFile("w", suffix=".before") as before_file:
        before_file.write(before)
        before_file.flush()
        diff = subprocess.run(
            ["git", "diff", "--no-index", "--no-color", "--no-ext-diff", "-U0", "--", before_file.name, after_path],
            capture_output=True,
            text=True,
            errors="replace",
            check=False,
        ).stdout

    return parse_diff(diff)


def parse_diff(diff: str) -> AddedLines:
    added = []
    removed_text: Counter[str] = Counter()
    number = 0

    for line in diff.splitlines():
        hunk = HUNK_HEADER.match(line)

        if hunk:
            number = int(hunk.group(1))
        elif line.startswith("+") and not line.startswith("+++"):
            added.append(AddedLine(number, line[1:]))
            number += 1
        elif line.startswith("-") and not line.startswith("---"):
            removed_text[line[1:].strip()] += 1

    not_moved = [line for line in added if not take_moved(line, removed_text)]

    return AddedLines(added, not_moved)


def take_moved(line: AddedLine, removed_text: Counter[str]) -> bool:
    text = line.text.strip()

    if removed_text[text] == 0:
        return False

    removed_text[text] -= 1

    return True
