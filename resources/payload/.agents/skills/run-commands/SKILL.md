---
name: run-commands
description: Run project, environment, infrastructure, cloud, logging, or diagnostic commands through the correct interface.
when_to_use: Use whenever choosing or executing project or operational commands, including tests, formatting, worktrees, services, databases, logs, and cloud inspection.
---

# Run Commands

Use the project's own interface to its environment and infrastructure before reaching for lower-level tools.

## Discover the execution environment

Before running project, environment, or operational commands:

1. Identify the working directory and execution environment
2. Preserve an existing project shell, container, development environment, or equivalent when one is already active
3. Read committed project instructions that define how commands should run
4. Discover the project's harness, task runner, scripts, or internal CLI
5. Use its help, list, or other read-only discovery interface when the available commands are not already clear

Do not assume a specific harness, task runner, container system, cloud, language tool, or command name.

## Prefer project tooling

Use a project operation instead of reproducing it with lower-level commands. This includes:

- environment setup and dependency commands
- worktrees and branch-local resources
- databases, ports, and services
- formatting, tests, and validation
- logs and runtime inspection
- operational, infrastructure, and cloud inspection
- feature, service, or development controls

Project commands may include setup, ownership, authentication, cleanup, and safety checks. Fall back only when they
cannot perform the operation.

## Read-only operational access

When investigating logs, runtime state, infrastructure, cloud resources, or operational behaviour:

1. Look for project-provided or internal tooling first
2. Use existing read-only access without another prompt when the task requires the investigation
3. Fall back to platform or vendor tooling only when project tooling cannot answer the question
4. Ask for access only after checking available read-only paths

Do not bypass a project wrapper merely because the underlying vendor CLI is familiar.

## Mutation boundary

Read-only discovery does not authorize mutation.

Do not mutate remote or production state unless the user requested or approved it.

When mutation is authorized, still prefer the project's command for it.

A command already authorized by another active workflow, such as creating an agreed worktree, formatting code, or running project tests, does not need another confirmation merely because this skill executes it.

## Fallback order

Use this order:

1. Existing project execution environment
2. Project harness, task runner, scripts, or internal CLI
3. Tools exposed through that environment
4. Direct lower-level or vendor tooling
5. Ask the user only when required access, information, or authorization is still unavailable

Do not invent project commands. Inspect the available interface first.
