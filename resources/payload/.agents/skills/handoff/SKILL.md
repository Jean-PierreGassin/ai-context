---
name: handoff
description: Write a handoff prompt that lets an expert engineer continue the current work cold, and start the fresh session that takes over. Use when handing work to another session, agent or person, or when context passes ~250k tokens.
---

Write the prompt a senior engineer needs to continue without the conversation: expert in the stack, new to this task.

Gather the goal, what is done, what remains and the decisions made, then verify the current state (branch, HEAD, working tree, open PR, last validation result). Point to the plan, ticket and reference files by exact path or link rather than restating them. Split the remaining work into pieces that can be finished independently, and mark where to start.

Keep it to what changes the next action: decisions and their reasons, constraints, traps hit, dead ends. Write plain imperative facts, and label guesses as unverified. Give each piece a done check the receiver can run, a command and the result that means pass, and tell them to loop on it until it passes.

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

Drop sections with nothing true to say.

## Output

Write the prompt once, with the file-writing tool, to `${XDG_STATE_HOME:-$HOME/.local/state}/agents/handoff/{repository directory name}-{branch with / as -}.md` as an absolute path (no repository: `{task-slug}.md`), replacing any earlier one. It lives outside every repository and worktree, so worktree guards and sandboxes let the write through and every session can read it. Then finish by mode:

- **continue** (default, and at ~250k tokens): this session's work moves to a fresh session, below.
- **paste**: the user wants text to paste, or a person takes over. Pipe the file into the clipboard command (`pbcopy`, `wl-copy`, `xclip -selection clipboard` or `clip.exe`) and reply in one line with the path and whether the copy worked.
- **brief**: `dispatch-session` wants a subagent brief. Reply with the file path.

### Continue

1. Put everything the prompt cites where a new session in this directory can reach it: scratch output and decisions go into the prompt or a file under the handoff directory. Record uncommitted work in State; commits and pushes follow the usual approvals.
2. Hand the worktree to the new session. A harness ties a worktree to the session that created it, and removing that session deletes the worktree, even while another session works in it. Replace its lock with one naming the handover: `git worktree unlock <path>` (it errors harmlessly on an unlocked worktree), then `git worktree lock --reason "handoff: owned by <new title>; previous session <this session's id> stopped" <path>`. Record the worktree and its lock in State.
3. Start a new top-level session in this directory on this session's model, titled `<TICKET-KEY> - <Area> - <what it does>` (without a ticket: `<Area> - <what it does>`; never the repository name), with the prompt:

   > Read `<absolute handoff path>` and continue the work it describes. First confirm the State it lists (branch, HEAD, working tree, worktree lock) matches what you see. Then stop the previous session `<this session's id>`, and never remove it: removing it deletes the worktree.

   With the `claude` CLI: `claude --bg --name "<title>" --model <model> "<prompt>"`, this session's id from `$CLAUDE_CODE_SESSION_ID`, stopped by `claude stop <id>`. Other harnesses have equivalents; without one, use paste.
4. Confirm the new session is listed under that title, reply in one line with the title and the file path, and finish there.
