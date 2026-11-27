from __future__ import annotations

import fnmatch
import glob
import os
from collections.abc import Iterator
from dataclasses import dataclass

from agent_hooks import event, locations, repository, shell

HEREDOC_WRITERS = {"cat", "tee"}
FILE_REDIRECTS = {">", ">>", ">|"}


@dataclass(frozen=True)
class Editor:
    options_with_values: frozenset[str]
    attached_options: frozenset[str]
    digit_options: frozenset[str]
    first_operand_ends_options: bool


EDITORS = {
    "sed": Editor(frozenset({"-e", "--expression", "-f", "--file", "-l", "--line-length"}), frozenset({"-i"}), frozenset(), False),
    "perl": Editor(frozenset({"-e", "-E", "-I", "-M", "-m", "-x", "-C", "-d", "-D", "-F"}), frozenset({"-i"}), frozenset({"-0", "-l"}), True),
}


def load_guarded_repositories() -> list[str]:
    config = locations.config_file("block-shell-edits")

    if not config.is_file():
        return []

    return [line.strip() for line in config.read_text().splitlines() if line.strip()]


def in_place_targets(command: shell.SimpleCommand) -> list[str]:
    editor = EDITORS.get(command.name)

    if not editor:
        return []

    arguments = shell.parse_arguments(
        command.words[1:],
        editor.options_with_values,
        editor.attached_options,
        editor.digit_options,
        editor.first_operand_ends_options,
    )

    return arguments.operands if {"-i", "--in-place"} & arguments.flags else []


def redirect_targets(words: list[str]) -> Iterator[str]:
    for index, word in enumerate(words[:-1]):
        if word in FILE_REDIRECTS:
            yield words[index + 1]

    if words[0] == "tee":
        yield from (word for word in words[1:] if not word.startswith("-") and word != shell.HEREDOC_WORD)


def heredoc_writes(commands: list[shell.SimpleCommand]) -> Iterator[tuple[shell.SimpleCommand, str]]:
    piped_heredoc = False

    for command in commands:
        has_heredoc = shell.HEREDOC_WORD in command.words
        writes_heredoc = has_heredoc or (piped_heredoc and command.follows_pipe)

        if command.name in HEREDOC_WRITERS and writes_heredoc:
            yield from ((command, target) for target in redirect_targets(command.words))

        piped_heredoc = writes_heredoc and command.name == "cat"


def existing_files(command: shell.SimpleCommand, path: str) -> list[str]:
    resolved = shell.resolve(command.directory, path, command.variables)

    return [match for match in glob.glob(resolved) if os.path.isfile(match)] if resolved else []


def is_guarded(path: str | None, guarded_repositories: list[str]) -> bool:
    if not path:
        return False

    parent = os.path.dirname(os.path.realpath(path))
    root = repository.toplevel(parent) if os.path.isdir(parent) else ""

    if not root:
        return False

    name = repository.repository_name(root)

    return any(fnmatch.fnmatch(name, pattern) for pattern in guarded_repositories)


def shell_edits(command: str, directory: str, guarded_repositories: list[str]) -> set[str]:
    commands = list(shell.commands(command, directory))
    edits = set()

    for simple_command in commands:
        targets = [file for operand in in_place_targets(simple_command) for file in existing_files(simple_command, operand)]

        if any(is_guarded(target, guarded_repositories) for target in targets):
            edits.add(simple_command.name + " -i")

    for simple_command, target in heredoc_writes(commands):
        if is_guarded(shell.resolve(simple_command.directory, target, simple_command.variables), guarded_repositories):
            edits.add("a heredoc written to a file")

    return edits


def main(arguments: list[str]) -> int:
    guarded_repositories = load_guarded_repositories()

    if not guarded_repositories:
        return 0

    hook_event = event.read_event()
    command = hook_event.get("tool_input", {}).get("command", "")
    directory = hook_event.get("cwd") or os.getcwd()
    edits = shell_edits(command, directory, guarded_repositories)

    if edits:
        event.deny("Change files in this repository with the Edit or Write tool, not " + ", ".join(sorted(edits)) + ".")

    return 0
