from __future__ import annotations

import fcntl
import json
import os
import pathlib
import tempfile
import time
from collections.abc import Callable
from typing import Any

from agent_hooks import locations

RETENTION_SECONDS = 30 * 24 * 60 * 60


class JsonStore:
    def __init__(self, hook_name: str, name: str) -> None:
        self.directory = locations.state_directory(hook_name)
        self.path = self.directory / (name + ".json")
        self.lock_path = self.directory / (name + ".lock")

    def load(self) -> dict[str, Any]:
        try:
            stored = json.loads(self.path.read_text())
        except (OSError, ValueError):
            return {}

        return stored if isinstance(stored, dict) else {}

    def update(self, change: Callable[[dict[str, Any]], Any]) -> Any:
        self.directory.mkdir(parents=True, exist_ok=True)

        with open(self.lock_path, "w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            stored = self.load()
            result = change(stored)
            self.save(stored)

        return result

    def save(self, stored: dict[str, Any]) -> None:
        is_new = not self.path.exists()
        handle, temporary_path = tempfile.mkstemp(dir=self.directory)

        with os.fdopen(handle, "w") as output:
            output.write(json.dumps(stored))

        os.replace(temporary_path, self.path)

        if is_new:
            forget_expired(self.directory)

    def clear(self) -> None:
        self.path.unlink(missing_ok=True)
        self.lock_path.unlink(missing_ok=True)


def forget_expired(directory: pathlib.Path) -> None:
    oldest_kept = time.time() - RETENTION_SECONDS

    for stored_file in directory.iterdir():
        try:
            if stored_file.stat().st_mtime < oldest_kept:
                stored_file.unlink()
        except OSError:
            continue
