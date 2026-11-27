---
name: handoff
description: Write a handoff prompt that lets an expert engineer continue the current work cold. Use when handing work to another session, agent, or person.
---

# Handoff

Write the prompt a senior engineer needs to continue this work without the conversation. Assume they are expert in the
stack and know nothing about this task.

## Process

1. Establish the goal, what is done, what remains, and the agreed decisions from the session and the repository
2. Verify current state: branch, HEAD, working tree, open PR, and the last validation result
3. Locate the plan, context, ticket, and reference files already in use and cite them by exact path or link
4. Split the remaining work into the pieces already defined, or into independently completable pieces when none exist
5. Fill the [template](#template), dropping any section that has nothing true to say
6. Save and copy the prompt as described in [Output](#output)

## Rules

- Write to the receiver as instructions in the imperative
- State facts plainly. No hedging, filler, praise, or narrative of how the session went
- Keep only what changes the next action: decisions and their reasons, constraints, traps already hit, and dead ends
  not to retry
- Reference the plan, context, and source files instead of restating them
- Use exact paths, commands, branch names, ticket keys, and symbol names
- Mark anything unverified as unverified; never present a guess as state
- Mark the first piece to start with
- State each piece's done as a check the receiver can run: a test or command and the result that means it passed. Tell
  the receiver to loop on it until it passes. Never define done as prose alone
- Write no preamble, summary, or commentary inside the prompt

## Template

```markdown
# Handoff: {task}

## Goal
{Outcome and why, in one or two sentences}

## Read first
- {Plan, context, ticket, or reference path or link}: {what it holds}

## State
- Location: {repository path or worktree}, branch `{branch}` at `{short SHA}`, {clean or uncommitted summary}
- Done: {completed piece}
- Validation: {last command run and its result}

## Decisions
- {Decision}: {reason}

## Remaining work
1. {Piece}. Done when `{command}` {expected result}. Files: `{path}`. Start here
2. {Piece}. Done when `{command}` {expected result}

## Constraints and traps
- {Constraint, trap, or dead end}

## Verify with
`{command}`
```

## Output

Generate the prompt once. Never repeat it in the reply or in a command.

1. Write the prompt with the file-writing tool to `${TMPDIR:-/tmp}/handoff/{repository}-{branch}.md`, overwriting any
   earlier handoff at that path
2. Copy the file without asking, by redirecting it into the platform command: `pbcopy < {file}` on macOS,
   `wl-copy < {file}` or `xclip -selection clipboard < {file}` on Linux, and `clip.exe < {file}` on WSL or Windows
3. Reply in one line with the file path and whether the copy succeeded
