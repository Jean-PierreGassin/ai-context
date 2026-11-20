from __future__ import annotations

import functools
import importlib
from types import ModuleType


@functools.cache
def claim_check_hook() -> ModuleType:
    return importlib.import_module("agent_hooks.third_party.andon.claim_check_hook")


def completion_claims(message: str) -> list[str]:
    return list(claim_check_hook().find_claims(message))


def markdown_code_spans(message: str) -> list[tuple[int, int]]:
    return list(claim_check_hook()._code_spans(message))
