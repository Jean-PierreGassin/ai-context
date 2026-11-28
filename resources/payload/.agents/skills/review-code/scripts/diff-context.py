#!/usr/bin/env python3
"""Print base ref, merge-base, diff range, commits, and diffstat for code review."""
from __future__ import annotations

import pathlib
import subprocess
import sys


def git(cwd: pathlib.Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def detect_base(repo_root: pathlib.Path) -> str:
    for candidate in ("origin/main", "origin/master", "main", "master"):
        if git(repo_root, "rev-parse", "--verify", "--quiet", candidate).returncode == 0:
            return candidate
    raise SystemExit("diff-context: could not detect base branch; pass <base-ref>")


def main(argv: list[str] | None = None) -> int:
    repo_root = pathlib.Path(
        subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    )
    base = argv[0] if argv else detect_base(repo_root)
    head_branch = git(repo_root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    merge_base = git(repo_root, "merge-base", base, "HEAD").stdout.strip()
    diff_range = f"{base}...HEAD"

    print(f"Branch: {head_branch}")
    print(f"Base: {base}")
    print(f"Merge-base: {merge_base}")
    print(f"Range: {diff_range}")

    commits = git(repo_root, "log", "--oneline", diff_range).stdout.strip()
    if commits:
        print("Commits:")
        for line in commits.splitlines():
            print(f"  {line}")

    stat = git(repo_root, "diff", "--stat", diff_range).stdout.strip()
    if stat:
        print("Diffstat:")
        for line in stat.splitlines():
            print(f"  {line}")

    wt_status = git(repo_root, "status", "--short").stdout.strip()
    if wt_status:
        print("Uncommitted:")
        for line in wt_status.splitlines():
            print(f"  {line}")

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
