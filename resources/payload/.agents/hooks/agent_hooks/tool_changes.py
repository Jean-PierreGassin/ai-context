from __future__ import annotations

import os
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from agent_hooks import added_lines, edits, event
from agent_hooks.added_lines import AddedLines
from agent_hooks.state import JsonStore


@dataclass(frozen=True)
class FileChange:
    root: str
    file: str
    added_lines: AddedLines


def pending_capture(hook_event: dict[str, Any]) -> JsonStore:
    tool_use = event.file_safe(str(hook_event.get("tool_use_id", "")))

    return JsonStore("verify-changes-pending", event.session_name(hook_event) + "-" + tool_use)


def capture_before_edit(hook_event: dict[str, Any], is_watched: Callable[[str], bool]) -> None:
    root = edits.edited_root(hook_event)

    if not root or not is_watched(root):
        return

    before = added_lines.read_text(os.path.realpath(edits.edited_path(hook_event)))
    pending_capture(hook_event).update(lambda stored: stored.update({"before": before}))


def take_capture(hook_event: dict[str, Any]) -> dict[str, Any]:
    capture = pending_capture(hook_event)
    stored = capture.load()
    capture.clear()

    return stored


def change_after_edit(hook_event: dict[str, Any]) -> FileChange | None:
    path = os.path.realpath(edits.edited_path(hook_event))
    root = edits.edited_root(hook_event)

    if not root or not os.path.isfile(path):
        return None

    capture = take_capture(hook_event)
    relative_path = os.path.relpath(path, os.path.realpath(root))
    new_lines = added_lines.between(capture["before"], path) if "before" in capture else AddedLines([], [])

    return FileChange(root, relative_path, new_lines)
