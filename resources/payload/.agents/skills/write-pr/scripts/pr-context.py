#!/usr/bin/env python3
"""Print branch, target, ahead/behind counts, commits, files, and PR template path."""
from __future__ import annotations

import pathlib
import subprocess
import sys


TEMPLATE_CANDIDATES = (
    ".github/pull_request_template.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".gitlab/merge_request_templates/Default.md",
    "docs/pull_request_template.md",
)


def git(cwd: pathlib.Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def detect_base(repo_root: pathlib.Path) -> str:
    for candidate in ("origin/main", "origin/master", "main", "master"):
        if git(repo_root, "rev-parse", "--verify", "--quiet", candidate).returncode == 0:
            return candidate
    raise SystemExit("pr-context: could not detect target branch; pass <target-ref>")


def find_template(repo_root: pathlib.Path) -> str | None:
    for rel in TEMPLATE_CANDIDATES:
        if (repo_root / rel).is_file():
            return rel
    tpl_dir = repo_root / ".github" / "PULL_REQUEST_TEMPLATE"
    if tpl_dir.is_dir():
        files = sorted(p.relative_to(repo_root).as_posix() for p in tpl_dir.glob("*.md"))
        if files:
            return ", ".join(files)
    return None


def main(argv: list[str] | None = None) -> int:
    repo_root = pathlib.Path(
        subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    )
    target = argv[0] if argv else detect_base(repo_root)
    branch = git(repo_root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()

    counts = git(repo_root, "rev-list", "--left-right", "--count", f"{target}...HEAD").stdout.strip()
    behind, ahead = (counts.split() + ["0", "0"])[:2]

    print(f"Branch: {branch}")
    print(f"Target: {target}")
    print(f"Behind target: {behind}, Ahead: {ahead}")

    template = find_template(repo_root)
    print(f"Template: {template or 'none (use assets/body-template.md)'}")

    commits = git(repo_root, "log", "--oneline", f"{target}..HEAD").stdout.strip()
    if commits:
        print("Commits:")
        for line in commits.splitlines():
            print(f"  {line}")

    files = git(repo_root, "diff", "--name-only", f"{target}...HEAD").stdout.strip()
    if files:
        print("Changed files:")
        for line in files.splitlines():
            print(f"  {line}")

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
