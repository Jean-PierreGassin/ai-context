from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from agent_hooks import event, locations, patterns, shell

RULE_KINDS = {"command", "api-write", "tool"}
HELP_OPTIONS = {"--help", "-h"}
WRITE_METHODS = {"POST", "PUT", "PATCH", "DELETE"}
READING_VERBS = {"get", "list", "read", "search", "draft", "fetch", "view", "find", "query", "lookup", "describe"}
WORD_BOUNDARY = re.compile(r"[_\-]+|(?<=[a-z0-9])(?=[A-Z])")


@dataclass(frozen=True)
class AskRule:
    kind: str
    expression: re.Pattern[str]
    reason: str


@dataclass(frozen=True)
class HttpClient:
    words: tuple[str, ...]
    options_with_values: frozenset[str]
    method_options: frozenset[str]
    body_options: frozenset[str]
    read_options: frozenset[str]
    upload_options: frozenset[str]


HTTP_CLIENTS = (
    HttpClient(
        ("curl",),
        frozenset({"-X", "--request", "-d", "--data", "--data-raw", "--data-binary", "--data-urlencode", "--json", "-F", "--form", "-T", "--upload-file",
                   "-H", "--header", "-o", "--output", "-u", "--user", "-A", "--user-agent", "-e", "--referer", "-b", "--cookie", "-c", "--cookie-jar",
                   "-K", "--config", "-m", "--max-time", "-w", "--write-out", "-x", "--proxy", "-r", "--range", "-E", "--cert", "--url"}),
        frozenset({"-X", "--request"}),
        frozenset({"-d", "--data", "--data-raw", "--data-binary", "--data-urlencode", "--json", "-F", "--form"}),
        frozenset({"-G", "--get"}),
        frozenset({"-T", "--upload-file"}),
    ),
    HttpClient(
        ("gh", "api"),
        frozenset({"-X", "--method", "-f", "--raw-field", "-F", "--field", "-H", "--header", "--input", "-q", "--jq", "-t", "--template",
                   "-p", "--preview", "--hostname", "--cache"}),
        frozenset({"-X", "--method"}),
        frozenset({"-f", "--raw-field", "-F", "--field", "--input"}),
        frozenset(),
        frozenset(),
    ),
)


def load_rules() -> list[AskRule]:
    config = locations.config_file("ask-first")
    lines = config.read_text().splitlines() if config.is_file() else []
    rules = []

    for line in lines:
        parts = line.split(None, 2)

        if len(parts) == 3 and parts[0] in RULE_KINDS and patterns.is_valid_pattern(parts[1]):
            rules.append(AskRule(parts[0], re.compile(parts[1]), parts[2]))

    return rules


def request_method(client: HttpClient, words: list[str]) -> str:
    arguments = shell.parse_arguments(words[len(client.words) :], client.options_with_values)
    method = arguments.value(*client.method_options)

    if method:
        return method.upper()

    if client.read_options & arguments.flags:
        return "GET"

    if client.upload_options & arguments.flags:
        return "PUT"

    return "POST" if client.body_options & arguments.flags else "GET"


def is_write_request(words: list[str]) -> bool:
    client = next((client for client in HTTP_CLIENTS if tuple(words[: len(client.words)]) == client.words), None)

    return client is not None and request_method(client, words) in WRITE_METHODS


def command_reasons(rules: list[AskRule], command: str) -> list[str]:
    commands = [simple_command for simple_command in shell.commands(command) if not HELP_OPTIONS & set(simple_command.words)]
    command_lines = [simple_command.line() for simple_command in commands]
    requests = [simple_command.line() for simple_command in commands if is_write_request(simple_command.words)]
    command_matches = [rule.reason for rule in rules if rule.kind == "command" and any(rule.expression.search(line) for line in command_lines)]
    request_matches = [rule.reason for rule in rules if rule.kind == "api-write" and any(rule.expression.search(request) for request in requests)]

    return command_matches + request_matches


def tool_reasons(rules: list[AskRule], tool_name: str) -> list[str]:
    action = tool_name.rsplit("__", 1)[-1]
    action_words = {word.lower() for word in WORD_BOUNDARY.split(action) if word}

    if action_words & READING_VERBS:
        return []

    return [rule.reason for rule in rules if rule.kind == "tool" and rule.expression.search(action.lower())]


def reasons(hook_event: dict[str, Any], rules: list[AskRule]) -> list[str]:
    tool_name = hook_event.get("tool_name", "")

    if tool_name.startswith("mcp__"):
        return tool_reasons(rules, tool_name)

    command = hook_event.get("tool_input", {}).get("command", "")

    return command_reasons(rules, command)


def main(arguments: list[str]) -> int:
    rules = load_rules()

    if not rules:
        return 0

    hook_event = event.read_event()
    ask_reasons = sorted(set(reasons(hook_event, rules)))

    if ask_reasons:
        event.ask(" ".join(ask_reasons))

    return 0
