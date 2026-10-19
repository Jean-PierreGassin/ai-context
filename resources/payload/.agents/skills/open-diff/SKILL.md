---
name: open-diff
description: Open the branch's changes against its target in the user's preferred IDE or diff tool. Use when asked to show, open, or review the changes or diff in an editor; not for reviewing code yourself.
---

# Open Diff

Open the current branch's changes in the user's own diff tool so they can review them. Do not print or summarize the diff
unless asked.

## Preference

Each user keeps their own preference in `${XDG_CONFIG_HOME:-$HOME/.config}/agents/open-diff`, the shared folder for
skill settings, for example:

```text
mode=dir
command='/path/to/phpstorm' diff --wait "$LOCAL" "$REMOTE"
```

- `command` is a POSIX `sh` command, whatever the user's login shell, that receives the two paths as `$LOCAL` and
  `$REMOTE`. It must block until the diff window closes
- `mode=dir` passes two directories for one tree diff, for tools such as JetBrains IDEs (`{ide} diff --wait`);
  `mode=file` opens one diff per changed file, for tools such as VS Code (`code --wait --diff`) that cannot compare
  directories

When no preference exists, or the user names a different tool, ask which tool to use, offering the IDEs and diff tools
installed on the machine. Look on `PATH` and in the platform's usual install locations, such as `/Applications` on
macOS, or JetBrains Toolbox scripts, `/snap/bin` and Flatpak exports on Linux. Resolve the launcher to an absolute path,
prefer a tree diff when the tool supports one, and save the file, creating its directory if needed.

If the saved launcher no longer exists, such as after an IDE version update, find the current install of the same tool
and update the file.

## Open

1. Resolve the immediate target branch: the PR base when a PR exists, otherwise the plan's or user's stated target,
   otherwise the remote default branch
2. Fetch the target so the comparison is current
3. Compare the merge base of the target and `HEAD` with the working tree, so uncommitted edits appear and stay editable
   in the tool
4. Launch in the background so the session stays usable. Git removes its temporary copies once the window closes. The
   tool needs a graphical session, so report failure over SSH or on a headless machine

Pass the command as a one-off tool through `-c`, which leaves git config untouched. Do not use `--extcmd`: in directory
mode git runs it as a bare program name, so a launcher with arguments fails.

```bash
base="$(git merge-base origin/{target} HEAD)"
git -c difftool.open-diff.cmd="$command" difftool --dir-diff --no-prompt --tool=open-diff "$base"   # mode=dir
git -c difftool.open-diff.cmd="$command" difftool --no-prompt --tool=open-diff "$base"              # mode=file
```

Untracked files are not part of a git diff. Do not add them to the index.

## Output

Reply with exactly one line and nothing else:

```text
open-diff: {tool}, {target}@{short base}..working tree[, {n} untracked excluded][, preference saved]
open-diff: failed, {reason}
```
