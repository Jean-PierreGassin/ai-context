#!/usr/bin/env python3
"""Read pipe-delimited table rows from stdin, print an aligned markdown table.

Input: one row per line, cells separated by "|", no padding needed, header first.
Output: the same table with every column padded to its widest cell and a
matching dashed separator row.
"""
import sys


def render(rows):
    widths = [max(len(row[column]) for row in rows) for column in range(len(rows[0]))]
    format_row = lambda row: "| " + " | ".join(
        cell.ljust(width) for cell, width in zip(row, widths)
    ) + " |"
    separator = "|" + "|".join("-" * (width + 2) for width in widths) + "|"
    lines = [format_row(rows[0]), separator] + [format_row(row) for row in rows[1:]]
    assert len({len(line) for line in lines}) == 1, "column mismatch after render"
    return "\n".join(lines)


if __name__ == "__main__":
    rows = [
        [cell.strip() for cell in line.rstrip("\n").split("|")]
        for line in sys.stdin
        if line.strip()
    ]
    print(render(rows))
