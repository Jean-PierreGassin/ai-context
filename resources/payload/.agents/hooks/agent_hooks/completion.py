from __future__ import annotations

import re
from dataclasses import dataclass

from agent_hooks import andon, locations, patterns

BLOCKQUOTE = re.compile(r"^ {0,3}>")


@dataclass(frozen=True)
class ResponseRule:
    name: str
    expression: re.Pattern[str]


def load_response_rules() -> list[ResponseRule]:
    config = locations.config_file("response-rules")
    lines = config.read_text().splitlines() if config.is_file() else []
    rules = []

    for line in lines:
        parts = line.split(None, 1)

        if len(parts) == 2 and patterns.is_valid_pattern(parts[1]):
            rules.append(ResponseRule(parts[0], re.compile(parts[1])))

    return rules


def prose(message: str) -> str:
    characters = list(message)

    for start, end in andon.markdown_code_spans(message):
        characters[start:end] = " " * (end - start)

    unquoted_lines = [line for line in "".join(characters).splitlines() if not BLOCKQUOTE.match(line)]

    return "\n".join(unquoted_lines)


def response_rules_report(message: str, rules: list[ResponseRule]) -> str:
    readable_text = prose(message)
    broken_rules = [rule.name for rule in rules if rule.expression.search(readable_text)]

    if not broken_rules:
        return ""

    return "Your last reply breaks these response rules: " + ", ".join(broken_rules) + ". Send the reply again without them."


def claims_report(claims: list[str], unverified_repositories: list[str]) -> str:
    quoted_claims = ", ".join('"' + claim + '"' for claim in claims)

    return (
        "Your reply says the work is finished (" + quoted_claims + "), but you changed "
        + ", ".join(unverified_repositories)
        + " after its handoff checks last passed. Run verify-changes.sh handoff from the repository root and show its"
        " output, or say plainly what is still unverified."
    )
