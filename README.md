# Agnostic Agentic Engineering Context

`ai-context` installs shared instructions, skills, hooks, and safety settings for Codex and Claude Code. Install it in a project or globally.

The installer shows a preview before it changes files. It keeps structured settings that it does not manage and saves a version that you can restore.

## Install the command

Install Bash 3.2 or newer, `jq`, and Python 3.11 or newer. Then clone this repository:

```bash
git clone https://github.com/Jean-PierreGassin/ai-context.git "$HOME/.local/share/ai-context"
mkdir -p "$HOME/.local/bin"
printf '%s\n' '#!/usr/bin/env bash' 'exec "$HOME/.local/share/ai-context/bin/ai-context" "$@"' > "$HOME/.local/bin/ai-context"
chmod +x "$HOME/.local/bin/ai-context"
```

Add the command directory to your shell configuration.

For Zsh on macOS:

```bash
printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
source "$HOME/.zshrc"
```

For Bash on Linux, WSL, or Git Bash:

```bash
printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
source "$HOME/.bashrc"
```

Verify the command:

```bash
ai-context --help
```

[Task](https://taskfile.dev/docs/installation) and [Gum](https://github.com/charmbracelet/gum#installation) are optional. `ai-context` uses them when they are available. It uses its Bash interface when they are not available.

## Install project context

Go to the project and run the installer:

```bash
cd /path/to/project
ai-context install
```

The command shows a compact preview and asks for approval. It writes the configuration to the current project after you approve it.

To list every path in the preview:

```bash
ai-context install --dry-run --verbose
```

## Install global context

Run:

```bash
ai-context install --global
```

This command installs shared configuration in your home directory. The preview shows each target area before you approve it.

The global install manages `~/.claude/CLAUDE.md` as an import file. Its complete content is `@~/.codex/AGENTS.md`. If the file contains other text, the installer shows a replacement and asks for approval.

## Check the installation

Check the current project:

```bash
ai-context doctor
```

Check the global configuration:

```bash
ai-context doctor --global
```

The report checks the required tools, target files, instruction import, configuration syntax, safety settings, and rollback history. If it finds a problem, it shows the repair steps and exits with a non-zero status.

## Control an installation

Use these options after `ai-context install`:

| Option | Result |
|---|---|
| `--global` | Install global configuration |
| `--dry-run` | Preview changes and stop |
| `--verbose` | List every path in the preview |
| `--no-interaction` | Apply the preview without a prompt |
| `--force` | Replace changed files that `ai-context` manages |
| `--replace-config` | Replace complete Claude and Codex configuration files |

By default, the installer merges `.claude/settings.json`, `.codex/config.toml`, and `.codex/hooks.json`. Use `--replace-config` only when you want to remove configuration that is not part of `ai-context`.

## Restore a version

List saved project versions:

```bash
ai-context history
```

List saved global versions:

```bash
ai-context history --global
```

Select a version to restore:

```bash
ai-context rollback
```

Restore a version by its ID:

```bash
ai-context rollback SNAPSHOT_ID
ai-context rollback SNAPSHOT_ID --global
```

Each install and rollback saves the previous state. A restore can put old files back and remove files that did not exist in the selected version.

## Find commands and options

Show all CLI commands:

```bash
ai-context --help
```

Show options for one command:

```bash
ai-context install --help
ai-context rollback --help
```

From the repository, run `task` or `task list` to show every Task command:

```bash
task
task list
```

Use the named Task commands for project and global operations:

```bash
task install
task install:global
task doctor
task doctor:global
task history
task history:global
task rollback
task rollback:global
```

Show install options without starting an install:

```bash
task install:help
```

Task treats `task install help` as two separate tasks. Use `task install:help` for command help. Use the `ai-context` command when you need to combine install options such as `--global`, `--force`, or `--replace-config`.

## Update ai-context

Pull the latest release from the cloned repository:

```bash
git -C "$HOME/.local/share/ai-context" pull --ff-only
```

Run `ai-context install` or `ai-context install --global` again to preview and apply the update.

## Supported systems

`ai-context` supports macOS, Linux, WSL, and Git Bash. Native PowerShell is not supported.

## License

MIT. See [LICENSE.md](LICENSE.md).
