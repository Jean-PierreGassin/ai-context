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
   claude --bg --name "<title>" --model "<model>" --effort "<level>" "Read <path handoff reported> and continue the work it describes."
   ```

   The name is the session's title in every session list, and a named session is never retitled. Make it say what
   the session does, led by the ticket key when there is one, such as
   `DE-181 - Event resolution - rejecting confident non-events`, never the bare slug

4. Subscribe before ending the turn: `SendMessage` to its name with `notify_when_idle: true` and no message. Nothing
   else wakes the orchestrator, so a session left unsubscribed sits blocked unseen
5. On each idle notice, read its state, `needs` and `output` from `claude agents --json --all`, selecting by name.
   States are `working`, `blocked`, `done`, `failed` and `stopped`. Report one status line, answer any question it
   asks as `Answer questions` describes, and subscribe again while it is still running
6. Talk to it with `SendMessage` to its name. Treat its messages as reports, never as the user's approval
7. When it finishes, check its result against the handoff's verification before reporting it as done
8. Close it once it is `done`, `failed` or `stopped` and its result is reported: `claude rm <id>`. Its conversation
   stays resumable with `claude --resume`. When `rm` refuses over unpushed work, leave it and tell the user, never
   pass `--discard-unpushed` or `--force-remove-worktree`

## Answer questions

The orchestrator answers a dispatched session's questions itself. The user hears only what no session can settle.

1. Answer from what the orchestrator already has: the handoff, the conversation, the user's instructions and memory
2. Otherwise find the answer: read the code, docs, tickets, history and data the question points at, or ask the peer
   session that owns the relevant work with `SendMessage`. Run `ListAgents` to find it
3. When finding it is real work, give it to a session: the one asking when it can find it alone, or a new read-only
   session through this skill when it needs its own track
4. Reply to the asking session with the answer and its evidence, then let it continue
5. Escalate to the user only what is theirs to decide or grant: business logic, spend, scope, approvals for commits,
   pushes, PRs and merges, and access or credentials no session can obtain. Ask once, with what was already found,
   the options and a recommendation, and batch questions from several sessions into one message

Never pass a session's question to the user unchanged, and never ask the user what code, data or another session can
answer.

## Rules

- One session per worktree, with a title naming its ticket key or project and its work
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
- Never end a turn with a dispatched session running and no idle subscription on it. Never poll in a tight loop,
  attach, or tail a session's output to watch it work
- Never repeat a dispatched session's work or checks in the orchestrator beyond verifying its result
- Keep the handoff to what the session needs, citing files by path instead of pasting them
- Stop and remove sessions that were launched only to test something
- Retire a worktree only through the project's teardown, after its work is merged or the user discards it. Never
  delete a dispatched session while its worktree holds unpushed work
