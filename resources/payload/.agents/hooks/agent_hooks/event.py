from __future__ import annotations

import json
import sys
from typing import Any


def read_event() -> dict[str, Any]:
    return json.load(sys.stdin)


def file_safe(text: str) -> str:
    return "".join(character for character in text if character.isalnum() or character in "-_")


def session_name(event: dict[str, Any]) -> str:
    return file_safe(str(event.get("session_id", "default")))


def decide(permission: str, reason: str) -> None:
    decision = {"hookEventName": "PreToolUse", "permissionDecision": permission, "permissionDecisionReason": reason}

    print(json.dumps({"hookSpecificOutput": decision}))


def deny(reason: str) -> None:
    decide("deny", reason)


def ask(reason: str) -> None:
    decide("ask", reason)


def block(reason: str) -> None:
    print(json.dumps({"decision": "block", "reason": reason}))


def notify(message: str) -> None:
    print(json.dumps({"systemMessage": message}))
