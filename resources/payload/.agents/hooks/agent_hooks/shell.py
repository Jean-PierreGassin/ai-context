from __future__ import annotations

import os
import re
from collections.abc import Iterator
from dataclasses import dataclass, field

HEREDOC = re.compile(r"<<(-)?[ \t]*\\?(['\"]?)(\w+)\2([^\n]*)\n.*?\n(?(1)\t*)\3[ \t]*(?=\n|$)", re.DOTALL)
HEREDOC_WORD = "__heredoc__"
VARIABLE = re.compile(r"\$\{?(\w+)\}?")
ASSIGNMENT = re.compile(r"\w+=")
COMMAND_SEPARATORS = {";", "&", "&&", "||", "|", "\n"}
SUBSHELL_OPENERS = {"(", "$("}
REDIRECTS = {"<", ">", ">>", "<<<", ">&", "<&", ">|"}
WRAPPERS = {"command", "env", "time", "exec", "nohup", "sudo", "xargs"}
COMMAND_PREFIXES = {"then", "do", "else", "elif", "if", "while", "until", "{", "!", *WRAPPERS}
DECLARATIONS = {"export", "local", "declare"}
GIT_OPTIONS_WITH_VALUES = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"}


@dataclass(frozen=True)
class Word:
    text: str
    quoted: bool


@dataclass(frozen=True)
class SimpleCommand:
    directory: str | None
    program: str
    words: list[str]
    quoted: list[bool]
    assignments: list[str]
    variables: dict[str, str]
    follows_pipe: bool

    @property
    def name(self) -> str:
        return self.words[0]

    def line(self) -> str:
        program = expand(self.program, self.variables) or self.program
        arguments = ['""' if is_quoted else word for word, is_quoted in zip(self.words[1:], self.quoted[1:])]

        return " ".join([*self.assignments, program, *arguments])


@dataclass(frozen=True)
class Arguments:
    flags: set[str]
    values: dict[str, list[str]]
    operands: list[str]

    def value(self, *options: str) -> str:
        found = [value for option in options for value in self.values.get(option, [])]

        return found[-1] if found else ""


def without_heredocs(command: str) -> str:
    previous = None

    while previous != command:
        previous = command
        command = HEREDOC.sub(lambda heredoc: " " + HEREDOC_WORD + " " + heredoc.group(4), command)

    return command


def quoted_text(command: str, start: int, has_escapes: bool) -> tuple[str, int]:
    quote = command[start]
    text = []
    index = start + 1

    while index < len(command) and command[index] != quote:
        if command[index] == "\\" and has_escapes and index + 1 < len(command):
            index += 1

        text.append(command[index])
        index += 1

    return "".join(text), index + 1


def operator_at(command: str, index: int) -> str:
    for operator in ("&&", "||", "$(", ">>", "<<<", ">&", "<&", ">|", ";", "&", "|", "(", ")", "\n", "<", ">"):
        if command.startswith(operator, index):
            return operator

    return ""


def tokens(command: str) -> Iterator[Word | str]:
    characters: list[str] = []
    is_quoted = False
    index = 0

    def word() -> Iterator[Word]:
        nonlocal characters, is_quoted

        if characters or is_quoted:
            yield Word("".join(characters), is_quoted)

        characters, is_quoted = [], False

    while index < len(command):
        character = command[index]
        operator = operator_at(command, index)

        if command.startswith("\\\n", index):
            index += 2
        elif character == "\\":
            characters.append(command[index + 1 : index + 2])
            index += 2
        elif character in "'\"" or command.startswith("$'", index):
            is_ansi_c = character == "$"
            text, index = quoted_text(command, index + is_ansi_c, character == '"' or is_ansi_c)
            characters.append(text)
            is_quoted = True
        elif character == "#" and not characters and not is_quoted:
            index = command.find("\n", index) if "\n" in command[index:] else len(command)
        elif character in " \t\r":
            yield from word()
            index += 1
        elif operator in REDIRECTS and "".join(characters).isdigit():
            characters = []
            yield operator
            index += len(operator)
        elif operator:
            yield from word()
            yield operator
            index += len(operator)
        else:
            characters.append(character)
            index += 1

    yield from word()


def expand(text: str, variables: dict[str, str]) -> str | None:
    expanded = VARIABLE.sub(lambda match: variables.get(match.group(1), "$"), text)

    if "$" in expanded or "`" in expanded:
        return None

    return os.path.expanduser(expanded)


def resolve(directory: str | None, path: str, variables: dict[str, str]) -> str | None:
    expanded = expand(path, variables)

    if directory is None or expanded is None:
        return None

    return os.path.join(directory, expanded)


@dataclass
class Location:
    directory: str | None
    previous: str | None
    pushed: list[str | None] = field(default_factory=list)

    def change(self, words: list[str], variables: dict[str, str]) -> None:
        target = words[1] if len(words) > 1 else "~"

        if words[0] == "popd":
            self.directory = self.pushed.pop() if self.pushed else None
            return

        if words[0] == "pushd":
            self.pushed.append(self.directory)

        new_directory = self.previous if target == "-" else resolve(self.directory, target, variables)
        self.previous, self.directory = self.directory, new_directory


def remember_assignment(word: str, following_word: str, variables: dict[str, str]) -> None:
    name, _, value = word.partition("=")

    if following_word and following_word not in DECLARATIONS:
        return

    expanded = expand(value, variables)

    if expanded is None:
        variables.pop(name, None)
        return

    variables[name] = expanded


def without_prefixes(words: list[Word], variables: dict[str, str]) -> list[str]:
    assignments = []

    while words and (words[0].text in COMMAND_PREFIXES or words[0].text in DECLARATIONS or ASSIGNMENT.match(words[0].text)):
        prefix = words.pop(0)

        if ASSIGNMENT.match(prefix.text):
            assignments.append(prefix.text)
            remember_assignment(prefix.text, words[0].text if words else "", variables)

        while prefix.text in WRAPPERS and words and words[0].text.startswith("-"):
            words.pop(0)

    return assignments


def commands(command: str, directory: str | None = None) -> Iterator[SimpleCommand]:
    variables = dict(os.environ)
    location = Location(directory, None)
    saved_locations: list[tuple[str | None, str | None]] = []
    words: list[Word] = []
    follows_pipe = False

    def finish() -> Iterator[SimpleCommand]:
        assignments = without_prefixes(words, variables)
        texts = [word.text for word in words]

        if texts and texts[0] in ("cd", "pushd", "popd"):
            location.change(texts, variables)
        elif texts:
            yield SimpleCommand(
                location.directory,
                texts[0],
                [os.path.basename(texts[0]), *texts[1:]],
                [word.quoted for word in words],
                assignments,
                dict(variables),
                follows_pipe,
            )

        words.clear()

    for token in tokens(without_heredocs(command)):
        if isinstance(token, Word) or token in REDIRECTS:
            words.append(token if isinstance(token, Word) else Word(token, False))
            continue

        yield from finish()
        follows_pipe = token == "|"

        if token in SUBSHELL_OPENERS:
            saved_locations.append((location.directory, location.previous))
        elif token == ")" and saved_locations:
            location.directory, location.previous = saved_locations.pop()

    yield from finish()


def parse_arguments(
    arguments: list[str],
    options_with_values: frozenset[str] = frozenset(),
    attached_options: frozenset[str] = frozenset(),
    digit_options: frozenset[str] = frozenset(),
    first_operand_ends_options: bool = False,
) -> Arguments:
    flags: set[str] = set()
    values: dict[str, list[str]] = {}
    operands: list[str] = []
    remaining = list(arguments)
    options_ended = False

    while remaining:
        argument = remaining.pop(0)

        if options_ended or argument == "-" or not argument.startswith("-"):
            operands.append(argument)
            options_ended = options_ended or first_operand_ends_options
        elif argument == "--":
            options_ended = True
        elif argument.startswith("--"):
            name, separator, value = argument.partition("=")
            flags.add(name)

            if separator or (name in options_with_values and remaining):
                values.setdefault(name, []).append(value if separator else remaining.pop(0))
        else:
            short_options(argument[1:], remaining, flags, values, options_with_values, attached_options, digit_options)

    return Arguments(flags, values, operands)


def short_options(
    letters: str,
    remaining: list[str],
    flags: set[str],
    values: dict[str, list[str]],
    options_with_values: frozenset[str],
    attached_options: frozenset[str],
    digit_options: frozenset[str],
) -> None:
    position = 0

    while position < len(letters):
        option = "-" + letters[position]
        rest = letters[position + 1 :]
        flags.add(option)

        if option in digit_options:
            digits = len(rest) - len(rest.lstrip("0123456789"))
            position += 1 + digits
            continue

        if option in attached_options or (option in options_with_values and rest):
            values.setdefault(option, []).append(rest)
            return

        if option in options_with_values and remaining:
            values.setdefault(option, []).append(remaining.pop(0))
            return

        position += 1


def git_invocation(words: list[str]) -> tuple[Arguments, str, list[str]]:
    global_options = parse_arguments(words[1:], frozenset(GIT_OPTIONS_WITH_VALUES), first_operand_ends_options=True)
    subcommand = global_options.operands[0] if global_options.operands else ""

    return global_options, subcommand, global_options.operands[1:]
