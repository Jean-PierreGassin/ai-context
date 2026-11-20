from __future__ import annotations

import functools
import os
import subprocess


def git_output(directory: str, *arguments: str) -> str:
    try:
        return subprocess.run(["git", "-C", directory, *arguments], capture_output=True, text=True, check=False).stdout
    except OSError:
        return ""


def git(directory: str, *arguments: str) -> str:
    return git_output(directory, *arguments).strip()


def git_fields(directory: str, *arguments: str) -> list[str]:
    return [field for field in git_output(directory, *arguments).split("\0") if field]


@functools.cache
def toplevel(directory: str) -> str:
    return git(directory, "rev-parse", "--show-toplevel")


@functools.cache
def repository_name(root: str) -> str:
    remote = git(root, "remote", "get-url", "origin")

    if not remote:
        return os.path.basename(root)

    repository_path = remote.rstrip("/")
    last_segment = repository_path.rsplit("/", 1)[-1]

    return last_segment.removesuffix(".git")
