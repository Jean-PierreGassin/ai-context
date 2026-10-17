---
name: open-diff
description: Open the branch's changes against its target in the user's preferred IDE or diff tool. Use when asked to show, open, or review the changes or diff in an editor; not for reviewing code yourself.
---

# Open Diff

Open the current branch's changes in the user's own diff tool so they can review them. Do not print or summarize the diff
unless asked.

## Preference

Read the saved tool from `${XDG_CONFIG_HOME:-$HOME/.config}/ai-context/open-diff`:

```text
mode=dir
command='/Applications/PhpStorm.app/Contents/MacOS/phpstorm' diff --wait
```

- `command` is a shell command that git appends two paths to. It must block until the diff window closes
- `mode=dir` passes two directories for one tree diff; `mode=file` opens one diff per changed file, for tools such as
  VS Code (`code --wait --diff`) that cannot compare directories

When no preference exists, or the user names a different tool, ask which tool to use, offering the IDEs and diff tools
installed on the machine. Resolve the launcher path, prefer a tree diff when the tool supports one, and save the file.
Mention once that it is remembered and how to change it.

If the saved launcher no longer exists, such as after an IDE version update, find the current install of the same tool,
update the file, and say so.

## Open

1. Resolve the immediate target branch: the PR base when a PR exists, otherwise the plan's or user's stated target,
   otherwise the remote default branch
2. Fetch the target so the comparison is current
3. Compare the merge base of the target and `HEAD` with the working tree, so uncommitted edits appear and stay editable
   in the tool
4. Launch in the background so the session stays usable. Git removes its temporary copies once the window closes

```bash
base="$(git merge-base origin/{target} HEAD)"
git difftool --dir-diff --no-prompt --extcmd="$command" "$base"   # mode=dir
git difftool --no-prompt --extcmd="$command" "$base"              # mode=file
```

Untracked files are not part of a git diff. Say so when the working tree has any, rather than adding them to the index.

Report the target and base compared, and nothing else unless the launch failed.
