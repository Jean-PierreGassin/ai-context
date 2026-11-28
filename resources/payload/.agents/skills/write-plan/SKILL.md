---
name: write-plan
description: Plan work as small, independent shippable changes (or a sequence when pieces genuinely depend on each other). Use when planning, splitting or sequencing multi-step work, or resuming a plan across sessions.
---

Prefer splitting work into small, focused, independent PRs targeting trunk that can ship on their own (not artificially tiny unless necessary). Only sequence dependent steps as a stack when pieces genuinely cannot ship independently, and order independent or foundation pieces to ship first.

1. Read [persisted-plans](references/persisted-plans.md) if you're picking up an existing plan.
2. Check the affected code and settle the facts from evidence.
3. Break the work into standalone checkpoints, each with one review focus that can ship, be verified, and roll back on its own.
4. Shape any sequence with [change-stack](references/change-stack.md).
5. Record the ticket (or why there isn't one) and pick where to work with `use-worktrees`.
6. Save plans that span sessions or form a stack; keep smaller changes in the conversation. Then stop for approval.

Before showing a plan, verify every claim against real code or data and resolve contradictions, ask upfront only about user decisions (business logic, spend, scope), and spell out the code shape (classes, signatures, enums, file placement) with file and line references to existing patterns. Start with a TL;DR, then short bullets with evidence.

Keep the plan and its restore context up to date as work moves forward. Bring any change to requirements, architecture, or stack shape back to the user for approval.
