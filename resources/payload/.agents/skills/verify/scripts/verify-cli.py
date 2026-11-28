#!/usr/bin/env python3
"""Run a CLI command and verify its exit code, stdout, and stderr."""
from __future__ import annotations

import argparse
import subprocess
import sys


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Verify a CLI command's exit code and output.")
    parser.add_argument("--expect-exit", type=int, default=0, help="Expected exit code (default: 0)")
    parser.add_argument("--expect-stdout", help="Substring required in stdout")
    parser.add_argument("--expect-stderr", help="Substring required in stderr")
    parser.add_argument("--forbid-stderr", help="Substring forbidden in stderr")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to run after --")
    args = parser.parse_args(argv)

    cmd = list(args.command)
    if cmd and cmd[0] == "--":
        cmd = cmd[1:]
    if not cmd:
        print("usage: verify-cli.py [--expect-exit N] [--expect-stdout S] -- <command...>", file=sys.stderr)
        return 2

    res = subprocess.run(cmd, capture_output=True, text=True)
    print(f"exit={res.returncode} cmd={' '.join(cmd)}")
    if res.stdout:
        print(f"stdout: {res.stdout[:500]}")
    if res.stderr:
        print(f"stderr: {res.stderr[:500]}")

    failed = False
    if res.returncode != args.expect_exit:
        print(f"FAIL: expected exit {args.expect_exit}, got {res.returncode}", file=sys.stderr)
        failed = True
    if args.expect_stdout is not None and args.expect_stdout not in res.stdout:
        print(f"FAIL: stdout missing {args.expect_stdout!r}", file=sys.stderr)
        failed = True
    if args.expect_stderr is not None and args.expect_stderr not in res.stderr:
        print(f"FAIL: stderr missing {args.expect_stderr!r}", file=sys.stderr)
        failed = True
    if args.forbid_stderr is not None and args.forbid_stderr in res.stderr:
        print(f"FAIL: stderr contained forbidden {args.forbid_stderr!r}", file=sys.stderr)
        failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
