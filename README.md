# Agnostic Agentic Engineering Context

`ai-context` installs a shared set of agent skills and workflow guidance for Codex and Claude Code. It can configure one project or your user-level configuration, while preserving unrelated settings already owned by you or the project.

## Prerequisites

- [Task](https://taskfile.dev/installation/)
- [Gum](https://github.com/charmbracelet/gum#installation)
- `jq`
- Python 3.11 or newer
- Bash 3.2 or newer

On macOS with Homebrew:

```bash
brew install go-task gum jq python@3.13
```

## Set up the command

Clone this repository, then link the launcher somewhere on your `PATH`:

```bash
git clone https://github.com/Jean-PierreGassin/ai-context.git ~/.local/share/ai-context
ln -s ~/.local/share/ai-context/bin/ai-context ~/.local/bin/ai-context
```

The launcher resolves the repository from its own location, so it works from any project directory.

## Usage

Install into the current project, which is the default:

```bash
ai-context install
# equivalent to
ai-context install --project
```

Install user-level context for every project:

```bash
ai-context install --global
```

Check dependencies, syntax, paths, and wiring:

```bash
ai-context doctor
ai-context doctor --global
```

List saved versions and restore the latest or a selected snapshot:

```bash
ai-context history
ai-context history --global
ai-context rollback
ai-context rollback 20260809T041530.123456Z-a1b2c3 --global
```

Every non-dry install saves the complete pre-install state of all managed paths. Rollback also saves the current state before restoring, so running rollback again can undo the rollback.

Preview or automate an install:

```bash
ai-context install --dry-run
ai-context install --no-interaction
ai-context install --force
ai-context install --replace-config
```

`--no-interaction` leaves changed managed files alone. `--force` replaces changed managed payload files, but structured Claude and Codex settings are still merged. `--replace-config` explicitly replaces `.claude/settings.json`, `.codex/config.toml`, and `.codex/hooks.json` after saving a rollback snapshot. It does not imply `--force` for other files.

## Install locations

| Content | Project | Global |
|---|---|---|
| Shared instructions | `AGENTS.md` | `~/.codex/AGENTS.md` |
| Claude instruction bridge | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Shared skills and hooks | `.agents/` | `~/.agents/` |
| Claude adapters and UI | `.claude/` | `~/.claude/` |
| Codex configuration | `.codex/` | `~/.codex/` |

Codex loads project overrides from `.codex/config.toml` and user configuration from `~/.codex/config.toml`. Claude Code uses the equivalent project and user scopes in `.claude/settings.json` and `~/.claude/settings.json`.

## Safe updates

- Existing `CLAUDE.md` content is retained and the appropriate `AGENTS.md` import is prepended once.
- Existing Claude JSON objects are retained. Missing keys are added, and arrays such as permissions and hooks are combined without duplicates.
- Existing Codex TOML is retained. Missing keys and tables are added without replacing model, marketplace, plugin, MCP, or other user configuration.
- Existing Codex hooks are JSON-merged rather than replaced.
- A changed managed skill, hook, or adapter prompts before replacement. Non-interactive installs skip it unless `--force` is supplied.
- Invalid or incompatible JSON and TOML is reported with a failing exit status and left valid.
- Symlinks and directories at managed file paths are refused, preventing writes outside the selected target.
- File replacements are atomic within each target directory.

## Version history

Snapshots are stored outside projects under `${XDG_STATE_HOME:-~/.local/state}/ai-context`. Each history is isolated by scope and the canonical target path. A snapshot records:

- The install or rollback action
- A content-derived payload version
- Existing files and directories with their modes
- Existing symlinks without following them
- Paths that did not exist, so rollback can remove files introduced by an install

History is retained until its state directory is removed. Dry runs do not create snapshots.

## Development

Run the fixture checks with Task:

```bash
task test
```

## License

MIT. See [LICENSE.md](LICENSE.md).
