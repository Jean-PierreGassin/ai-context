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
  since the branch left trunk. Put slow, whole-change checks here, such as the full static analysis run CI does
- `<repository>` matches the origin repository's name, `*` for any; `<path glob>` matches the path from the
  repository root
- `$FILES` expands to the matching files, quoted. Commands run from the repository root at low priority, one at a
  time per repository, and a command that is not installed is skipped
- `env` is an optional command run before each check, for example to load the project's toolchain

A failed check is reported back to the agent. A turn check that still fails after one fix attempt is shown to you and
no longer blocks. State is kept per session, so parallel sessions and worktrees never share results.

## Commit gates

The `commit-gate` hook refuses a `git commit` until the session has run the gates you require for that repository
since the agent last edited a file in it. It runs nothing until `${XDG_CONFIG_HOME:-$HOME/.config}/agents/commit-gate` exists:

```text
my-app review Agent ^code-reviewer$
my-app lint Bash \bnpm\s+run\s+lint\b
my-app data Skill ^db:query$
```

Each line is `<repository> <gate> <source> <pattern>`:

- `<repository>` matches the origin repository's name, `*` for any
- `<source>` is where the gate is seen: `Bash` matches the command, `Skill` the skill name, and `Agent` the type of a
  subagent when it finishes, so a review counts only once it is done
- `<pattern>` is a regular expression. Lines that share a gate name are alternatives

A gate counts for the repositories its line names, and only in the session that ran it, until the agent edits or
writes another file in that repository. One gated change can go out as several commits. A gate run in another
session, for example before a handoff, has to run again. Files changed through Bash are not seen as edits. Bash
patterns skip quoted arguments, so searching for a gate's command does not count as running it, while a quoted
command or assignment, such as `"$HOME/bin/lint.sh"` or `LINT="…/lint.sh"`, still counts. A Bash gate counts once
its command completes, so a command that hides its own exit status counts even when the tool it ran failed. A commit
whose repository cannot be worked out, such as `git -C $DIR commit` with `DIR` unset, is refused while any gate is
configured.

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
