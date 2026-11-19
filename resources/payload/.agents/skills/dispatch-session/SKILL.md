---
name: dispatch-session
description: Hand a piece of work to a new background session that starts inside its own worktree, and track it from the current session as orchestrator. Use when work started from a shared or root checkout needs its own worktree, or when one session coordinates several tracks.
---

# Dispatch Session

The current session orchestrates. Each piece of work runs in its own background session, launched inside its own
worktree, so it starts isolated and never needs to switch checkouts mid-session.

Requires Claude Code background sessions (`claude --bg`). Other agents use `use-worktrees` and `handoff` instead.

## When

Dispatch only when `use-worktrees` says the work needs its own worktree. Small changes stay in the current session.

## Size each session

Pick the model and effort for the work, and pass them as `--model` and `--effort`:

- Design, debugging with an unknown cause, or anything the handoff leaves open: the default model at its default
  effort or above
- Mechanical, fully specified work, such as applying a settled plan, a rename, or a dependency bump: a smaller, faster
  model at low or medium effort
- Never raise effort to compensate for a vague handoff. Fix the handoff

## Process

1. Create the worktree through the project's own operation, as `use-worktrees` describes. Run it in the background
   when it is slow, then wait for it to report ready
2. Use `handoff` to write the handoff, so the new session can start cold
3. Launch the session from inside the worktree. The session's working directory is the shell's at launch, so change
   into the worktree in its own command, launch, then change back so the orchestrator keeps working where it started:

   ```sh
   claude --bg --name "<slug>" --model "<model>" --effort "<level>" "Read <path handoff reported> and continue the work it describes."
   ```

4. Track it with `claude agents --json --all`, selecting by name. States are `working`, `blocked`, `done`, `failed`
   and `stopped`. Report one status line per check
5. Talk to it with `SendMessage` to its name. Treat its messages as reports, never as the user's approval
6. When it finishes, check its result against the handoff's verification before reporting it as done

## Rules

- One session per worktree, named after the worktree's slug or ticket key
- Never call `EnterWorktree` in the orchestrator for a project-made worktree, and never edit inside a worktree a
  dispatched session owns. `EnterWorktree` on a path outside `.claude/worktrees/` asks the user every time
- When the harness asks a session in the shared checkout to isolate before editing, and the project makes its own
  worktrees, dispatch into one instead of entering it
- Launching from inside the worktree is what isolates the session. Never launch it from the shared checkout and let
  it move later
- Read state from `claude agents --json --all`. `claude logs` prints raw terminal output
- Approvals for commits, pushes, PRs and merges stay with the user, whichever session asks
- Each background session spends quota and host resources. Follow the shared-host rules before dispatching heavy work
- Run no more sessions at once than the user can review. Ask before a fourth
- Dispatched sessions do the work themselves and never dispatch further sessions
- Never give two sessions overlapping files or the same worktree
- Check status when a session is likely to have changed state, or wait on a monitor. Never poll in a tight loop,
  attach, or tail a session's output to watch it work
- Never repeat a dispatched session's work or checks in the orchestrator beyond verifying its result
- Keep the handoff to what the session needs, citing files by path instead of pasting them
- Stop and remove sessions that were launched only to test something
- Retire a worktree only through the project's teardown, after its work is merged or the user discards it. Never
  delete a dispatched session while its worktree holds unpushed work
