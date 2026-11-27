from __future__ import annotations

import fnmatch
import re
from dataclasses import dataclass

from agent_hooks import locations, patterns, repository
from agent_hooks.reported_once import ReportedOnce
from agent_hooks.tool_changes import FileChange

MAXIMUM_REPORTED = 15


@dataclass(frozen=True)
class PathRule:
    repository: str
    pattern: str

    def applies_to(self, name: str, file: str) -> bool:
        return fnmatch.fnmatch(name, self.repository) and fnmatch.fnmatch(file, self.pattern)


@dataclass(frozen=True)
class AddedLineRule:
    path: PathRule
    expression: re.Pattern[str]


@dataclass(frozen=True)
class Rules:
    added_lines: list[AddedLineRule]
    changed_files: list[PathRule]

    def has_rules(self) -> bool:
        return bool(self.added_lines or self.changed_files)

    def covers(self, name: str) -> bool:
        repositories = [rule.path.repository for rule in self.added_lines] + [rule.repository for rule in self.changed_files]

        return any(fnmatch.fnmatch(name, repository_pattern) for repository_pattern in repositories)


def load_rules() -> Rules:
    config = locations.config_file("weakening")
    added_lines = []
    changed_files = []
    lines = config.read_text().splitlines() if config.is_file() else []

    for line in lines:
        parts = line.split(None, 3)

        if len(parts) == 4 and parts[0] == "added" and patterns.is_valid_pattern(parts[3]):
            added_lines.append(AddedLineRule(PathRule(parts[1], parts[2]), re.compile(parts[3])))
            continue

        if len(parts) == 3 and parts[0] == "changed":
            changed_files.append(PathRule(parts[1], parts[2]))

    return Rules(added_lines, changed_files)


def change_findings(rules: Rules, change: FileChange) -> list[str]:
    name = repository.repository_name(change.root)
    findings = [change.file + " changed, and it decides how the work is verified" for rule in rules.changed_files if rule.applies_to(name, change.file)]
    expressions = [rule.expression for rule in rules.added_lines if rule.path.applies_to(name, change.file)]
    matching_lines = [line for line in change.added_lines.not_moved if any(expression.search(line.text) for expression in expressions)]
    findings.extend(f"{change.file}:{line.number} adds: {line.text.strip()[:120]}" for line in matching_lines)

    return findings


def findings(rules: Rules, session: str, change: FileChange) -> list[str]:
    change_reports = change_findings(rules, change)

    if not change_reports:
        return []

    return ReportedOnce("weakening", session).keep_new(change_reports, MAXIMUM_REPORTED)
