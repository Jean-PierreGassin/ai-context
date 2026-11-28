#!/usr/bin/env python3
"""Prove that new or changed tests fail against the trunk version of modified files."""
from __future__ import annotations

import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile


TEST_SEGMENTS = ("tests/", "test/", "__tests__/", "spec/")
TEST_SUFFIXES = ("Test.php", ".test.ts", ".test.tsx", ".test.js", ".spec.ts", ".spec.js", "_test.go", "_test.py")


def is_test_path(path: str) -> bool:
    name = pathlib.Path(path).name
    return (
        any(seg in path for seg in TEST_SEGMENTS)
        or path.startswith("tests/")
        or path.startswith("test/")
        or name.startswith("test_")
        or name.endswith(TEST_SUFFIXES)
    )


def detect_base(repo_root: pathlib.Path) -> str:
    for candidate in ("origin/main", "origin/master", "main", "master"):
        res = subprocess.run(
            ["git", "rev-parse", "--verify", "--quiet", candidate],
            cwd=repo_root,
            capture_output=True,
            text=True,
        )
        if res.returncode == 0:
            return candidate
    raise SystemExit("prove-tests: could not detect trunk branch; pass --base <ref>")


def changed_non_test_files(repo_root: pathlib.Path, base: str) -> list[str]:
    res = subprocess.run(
        ["git", "diff", "--name-only", base],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line for line in res.stdout.splitlines() if line and not is_test_path(line)]


def file_exists_in_ref(repo_root: pathlib.Path, base: str, rel_path: str) -> bool:
    res = subprocess.run(
        ["git", "cat-file", "-e", f"{base}:{rel_path}"],
        cwd=repo_root,
        capture_output=True,
    )
    return res.returncode == 0


def read_blob(repo_root: pathlib.Path, base: str, rel_path: str) -> bytes:
    res = subprocess.run(
        ["git", "show", f"{base}:{rel_path}"],
        cwd=repo_root,
        capture_output=True,
        check=True,
    )
    return res.stdout


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Prove tests fail against trunk versions of changed files.")
    parser.add_argument("--base", help="Base git ref (defaults to origin/main, origin/master, main, or master)")
    parser.add_argument("--file", dest="files", action="append", help="Specific file(s) to revert temporarily")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Test command after --")
    args = parser.parse_args(argv)

    cmd = list(args.command)
    if cmd and cmd[0] == "--":
        cmd = cmd[1:]
    if not cmd:
        print("usage: prove-tests.py [--base <ref>] [--file <path> ...] -- <test command...>", file=sys.stderr)
        return 2

    repo_root = pathlib.Path(
        subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    )
    base = args.base or detect_base(repo_root)
    targets = args.files or changed_non_test_files(repo_root, base)
    if not targets:
        print("prove-tests: no non-test files changed relative to", base, file=sys.stderr)
        return 2

    backup_root = pathlib.Path(tempfile.mkdtemp(prefix="prove-tests-"))
    records: list[tuple[pathlib.Path, pathlib.Path | None, int | None]] = []

    try:
        for rel in targets:
            target = repo_root / rel
            if target.exists():
                backup = backup_root / rel
                backup.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(target, backup)
                mode = target.stat().st_mode
                records.append((target, backup, mode))
            else:
                records.append((target, None, None))

            if file_exists_in_ref(repo_root, base, rel):
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(read_blob(repo_root, base, rel))
            elif target.exists():
                target.unlink()

        print(f"prove-tests: running against {base} for {len(targets)} file(s): {', '.join(targets)}")
        result = subprocess.run(cmd, cwd=repo_root)
    finally:
        for target, backup, mode in records:
            if backup is not None:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(backup, target)
                if mode is not None:
                    os.chmod(target, mode)
            elif target.exists():
                target.unlink()
        shutil.rmtree(backup_root, ignore_errors=True)

    if result.returncode == 0:
        print("FAIL: tests still passed against trunk; they do not guard the change.", file=sys.stderr)
        return 1

    print(f"PASS: tests failed against {base} (exit {result.returncode}), confirming they guard the change.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
