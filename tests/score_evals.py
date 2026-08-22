#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import json
import pathlib
import subprocess
import tempfile
import unittest

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
RUNNER = REPOSITORY_ROOT / "scripts" / "score_evals.py"
EVALS_ROOT = REPOSITORY_ROOT / "evals" / "skills"
SKILLS_ROOT = REPOSITORY_ROOT / "resources" / "payload" / ".agents" / "skills"


def complete_results(category: str | None = None) -> dict:
    triggers = []
    behaviour = []
    for skill_root in sorted(EVALS_ROOT.iterdir()):
        trigger_cases = json.loads((skill_root / "triggers.json").read_text())
        behaviour_cases = [
            case
            for case in json.loads((skill_root / "behaviour.json").read_text())["evals"]
            if category is None or case.get("category") == category
        ]
        triggers.append(
            {
                "skill": skill_root.name,
                "cases": [
                    {
                        "query": case["query"],
                        "triggered": case["should_trigger"],
                        "response": "Observed skill selection output",
                        "rationale": "Selection matches the applicable skill boundary",
                    }
                    for case in trigger_cases
                ],
            }
        )
        behaviour.append(
            {
                "skill": skill_root.name,
                "cases": [
                    {
                        "id": case["id"],
                        "response": "Observed model response",
                        "rationale": "The response was judged against every expectation",
                        "expectations": [
                            {
                                "expectation": expectation,
                                "passed": True,
                                "evidence": "The response or recorded tool state demonstrates this expectation",
                            }
                            for expectation in case["expectations"]
                        ],
                    }
                    for case in behaviour_cases
                ],
            }
        )
    first_run = {
        "id": "run-1",
        "metadata": {"seed": 1},
        "triggers": triggers,
        "behaviour": behaviour,
    }
    second_run = copy.deepcopy(first_run)
    second_run["id"] = "run-2"
    second_run["metadata"] = {"seed": 2}
    return {
        "schema_version": 1,
        "selection": {"behaviour_category": category},
        "model": {"name": "example-model", "reasoning": "high", "provider": "example"},
        "runner": {"name": "example-runner", "version": "1.2.3"},
        "skill_hashes": {
            skill_root.name: hashlib.sha256((skill_root / "SKILL.md").read_bytes()).hexdigest()
            for skill_root in sorted(SKILLS_ROOT.iterdir())
            if (skill_root / "SKILL.md").is_file()
        },
        "runs": [first_run, second_run],
    }


class ScoreEvalsTest(unittest.TestCase):
    def run_runner(self, results: dict, output_format: str = "json") -> subprocess.CompletedProcess:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json") as result_file:
            json.dump(results, result_file)
            result_file.flush()
            return subprocess.run(
                [str(RUNNER), result_file.name, "--format", output_format],
                capture_output=True,
                check=False,
                text=True,
            )

    def test_scores_repeated_complete_runs_and_preserves_metadata(self) -> None:
        completed = self.run_runner(complete_results())

        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads(completed.stdout)
        self.assertEqual(report["aggregate"]["runs"], 2)
        self.assertEqual(report["aggregate"]["triggers"]["false_positive"], 0)
        self.assertEqual(report["aggregate"]["triggers"]["false_negative"], 0)
        self.assertEqual(report["aggregate"]["behaviour"]["case_pass_rate"], 1)
        self.assertEqual(report["model"]["reasoning"], "high")
        self.assertEqual(report["runner"]["version"], "1.2.3")
        self.assertEqual(report["runs"][1]["metadata"], {"seed": 2})
        self.assertTrue(report["runs"][0]["behaviour"]["cases"][0]["expectations"][0]["evidence"])

    def test_counts_false_positives_false_negatives_and_mandatory_expectations(self) -> None:
        results = complete_results()
        positive = next(
            case
            for skill in results["runs"][0]["triggers"]
            for case in skill["cases"]
            if case["triggered"]
        )
        negative = next(
            case
            for skill in results["runs"][0]["triggers"]
            for case in skill["cases"]
            if not case["triggered"]
        )
        positive["triggered"] = False
        negative["triggered"] = True
        expectations = results["runs"][0]["behaviour"][0]["cases"][0]["expectations"]
        expectations[0]["passed"] = False

        completed = self.run_runner(results)

        report = json.loads(completed.stdout)
        self.assertEqual(report["aggregate"]["triggers"]["false_positive"], 1)
        self.assertEqual(report["aggregate"]["triggers"]["false_negative"], 1)
        self.assertEqual(
            report["runs"][0]["behaviour"]["cases_passed"],
            report["runs"][0]["behaviour"]["cases_total"] - 1,
        )
        self.assertEqual(len(report["runs"][0]["triggers"]["failures"]), 2)
        self.assertEqual(len(report["runs"][0]["behaviour"]["failures"]), 1)
        self.assertIn("expectation", report["runs"][0]["behaviour"]["failures"][0])

    def test_rejects_a_missing_expectation_verdict(self) -> None:
        results = complete_results()
        results["runs"][0]["behaviour"][0]["cases"][0]["expectations"].pop()

        completed = self.run_runner(results)

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("is incomplete", completed.stderr)

    def test_rejects_missing_expectation_evidence(self) -> None:
        results = complete_results()
        del results["runs"][0]["behaviour"][0]["cases"][0]["expectations"][0]["evidence"]

        completed = self.run_runner(results)

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("evidence must be a non-empty string", completed.stderr)

    def test_rejects_one_run_or_a_stale_skill_hash(self) -> None:
        one_run = complete_results()
        one_run["runs"].pop()
        stale_hash = complete_results()
        skill = next(iter(stale_hash["skill_hashes"]))
        stale_hash["skill_hashes"][skill] = "0" * 64

        one_run_result = self.run_runner(one_run)
        stale_hash_result = self.run_runner(stale_hash)

        self.assertNotEqual(one_run_result.returncode, 0)
        self.assertIn("at least two runs", one_run_result.stderr)
        self.assertNotEqual(stale_hash_result.returncode, 0)
        self.assertIn("does not match", stale_hash_result.stderr)

    def test_requires_provenance_responses_and_rationales(self) -> None:
        mutations = (
            ("provider", lambda results: results["model"].pop("provider")),
            ("runner.name", lambda results: results["runner"].pop("name")),
            (
                "response",
                lambda results: results["runs"][0]["triggers"][0]["cases"][0].pop("response"),
            ),
            (
                "rationale",
                lambda results: results["runs"][0]["behaviour"][0]["cases"][0].pop(
                    "rationale"
                ),
            ),
        )

        for expected_error, mutate in mutations:
            with self.subTest(field=expected_error):
                results = complete_results()
                mutate(results)

                completed = self.run_runner(results)

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(expected_error, completed.stderr)

    def test_rejects_an_incomplete_trigger_run(self) -> None:
        results = complete_results()
        results["runs"][0]["triggers"][0]["cases"].pop()

        completed = self.run_runner(results)

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("is incomplete", completed.stderr)

    def test_scores_a_declared_regression_suite_and_rejects_mismatched_results(self) -> None:
        regression = complete_results("regression")
        mismatched = complete_results("regression")
        mismatched["selection"] = {"behaviour_category": None}

        completed = self.run_runner(regression)
        rejected = self.run_runner(mismatched)

        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads(completed.stdout)
        self.assertEqual(report["selection"], {"behaviour_category": "regression"})
        expected_cases = sum(
            len(skill["cases"])
            for skill in regression["runs"][0]["behaviour"]
        )
        self.assertEqual(report["aggregate"]["behaviour"]["cases_total"], expected_cases * 2)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn("is incomplete", rejected.stderr)

    def test_prints_a_concise_human_summary(self) -> None:
        completed = self.run_runner(complete_results(), "human")

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("2 run(s)", completed.stdout)
        self.assertIn("Triggers: FP 0/", completed.stdout)
        self.assertIn("Behaviour:", completed.stdout)


if __name__ == "__main__":
    unittest.main()
