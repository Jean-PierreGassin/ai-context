---
name: handoff
description: Write a handoff prompt that lets an expert engineer continue the current work cold, and start the fresh session that takes over. Use when handing work to another session, agent or person, or when context passes ~250k tokens.
---

Write a handoff note that lets a senior engineer pick up this work cold: someone who knows the stack well, but hasn't seen this conversation.

Run `python3 scripts/handoff-state.py` (in this skill's directory) to gather the verified location, branch, HEAD, working tree state, worktree locks, open PR, and exact output path. Link to plans, tickets, and reference files by exact path or URL instead of copying them in. Break the remaining work into independent pieces and mark where to start.

Keep the note to what changes the next move:
- Goal and why, in one or two sentences
- Exact paths or links to read first, with a short note on what each holds
- Verified state on disk (from `scripts/handoff-state.py`, plus what's done and the last validation command and result)
- Decisions made and why
- Remaining work split into independent pieces, marking where to start, with a concrete pass/fail command and expected result for each (tell the receiver to loop on it until it passes)
- Constraints, gotchas, and dead ends

Write plain facts, flag anything unverified as a guess, and skip anything with nothing useful to say.

## Saving and finishing

Write the note once using the file-writing tool to the `Handoff path` printed by `scripts/handoff-state.py` (`${XDG_STATE_HOME:-$HOME/.local/state}/agents/handoff/{repository directory name}-{branch with / as -}.md`, or `{task-slug}.md` outside a repo), replacing any old one. Keeping it outside every repo and worktree avoids worktree guards and lets any session read it.

Then finish based on the mode:

- **continue** (default, and at ~250k tokens): move this work to a fresh session (steps below).
- **paste** (the user wants text to paste, or a human is taking over): run `bash scripts/handoff-finish.sh copy <handoff path>` and reply in one line with the path and whether copying worked.
- **brief** (`dispatch-session` needs a subagent brief): reply with the file path.

### Moving to a fresh session

1. Make sure everything the handoff mentions is reachable from a new session in this directory: put scratch outputs and decisions in the handoff or under the handoff directory. Record uncommitted work in state (commits and pushes still follow the usual approvals).
2. Hand the worktree to the new session so removing this session won't delete the worktree while the new one is working in it. Run `bash scripts/handoff-finish.sh lock <worktree path> "<new title>" "<this session's id>"` and record the worktree and its lock in the handoff.
3. Start a new top-level session in this directory on the same model, titled `<TICKET-KEY> - <Area> - <what it does>` (or `<Area> - <what it does>` with no ticket; never the repo name), with this prompt:

   > Read `<absolute handoff path>` and continue the work it describes. First confirm the State it lists (branch, HEAD, working tree, worktree lock) matches what you see. Then stop the previous session `<this session's id>`, and never remove it: removing it deletes the worktree.

   With `claude`: `claude --bg --name "<title>" --model <model> "<prompt>"`, using `$CLAUDE_CODE_SESSION_ID` for this session's id and `claude stop <id>` to stop it. Other harnesses have equivalents; if there isn't one, fall back to paste.
4. Confirm the new session shows up under that title, reply in one line with the title and file path, and stop there.
