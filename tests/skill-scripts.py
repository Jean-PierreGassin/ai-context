#!/usr/bin/env python3
"""Tests for reusable scripts shipped inside skills."""
from __future__ import annotations

import http.server
import os
import pathlib
import shutil
import subprocess
import tempfile
import threading
import unittest


REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_ROOT = REPO_ROOT / "resources" / "payload" / ".agents" / "skills"


def run(cmd: list[str], cwd: pathlib.Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    return subprocess.run(cmd, cwd=cwd, env=merged_env, capture_output=True, text=True)


def init_git_repo(path: pathlib.Path) -> None:
    subprocess.run(["git", "init", "-b", "main"], cwd=path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=path, check=True, capture_output=True)


class SkillScriptsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix="ai-context-skill-scripts-"))

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_prove_tests_passes_when_trunk_fails_and_restores_files(self) -> None:
        repo = self.tmp / "repo-prove"
        repo.mkdir()
        init_git_repo(repo)
        (repo / "app.py").write_text("VALUE = 1\n")
        (repo / "tests").mkdir()
        (repo / "tests" / "test_app.py").write_text(
            "import app\nassert app.VALUE == 2\n"
        )
        subprocess.run(["git", "add", "app.py"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "init"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "checkout", "-b", "feat/fix"], cwd=repo, check=True, capture_output=True)
        (repo / "app.py").write_text("VALUE = 2\n")

        script = SKILLS_ROOT / "verify" / "scripts" / "prove-tests.py"
        res = run(["python3", str(script), "--base", "main", "--", "python3", "tests/test_app.py"], cwd=repo)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("PASS:", res.stdout)
        self.assertEqual((repo / "app.py").read_text(), "VALUE = 2\n")

        # Now prove-tests should fail if the test still passes on trunk
        (repo / "tests" / "test_app.py").write_text("assert True\n")
        bad = run(["python3", str(script), "--base", "main", "--", "python3", "tests/test_app.py"], cwd=repo)
        self.assertEqual(bad.returncode, 1)
        self.assertEqual((repo / "app.py").read_text(), "VALUE = 2\n")

    def test_verify_http_checks_status_body_and_appended_logs(self) -> None:
        log_file = self.tmp / "app.log"
        log_file.write_text("INFO old error-free boot\nERROR old historical error\n")

        mode = {"emit_error": False, "status": 200}

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self) -> None:
                if mode["emit_error"]:
                    with log_file.open("a") as fh:
                        fh.write("ERROR failed to render invoice\n")
                self.send_response(mode["status"])
                self.end_headers()
                self.wfile.write(b"ok-invoice-123")

            def log_message(self, format: str, *args: object) -> None:
                return

        server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
        port = server.server_address[1]
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            script = SKILLS_ROOT / "verify" / "scripts" / "verify-http.py"
            ok = run(
                [
                    "python3",
                    str(script),
                    "--url",
                    f"http://127.0.0.1:{port}/",
                    "--expect-status",
                    "200",
                    "--expect-body",
                    "invoice-123",
                    "--log-file",
                    str(log_file),
                ],
                cwd=self.tmp,
            )
            self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)

            mode["emit_error"] = True
            bad_log = run(
                [
                    "python3",
                    str(script),
                    "--url",
                    f"http://127.0.0.1:{port}/",
                    "--log-file",
                    str(log_file),
                ],
                cwd=self.tmp,
            )
            self.assertEqual(bad_log.returncode, 1)
            self.assertIn("ERROR failed to render invoice", bad_log.stderr)

            mode["emit_error"] = False
            mode["status"] = 500
            bad_status = run(
                ["python3", str(script), "--url", f"http://127.0.0.1:{port}/", "--expect-status", "200"],
                cwd=self.tmp,
            )
            self.assertEqual(bad_status.returncode, 1)
        finally:
            server.shutdown()
            server.server_close()

    def test_verify_cli_checks_exit_and_streams(self) -> None:
        script = SKILLS_ROOT / "verify" / "scripts" / "verify-cli.py"
        ok = run(
            [
                "python3",
                str(script),
                "--expect-exit",
                "0",
                "--expect-stdout",
                "hello",
                "--forbid-stderr",
                "FATAL",
                "--",
                "python3",
                "-c",
                "print('hello world')",
            ],
            cwd=self.tmp,
        )
        self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)

        bad = run(
            [
                "python3",
                str(script),
                "--forbid-stderr",
                "boom",
                "--",
                "python3",
                "-c",
                "import sys; sys.stderr.write('boom')",
            ],
            cwd=self.tmp,
        )
        self.assertEqual(bad.returncode, 1)

    def test_handoff_state_and_lock(self) -> None:
        repo = self.tmp / "my-app"
        repo.mkdir()
        init_git_repo(repo)
        (repo / "README.md").write_text("hi\n")
        subprocess.run(["git", "add", "README.md"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "init"], cwd=repo, check=True, capture_output=True)

        wt = self.tmp / "my-app-wt"
        subprocess.run(["git", "worktree", "add", "-b", "feat/demo", str(wt)], cwd=repo, check=True, capture_output=True)

        lock_script = SKILLS_ROOT / "handoff" / "scripts" / "handoff-finish.sh"
        lock_res = run(["bash", str(lock_script), "lock", str(wt), "ABC-1 - Demo", "sess-123"], cwd=repo)
        self.assertEqual(lock_res.returncode, 0, lock_res.stderr)

        state_script = SKILLS_ROOT / "handoff" / "scripts" / "handoff-state.py"
        state_home = self.tmp / "state"
        state_res = run(["python3", str(state_script)], cwd=wt, env={"XDG_STATE_HOME": str(state_home)})
        self.assertEqual(state_res.returncode, 0, state_res.stderr)
        self.assertIn("Branch: feat/demo @", state_res.stdout)
        self.assertIn("handoff: owned by ABC-1 - Demo; previous session sess-123 stopped", state_res.stdout)
        self.assertIn(str(state_home / "agents" / "handoff" / "my-app-wt-feat-demo.md"), state_res.stdout)

    def test_diff_and_pr_context(self) -> None:
        repo = self.tmp / "repo-pr"
        repo.mkdir()
        init_git_repo(repo)
        (repo / ".github").mkdir()
        (repo / ".github" / "pull_request_template.md").write_text("Template\n")
        (repo / "a.txt").write_text("one\n")
        subprocess.run(["git", "add", "."], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "init"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "checkout", "-b", "feat/one"], cwd=repo, check=True, capture_output=True)
        (repo / "a.txt").write_text("two\n")
        subprocess.run(["git", "commit", "-am", "update a"], cwd=repo, check=True, capture_output=True)

        diff_script = SKILLS_ROOT / "review-code" / "scripts" / "diff-context.py"
        diff_res = run(["python3", str(diff_script), "main"], cwd=repo)
        self.assertEqual(diff_res.returncode, 0, diff_res.stderr)
        self.assertIn("Range: main...HEAD", diff_res.stdout)
        self.assertIn("update a", diff_res.stdout)

        pr_script = SKILLS_ROOT / "write-pr" / "scripts" / "pr-context.py"
        pr_res = run(["python3", str(pr_script), "main"], cwd=repo)
        self.assertEqual(pr_res.returncode, 0, pr_res.stderr)
        self.assertIn("Behind target: 0, Ahead: 1", pr_res.stdout)
        self.assertIn(".github/pull_request_template.md", pr_res.stdout)

    def test_safe_remove_worktree(self) -> None:
        repo = self.tmp / "repo-wt"
        repo.mkdir()
        init_git_repo(repo)
        (repo / "a.txt").write_text("one\n")
        subprocess.run(["git", "add", "a.txt"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", "init"], cwd=repo, check=True, capture_output=True)

        wt = self.tmp / "wt-clean"
        subprocess.run(["git", "worktree", "add", "-b", "feat/wt", str(wt)], cwd=repo, check=True, capture_output=True)

        safe_remove = SKILLS_ROOT / "use-worktrees" / "scripts" / "safe-remove.sh"

        # Uncommitted change should refuse removal
        (wt / "dirty.txt").write_text("dirty\n")
        dirty_res = run(["bash", str(safe_remove), str(wt)], cwd=repo)
        self.assertEqual(dirty_res.returncode, 1)
        self.assertTrue(wt.exists())
        (wt / "dirty.txt").unlink()

        # Unmerged commit without upstream should refuse removal
        (wt / "a.txt").write_text("two\n")
        subprocess.run(["git", "commit", "-am", "unmerged"], cwd=wt, check=True, capture_output=True)
        unmerged_res = run(["bash", str(safe_remove), str(wt)], cwd=repo)
        self.assertEqual(unmerged_res.returncode, 1)
        self.assertTrue(wt.exists())

        # Merge into main, lock worktree, and verify safe-remove cleans it up even from outside the repo
        subprocess.run(["git", "merge", "--ff-only", "feat/wt"], cwd=repo, check=True, capture_output=True)
        subprocess.run(["git", "worktree", "lock", "--reason", "handoff", str(wt)], cwd=repo, check=True, capture_output=True)
        ok_res = run(["bash", str(safe_remove), str(wt)], cwd=self.tmp)
        self.assertEqual(ok_res.returncode, 0, ok_res.stdout + ok_res.stderr)
        self.assertFalse(wt.exists())


if __name__ == "__main__":
    unittest.main()
