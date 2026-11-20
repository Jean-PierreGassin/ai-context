from __future__ import annotations

import fnmatch
import functools
import os
import re
import time
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from typing import Any

from agent_hooks import edits, event, locations, repository, shell
from agent_hooks.state import JsonStore

GATE_SOURCES = {"Bash", "Skill", "Agent"}
UNKNOWN_REPOSITORY = "Cannot tell which repository this commit is for. Run git commit from the repository, or pass git -C a literal path."


@dataclass(frozen=True)
class Gate:
    repository: str
    name: str
    source: str
    pattern: str


def ledger(session: str) -> JsonStore:
    return JsonStore("commit-gate", session)


def gate_key(root: str, gate_name: str) -> str:
    return root + "\t" + gate_name


def load_gates() -> list[Gate]:
    config = locations.config_file("commit-gate")
    gates = []

    if not config.is_file():
        return gates

    for line in config.read_text().splitlines():
        parts = line.split(None, 3)

        if len(parts) == 4 and parts[2] in GATE_SOURCES:
            gates.append(Gate(*parts))

    return gates


def git_target(command: shell.SimpleCommand) -> tuple[str | None, str]:
    global_options, subcommand, _ = shell.git_invocation(command.words)
    directories = global_options.values.get("-C", []) + global_options.values.get("--work-tree", [])
    target = functools.reduce(lambda current, path: shell.resolve(current, path, command.variables), directories, command.directory)

    return target, subcommand


def commit_directories(command: str, directory: str) -> list[str | None]:
    targets = (git_target(simple_command) for simple_command in shell.commands(command, directory) if simple_command.name == "git")

    return [target for target, subcommand in targets if subcommand == "commit"]


def visited_directories(command: str, directory: str) -> set[str]:
    visited = {simple_command.directory for simple_command in shell.commands(command, directory)}

    return {visited_directory for visited_directory in visited if visited_directory} or {directory}


def gate_subject(hook_event: dict[str, Any], command: str) -> tuple[str, str]:
    if hook_event.get("hook_event_name") in ("SubagentStart", "SubagentStop"):
        return "Agent", hook_event.get("agent_type", "")

    if hook_event.get("tool_name") == "Skill":
        return "Skill", hook_event.get("tool_input", {}).get("skill", "")

    return "Bash", " ; ".join(simple_command.line() for simple_command in shell.commands(command))


def run_key(hook_event: dict[str, Any]) -> str:
    return str(hook_event.get("tool_use_id") or hook_event.get("agent_id") or "")


def command_roots(hook_event: dict[str, Any], command: str) -> set[str]:
    cwd = hook_event.get("cwd") or os.getcwd()
    roots = {repository.toplevel(directory) for directory in visited_directories(command, cwd)}

    return {root for root in roots if root}


def matching_gates(hook_event: dict[str, Any], gates: list[Gate], command: str) -> list[Gate]:
    source, subject = gate_subject(hook_event, command)

    return [gate for gate in gates if gate.source == source and re.search(gate.pattern, subject)]


def gate_names_for(root: str, gates: list[Gate]) -> set[str]:
    name = repository.repository_name(root)

    return {gate.name for gate in gates if fnmatch.fnmatch(name, gate.repository)}


def start(hook_event: dict[str, Any], gates: list[Gate], command: str) -> None:
    key = run_key(hook_event)

    if not key or not matching_gates(hook_event, gates, command):
        return

    ledger(event.session_name(hook_event)).update(lambda stored: stored.setdefault("run_starts", {}).update({key: time.time()}))


def credited_roots(hook_event: dict[str, Any], stored: dict[str, Any], command: str) -> set[str]:
    if gate_subject(hook_event, command)[0] == "Bash":
        return command_roots(hook_event, command)

    return set(stored.get("roots", []))


def record_gates(hook_event: dict[str, Any], recorded_gates: list[Gate], command: str) -> None:
    key = run_key(hook_event)

    def store(stored: dict[str, Any]) -> None:
        started_at = stored.setdefault("run_starts", {}).pop(key, time.time())
        gate_times = stored.setdefault("gate_times", {})

        for root in credited_roots(hook_event, stored, command):
            gate_times.update({gate_key(root, gate_name): started_at for gate_name in gate_names_for(root, recorded_gates)})

    ledger(event.session_name(hook_event)).update(store)


def remember_roots(hook_event: dict[str, Any], roots: set[str]) -> None:
    def store(stored: dict[str, Any]) -> None:
        stored["roots"] = sorted(set(stored.get("roots", [])) | roots)

    ledger(event.session_name(hook_event)).update(store)


def record(hook_event: dict[str, Any], gates: list[Gate], command: str) -> None:
    edited_root = edits.edited_root(hook_event)

    if edited_root:
        edits.record(event.session_name(hook_event), edited_root)
        remember_roots(hook_event, {edited_root})
        return

    recorded_gates = matching_gates(hook_event, gates, command)

    if recorded_gates:
        record_gates(hook_event, recorded_gates, command)
        return

    roots = command_roots(hook_event, command) if hook_event.get("tool_name") == "Bash" else set()

    if roots:
        remember_roots(hook_event, roots)


def missing_gates(root: str, gates: list[Gate], gate_times: dict[str, float], last_edit: float) -> list[str]:
    required = sorted(gate_names_for(root, gates))

    return [gate_name for gate_name in required if gate_times.get(gate_key(root, gate_name), 0.0) <= last_edit]


def commit_denial(session: str, root: str, gates: list[Gate]) -> str:
    gate_times = ledger(session).load().get("gate_times", {})
    last_edit = edits.last_edit(session, root)
    missing = missing_gates(root, gates, gate_times, last_edit)

    if not missing:
        return ""

    name = repository.repository_name(root)
    since = "since your last edit there" if last_edit else "in this session"

    return (
        "Commit gates for " + name + " have not run " + since + ": " + ", ".join(missing)
        + ". Run them on this change, then commit. If one cannot apply, stop and ask the user."
    )


def commit_denials(hook_event: dict[str, Any], gates: list[Gate], command: str) -> Iterator[str]:
    session = event.session_name(hook_event)

    for directory in commit_directories(command, hook_event.get("cwd") or os.getcwd()):
        if directory is None:
            yield UNKNOWN_REPOSITORY
            continue

        root = repository.toplevel(directory)
        yield commit_denial(session, root, gates) if root else ""


def check(hook_event: dict[str, Any], gates: list[Gate], command: str) -> None:
    denial = next((reason for reason in commit_denials(hook_event, gates, command) if reason), "")

    if denial:
        event.deny(denial)
        return

    start(hook_event, gates, command)


PHASES: dict[str, Callable[[dict[str, Any], list[Gate], str], None]] = {
    "check": check,
    "start": start,
    "record": record,
}


def main(arguments: list[str]) -> int:
    phase = arguments[0]
    hook_event = event.read_event()
    gates = load_gates()

    if not gates:
        return 0

    command = hook_event.get("tool_input", {}).get("command", "")
    PHASES[phase](hook_event, gates, command)

    return 0
