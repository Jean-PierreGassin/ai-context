#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import re
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_ROOT = REPOSITORY_ROOT / "resources" / "payload" / ".agents" / "skills"
ADAPTERS_ROOT = REPOSITORY_ROOT / "resources" / "payload" / ".claude" / "skills"
EVALS_ROOT = REPOSITORY_ROOT / "evals" / "skills"

CATEGORIES = frozenset(
    {
        "normal",
        "counterexample",
        "project-precedence",
        "proportionality",
        "composition",
        "regression",
    }
)
SUPPORTING_DIRECTORIES = ("references", "assets", "examples", "scripts")
SUPPORTING_PATH = re.compile(
    rf"(?:{'|'.join(SUPPORTING_DIRECTORIES)})/[A-Za-z0-9][A-Za-z0-9._/-]*\.[A-Za-z0-9]+"
)
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
ADAPTER_TARGET = re.compile(r"`\.agents/skills/([A-Za-z0-9._-]+)/SKILL\.md`")

failures: list[str] = []


def fail(location: pathlib.Path | str, message: str) -> None:
    where = location.relative_to(REPOSITORY_ROOT) if isinstance(location, pathlib.Path) else location
    failures.append(f"{where}: {message}")


def read_json(path: pathlib.Path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as error:
        fail(path, f"invalid JSON, {error}")
        return None


def frontmatter_field(path: pathlib.Path, field: str) -> str | None:
    match = FRONTMATTER.match(path.read_text())
    if match is None:
        fail(path, "missing YAML frontmatter")
        return None
    value = re.search(rf"^{field}:\s*(.*?)(?=\n[a-z_]+:|\Z)", match.group(1), re.DOTALL | re.MULTILINE)
    if value is None:
        fail(path, f"frontmatter has no {field}")
        return None
    return " ".join(value.group(1).split())


def is_filled_string(value) -> bool:
    return isinstance(value, str) and value.strip() != ""


def discover_skills() -> list[str]:
    if not SKILLS_ROOT.is_dir():
        fail(SKILLS_ROOT, "canonical skills directory is missing")
        return []
    skills = sorted(
        directory.name for directory in SKILLS_ROOT.iterdir() if (directory / "SKILL.md").is_file()
    )
    if not skills:
        fail(SKILLS_ROOT, "no skills found")
    return skills


def check_supporting_paths(skill: str) -> None:
    skill_root = SKILLS_ROOT / skill
    for document in sorted(skill_root.rglob("*.md")):
        for reference in sorted(set(SUPPORTING_PATH.findall(document.read_text()))):
            if not (skill_root / reference).exists():
                fail(document, f"references a missing path, {reference}")


def check_adapter_redirect(adapter: pathlib.Path, skill: str) -> None:
    target = ADAPTER_TARGET.search(adapter.read_text())
    if target is None:
        fail(adapter, "does not redirect to a canonical .agents skill")
    elif not (SKILLS_ROOT / target.group(1) / "SKILL.md").is_file():
        fail(adapter, f"redirects to a skill that does not exist, {target.group(1)}")
    elif target.group(1) != skill:
        fail(adapter, f"redirects to {target.group(1)} rather than {skill}")


def check_adapter_frontmatter(adapter: pathlib.Path, skill: str) -> None:
    canonical = SKILLS_ROOT / skill / "SKILL.md"
    for field in ("name", "description"):
        adapter_value = frontmatter_field(adapter, field)
        canonical_value = frontmatter_field(canonical, field)
        if adapter_value is not None and canonical_value is not None and adapter_value != canonical_value:
            fail(adapter, f"{field} does not match the canonical skill")


def check_adapter(skill: str) -> None:
    adapter = ADAPTERS_ROOT / skill / "SKILL.md"
    if not adapter.is_file():
        fail(f"resources/payload/.claude/skills/{skill}/SKILL.md", "Claude adapter is missing")
        return

    check_adapter_redirect(adapter, skill)
    check_adapter_frontmatter(adapter, skill)


def check_triggers(skill: str) -> None:
    path = EVALS_ROOT / skill / "triggers.json"
    if not path.is_file():
        fail(f"evals/skills/{skill}/triggers.json", "missing")
        return

    entries = read_json(path)
    if entries is None:
        return
    if not isinstance(entries, list) or not entries:
        fail(path, "expected a non-empty array of trigger cases")
        return

    outcomes = {check_trigger_case(path, entry, f"entry {index}") for index, entry in enumerate(entries)}
    if not {True, False} <= outcomes:
        fail(path, "needs both positive and negative cases")


def check_trigger_case(path: pathlib.Path, entry, label: str) -> bool | None:
    if not isinstance(entry, dict):
        fail(path, f"{label} is not an object")
        return None

    if not is_filled_string(entry.get("query")):
        fail(path, f"{label} has no non-empty query")

    if not isinstance(entry.get("should_trigger"), bool):
        fail(path, f"{label} has no boolean should_trigger")
        return None

    return entry["should_trigger"]


def check_behaviour(skill: str) -> None:
    path = EVALS_ROOT / skill / "behaviour.json"
    if not path.is_file():
        fail(f"evals/skills/{skill}/behaviour.json", "missing")
        return

    document = read_json(path)
    if document is None:
        return
    if not isinstance(document, dict):
        fail(path, "expected an object with skill_name and evals")
        return
    if document.get("skill_name") != skill:
        fail(path, f"skill_name is {document.get('skill_name')!r} rather than {skill!r}")

    cases = document.get("evals")
    if not isinstance(cases, list) or not cases:
        fail(path, "expected a non-empty evals array")
        return

    seen: set[str] = set()
    for index, case in enumerate(cases):
        check_behaviour_case(path, skill, case, f"eval {index}", seen)


def check_behaviour_case(path: pathlib.Path, skill: str, case, label: str, seen: set[str]) -> None:
    if not isinstance(case, dict):
        fail(path, f"{label} is not an object")
        return

    identifier = case.get("id")
    if not is_filled_string(identifier):
        fail(path, f"{label} has no non-empty id")
    elif identifier in seen:
        fail(path, f"duplicate id, {identifier}")
    else:
        seen.add(identifier)
        label = identifier

    if not is_filled_string(case.get("prompt")):
        fail(path, f"{label} has no non-empty prompt")

    expectations = case.get("expectations")
    if not isinstance(expectations, list) or not expectations:
        fail(path, f"{label} has no non-empty expectations array")
    elif not all(is_filled_string(expectation) for expectation in expectations):
        fail(path, f"{label} has an empty or non-string expectation")

    if "expected_output" in case and not is_filled_string(case["expected_output"]):
        fail(path, f"{label} has an empty expected_output")

    category = case.get("category")
    if category is not None and category not in CATEGORIES:
        fail(path, f"{label} has an unknown category, {category}")

    check_fixture(path, skill, case.get("fixture"), label)


def check_fixture(path: pathlib.Path, skill: str, fixture, label: str) -> None:
    if fixture is None:
        return
    if not is_filled_string(fixture):
        fail(path, f"{label} has an empty fixture path")
    elif not (EVALS_ROOT / skill / fixture).exists():
        fail(path, f"{label} points at a missing fixture, {fixture}")


def check_no_orphan_eval_directories(skills: list[str]) -> None:
    if not EVALS_ROOT.is_dir():
        fail(EVALS_ROOT, "eval directory is missing")
        return
    for directory in sorted(EVALS_ROOT.iterdir()):
        if directory.is_dir() and directory.name not in skills:
            fail(directory, "has evals but is not a skill")


def main() -> int:
    skills = discover_skills()
    check_no_orphan_eval_directories(skills)
    for skill in skills:
        check_supporting_paths(skill)
        check_adapter(skill)
        check_triggers(skill)
        check_behaviour(skill)

    if failures:
        print(f"eval validation failed with {len(failures)} problem(s):", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print(f"eval validation passed for {len(skills)} skill(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
