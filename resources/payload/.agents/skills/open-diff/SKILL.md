---
name: open-diff
description: Open the branch's changes against its target in the user's preferred IDE or diff tool. Use when asked to show, open, or review the changes or diff in an editor; not for reviewing code yourself.
---

# Open Diff

Open the current branch's changes in the user's own diff tool so they can review them. Do not print or summarize the diff
unless asked.

## Preference

Read the saved tool from `${XDG_CONFIG_HOME:-$HOME/.config}/agents/open-diff`:

```text
mode=dir
command='{launcher}' diff --wait "$LOCAL" "$REMOTE"
```

- `mode=dir` opens one tree diff; `mode=file` opens one diff per file, for tools that cannot compare directories. Both
  run through `git difftool`, whose `command` receives the two paths as `$LOCAL` and `$REMOTE` and must block until the
  diff window closes
- `mode=repo` is for tools that read the repository themselves. Its `command` receives the compare target as `$BASE_REF`,
  runs from the repository root, and must block until the review ends

When no preference exists, or the user names a different tool, ask which installed IDE or diff tool to use, prefer a
tree diff when it supports one, and save its absolute launcher path. If the saved launcher no longer exists, find the
current install of the same tool and update the file.

## Open

1. Resolve the immediate target branch: the PR base when a PR exists, otherwise the plan's or user's stated target,
   otherwise the remote default branch
2. Fetch the target so the comparison is current
3. Compare the merge base of the target and `HEAD` with the working tree, so uncommitted edits appear and stay editable
   in the tool
4. Run it as a background command, since the tool blocks until the window closes

Pass a difftool command with `-c`, not `--extcmd`, which cannot take arguments in directory mode.

```bash
base="$(git merge-base origin/{target} HEAD)"
git -c difftool.open-diff.cmd="$command" difftool --dir-diff --no-prompt --tool=open-diff "$base"   # mode=dir
git -c difftool.open-diff.cmd="$command" difftool --no-prompt --tool=open-diff "$base"              # mode=file
BASE_REF="origin/{target}" sh -c "$command"                                                       # mode=repo
```

Untracked files are not part of a git diff. Do not add them to the index.

## Plannotator

For `plannotator review`, use `mode=repo` with `--diff-type merge-base --json`. When it finishes, read `decision` from
the JSON:

- `approved`: report it; approval covers only the review, not commits, pushes, or PRs
- `annotated`: treat `message` as the user's review feedback on the current work and address it
- `dismissed`, or the command fails: report it and continue

## Output

Reply with exactly one line and nothing else, then follow up on any Plannotator decision:

```text
open-diff: {tool}, {target}@{short base}..working tree[, {n} untracked excluded][, preference saved]
open-diff: failed, {reason}
```

Count untracked files only in `dir` and `file` modes.
