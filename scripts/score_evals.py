#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
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


class InvalidResults(ValueError):
    pass


def load_json(path: pathlib.Path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidResults(f"could not read {path}: {error}") from error


def require_string(value, location: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise InvalidResults(f"{location} must be a non-empty string")
    return value


def require_boolean(value, location: str) -> bool:
    if not isinstance(value, bool):
        raise InvalidResults(f"{location} must be a boolean")
    return value


def load_corpus(category: str | None) -> dict[str, dict]:
    corpus = {}
    for skill_root in sorted(EVALS_ROOT.iterdir()):
        if not skill_root.is_dir():
            continue
        triggers = load_json(skill_root / "triggers.json")
        behaviour = load_json(skill_root / "behaviour.json")
        skill_path = (
            REPOSITORY_ROOT
            / "resources"
            / "payload"
            / ".agents"
            / "skills"
            / skill_root.name
            / "SKILL.md"
        )
        corpus[skill_root.name] = {
            "hash": hashlib.sha256(skill_path.read_bytes()).hexdigest(),
            "triggers": {case["query"]: case["should_trigger"] for case in triggers},
            "behaviour": {
                case["id"]: case["expectations"]
                for case in behaviour["evals"]
                if category is None or case.get("category") == category
            },
        }
    return corpus


def index_unique(entries: list, key: str, location: str) -> dict:
    indexed = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            raise InvalidResults(f"{location}[{index}] must be an object")
        identifier = require_string(entry.get(key), f"{location}[{index}].{key}")
        if identifier in indexed:
            raise InvalidResults(f"{location} contains duplicate {key} {identifier!r}")
        indexed[identifier] = entry
    return indexed


def require_complete(actual: set, expected: set, location: str) -> None:
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing or extra:
        details = []
        if missing:
            details.append(f"missing {missing!r}")
        if extra:
            details.append(f"unknown {extra!r}")
        raise InvalidResults(f"{location} is incomplete: {', '.join(details)}")


def score_trigger_results(results: list, corpus: dict, location: str) -> dict:
    by_skill = index_unique(results, "skill", location)
    require_complete(set(by_skill), set(corpus), location)
    counts = {"true_positive": 0, "true_negative": 0, "false_positive": 0, "false_negative": 0}
    failures = []
    scored_cases = []

    for skill, skill_corpus in corpus.items():
        cases = by_skill[skill].get("cases")
        if not isinstance(cases, list):
            raise InvalidResults(f"{location}.{skill}.cases must be an array")
        indexed = index_unique(cases, "query", f"{location}.{skill}.cases")
        expected = skill_corpus["triggers"]
        require_complete(set(indexed), set(expected), f"{location}.{skill}.cases")
        for query, should_trigger in expected.items():
            triggered = require_boolean(
                indexed[query].get("triggered"),
                f"{location}.{skill}.cases[{query!r}].triggered",
            )
            response = require_string(
                indexed[query].get("response"),
                f"{location}.{skill}.cases[{query!r}].response",
            )
            rationale = require_string(
                indexed[query].get("rationale"),
                f"{location}.{skill}.cases[{query!r}].rationale",
            )
            scored_cases.append(
                {
                    "skill": skill,
                    "query": query,
                    "expected": should_trigger,
                    "actual": triggered,
                    "response": response,
                    "rationale": rationale,
                }
            )
            if should_trigger and triggered:
                counts["true_positive"] += 1
            elif not should_trigger and not triggered:
                counts["true_negative"] += 1
            elif triggered:
                counts["false_positive"] += 1
                failures.append(
                    {"skill": skill, "query": query, "expected": should_trigger, "actual": triggered}
                )
            else:
                counts["false_negative"] += 1
                failures.append(
                    {"skill": skill, "query": query, "expected": should_trigger, "actual": triggered}
                )

    positives = counts["true_positive"] + counts["false_negative"]
    negatives = counts["true_negative"] + counts["false_positive"]
    counts["false_positive_rate"] = counts["false_positive"] / negatives if negatives else 0
    counts["false_negative_rate"] = counts["false_negative"] / positives if positives else 0
    counts["total"] = positives + negatives
    counts["failures"] = failures
    counts["cases"] = scored_cases
    return counts


def score_behaviour_results(results: list, corpus: dict, location: str) -> dict:
    by_skill = index_unique(results, "skill", location)
    require_complete(set(by_skill), set(corpus), location)
    expectation_passes = 0
    expectation_total = 0
    case_passes = 0
    case_total = 0
    failures = []
    scored_cases = []

    for skill, skill_corpus in corpus.items():
        cases = by_skill[skill].get("cases")
        if not isinstance(cases, list):
            raise InvalidResults(f"{location}.{skill}.cases must be an array")
        indexed = index_unique(cases, "id", f"{location}.{skill}.cases")
        expected_cases = skill_corpus["behaviour"]
        require_complete(set(indexed), set(expected_cases), f"{location}.{skill}.cases")

        for case_id, expectations in expected_cases.items():
            response = require_string(
                indexed[case_id].get("response"),
                f"{location}.{skill}.cases[{case_id!r}].response",
            )
            rationale = require_string(
                indexed[case_id].get("rationale"),
                f"{location}.{skill}.cases[{case_id!r}].rationale",
            )
            verdicts = indexed[case_id].get("expectations")
            if not isinstance(verdicts, list):
                raise InvalidResults(
                    f"{location}.{skill}.cases[{case_id!r}].expectations must be an array"
                )
            by_expectation = index_unique(
                verdicts,
                "expectation",
                f"{location}.{skill}.cases[{case_id!r}].expectations",
            )
            require_complete(
                set(by_expectation),
                set(expectations),
                f"{location}.{skill}.cases[{case_id!r}].expectations",
            )
            scored_expectations = []
            for expectation in expectations:
                verdict = by_expectation[expectation]
                passed_verdict = require_boolean(
                    verdict.get("passed"),
                    f"{location}.{skill}.cases[{case_id!r}][{expectation!r}].passed",
                )
                evidence = require_string(
                    verdict.get("evidence"),
                    f"{location}.{skill}.cases[{case_id!r}][{expectation!r}].evidence",
                )
                scored_expectations.append(
                    {"expectation": expectation, "passed": passed_verdict, "evidence": evidence}
                )
            passed = [verdict["passed"] for verdict in scored_expectations]
            expectation_passes += sum(passed)
            expectation_total += len(passed)
            case_passes += all(passed)
            case_total += 1
            for expectation, verdict in zip(expectations, passed):
                if not verdict:
                    failures.append(
                        {"skill": skill, "case_id": case_id, "expectation": expectation}
                    )
            scored_cases.append(
                {
                    "skill": skill,
                    "id": case_id,
                    "response": response,
                    "rationale": rationale,
                    "passed": all(passed),
                    "expectations": scored_expectations,
                }
            )

    return {
        "cases_passed": case_passes,
        "cases_total": case_total,
        "case_pass_rate": case_passes / case_total if case_total else 0,
        "expectations_passed": expectation_passes,
        "expectations_total": expectation_total,
        "expectation_pass_rate": expectation_passes / expectation_total if expectation_total else 0,
        "failures": failures,
        "cases": scored_cases,
    }


def read_selection(document: dict) -> dict:
    selection = document.get("selection")
    if not isinstance(selection, dict) or set(selection) != {"behaviour_category"}:
        raise InvalidResults("selection must contain only behaviour_category")
    category = selection["behaviour_category"]
    if category is not None and category not in CATEGORIES:
        raise InvalidResults(f"selection.behaviour_category is unknown: {category!r}")
    return selection


def score(document: dict, corpus: dict) -> dict:
    if not isinstance(document, dict):
        raise InvalidResults("results must be an object")
    if document.get("schema_version") != 1:
        raise InvalidResults("schema_version must be 1")
    model = document.get("model")
    if not isinstance(model, dict):
        raise InvalidResults("model must be an object")
    require_string(model.get("name"), "model.name")
    require_string(model.get("reasoning"), "model.reasoning")
    require_string(model.get("provider"), "model.provider")
    runner = document.get("runner")
    if not isinstance(runner, dict):
        raise InvalidResults("runner must be an object")
    require_string(runner.get("name"), "runner.name")
    require_string(runner.get("version"), "runner.version")
    skill_hashes = document.get("skill_hashes")
    if not isinstance(skill_hashes, dict):
        raise InvalidResults("skill_hashes must be an object")
    require_complete(set(skill_hashes), set(corpus), "skill_hashes")
    for skill, skill_corpus in corpus.items():
        if skill_hashes[skill] != skill_corpus["hash"]:
            raise InvalidResults(f"skill_hashes.{skill} does not match the canonical SKILL.md")

    runs = document.get("runs")
    if not isinstance(runs, list) or len(runs) < 2:
        raise InvalidResults("runs must contain at least two runs")
    indexed_runs = index_unique(runs, "id", "runs")
    scored_runs = []
    for run_id, run in indexed_runs.items():
        trigger_results = run.get("triggers")
        behaviour_results = run.get("behaviour")
        if not isinstance(trigger_results, list) or not isinstance(behaviour_results, list):
            raise InvalidResults(f"run {run_id!r} must contain trigger and behaviour arrays")
        metadata = run.get("metadata", {})
        if not isinstance(metadata, dict):
            raise InvalidResults(f"run {run_id!r} metadata must be an object")
        scored_runs.append(
            {
                "id": run_id,
                "metadata": metadata,
                "triggers": score_trigger_results(trigger_results, corpus, f"runs.{run_id}.triggers"),
                "behaviour": score_behaviour_results(
                    behaviour_results,
                    corpus,
                    f"runs.{run_id}.behaviour",
                ),
            }
        )

    aggregate = {
        "runs": len(scored_runs),
        "triggers": aggregate_counts(scored_runs, "triggers"),
        "behaviour": aggregate_behaviour(scored_runs),
    }
    return {
        "schema_version": 1,
        "selection": document["selection"],
        "model": model,
        "runner": runner,
        "skill_hashes": skill_hashes,
        "runs": scored_runs,
        "aggregate": aggregate,
    }


def aggregate_counts(runs: list[dict], section: str) -> dict:
    keys = ("true_positive", "true_negative", "false_positive", "false_negative")
    counts = {key: sum(run[section][key] for run in runs) for key in keys}
    positives = counts["true_positive"] + counts["false_negative"]
    negatives = counts["true_negative"] + counts["false_positive"]
    counts["false_positive_rate"] = counts["false_positive"] / negatives if negatives else 0
    counts["false_negative_rate"] = counts["false_negative"] / positives if positives else 0
    counts["total"] = positives + negatives
    return counts


def aggregate_behaviour(runs: list[dict]) -> dict:
    result = {
        key: sum(run["behaviour"][key] for run in runs)
        for key in ("cases_passed", "cases_total", "expectations_passed", "expectations_total")
    }
    result["case_pass_rate"] = result["cases_passed"] / result["cases_total"]
    result["expectation_pass_rate"] = (
        result["expectations_passed"] / result["expectations_total"]
    )
    return result


def percentage(value: float) -> str:
    return f"{value * 100:.1f}%"


def human_summary(report: dict) -> str:
    trigger = report["aggregate"]["triggers"]
    behaviour = report["aggregate"]["behaviour"]
    return "\n".join(
        (
            f"Eval results: {report['model']['name']} ({report['model']['reasoning']}), "
            f"{report['aggregate']['runs']} run(s)",
            f"Triggers: FP {trigger['false_positive']}/{trigger['true_negative'] + trigger['false_positive']} "
            f"({percentage(trigger['false_positive_rate'])}), FN "
            f"{trigger['false_negative']}/{trigger['true_positive'] + trigger['false_negative']} "
            f"({percentage(trigger['false_negative_rate'])})",
            f"Behaviour: {behaviour['cases_passed']}/{behaviour['cases_total']} mandatory cases "
            f"({percentage(behaviour['case_pass_rate'])}), "
            f"{behaviour['expectations_passed']}/{behaviour['expectations_total']} expectations "
            f"({percentage(behaviour['expectation_pass_rate'])})",
        )
    )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Score provider-independent skill eval results")
    parser.add_argument("results", type=pathlib.Path)
    parser.add_argument("--format", choices=("human", "json"), default="human")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    try:
        document = load_json(arguments.results)
        if not isinstance(document, dict):
            raise InvalidResults("results must be an object")
        selection = read_selection(document)
        report = score(document, load_corpus(selection["behaviour_category"]))
    except InvalidResults as error:
        print(f"invalid eval results: {error}", file=sys.stderr)
        return 1
    if arguments.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(human_summary(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
