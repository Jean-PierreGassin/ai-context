from __future__ import annotations

from agent_hooks.state import JsonStore


def passes() -> JsonStore:
    return JsonStore("verify-changes", "handoff-passes")


def record(root: str, started_at: float) -> None:
    passes().update(lambda stored: stored.update({root: started_at}))


def last_pass(root: str) -> float:
    return passes().load().get(root, 0.0)
