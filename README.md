# Agnostic Agentic Engineering Context

`ai-context` installs shared skills and workflow guidance for Codex and Claude Code. It can configure one project or your user account. It keeps settings that it does not manage.

## System support

Use `ai-context` in a Bash environment on:

- macOS
- Linux
- Windows with Windows Subsystem for Linux (WSL) or Git Bash

Native PowerShell is not supported.

Install these required tools:

- Bash 3.2 or newer
- `jq`
- Python 3.11 or newer

[Task](https://taskfile.dev/docs/installation) and [Gum](https://github.com/charmbracelet/gum#installation) are optional. The launcher uses Task when Task can start the command. It uses the shell directly when Task is not installed or cannot start. It uses Gum for formatted output and prompts. It uses plain terminal output when Gum is not installed.

Use your operating system package manager to install the tools. See each tool's official installation page for supported package managers and binary downloads.

## Set up the command

Clone the repository to a permanent directory:

```bash
git clone https://github.com/Jean-PierreGassin/ai-context.git
```

Run the launcher from that directory:

```bash
bash /path/to/ai-context/bin/ai-context help
```

You can also add `bin` to your `PATH`. Use the method for your operating system and shell. After that, use `ai-context` from any directory.

## Install context

Install context in the current project:

```bash
ai-context install
```

This command is the same as:

```bash
ai-context install --project
```

Install context for your user account:

```bash
ai-context install --global
```

The project scope is the default. Do not use `--project` and `--global` together.

## Check an installation

Check the project installation:

```bash
ai-context doctor
```

Check the user installation:

```bash
ai-context doctor --global
```

`doctor` checks required tools, installed files, imports, and configuration syntax. Missing Task, Gum, Codex, or Claude Code produces a warning. A missing required tool produces a failure.

## Preview and automate

Preview changes without writing files:

```bash
ai-context install --dry-run
```

Run without prompts:

```bash
ai-context install --no-interaction
```

Replace changed managed payload files:

```bash
ai-context install --force
```

`--force` does not replace structured Claude or Codex configuration. It still merges those files.

Replace the complete structured configuration:

```bash
ai-context install --replace-config
```

This option replaces `.claude/settings.json`, `.codex/config.toml`, and `.codex/hooks.json`. The installer saves a rollback snapshot first. Use this option only when you want to remove settings that `ai-context` does not manage.

## Restore a version

List saved versions:

```bash
ai-context history
ai-context history --global
```

Restore the latest saved version:

```bash
ai-context rollback
```

Restore a selected version:

```bash
ai-context rollback SNAPSHOT_ID
ai-context rollback SNAPSHOT_ID --global
```

Each install saves the complete state of all managed paths before it writes files. Each rollback also saves the current state. You can run rollback again to undo a rollback.

Dry runs do not create snapshots. Snapshots stay in `${XDG_STATE_HOME:-~/.local/state}/ai-context` until you remove that directory.

## Install locations

| Content | Project scope | User scope |
|---|---|---|
| Shared instructions | `AGENTS.md` | `~/.codex/AGENTS.md` |
| Claude instruction import | `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Shared skills and hooks | `.agents/` | `~/.agents/` |
| Claude adapters and settings | `.claude/` | `~/.claude/` |
| Codex configuration | `.codex/` | `~/.codex/` |

## Update rules

The installer uses these rules:

- It adds the required `AGENTS.md` import to `CLAUDE.md` once. It keeps the other content.
- It merges Claude JSON objects. It combines arrays, such as permissions and hooks, without duplicate values.
- It adds missing Codex TOML keys and tables. It keeps existing model, marketplace, plugin, MCP, and user settings.
- It merges Codex hook JSON.
- It asks before it replaces a changed managed payload file.
- It skips that replacement in non-interactive mode unless you use `--force`.
- It reports invalid JSON or TOML and does not replace the valid target.
- It refuses a symlink or directory at a managed file path.
- It replaces files atomically in each target directory.

## Development

### Task shortcuts

You can run each public command through Task from the repository root:

```bash
task install
task doctor
task history
task rollback
```

Put command options after `--`:

```bash
task install -- --global --no-interaction
task doctor -- --global
task rollback -- SNAPSHOT_ID --global
```

These shortcuts use the same validation and defaults as the `ai-context` command.

### Tests

Run all tests with Task:

```bash
task test
```

The E2E tests cover the Task path, the direct shell path, Task startup failure, install, doctor, history, and rollback.

## License

MIT. See [LICENSE.md](LICENSE.md).
