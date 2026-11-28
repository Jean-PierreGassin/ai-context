#!/usr/bin/env python3
"""Send an HTTP request and verify status, body, and appended server log lines."""
from __future__ import annotations

import argparse
import pathlib
import re
import sys
import urllib.error
import urllib.request


ERROR_PATTERN = re.compile(r"\b(ERROR|CRITICAL|FATAL|Exception|Traceback)\b")


def parse_headers(items: list[str]) -> dict[str, str]:
    headers: dict[str, str] = {}
    for item in items:
        if ":" not in item:
            raise SystemExit(f"verify-http: invalid header {item!r}; expected 'Name: Value'")
        key, value = item.split(":", 1)
        headers[key.strip()] = value.strip()
    return headers


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Verify an HTTP endpoint and optional log file.")
    parser.add_argument("--url", required=True, help="Target URL")
    parser.add_argument("--method", default="GET", help="HTTP method (default: GET)")
    parser.add_argument("--header", dest="headers", action="append", default=[], help="HTTP header 'Key: Value'")
    parser.add_argument("--data", help="Request body string")
    parser.add_argument("--expect-status", type=int, default=200, help="Expected HTTP status (default: 200)")
    parser.add_argument("--expect-body", help="Substring expected in the response body")
    parser.add_argument("--log-file", dest="log_files", action="append", default=[], help="Log file to check for new errors")
    parser.add_argument("--timeout", type=float, default=15.0, help="Request timeout in seconds (default: 15)")
    args = parser.parse_args(argv)

    log_offsets: list[tuple[pathlib.Path, int]] = []
    for raw_path in args.log_files:
        path = pathlib.Path(raw_path)
        offset = path.stat().st_size if path.is_file() else 0
        log_offsets.append((path, offset))

    body_bytes = args.data.encode("utf-8") if args.data is not None else None
    req = urllib.request.Request(
        args.url,
        data=body_bytes,
        headers=parse_headers(args.headers),
        method=args.method.upper(),
    )

    status = 0
    response_text = ""
    try:
        with urllib.request.urlopen(req, timeout=args.timeout) as resp:
            status = resp.status
            response_text = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as err:
        status = err.code
        response_text = err.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as err:
        print(f"FAIL: request error for {args.url}: {err.reason}", file=sys.stderr)
        return 1

    print(f"HTTP {status} {args.method.upper()} {args.url}")
    if response_text:
        snippet = response_text[:500]
        print(snippet + ("..." if len(response_text) > 500 else ""))

    failed = False
    if status != args.expect_status:
        print(f"FAIL: expected status {args.expect_status}, got {status}", file=sys.stderr)
        failed = True

    if args.expect_body is not None and args.expect_body not in response_text:
        print(f"FAIL: response body missing {args.expect_body!r}", file=sys.stderr)
        failed = True

    for path, offset in log_offsets:
        if not path.is_file():
            continue
        raw = path.read_bytes()
        appended = raw[offset:] if len(raw) >= offset else raw
        text = appended.decode("utf-8", errors="replace")
        bad_lines = [line for line in text.splitlines() if ERROR_PATTERN.search(line)]
        if bad_lines:
            print(f"FAIL: {path} recorded {len(bad_lines)} error line(s):", file=sys.stderr)
            for line in bad_lines[:10]:
                print(f"  {line}", file=sys.stderr)
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
