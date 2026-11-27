from __future__ import annotations

import concurrent.futures
import fnmatch
import os
import shlex
import subprocess
import tempfile
import time
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from typing import Any

from agent_hooks import (
    andon,
    completion,
    edits,
    event,
    handoff_passes,
    locations,
    repository,
    tool_changes,
    weakening,
)
from agent_hooks.reported_once import ReportedOnce
from agent_hooks.state import JsonStore
from agent_hooks.tool_changes import FileChange

PHASES = {"edit", "turn", "handoff"}
CHECK_TIMEOUT_SECONDS = 150
REPORTED_OUTPUT_LINES = 40
SKIPPED_EXIT_CODES = {0, 126, 127}


@dataclass(frozen=True)
class Check:
    phase: str
    repository: str
    pattern: str
    command: str


@dataclass(frozen=True)
class Config:
    environment: str
    checks: list[Check]


@dataclass(frozen=True)
class Settings:
    config: Config
    weakening_rules: weakening.Rules
    response_rules: list[completion.ResponseRule]

    def is_empty(self) -> bool:
        return not (self.config.checks or self.weakening_rules.has_rules() or self.response_rules)


def load_config() -> Config:
    config_path = locations.config_file("verify-changes")

    if not config_path.is_file():
        return Config("", [])

    environment = ""
    checks = []

    for line in config_path.read_text().splitlines():
        parts = line.split(None, 3)

        if parts[:1] == ["env"]:
            environment = line.split(None, 1)[1] if len(parts) > 1 else ""
            continue

        if len(parts) == 4 and parts[0] in PHASES:
            checks.append(Check(*parts))

    return Config(environment, checks)


def turn_state(hook_event: dict[str, Any]) -> JsonStore:
    return JsonStore("verify-changes", event.session_name(hook_event))


def response_retry(hook_event: dict[str, Any]) -> JsonStore:
    return JsonStore("verify-changes", event.session_name(hook_event) + "-response-retry")


def matching_checks(config: Config, phase: str, root: str, files: list[str]) -> Iterator[tuple[Check, list[str]]]:
    name = repository.repository_name(root)

    for check in config.checks:
        if check.phase != phase or not fnmatch.fnmatch(name, check.repository):
            continue

        matching_files = [file for file in files if fnmatch.fnmatch(file, check.pattern)]

        if matching_files:
            yield check, matching_files


def run_check(config: Config, root: str, check: Check, files: list[str], environment: dict[str, str]) -> str:
    quoted_files = " ".join(shlex.quote(file) for file in files)
    script = check.command.replace("$FILES", quoted_files)
    script = script.replace("$FILE", quoted_files)
    prefix = config.environment + " >/dev/null 2>&1; " if config.environment else ""

    try:
        completed = subprocess.run(
            ["nice", "-n", "10", "bash", "-c", prefix + script],
            cwd=root,
            env={**os.environ, **environment},
            capture_output=True,
            text=True,
            timeout=CHECK_TIMEOUT_SECONDS,
            stdin=subprocess.DEVNULL,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return check.command + ": timed out after " + str(CHECK_TIMEOUT_SECONDS) + "s"
    except OSError:
        return ""

    if completed.returncode in SKIPPED_EXIT_CODES:
        return ""

    output = completed.stdout + completed.stderr
    output_lines = output.strip().splitlines()
    tool_name = check.command.split()[0]

    return tool_name + " on " + ", ".join(files) + ":\n" + "\n".join(output_lines[-REPORTED_OUTPUT_LINES:])


def repository_failures(config: Config, phase: str, root: str, files: list[str], environment: dict[str, str]) -> list[str]:
    checks = matching_checks(config, phase, root, files)
    results = [run_check(config, root, check, matching_files, environment) for check, matching_files in checks]

    return [failure for failure in results if failure]


def failures(config: Config, phase: str, changes: dict[str, list[str]], environment: dict[str, str] | None = None) -> list[str]:
    check_environment = environment or {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = pool.map(lambda change: repository_failures(config, phase, change[0], change[1], check_environment), changes.items())

        return [failure for repository_results in results for failure in repository_results]


def changed_since_base(root: str) -> list[str]:
    base_ref = repository.git(root, "symbolic-ref", "--short", "refs/remotes/origin/HEAD") or "origin/main"
    base = repository.git(root, "merge-base", base_ref, "HEAD")
    tracked = repository.git_fields(root, "diff", "-z", "--name-only", "--diff-filter=d", base) if base else []
    untracked = repository.git_fields(root, "ls-files", "-z", "--others", "--exclude-standard")

    return sorted(set(tracked + untracked))


def run_handoff(config: Config) -> int:
    root = repository.toplevel(os.getcwd())

    if not root:
        print("Not inside a git repository")
        return 1

    started_at = time.time()
    files = changed_since_base(root)
    handoff_failures = failures(config, "handoff", {root: files}) if files else []

    if handoff_failures:
        print("Handoff checks failed:\n\n" + "\n\n".join(handoff_failures))
        return 1

    handoff_passes.record(root, started_at)
    print("Handoff checks passed on " + str(len(files)) + " changed file(s)")

    return 0


def is_watched(settings: Settings, root: str) -> bool:
    name = repository.repository_name(root)
    has_checks = any(fnmatch.fnmatch(name, check.repository) for check in settings.config.checks)

    return has_checks or settings.weakening_rules.covers(name)


def remember_change(hook_event: dict[str, Any], change: FileChange) -> None:
    edits.record(event.session_name(hook_event), change.root)

    def add_file(stored: dict[str, Any]) -> None:
        files = stored.setdefault("changes", {}).setdefault(change.root, [])

        if change.file not in files:
            files.append(change.file)

    turn_state(hook_event).update(add_file)


def added_lines_file(change: FileChange) -> str:
    listing = [change.file + ":" + str(added_line.number) for added_line in change.added_lines.all]
    handle, path = tempfile.mkstemp(prefix="added-lines-", suffix=".txt")

    with os.fdopen(handle, "w") as output:
        output.write("\n".join(listing) + ("\n" if listing else ""))

    return path


def edit_report(config: Config, hook_event: dict[str, Any], change: FileChange) -> str:
    listing_path = added_lines_file(change)

    try:
        all_failures = failures(config, "edit", {change.root: [change.file]}, {"ADDED_LINES": listing_path})
    finally:
        os.unlink(listing_path)

    edit_failures = ReportedOnce("verify-changes", event.session_name(hook_event)).keep_new(all_failures, len(all_failures))

    if not edit_failures:
        return ""

    return "Checks failed on " + change.file + ". Fix them before moving on:\n\n" + "\n\n".join(edit_failures)


def weakening_report(settings: Settings, hook_event: dict[str, Any], change: FileChange) -> str:
    weakening_findings = weakening.findings(settings.weakening_rules, event.session_name(hook_event), change)

    if not weakening_findings:
        return ""

    return "These changes weaken how the work is verified. Undo each one, or say in one line why it is needed:\n- " + "\n- ".join(weakening_findings)


def capture_before_tool(settings: Settings, hook_event: dict[str, Any]) -> None:
    tool_changes.capture_before_edit(hook_event, lambda root: is_watched(settings, root))


def run_edit(settings: Settings, hook_event: dict[str, Any]) -> None:
    change = tool_changes.change_after_edit(hook_event)

    if not change:
        return

    remember_change(hook_event, change)
    reports = [edit_report(settings.config, hook_event, change), weakening_report(settings, hook_event, change)]
    reasons = [report for report in reports if report]

    if reasons:
        event.block("\n\n".join(reasons))


def existing_changes(stored: dict[str, Any]) -> dict[str, list[str]]:
    changes = {root: [file for file in files if os.path.isfile(os.path.join(root, file))] for root, files in stored.get("changes", {}).items()}

    return {root: files for root, files in changes.items() if files}


def unverified_edits(config: Config, session: str) -> dict[str, float]:
    unverified = {}

    for root, edited_at in edits.last_edits(session).items():
        if edited_at <= handoff_passes.last_pass(root) or not os.path.isdir(root):
            continue

        if any(matching_checks(config, "handoff", root, changed_since_base(root))):
            unverified[root] = edited_at

    return unverified


def claims_reports(config: Config, hook_event: dict[str, Any], message: str) -> list[str]:
    session = event.session_name(hook_event)
    unverified = unverified_edits(config, session)

    if not unverified:
        return []

    report_key = "unverified " + " ".join(root + "@" + str(edited_at) for root, edited_at in sorted(unverified.items()))
    claims = andon.completion_claims(message)

    if not claims or not ReportedOnce("verify-changes", session).is_first(report_key):
        return []

    repository_names = sorted(repository.repository_name(root) for root in unverified)

    return [completion.claims_report(claims, repository_names)]


def response_rules_reports(settings: Settings, hook_event: dict[str, Any], message: str) -> list[str]:
    retry = response_retry(hook_event)

    if hook_event.get("stop_hook_active") and retry.load():
        retry.clear()
        return []

    report = completion.response_rules_report(message, settings.response_rules)

    if not report:
        return []

    retry.update(lambda stored: stored.update({"pending": True}))

    return [report]


def completion_reports(settings: Settings, hook_event: dict[str, Any]) -> list[str]:
    message = hook_event.get("last_assistant_message") or ""

    if not message:
        return []

    return claims_reports(settings.config, hook_event, message) + response_rules_reports(settings, hook_event, message)


def run_turn(settings: Settings, hook_event: dict[str, Any]) -> None:
    state = turn_state(hook_event)
    stored = state.load()
    changes = existing_changes(stored)
    turn_failures = failures(settings.config, "turn", changes) if changes else []

    if turn_failures:
        report_turn_failures(hook_event, state, stored, turn_failures)
        return

    state.clear()
    reports = completion_reports(settings, hook_event)

    if reports:
        event.block("\n\n".join(reports))


def report_turn_failures(hook_event: dict[str, Any], state: JsonStore, stored: dict[str, Any], turn_failures: list[str]) -> None:
    report = "\n\n".join(turn_failures)

    if hook_event.get("stop_hook_active") and stored.get("blocked"):
        state.clear()
        event.notify("Turn checks still fail after one fix attempt:\n\n" + report)
        return

    state.update(lambda current: current.update({"blocked": True}))
    event.block("Checks on the files changed this turn failed. Fix them, or say why one does not apply:\n\n" + report)


def run_handoff_phase() -> int:
    config_path = locations.config_file("verify-changes")

    if not config_path.is_file():
        print("No checks configured in " + str(config_path))
        return 0

    return run_handoff(load_config())


HOOK_PHASES: dict[str, Callable[[Settings, dict[str, Any]], None]] = {
    "before-tool": capture_before_tool,
    "edit": run_edit,
    "turn": run_turn,
}


def main(arguments: list[str]) -> int:
    phase = arguments[0]

    if phase == "handoff":
        return run_handoff_phase()

    hook_event = event.read_event()
    settings = Settings(load_config(), weakening.load_rules(), completion.load_response_rules())

    if not settings.is_empty():
        HOOK_PHASES[phase](settings, hook_event)

    return 0
