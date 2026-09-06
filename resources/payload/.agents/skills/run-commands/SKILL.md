---
name: run-commands
description: Run project, harness, and environment commands through the correct interface. Use for tests, formatting, services, task runners, diagnostics, infrastructure, or any other command the project environment supplies.
---

# Run Commands

Use the project's own interface before lower-level tools.

## Process

1. Identify the working directory and execution environment
2. Read committed instructions that define how commands run
3. Discover the project's harness, scripts, task runner, task files, internal CLI, or other supplied command interface
4. Prefer its read-only discovery and execution paths
5. Fall back to lower-level or vendor tools only when the project interface cannot perform the operation

## Safety

- Read-only discovery does not authorize mutation
- Do not mutate remote or production state unless requested or already authorized by the active workflow
- Prefer existing read-only access before asking for more access
- Do not invent project commands
