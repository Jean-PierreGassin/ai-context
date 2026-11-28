---
name: verify
description: Verify finished work end to end before reporting it done, combining automated checks, mutation-proving tests, and real runtime or visual checks. Use when work looks done, before presenting a diff, or before claiming a fix works.
---

Verify the finished change against the real system before calling it done.

Check `${XDG_CONFIG_HOME:-$HOME/.config}/agents/verify` when it exists, plus the project's committed instructions, for how to start the app, its base URL, any local dev auth shortcut, and log file paths.

## Process

1. Run `sh <agents>/hooks/verify-changes.sh handoff` from the repository root (using the repo's `.agents/` or `~/.agents/`) and fix anything it flags.
2. Check `git diff --name-only` against trunk and run the matching runtime checks (the `scripts/` helpers live inside this skill's directory):
   - **New or changed tests:** run `python3 scripts/prove-tests.py -- <test command>` to confirm they fail against the trunk version of the changed files.
   - **Backend, HTTP, or API changes:** start or target the local app and run `python3 scripts/verify-http.py --url <url> --expect-status <code>` (plus `--log-file <path>` when the app writes logs) to check status, body, and server logs.
   - **CLI or script changes:** run `python3 scripts/verify-cli.py -- <command>` on realistic inputs to check exit code, stdout, and stderr.
   - **UI or visual changes:** use whatever headless browser tool is available in the environment to walk the real flow, confirm zero console, page, or HTTP `>= 400` errors, capture screenshots of key states, and inspect them visually.
3. Loop on any failing check until everything passes without weakening assertions or skipping cases.
4. Report the Evidence section with the exact commands run, observed output/exit status, and visual or log check results. Name anything you could not verify.
