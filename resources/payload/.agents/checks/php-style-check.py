from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

ANNOTATION = r"@(param|var|return|phpstan|psalm|template|extends|implements|use|mixin|property|method|throws)\b"
LINE_COMMENT = re.compile(r"^\s*(//|#(?!\[)|/\*(?!\*))")
DOCBLOCK_LINE = re.compile(r"^\s*(/\*\*|\*/|\*)\s*(" + ANNOTATION + r"|\*/|$)")
DOCBLOCK_ANNOTATION = re.compile(r"^\s*(/\*\*|\*)\s*" + ANNOTATION)
DOCBLOCK_BLANK = re.compile(r"^\s*(/\*\*|\*/|\*)\s*$")
HEREDOC = re.compile(r"<<<\s*(['\"]?)(\w+)\1[ \t]*\n.*?\n[ \t]*\2\b", re.DOTALL)
CHAINED_LINKS = re.compile(r"->\w+\((?:[^()]|\([^()]*\))*\)->")
PROPERTY_THEN_CALL = re.compile(r"(?:\$\w+|\))(?:\??->\w+){2,}\s*\(")
NEW_AFTER_COMMA = re.compile(r",\s*new\s")
NEW_IN_ARGUMENTS = re.compile(r"\(\s*new\s")
SOLE_SIMPLE_NEW = re.compile(r"\(\s*new\s+[\w\\]+\(\s*[\w$:>'\".-]*\s*\)\s*\)")
CONTROL_BLOCK = re.compile(r"^\s*(if|foreach|for|while|switch|try|do)\b\s*[({]")
STRING_LITERAL = re.compile(r"\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'")
MAXIMUM_LINE_LENGTH = 120
MAXIMUM_RETURNS = 3
COMMENT_OR_STRING = re.compile(r"//[^\n]*|#(?!\[)[^\n]*|/\*.*?\*/|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'", re.DOTALL)
FUNCTION_DECLARATION = re.compile(r"\bfunction\b")
RETURN_STATEMENT = re.compile(r"\breturn\b")


def added_line_numbers() -> dict[str, set[int]]:
    numbers: dict[str, set[int]] = defaultdict(set)
    listing_path = os.environ.get("ADDED_LINES", "")

    if not listing_path:
        return numbers

    with open(listing_path) as listing:
        for entry in listing.read().splitlines():
            path, _, number = entry.rpartition(":")

            if path and number.isdigit():
                numbers[path].add(int(number))

    return numbers


def top_level_commas(text: str) -> int:
    depth = 0
    commas = 0

    for character in STRING_LITERAL.sub('""', text):
        depth += (character in "([{") - (character in ")]}")
        commas += character == "," and depth == 0

    return commas


def has_argument_after_open_paren(text: str) -> bool:
    plain_text = STRING_LITERAL.sub('""', text)
    open_positions: list[int] = []

    for position, character in enumerate(plain_text):
        if character == "(":
            open_positions.append(position)

        if character == ")" and open_positions:
            open_positions.pop()

    return bool(open_positions) and plain_text[open_positions[-1] + 1 :].strip() not in ("", ",")


def nested_new_finding(line: str) -> str:
    if NEW_AFTER_COMMA.search(line):
        return "new inside a multi-argument list (hoist it)"

    nested = [match for match in NEW_IN_ARGUMENTS.finditer(line) if not SOLE_SIMPLE_NEW.match(line[match.start() :])]

    return "new inside an argument list (hoist it unless it is the sole, simple argument)" if nested else ""


def broken_call_finding(stripped: str) -> str:
    if not stripped.endswith(","):
        return ""

    if has_argument_after_open_paren(stripped):
        return "call broken after its first argument (one argument per line)"

    is_plain_arguments = "=>" not in stripped and not stripped.startswith(("//", "*", "#"))

    return "several arguments on one line of a broken call" if is_plain_arguments and top_level_commas(stripped[:-1]) > 0 else ""


def is_comment_prose(line: str, in_docblock: bool) -> bool:
    if in_docblock:
        return not DOCBLOCK_LINE.match(line)

    return bool(LINE_COMMENT.search(line))


def docblock_line_numbers(lines: list[str]) -> tuple[set[int], set[int]]:
    numbers = set()
    annotation_numbers = set()
    opened_at = 0
    in_annotation = False

    for number, line in enumerate(lines, start=1):
        if not opened_at and line.strip().startswith("/**"):
            opened_at = number
            in_annotation = False

        if opened_at:
            numbers.add(number)
            in_annotation = bool(DOCBLOCK_ANNOTATION.match(line)) or (in_annotation and not DOCBLOCK_BLANK.match(line))

        if in_annotation:
            annotation_numbers.add(number)

        if opened_at and "*/" in line:
            opened_at = 0

    return numbers - annotation_numbers, annotation_numbers


def string_body_line_numbers(source: str) -> set[int]:
    numbers = set()

    def mark(start: int, end: int) -> None:
        first = source.count("\n", 0, start) + 1
        last = source.count("\n", 0, end) + 1
        numbers.update(range(first + 1, last + 1))

    def blank_heredoc(match: re.Match[str]) -> str:
        mark(match.start(), match.end())

        return re.sub(r"[^\n]", " ", match.group(0))

    without_heredocs = HEREDOC.sub(blank_heredoc, source)

    for match in COMMENT_OR_STRING.finditer(without_heredocs):
        if match.group(0)[0] in "'\"":
            mark(match.start(), match.end())

    return numbers


def line_findings(line: str, previous_line: str, in_docblock: bool, in_string: bool) -> list[str]:
    stripped = line.strip()

    if in_string:
        return [f"line over {MAXIMUM_LINE_LENGTH}: " + stripped[:100]] if len(line) > MAXIMUM_LINE_LENGTH else []

    code = STRING_LITERAL.sub('""', line)
    findings = [
        "comment or docblock prose" if is_comment_prose(line, in_docblock) else "",
        "chain with more than one link on a line" if CHAINED_LINKS.search(code) or PROPERTY_THEN_CALL.search(code) else "",
        nested_new_finding(line),
        f"line over {MAXIMUM_LINE_LENGTH}" if len(line) > MAXIMUM_LINE_LENGTH else "",
        "control block without a blank line above it" if CONTROL_BLOCK.match(line) and previous_line and not previous_line.endswith(("{", ":", "<?php")) else "",
        broken_call_finding(stripped),
    ]

    return [finding + ": " + stripped[:100] for finding in findings if finding]


def code_only(source: str) -> str:
    def blank(match: re.Match[str]) -> str:
        return re.sub(r"[^\n]", " ", match.group(0))

    return COMMENT_OR_STRING.sub(blank, source)


def function_bodies(code: str) -> list[tuple[int, int, int]]:
    bodies = []

    for declaration in FUNCTION_DECLARATION.finditer(code):
        opening = code.find("{", declaration.end())
        semicolon = code.find(";", declaration.end())
        is_bodiless = semicolon != -1 and (opening == -1 or semicolon < opening)
        closing = -1 if is_bodiless or opening == -1 else matching_brace(code, opening)

        if closing != -1:
            bodies.append((declaration.start(), opening, closing))

    return bodies


def matching_brace(code: str, opening: int) -> int:
    depth = 0

    for position in range(opening, len(code)):
        depth += (code[position] == "{") - (code[position] == "}")

        if depth == 0:
            return position

    return -1


def innermost_body(bodies: list[tuple[int, int, int]], position: int) -> tuple[int, int, int]:
    containing = [body for body in bodies if body[1] < position < body[2]]

    return max(containing, key=lambda body: body[1]) if containing else (-1, -1, -1)


def return_count_findings(path: str, source: str, numbers: set[int]) -> list[str]:
    code = code_only(source)
    bodies = function_bodies(code)
    return_counts: dict[tuple[int, int, int], int] = defaultdict(int)

    for statement in RETURN_STATEMENT.finditer(code):
        return_counts[innermost_body(bodies, statement.start())] += 1

    line_starts = [0] + [match.end() for match in re.finditer("\n", source)]
    added_offsets = [line_starts[number - 1] for number in numbers if number <= len(line_starts)]
    findings = []

    for body, count in return_counts.items():
        touched = any(body[0] <= offset <= body[2] for offset in added_offsets)

        if body[0] != -1 and touched and count > MAXIMUM_RETURNS:
            line_number = source.count("\n", 0, body[0]) + 1
            findings.append(f"{path}:{line_number} function with {count} returns, more than {MAXIMUM_RETURNS}")

    return findings


def file_findings(path: str, numbers: set[int]) -> list[str]:
    with open(path, errors="replace") as source_file:
        source = source_file.read()

    lines = source.splitlines()
    findings = return_count_findings(path, source, numbers)
    existing_numbers = sorted(number for number in numbers if number <= len(lines))
    docblock_lines, _ = docblock_line_numbers(lines)
    string_lines = string_body_line_numbers(source)

    for number in existing_numbers:
        previous_line = lines[number - 2].strip() if number > 1 else ""
        new_findings = line_findings(lines[number - 1], previous_line, number in docblock_lines, number in string_lines)
        findings.extend(f"{path}:{number} {finding}" for finding in new_findings)

    return findings


def main() -> int:
    numbers = added_line_numbers()
    findings = [finding for path in sys.argv[1:] for finding in file_findings(path, numbers.get(path, set()))]

    if findings:
        print("Fix each, or keep it and say why the rule does not apply:\n- " + "\n- ".join(findings[:15]))

    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
