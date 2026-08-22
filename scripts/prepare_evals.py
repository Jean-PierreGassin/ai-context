#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
EVALS_ROOT = REPOSITORY_ROOT / "evals" / "skills"
SKILLS_ROOT = REPOSITORY_ROOT / "resources" / "payload" / ".agents" / "skills"
CATEGORIES = (
    "normal",
    "counterexample",
    "project-precedence",
    "proportionality",
    "composition",
    "regression",
)


def read_json(path: pathlib.Path):
    return json.loads(path.read_text())


def prepare(category: str | None = None) -> dict:
    skill_hashes = {}
    trigger_tasks = []
    behaviour_tasks = []
    for skill_root in sorted(EVALS_ROOT.iterdir()):
        if not skill_root.is_dir():
            continue
        skill = skill_root.name
        skill_content = (SKILLS_ROOT / skill / "SKILL.md").read_text()
        skill_hashes[skill] = hashlib.sha256(skill_content.encode()).hexdigest()
        triggers = read_json(skill_root / "triggers.json")
        behaviour = read_json(skill_root / "behaviour.json")["evals"]
        trigger_tasks.extend(
            {
                "id": f"{skill}:trigger:{index}",
                "skill": skill,
                "query": case["query"],
                "skill_content": skill_content,
            }
            for index, case in enumerate(triggers)
        )
        behaviour_tasks.extend(
            {
                "id": f"{skill}:behaviour:{case['id']}",
                "skill": skill,
                "case_id": case["id"],
                "prompt": case["prompt"],
                "skill_content": skill_content,
                "fixture": str((skill_root / case["fixture"]).resolve())
                if case.get("fixture")
                else None,
            }
            for case in behaviour
            if category is None or case.get("category") == category
        )
    return {
        "schema_version": 1,
        "selection": {"behaviour_category": category},
        "skill_hashes": skill_hashes,
        "triggers": trigger_tasks,
        "behaviour": behaviour_tasks,
    }


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export blind provider-independent skill eval tasks")
    parser.add_argument("--output", type=pathlib.Path)
    parser.add_argument("--category", choices=CATEGORIES)
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    output = json.dumps(prepare(arguments.category), indent=2, sort_keys=True) + "\n"
    if arguments.output:
        arguments.output.write_text(output)
    else:
        sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
