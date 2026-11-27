# AI Context

`ai-context` installs shared instructions, skills, hooks, and safety settings for coding agents.

It uses open formats:

- `AGENTS.md` for shared instructions
- `.agents/skills/` for canonical skills
- `.claude/` and `.codex/` for agent-specific integration

Install it globally for all projects, or locally within one project.

## Requirements

- macOS, Linux, WSL, or Git Bash
- Bash 3.2 or newer
- Python 3.11 or newer
- `jq`

Native PowerShell is not supported. [Task](https://taskfile.dev/docs/installation) and
[Gum](https://github.com/charmbracelet/gum#installation) are optional.

Interactive plan review uses [Plannotator](https://plannotator.ai). Install Plannotator with its managed Codex Stop
hook to enable automatic browser opening and feedback.

## Install

```bash
git clone https://github.com/Jean-PierreGassin/ai-context.git "$HOME/.local/share/ai-context"
mkdir -p "$HOME/.local/bin"
printf '%s\n' '#!/usr/bin/env bash' 'exec "$HOME/.local/share/ai-context/bin/ai-context" "$@"' > "$HOME/.local/bin/ai-context"
chmod +x "$HOME/.local/bin/ai-context"
```

Add `~/.local/bin` to your shell path, then verify the command:

```bash
export PATH="$HOME/.local/bin:$PATH"
ai-context --help
```

Add the export to `~/.zshrc` or `~/.bashrc` to make it permanent.

## Usage

Install into the current project:

```bash
ai-context install
```

Install globally:

```bash
ai-context install --global
```

Preview all affected paths without applying changes:

```bash
ai-context install --dry-run --verbose
```

Common options:

| Option             | Purpose                                               |
|--------------------|-------------------------------------------------------|
| `--global`         | Target global configuration                           |
| `--dry-run`        | Preview changes without applying them                 |
| `--verbose`        | List every affected path                              |
| `--no-interaction` | Apply without prompting                               |
| `--force`          | Replace changed managed files outside packaged skills |
| `--replace-config` | Replace complete Claude and Codex configuration files |

## Safety and ownership

The installer previews changes before applying them and merges structured Claude and Codex configuration by default.
Settings the package manages take the package's values, including complete lists such as permission rules. Settings
the package does not manage, and hooks it does not own, are preserved unless `--replace-config` is used.

Packaged skill files are tracked per installation target. Later installs update current files and remove only stale
files previously owned by `ai-context`. Unmanaged files and non-empty directories are preserved.

Every install and rollback saves the previous state.

## Hooks

Rules a machine can check run as hooks; working rules that need judgement, such as asking before posting or reading
secrets, are plain-English instructions in `AGENTS.md`. Besides the checks below, `migration-generator` refuses a new
Laravel migration written by hand and points the agent to `php artisan make:migration`, and `play-sound` plays a sound
when an interactive turn ends.

Installing over an earlier version removes the retired `ask-first` and `commit-gate` hooks and the settings entries
that ran them. A retired file you changed is left in place.

## Change checks

The `verify-changes` hook runs your checks on the files an agent changes, so problems surface while it works rather
than at review. It runs nothing until `${XDG_CONFIG_HOME:-$HOME/.config}/agents/verify-changes` exists:

```text
env . "$HOME/.config/my-env.sh"
edit * *.py ruff check $FILES
turn my-app src/*.ts npx eslint $FILES
handoff my-app * npx tsc --noEmit
```

Each check line is `<phase> <repository> <path glob> <command>`:

- `edit` runs after every edit or write, on that file. Keep these to checks that take about a second
- `turn` runs once when the agent finishes a turn, on every file it changed since the last clean run
- `handoff` runs when the agent calls `verify-changes.sh handoff` before handing work back, on every file changed
  since the branch left trunk, untracked files included. Put slow, whole-change checks here, such as the full static
  analysis run CI does
- `<repository>` matches the origin repository's name, `*` for any; `<path glob>` matches the path from the
  repository root
- `$ADDED_LINES` in an `edit` check names a file listing each line the edit added, moved lines included, one
  `path:line` per line, so a check can judge only what the agent wrote and leave your uncommitted work alone
- `$FILES` expands to the matching files, quoted. A check sees whole files, your uncommitted lines included, so use
  `$ADDED_LINES` when a rule should judge only the agent's lines. Commands run from the repository root at low
  priority, one at a time per repository, and a command that is not installed is skipped
- `env` is an optional command run before each check, for example to load the project's toolchain

A failed check is reported back to the agent once; the same output is not reported again. A failed turn check blocks
the agent once, and after one fix attempt it is shown to you and no longer blocks. State is kept per session, so
parallel sessions and worktrees never share results.

Only the Edit and Write tools count as the agent's changes. Files changed only by a shell command, by you, or by a
branch switch or pull are never checked. `block-shell-edits` keeps agents on the edit tools. Each hook exits before
starting Python while its config file is absent.

### Recurring review findings

When a review catches a mistake that has happened before, `review-code` proposes a deterministic rule for it instead
of a Markdown instruction: a project lint rule first, then an `edit` check or a rule in an existing check script, then
a `weakening` pattern. It proves the rule on the finding's lines and adds it only once you approve.

### PHP style check

`~/.agents/checks/php-style-check.py` is a ready-made `edit` check for PHP. It judges only the lines in
`$ADDED_LINES`: chains with more than one link on a line, `new` nested in arguments, lines over 120 characters,
control blocks without a blank line above, broken calls with several arguments on a line, comment prose, and
functions with more than three returns. Text inside strings and heredocs gets only the line length rule:

```text
edit my-app *.php python3 -I "$HOME/.agents/checks/php-style-check.py" $FILES
```

### Weakened verification

The same hook points out changes that make the work easier to pass rather than more correct. It reads
`${XDG_CONFIG_HOME:-$HOME/.config}/agents/weakening`:

```text
added my-app *.ts @ts-(ignore|expect-error)
added my-app tests/*.ts \b(it|describe)\.skip\(
changed my-app tsconfig.json
```

- `added <repository> <path glob> <pattern>` matches lines the edit adds. A line that was only moved or re-indented
  does not count
- `changed <repository> <path glob>` matches files the edit writes

Each finding is reported once per session, and the agent undoes it or says why it is needed. Nothing is refused, so an
unattended agent never stalls waiting for an answer.

### Finished-work claims

When a turn ends on a claim that the work is finished, such as "Done." or "Fixed the tests.", and the agent edited a
repository with handoff checks after `verify-changes.sh handoff` last started a passing run there, the agent is told
once, then runs the handoff checks or says what is still unverified. Your own changes never re-open the check. A
session that edited no such repository since its last pass is never stopped.

Claims are found by the detector from [Andon](https://github.com/PrimeFoldTools/Andon), copied unchanged under its
MIT license into `.agents/hooks/agent_hooks/third_party/andon/`, with its claim corpus in `tests/third_party/andon/`.

### Response rules

`${XDG_CONFIG_HOME:-$HOME/.config}/agents/response-rules` lists patterns a reply must not contain, one
`<name> <pattern>` per line. Code and quoted blocks are ignored. A reply that breaks a rule is sent back once to be
written again; the rewritten reply is not checked again.

```text
em-dash —
```

## Shell edits

The `block-shell-edits` hook refuses `sed -i`, `perl -i` and heredocs written to a file when the target file is in a
repository listed in `${XDG_CONFIG_HOME:-$HOME/.config}/agents/block-shell-edits`, one repository name or glob per
line, and points the agent to the Edit and Write tools, which the change checks follow line by line:

```text
my-app
```

A heredoc counts as a file write only when `cat` or `tee` writes it to a file. The hook follows `cd`, expands globs,
and finds `-i` anywhere among the options. Files outside those repositories, such as scratch files in `/tmp`,
heredocs fed to a command, such as `git commit -F -` or `python3 - > out.txt`, quoted text, such as
`grep 'sed -i'`, and `perl -I` or `-M` options are allowed. Edits it cannot resolve, such as through `find -exec`
or `xargs`, are let through. It runs nothing without the file.

## Check and restore

Check an installation:

```bash
ai-context doctor
ai-context doctor --global
```

List saved versions:

```bash
ai-context history
ai-context history --global
```

Restore a version:

```bash
ai-context rollback
ai-context rollback SNAPSHOT_ID
ai-context rollback SNAPSHOT_ID --global
```

## Update

```bash
git -C "$HOME/.local/share/ai-context" pull --ff-only
ai-context install --global
```

Run a project install separately for projects that use local context.

## Development

Canonical skills live in `resources/payload/.agents/skills/`. The installer copies each one into `.claude/skills/` as
well, so Claude Code loads the full skill without a redirect.

Keep skills generic across platforms and shells. A skill that saves a per-user setting stores it in
`${XDG_CONFIG_HOME:-$HOME/.config}/agents/{skill}`, one file per skill.

Behaviour and trigger evals live in `evals/`. See [evals/README.md](evals/README.md) for the schema.

Run the regression suite after changes:

```bash
task test
```

The suite requires [ShellCheck](https://www.shellcheck.net/).

## License

MIT. See [LICENSE.md](LICENSE.md).
