---
name: run-commands
description: Use whenever running project, environment, development, operational, infrastructure, cloud, logging, or diagnostic commands, including through task runners, project CLIs, shells, containers, or vendor tools.
when_to_use: Triggers on requests that require executing or choosing commands for a project or its runtime environment, including tests, formatting, worktrees, services, databases, logs, cloud inspection, or operational diagnostics. Applies on top of project and plugin guidance.
---

# Run Commands

Use the project's own interface to its environment and infrastructure before reaching for lower-level tools.

## Discover the execution environment

Before running project, environment, or operational commands:

1. Identify the current working directory and execution environment
2. Preserve an existing project shell, container, development environment, or equivalent when one is already active
3. Read committed project instructions that define how commands should run
4. Discover the project's harness, task runner, scripts, internal CLI, or equivalent command surface
5. Use its help, list, or other read-only discovery interface when the available commands are not already clear

Do not assume a specific harness, task runner, container system, cloud, language tool, or command name.

## Prefer project tooling

When the project provides an operation, use it instead of reproducing that operation with lower-level commands.

This includes:

- environment setup and dependency commands
- worktrees and branch-local resources
- databases, ports, and services
- formatting, tests, and validation
- logs and runtime inspection
- operational and infrastructure inspection
- cloud resource inspection
- feature, service, or development controls

A project command can perform setup, ownership tracking, resource allocation, authentication, cleanup, or safety checks that are not visible from the lower-level command.

Use a lower-level tool only when the project does not provide the required operation or its tooling cannot perform it.

## Read-only operational access

When investigating logs, runtime state, infrastructure, cloud resources, or operational behaviour:

1. Look for project-provided or internal tooling first
2. Prefer an existing read-only path when one is available
3. Use read-only inspection without asking for permission when the user's task already requires that investigation and existing access is sufficient
4. Fall back to the underlying platform or vendor tooling when the project tooling cannot answer the question
5. Ask for access only after the available project and read-only paths have been checked

This includes internal commands that wrap logs, cloud providers, container orchestration, databases, queues, metrics, or deployment state.

Do not bypass a project wrapper merely because the underlying vendor CLI is familiar.

## Mutation boundary

Read-only discovery does not authorize mutation.

Do not deploy, restart, scale, write production data, change cloud resources, toggle operational state, or perform another remote mutation unless the user requested or approved that action.

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
