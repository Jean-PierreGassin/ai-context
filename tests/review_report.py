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
SKILL_ROOT = REPOSITORY_ROOT / "resources" / "payload" / ".agents" / "skills" / "review-report"
BUILDER = SKILL_ROOT / "scripts" / "build_report.py"
TEMPLATE = SKILL_ROOT / "assets" / "report.html"


def git(directory: pathlib.Path, *arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", str(directory), *arguments],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


class BuildReportTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.directory.name)
        self.clone = self.root / "clone"
        self.clone.mkdir()
        git(self.clone, "init", "--quiet")
        git(self.clone, "config", "user.email", "test@example.com")
        git(self.clone, "config", "user.name", "Test")
        source = self.clone / "Checkout.php"
        source.write_text("<?php\n\nreturn $tickets->count() === $bundle;\n")
        git(self.clone, "add", ".")
        git(self.clone, "commit", "--quiet", "-m", "base")
        self.base = git(self.clone, "rev-parse", "HEAD")
        source.write_text("<?php\n\nreturn $tickets->unlocked()->count() === $bundle;\n")
        git(self.clone, "commit", "--quiet", "-am", "head")
        self.head = git(self.clone, "rev-parse", "HEAD")
        self.base_output = self.root / "base.txt"
        self.base_output.write_text("RESULT refused\n")
        self.head_output = self.root / "head.txt"
        self.head_output.write_text("RESULT accepted\n")
        self.data = {
            "pull": {"repository": "owner/repo", "number": 1, "title": "Change", "url": "https://example.com"},
            "tldr": ["Something changes."],
            "steps": [{"id": "pay", "actor": "Buyer", "title": "Checks out"}],
            "flags": [
                {
                    "at": "pay",
                    "kind": "critical",
                    "headline": "Partial bundles sell",
                    "summary": "The rest of a bundle sells.",
                    "code": [{"path": "Checkout.php", "line": 3, "note": "Locked tickets drop out"}],
                    "evidence": [
                        {"kind": "ran", "side": "base", "claim": "Base refuses", "command": "test", "output": str(self.base_output)},
                        {"kind": "ran", "side": "head", "claim": "Head accepts", "command": "test", "output": str(self.head_output)},
                        {"kind": "read", "repo": "owner/repo", "ref": self.head, "path": "Checkout.php", "line": 3, "quote": "unlocked()->count()", "claim": "Head counts unlocked tickets"},
                    ],
                }
            ],
        }

    def tearDown(self) -> None:
        self.directory.cleanup()

    def build(self, data: dict, audit: dict | None = None, draft: bool = False) -> subprocess.CompletedProcess:
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(data))
        arguments = [
            "python3", str(BUILDER),
            "--template", str(TEMPLATE),
            "--data", str(data_path),
            "--clone", str(self.clone),
            "--base", self.base,
            "--head", self.head,
            "--out", str(self.root / "out" / "report.html"),
        ]

        if draft:
            arguments.append("--draft")

        if audit is not None:
            if audit.get("dataSha256") == "match":
                audit = {**audit, "dataSha256": hashlib.sha256(data_path.read_bytes()).hexdigest()}

            audit_path = self.root / "audit.json"
            audit_path.write_text(json.dumps(audit))
            arguments += ["--audit", str(audit_path)]

        return subprocess.run(arguments, capture_output=True, text=True)

    def assert_refused(self, result: subprocess.CompletedProcess, reason: str) -> None:
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(reason, result.stderr)

    def test_builds_an_audited_report(self) -> None:
        result = self.build(self.data, audit={"dataSha256": "match", "verdict": "pass", "checked": 4})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('"state":"audited"', (self.root / "out" / "report.html").read_text())

    def test_refuses_a_final_report_without_an_audit(self) -> None:
        self.assert_refused(self.build(self.data), "needs --audit")

    def test_refuses_an_audit_of_other_data(self) -> None:
        result = self.build(self.data, audit={"dataSha256": "0" * 64, "verdict": "pass"})

        self.assert_refused(result, "different version of the data")

    def test_refuses_a_failed_audit(self) -> None:
        result = self.build(self.data, audit={"dataSha256": "match", "verdict": "fail"})

        self.assert_refused(result, "did not pass")

    def test_refuses_a_flag_without_evidence(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["evidence"] = []

        self.assert_refused(self.build(data, draft=True), "has no evidence")

    def test_refuses_a_quote_missing_from_its_line(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["evidence"][2]["quote"] = "notLocked()"

        self.assert_refused(self.build(data, draft=True), "which is not on Checkout.php:3")

    def test_refuses_a_critical_without_both_runs(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["evidence"] = data["flags"][0]["evidence"][1:]

        self.assert_refused(self.build(data, draft=True), "ran evidence on both base and head")

    def test_refuses_an_empty_run_output(self) -> None:
        self.head_output.write_text("")

        self.assert_refused(self.build(self.data, draft=True), "missing or empty")

    def test_keeps_each_code_location_highlight_in_one_file(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["code"] = [
            {"path": "Checkout.php", "line": 1, "note": "First"},
            {"path": "Checkout.php", "line": 3, "note": "Second"},
        ]
        result = self.build(data, draft=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))
        focused = [
            [row["new"] for row in location["rows"] if row.get("focus")]
            for location in payload["flags"][0]["code"]
        ]

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(focused, [[1], [3]])

    def test_refuses_unverified_points(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["unknowns"] = ["How often it happens in production"]

        self.assert_refused(self.build(data, draft=True), "verified facts only")

    def test_builds_a_self_review_without_pull_request_links(self) -> None:
        data = copy.deepcopy(self.data)
        data["mode"] = "self"
        data["pull"] = {"branch": "partial-bundles", "base": "main", "title": "Change"}
        data["flags"][0]["evidence"][2]["repo"] = "local"
        data["flags"][0]["comment"] = "keep locked tickets in the bundle count"
        result = self.build(data, draft=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))
        location = payload["flags"][0]["code"][0]

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("<title>partial-bundles self-review</title>", html)
        self.assertEqual([location["diffUrl"], location["fileUrl"]], [None, None])

    def test_writes_numbered_markdown_beside_the_page(self) -> None:
        data = copy.deepcopy(self.data)
        structure = copy.deepcopy(data["flags"][0])
        structure.update(kind="structure", headline="Count helper is misnamed")
        data["flags"].insert(0, structure)
        result = self.build(data, draft=True)
        markdown = (self.root / "out" / "report.md").read_text()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLess(markdown.index("### 1. [Critical] Partial bundles sell"), markdown.index("### 2. [Code quality] Count helper is misnamed"))
        self.assertIn("1. Buyer: Checks out · issues 1, 2", markdown)
        self.assertIn("- Code: Checkout.php:3: Locked tickets drop out", markdown)

    def test_refuses_a_step_file_the_change_does_not_touch(self) -> None:
        data = copy.deepcopy(self.data)
        data["steps"][0]["files"] = ["Other.php"]

        self.assert_refused(self.build(data, draft=True), "which this change does not touch")

    def test_writes_each_step_change_into_the_markdown(self) -> None:
        data = copy.deepcopy(self.data)
        data["steps"][0].update(before="Refused part of a bundle.", now="Counts unlocked tickets only.", files=["Checkout.php"])
        result = self.build(data, draft=True)
        markdown = (self.root / "out" / "report.md").read_text()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("   - Before: Refused part of a bundle.\n   - Now: Counts unlocked tickets only.\n   - Files: Checkout.php", markdown)

    def test_links_each_code_location_to_the_editor(self) -> None:
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(self.data))
        result = subprocess.run(
            [
                "python3", str(BUILDER),
                "--template", str(TEMPLATE),
                "--data", str(data_path),
                "--clone", str(self.clone),
                "--base", self.base,
                "--head", self.head,
                "--editor", "phpstorm://open?file={path}&line={line}",
                "--draft",
                "--out", str(self.root / "out" / "report.html"),
            ],
            capture_output=True,
            text=True,
        )
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(payload["flags"][0]["code"][0]["editorUrl"], f"phpstorm://open?file={self.clone.resolve()}/Checkout.php&line=3")

    def test_finds_the_flagged_line_where_the_checkout_has_it(self) -> None:
        git(self.clone, "checkout", "--quiet", self.base)
        (self.clone / "Checkout.php").write_text("<?php\n\n// moved\n\nreturn $tickets->unlocked()->count() === $bundle;\n")
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(self.data))
        arguments = ["--editor", "phpstorm://open?file={path}&line={line}", "--draft", "--out", str(self.root / "out" / "report.html")]
        subprocess.run(["python3", str(BUILDER), "--template", str(TEMPLATE), "--data", str(data_path), "--clone", str(self.clone), "--base", self.base, "--head", self.head, *arguments], check=True, capture_output=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))

        self.assertTrue(payload["flags"][0]["code"][0]["editorUrl"].endswith("Checkout.php&line=5"))

    def test_leaves_out_the_editor_link_when_the_code_is_not_checked_out(self) -> None:
        git(self.clone, "checkout", "--quiet", self.base)
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(self.data))
        arguments = ["--editor", "phpstorm://open?file={path}&line={line}", "--draft", "--out", str(self.root / "out" / "report.html")]
        subprocess.run(["python3", str(BUILDER), "--template", str(TEMPLATE), "--data", str(data_path), "--clone", str(self.clone), "--base", self.base, "--head", self.head, *arguments], check=True, capture_output=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))

        self.assertIsNone(payload["flags"][0]["code"][0]["editorUrl"])

    def test_links_a_read_at_the_pull_request_head(self) -> None:
        result = self.build(self.data, draft=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(payload["flags"][0]["evidence"][2]["url"], f"https://github.com/owner/repo/blob/{self.head}/Checkout.php#L3")

    def test_links_no_unpushed_read_in_a_self_review(self) -> None:
        data = copy.deepcopy(self.data)
        data["mode"] = "self"
        data["pull"] = {"repository": "owner/repo", "branch": "partial-bundles", "base": "main", "title": "Change"}
        data["flags"][0]["comment"] = "keep locked tickets in the bundle count"
        result = self.build(data, draft=True)
        html = (self.root / "out" / "report.html").read_text()
        payload = json.loads(html.split('id="report-data">', 1)[1].split("</script>", 1)[0].replace("<\\/", "</"))

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(payload["flags"][0]["evidence"][2]["url"])

    def test_refuses_a_self_review_flag_without_a_fix(self) -> None:
        data = copy.deepcopy(self.data)
        data["mode"] = "self"
        data["pull"] = {"branch": "partial-bundles", "base": "main", "title": "Change"}
        data["flags"][0]["evidence"][2]["repo"] = "local"
        data["flags"][0].pop("comment", None)

        self.assert_refused(self.build(data, draft=True), "needs a comment saying what to fix")

    def test_refuses_an_audit_that_lists_problems(self) -> None:
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(self.data))
        digest = hashlib.sha256(data_path.read_bytes()).hexdigest()
        audit = self.root / "audit.json"
        audit.write_text(json.dumps({"dataSha256": digest, "verdict": "pass", "problems": [{"sentence": "x"}]}))
        result = subprocess.run(["python3", str(BUILDER), "--template", str(TEMPLATE), "--data", str(data_path), "--clone", str(self.clone), "--base", self.base, "--head", self.head, "--audit", str(audit), "--out", str(self.root / "out" / "report.html")], capture_output=True, text=True)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not pass", result.stderr)

    def test_counts_lines_like_git_when_a_line_holds_a_form_feed(self) -> None:
        (self.clone / "Feed.php").write_text("one\ntwo \x0c mid\nthree target\n")
        git(self.clone, "add", "Feed.php")
        git(self.clone, "commit", "--quiet", "-m", "feed")
        head = git(self.clone, "rev-parse", "HEAD").strip()
        data = copy.deepcopy(self.data)
        data["flags"][0]["evidence"].append({"kind": "read", "repo": "owner/repo", "ref": head, "path": "Feed.php", "line": 3, "quote": "three target", "claim": "Line 3 holds the target"})
        data_path = self.root / "data.json"
        data_path.write_text(json.dumps(data))
        result = subprocess.run(["python3", str(BUILDER), "--template", str(TEMPLATE), "--data", str(data_path), "--clone", str(self.clone), "--base", self.base, "--head", head, "--draft", "--out", str(self.root / "out" / "report.html")], capture_output=True, text=True)

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_refuses_a_pull_request_review_without_a_number(self) -> None:
        data = copy.deepcopy(self.data)
        del data["pull"]["number"]

        self.assert_refused(self.build(data, draft=True), "needs pull.repository and pull.number")

    def test_snapshot_captures_uncommitted_work_without_moving_the_branch(self) -> None:
        (self.clone / "Checkout.php").write_text("<?php\n\nreturn true;\n")
        (self.clone / "New.php").write_text("<?php\n")
        snapshot = subprocess.run(
            ["sh", str(SKILL_ROOT / "scripts" / "snapshot.sh"), str(self.clone)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

        self.assertEqual(git(self.clone, "rev-parse", "HEAD"), self.head)
        self.assertEqual(git(self.clone, "show", f"{snapshot}:Checkout.php"), "<?php\n\nreturn true;")
        self.assertEqual(git(self.clone, "show", f"{snapshot}:New.php"), "<?php")
        self.assertEqual(git(self.clone, "status", "--porcelain"), "M Checkout.php\n?? New.php")

    def test_refuses_reading_an_unknown_repository(self) -> None:
        data = copy.deepcopy(self.data)
        data["flags"][0]["evidence"][2]["repo"] = "owner/other"

        self.assert_refused(self.build(data, draft=True), "has no --repo clone")


if __name__ == "__main__":
    unittest.main()
