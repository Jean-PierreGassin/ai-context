#!/usr/bin/env python3
"""Print verified git, worktree, PR, and output-path state for a handoff."""
from __future__ import annotations

import os
import pathlib
import re
import shutil
import subprocess
import sys


def git(cwd: pathlib.Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
    )


def handoff_path(repo_root: pathlib.Path | None, branch: str, slug: str) -> pathlib.Path:
    state_home = pathlib.Path(
        os.environ.get("XDG_STATE_HOME") or (pathlib.Path.home() / ".local" / "state")
    )
    if repo_root is not None:
        safe_branch = branch.replace("/", "-")
        name = f"{repo_root.name}-{safe_branch}.md"
    else:
        safe_slug = re.sub(r"[^A-Za-z0-9._-]+", "-", slug).strip("-") or "session"
        name = f"{safe_slug}.md"
    return state_home / "agents" / "handoff" / name


def main(argv: list[str] | None = None) -> int:
    cwd = pathlib.Path.cwd()
    slug = argv[0] if argv else cwd.name

    top = git(cwd, "rev-parse", "--show-toplevel")
    if top.returncode != 0:
        print(f"Location: {cwd} (not a git repo)")
        print(f"Handoff path: {handoff_path(None, '', slug)}")
        return 0

    repo_root = pathlib.Path(top.stdout.strip())
    branch = git(repo_root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    sha = git(repo_root, "rev-parse", "--short", "HEAD").stdout.strip()
    status_lines = [line for line in git(repo_root, "status", "--short").stdout.splitlines() if line]

    print(f"Location: {repo_root}")
    print(f"Branch: {branch} @ {sha}")
    if status_lines:
        print(f"Working tree: dirty ({len(status_lines)} item(s))")
        for line in status_lines[:20]:
            print(f"  {line}")
    else:
        print("Working tree: clean")

    wt = git(repo_root, "worktree", "list", "--porcelain")
    if wt.returncode == 0 and wt.stdout.strip():
        print("Worktrees:")
        for block in wt.stdout.strip().split("\n\n"):
            wt_path = ""
            wt_branch = ""
            wt_locked = ""
            for line in block.splitlines():
                if line.startswith("worktree "):
                    wt_path = line.split(" ", 1)[1]
                elif line.startswith("branch "):
                    wt_branch = line.split(" ", 1)[1].removeprefix("refs/heads/")
                elif line.startswith("locked"):
                    wt_locked = line
            suffix = f" [{wt_branch}]" if wt_branch else ""
            if wt_locked:
                suffix += f" ({wt_locked})"
            print(f"  {wt_path}{suffix}")

    if shutil.which("gh"):
        pr = subprocess.run(
            ["gh", "pr", "view", "--json", "number,url,state,title"],
            cwd=repo_root,
            capture_output=True,
            text=True,
        )
        if pr.returncode == 0 and pr.stdout.strip():
            print(f"Open PR: {pr.stdout.strip()}")

    print(f"Handoff path: {handoff_path(repo_root, branch, slug)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
