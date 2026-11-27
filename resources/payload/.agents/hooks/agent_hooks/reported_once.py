from __future__ import annotations

import hashlib
from typing import Any

from agent_hooks.state import JsonStore


class ReportedOnce:
    def __init__(self, hook_name: str, session: str) -> None:
        self.store = JsonStore(hook_name, session + "-reported")

    def keep_new(self, reports: list[str], limit: int) -> list[str]:
        def take_new(stored: dict[str, Any]) -> list[str]:
            new_reports = [report for report in dict.fromkeys(reports) if fingerprint(report) not in stored]
            kept = new_reports[:limit]
            stored.update({fingerprint(report): True for report in kept})
            hidden_count = len(new_reports) - len(kept)

            if not hidden_count:
                return kept

            return kept + ["and " + str(hidden_count) + " more like these"]

        return self.store.update(take_new)

    def is_first(self, report_key: str) -> bool:
        return bool(self.keep_new([report_key], 1))


def fingerprint(report: str) -> str:
    return hashlib.sha256(report.encode()).hexdigest()[:16]
