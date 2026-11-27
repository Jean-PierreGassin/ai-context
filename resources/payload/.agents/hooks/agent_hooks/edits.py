from __future__ import annotations

import os
import time
from typing import Any

from agent_hooks import repository
from agent_hooks.state import JsonStore


def edited_path(hook_event: dict[str, Any]) -> str:
    tool_input = hook_event.get("tool_input", {})

    return tool_input.get("file_path") or tool_input.get("notebook_path") or ""


def nearest_existing_directory(path: str) -> str:
    directory = os.path.dirname(os.path.realpath(path))

    while directory and not os.path.isdir(directory):
        directory = os.path.dirname(directory)

    return directory


def edited_root(hook_event: dict[str, Any]) -> str:
    path = edited_path(hook_event)

    return repository.toplevel(nearest_existing_directory(path)) if path else ""


def session_edits(session: str) -> JsonStore:
    return JsonStore("agent-edits", session)


def record(session: str, root: str) -> None:
    session_edits(session).update(lambda stored: stored.update({root: time.time()}))


def last_edits(session: str) -> dict[str, float]:
    return session_edits(session).load()


def last_edit(session: str, root: str) -> float:
    return last_edits(session).get(root, 0.0)
