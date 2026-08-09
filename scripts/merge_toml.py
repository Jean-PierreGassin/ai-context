#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import re
import sys
import tomllib
from collections import defaultdict
from typing import Any


def flatten_tables(value: dict[str, Any], path: tuple[str, ...] = ()) -> dict[tuple[str, ...], dict[str, Any]]:
    tables: dict[tuple[str, ...], dict[str, Any]] = defaultdict(dict)
    for key, child in value.items():
        if isinstance(child, dict):
            tables.update(flatten_tables(child, (*path, key)))
        else:
            tables[path][key] = child
    return tables


def lookup(value: dict[str, Any], path: tuple[str, ...]) -> dict[str, Any] | None:
    current: Any = value
    for key in path:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current if isinstance(current, dict) else None


def has_scalar_ancestor(value: dict[str, Any], path: tuple[str, ...]) -> bool:
    current: Any = value
    for key in path:
        if not isinstance(current, dict):
            return True
        if key not in current:
            return False
        current = current[key]
    return not isinstance(current, dict)


def format_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    return json.dumps(value, ensure_ascii=False)


def table_header(path: tuple[str, ...]) -> str:
    return ".".join(format_key(part) for part in path)


def format_key(key: str) -> str:
    return json.dumps(key) if re.search(r"[^A-Za-z0-9_-]", key) else key


def merge(existing_text: str, desired: dict[str, Any]) -> tuple[str, bool]:
    existing = tomllib.loads(existing_text) if existing_text.strip() else {}
    missing: dict[tuple[str, ...], dict[str, Any]] = {}
    for path, values in flatten_tables(desired).items():
        current = lookup(existing, path)
        absent = {key: value for key, value in values.items() if current is None or key not in current}
        if absent:
            missing[path] = absent

    if not missing:
        return existing_text, False

    lines = existing_text.splitlines()
    headers: dict[tuple[str, ...], int] = {}
    for index, line in enumerate(lines):
        match = re.match(r"^\s*\[([^\[].*)\]\s*(?:#.*)?$", line)
        if match:
            headers[tuple(part.strip().strip('"') for part in match.group(1).split("."))] = index

    insertions: dict[int, list[str]] = defaultdict(list)
    append_sections: list[str] = []
    first_header = min(headers.values(), default=len(lines))
    skipped_paths: list[tuple[str, ...]] = []
    for path, values in missing.items():
        rendered = [f"{format_key(key)} = {format_value(value)}" for key, value in values.items()]
        if not path:
            insertions[first_header].extend(rendered + ([""] if first_header < len(lines) else []))
        elif path in headers:
            following = [index for index in headers.values() if index > headers[path]]
            insertion_at = min(following, default=len(lines))
            insertions[insertion_at].extend(rendered)
        elif lookup(existing, path) is not None or has_scalar_ancestor(existing, path):
            skipped_paths.append(path)
        else:
            append_sections.extend([f"[{table_header(path)}]", *rendered, ""])

    output: list[str] = []
    for index in range(len(lines) + 1):
        output.extend(insertions.get(index, []))
        if index < len(lines):
            output.append(lines[index])
    if append_sections:
        if output and output[-1] != "":
            output.append("")
        output.extend(append_sections)
    merged = "\n".join(output).rstrip() + "\n"
    tomllib.loads(merged)
    for path in skipped_paths:
        print(f'preserved incompatible TOML value at {".".join(path)}', file=sys.stderr)
    return merged, bool(skipped_paths)


def main() -> int:
    target_path, desired_path, output_path = map(pathlib.Path, sys.argv[1:])
    existing_text = target_path.read_text() if target_path.is_file() else ""
    desired = tomllib.loads(desired_path.read_text())
    merged, has_conflicts = merge(existing_text, desired)
    output_path.write_text(merged)
    return 2 if has_conflicts else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, tomllib.TOMLDecodeError, ValueError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
