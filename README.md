# AI Context

`ai-context` installs shared instructions, skills, hooks and safety settings for coding agents, using open formats: `AGENTS.md`, `.agents/skills/`, and `.claude/` and `.codex/` for agent-specific files. Install it globally or per project.

## Requirements

- macOS, Linux, WSL, or Git Bash (no native PowerShell)
- Bash 3.2+, Python 3.11+, `jq`
- Optional: [Task](https://taskfile.dev/docs/installation), [Gum](https://github.com/charmbracelet/gum#installation)

Reviews open in [Plannotator](https://plannotator.ai) on request.

## Install

```bash
git clone https://github.com/Jean-PierreGassin/ai-context.git "$HOME/.local/share/ai-context"
mkdir -p "$HOME/.local/bin"
printf '%s\n' '#!/usr/bin/env bash' 'exec "$HOME/.local/share/ai-context/bin/ai-context" "$@"' > "$HOME/.local/bin/ai-context"
chmod +x "$HOME/.local/bin/ai-context"
```

Add `~/.local/bin` to your path (persist it in `~/.zshrc` or `~/.bashrc`), then verify:

```bash
export PATH="$HOME/.local/bin:$PATH"
ai-context --help
```

## Usage

```bash
ai-context install                      # current project
ai-context install --global             # all projects
ai-context install --dry-run --verbose  # preview every affected path
```

| Option             | Purpose                                               |
|--------------------|-------------------------------------------------------|
| `--global`         | Target global configuration                           |
| `--dry-run`        | Preview changes without applying them                 |
| `--verbose`        | List every affected path                              |
| `--no-interaction` | Apply without prompting                               |
| `--force`          | Replace changed managed files outside packaged skills |
| `--replace-config` | Replace complete Claude and Codex configuration files |

The installer merges Claude and Codex configuration. Settings it manages take its values; other settings and hooks are kept unless you pass `--replace-config`.

Later installs update packaged skill files and remove only stale files it previously installed. Unmanaged files are kept. Every install and rollback saves the previous state.

## Hooks

Rules a machine can check run as hooks. Rules that need judgement are plain-English instructions in `AGENTS.md`. Three more hooks:

- `migration-generator` refuses a hand-written Laravel migration and points to `php artisan make:migration`.
- `play-sound` plays a sound when an interactive turn ends.
- `context-handoff` (Claude) stops a session past ~250k tokens of context and tells it to hand off to a fresh session.

Installing over an earlier version removes the retired `ask-first` and `commit-gate` hooks. A retired file you changed is left in place.

## Change checks

The `verify-changes` hook runs your checks on files an agent changes. It does nothing until `${XDG_CONFIG_HOME:-$HOME/.config}/agents/verify-changes` exists:

```text
env . "$HOME/.config/my-env.sh"
edit * *.py ruff check $FILES
turn my-app src/*.ts npx eslint $FILES
handoff my-app * npx tsc --noEmit
```

Each check line is `<phase> <repository> <path glob> <command>`:

- `edit` runs after every edit or write, on that file. Keep it to about a second
- `turn` runs once when the agent finishes a turn, on every file changed since the last clean run
- `handoff` runs when the agent calls `verify-changes.sh handoff`, on every file changed since the branch left trunk. Put slow checks here
- `<repository>` is the origin repository's name, or `*` for any; `<path glob>` matches from the repository root
- `$FILES` expands to the matching files
- `$ADDED_LINES` (in `edit` checks) names a file of `path:line` entries for each line the edit added
- `env` is an optional command run before each check, for example to load a toolchain

Commands run from the repository root, one at a time per repository. A missing command is skipped.

A failed check is reported to the agent once. A failed `turn` check blocks once; after one fix attempt it is shown to you instead. State is per session.

Only the agent's Edit and Write tool changes are checked. `block-shell-edits` keeps agents on those tools.

### Recurring review findings

When a review catches a repeat mistake, `review-code` proposes a deterministic rule instead of a Markdown instruction: a project lint rule, then an `edit` check, then a `weakening` pattern. It adds the rule only once you approve.

### PHP style check

`~/.agents/checks/php-style-check.py` is a ready-made `edit` check for PHP. It judges only `$ADDED_LINES`:

```text
edit my-app *.php python3 -I "$HOME/.agents/checks/php-style-check.py" $FILES
```

### Weakened verification

The same hook flags changes that make work easier to pass rather than more correct. It reads `${XDG_CONFIG_HOME:-$HOME/.config}/agents/weakening`:

```text
added my-app *.ts @ts-(ignore|expect-error)
added my-app tests/*.ts \b(it|describe)\.skip\(
changed my-app tsconfig.json
```

- `added <repository> <path glob> <pattern>` matches lines the edit adds
- `changed <repository> <path glob>` matches files the edit writes

Each finding is reported once per session. The agent undoes it or says why it is needed. Nothing is refused.

### Finished-work claims

When a turn ends on a claim that the work is finished ("Done.") and handoff checks have not passed since the last edit, the agent is told once to run them or say what is unverified.

Claims are found by the detector from [Andon](https://github.com/PrimeFoldTools/Andon), copied unchanged under its MIT license into `.agents/hooks/agent_hooks/third_party/andon/`, with its corpus in `tests/third_party/andon/`.

### Response rules

`${XDG_CONFIG_HOME:-$HOME/.config}/agents/response-rules` lists patterns a reply must not contain, one `<name> <pattern>` per line. A reply that breaks one is sent back once to be rewritten.

```text
em-dash —
```

## Shell edits

The `block-shell-edits` hook refuses `sed -i`, `perl -i` and heredocs written to a file in repositories listed in `${XDG_CONFIG_HOME:-$HOME/.config}/agents/block-shell-edits` (one repository name or glob per line), and points to the Edit and Write tools:

```text
my-app
```

Files outside those repositories, heredocs fed to a command, and quoted text are allowed. It does nothing without the file.

## Check and restore

```bash
ai-context doctor [--global]               # check an installation
ai-context history [--global]              # list saved versions
ai-context rollback [SNAPSHOT_ID] [--global]  # restore a version
```

## Update

```bash
git -C "$HOME/.local/share/ai-context" pull --ff-only
ai-context install --global
```

Run a project install separately for projects that use local context.

## Development

Canonical skills live in `resources/payload/.agents/skills/`. The installer also copies each into `.claude/skills/`.

Keep skills generic across platforms and shells. A per-user skill setting goes in `${XDG_CONFIG_HOME:-$HOME/.config}/agents/{skill}`, one file per skill.

Evals live in `evals/`; see [evals/README.md](evals/README.md). After changes, run the regression suite (requires [ShellCheck](https://www.shellcheck.net/)):

```bash
task test
```

## License

MIT. See [LICENSE.md](LICENSE.md).
