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
6. Output only the prompt in one fenced `markdown` block, then the [clipboard offer](#clipboard)

## Rules

- Write to the receiver as instructions in the imperative
- State facts plainly. No hedging, filler, praise, or narrative of how the session went
- Keep only what changes the next action: decisions and their reasons, constraints, traps already hit, and dead ends
  not to retry
- Reference the plan, context, and source files instead of restating them
- Use exact paths, commands, branch names, ticket keys, and symbol names
- Mark anything unverified as unverified; never present a guess as state
- Mark the first piece to start with
- Write no preamble, summary, or commentary outside the block

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
1. {Piece}: {what done means}. Files: `{path}`. Start here
2. {Piece}: {what done means}

## Constraints and traps
- {Constraint, trap, or dead end}

## Verify with
`{command}`
```

## Clipboard

After the block, ask in one line whether to copy the prompt to the clipboard. On approval, copy exactly the block's
contents with the platform command: `pbcopy` on macOS, `wl-copy` or `xclip -selection clipboard` on Linux, and
`clip.exe` on WSL or Windows.
