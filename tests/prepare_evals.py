#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import subprocess
import unittest

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parent.parent
PREPARER = REPOSITORY_ROOT / "scripts" / "prepare_evals.py"


class PrepareEvalsTest(unittest.TestCase):
    def run_preparer(self, *arguments: str) -> dict:
        completed = subprocess.run(
            [str(PREPARER), *arguments],
            capture_output=True,
            check=False,
            text=True,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        return json.loads(completed.stdout)

    def test_exports_complete_blind_tasks(self) -> None:
        document = self.run_preparer()

        self.assertEqual(document["selection"], {"behaviour_category": None})
        self.assertTrue(document["triggers"])
        self.assertTrue(document["behaviour"])
        self.assertTrue(document["skill_hashes"])
        self.assertIn("skill_content", document["triggers"][0])
        self.assertIn("skill_content", document["behaviour"][0])
        self.assertIn("fixture", document["behaviour"][0])
        self.assertTrue(all("should_trigger" not in task for task in document["triggers"]))
        self.assertTrue(all("expectations" not in task for task in document["behaviour"]))
        self.assertTrue(all("expected_output" not in task for task in document["behaviour"]))

    def test_exports_regression_behaviour_and_all_triggers(self) -> None:
        full = self.run_preparer()
        regression = self.run_preparer("--category", "regression")
        regression_ids = {
            case["id"]
            for path in (REPOSITORY_ROOT / "evals" / "skills").glob("*/behaviour.json")
            for case in json.loads(path.read_text())["evals"]
            if case.get("category") == "regression"
        }

        self.assertEqual(regression["selection"], {"behaviour_category": "regression"})
        self.assertEqual(len(regression["triggers"]), len(full["triggers"]))
        self.assertEqual({task["case_id"] for task in regression["behaviour"]}, regression_ids)


if __name__ == "__main__":
    unittest.main()
