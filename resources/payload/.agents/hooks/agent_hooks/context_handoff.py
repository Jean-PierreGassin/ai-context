from __future__ import annotations

import json
import os
from typing import Any

from agent_hooks import event
from agent_hooks.state import JsonStore

LIMIT_TOKENS = 250_000
TAIL_BYTES = 4 * 1024 * 1024
REASON = (
    "Context is over ~250k tokens. Finish the current step, then use the `handoff` skill in continue mode: "
    "start a fresh session on this work and stop here."
)


def context_tokens(transcript_path: str) -> int:
    try:
        with open(transcript_path, "rb") as transcript:
            transcript.seek(max(0, os.path.getsize(transcript_path) - TAIL_BYTES))
            lines = transcript.read().decode("utf-8", "replace").splitlines()
    except OSError:
        return 0

    for line in reversed(lines):
        usage = main_thread_usage(line)

        if usage is not None:
            return sum(int(usage.get(key) or 0) for key in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))

    return 0


def main_thread_usage(line: str) -> dict[str, Any] | None:
    try:
        entry = json.loads(line)
    except ValueError:
        return None

    if not isinstance(entry, dict) or entry.get("type") != "assistant" or entry.get("isSidechain"):
        return None

    message = entry.get("message")
    usage = message.get("usage") if isinstance(message, dict) else None

    return usage if isinstance(usage, dict) else None


def first_crossing(session: str) -> bool:
    def mark(stored: dict[str, Any]) -> bool:
        if stored.get(session):
            return False

        stored[session] = True

        return True

    return JsonStore("context-handoff", "sessions").update(mark)


def main(arguments: list[str]) -> int:
    hook_event = event.read_event()

    if hook_event.get("stop_hook_active"):
        return 0

    if context_tokens(str(hook_event.get("transcript_path", ""))) <= LIMIT_TOKENS:
        return 0

    if first_crossing(event.session_name(hook_event)):
        event.block(REASON)

    return 0
