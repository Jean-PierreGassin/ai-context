---
name: git-commit
description: Use whenever committing, continuing a rebase that writes commits, staging, splitting a diff, or writing
  the commit message itself.
when_to_use: Triggers on requests like "commit this", "commit these changes", "stage and commit", "write a commit
  message", or "split this into commits". Applies on top of any standards a plugin or project skill has already
  supplied, and is still required when one is active.
context: fork
agent: general-purpose
background: false
---

Read `.agents/skills/git-commit/SKILL.md` now and follow it, with any references it directs you to.
