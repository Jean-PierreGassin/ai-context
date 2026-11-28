---
name: run-commands
description: Run project and environment commands through the project's own interface. Use for tests, formatting, services, task runners, diagnostics, or infrastructure.
---

Use the project's own interface: read its committed instructions, then run its harness, task runner or internal CLI, preferring read-only discovery. Vendor tools cover what that interface can't. Take project commands from its docs and help output.

- Run one plain command per call, from the intended checkout, so permission checks can verify it.
- Run lint and static analysis in the background while other work continues, and wait for the completion notice. CI runs the full test suite.
- Treat read-only access as read-only. Remote and production changes come from the user or the active workflow.
