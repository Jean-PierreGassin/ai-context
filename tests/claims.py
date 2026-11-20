#!/usr/bin/env python3
from __future__ import annotations

import importlib
import pathlib
import sys

sys.dont_write_bytecode = True
repository_root = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repository_root / "resources/payload/.agents/hooks"))
sys.path.insert(0, str(repository_root / "tests/third_party/andon"))
sys.modules["claim_check_hook"] = importlib.import_module("agent_hooks.third_party.andon.claim_check_hook")
andon = importlib.import_module("agent_hooks.andon")


def check_adapter() -> None:
    assert andon.completion_claims("Done.") == ["Done."]
    assert andon.markdown_code_spans("see `x`") == [(4, 7)]


def main() -> int:
    check_adapter()

    claim_corpus = importlib.import_module("test_claim_corpus")
    tests = [getattr(claim_corpus, name) for name in dir(claim_corpus) if name.startswith("test_")]
    failed = []

    for test in tests:
        try:
            test()
        except AssertionError as error:
            failed.append(test.__name__ + ": " + str(error))

    if failed:
        print("\n".join("FAIL " + failure for failure in failed), file=sys.stderr)
        return 1

    print(f"claim corpus tests passed ({len(tests)} tests, {len(claim_corpus.CORPUS)} sentences)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
