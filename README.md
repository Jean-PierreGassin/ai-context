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
Existing settings that the package does not manage are preserved unless `--replace-config` is used.

Packaged skill files are tracked per installation target. Later installs update current files and remove only stale
files previously owned by `ai-context`. Unmanaged files and non-empty directories are preserved.

Every install and rollback saves the previous state.

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

Canonical skills live in `resources/payload/.agents/skills/`. Claude adapters live in
`resources/payload/.claude/skills/` and point to the canonical skills.

Behaviour and trigger evals live in `evals/`. See [evals/README.md](evals/README.md) for the schema.

Run the regression suite after changes:

```bash
task test
```

The suite requires [ShellCheck](https://www.shellcheck.net/).

## License

MIT. See [LICENSE.md](LICENSE.md).
