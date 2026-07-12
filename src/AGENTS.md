# AI Work Guidelines

Use this as the short operating agreement for AI-assisted work in this project. Project-local docs and explicit user instructions override these defaults.

## Conversational Overrides

- Use a warm, collaborative tone. Acknowledge the user's framing before answering
- Provide concise, focused responses. Skip non-essential context, and keep examples minimal
- Lead with the ask, not the reasoning - state the decision needed in the first sentence
- One decision per numbered point (no packing two unrelated issues into one item)
- Max 2 sentences of reasoning per point - cut "Agreed," "Confirmed," "Fair catch," and similar throat-clearing
- Group into RESOLVED vs NEEDS DECISION - don't interleave them
- State blockers in line one, before the numbered list
- Trivial/confirmed items get one line, no sub-bullets
- Sub-bullets only when comparing 2+ named options

## Planning

- Use the [write-plan](.agents/skills/write-plan) skill to write/resume plans

## Writing Code

- Use the [write-code](.agents/skills/write-code) skill to write code for each language

## Writing Tests

- Use the [write-tests](.agents/skills/write-tests) skill to write tests

## Workflow

- Branch and worktree names use the tracker's ticket key, or fallback (`ABC-1234` or `ABC-1234-slug` or `title-of-changes-summarized`)
- For symbol navigation, prefer the LSP tool over grep; use grep only for literal text; and trust the language server's results rather than re-reading files to confirm them

## Git Worktrees

- On creation, check the repo's `.worktreeinclude` (or equivalent list of env/config files the tooling needs) against what actually landed in the worktree, and manually `cp` anything it missed from the repo root
- Never copy `vendor`/`node_modules`/other dependency directories into a worktree
- Always run the real installation commands (`composer install`, `yarn install`, etc.) inside the worktree
- When the user wants to verify/review/has intent to look at the changes:
  - You must ensure the worktree has been committed to
  - You must run `git checkout --detach` on the worktree before checking out the branch in the main repository directory
- Ensure "finished" worktrees are pruned as long as there are no pending changes
