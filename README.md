# Agnostic Agentic Engineering Context

`ai-context` installs shared instructions, skills, hooks, and safety settings for coding agents. Install it in a project
or globally.

The instructions and skills use open formats: `AGENTS.md` for the instructions, and one `SKILL.md` per skill. They
install to `AGENTS.md` and `.agents/`, outside any vendor directory, so nothing about them is tied to one agent. Point
any harness that reads those formats at them. `ai-context` also writes the adapters and safety settings that Claude Code
and Codex need, which is what `CLAUDE.md`, `.claude/`, and `.codex/` are for.

The installer shows a preview before it changes files. It keeps structured settings that it does not manage and saves a
version that you can restore.

## Supported systems

`ai-context` supports macOS, Linux, WSL, and Git Bash. Native PowerShell is not supported.

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

[Task](https://taskfile.dev/docs/installation) and [Gum](https://github.com/charmbracelet/gum#installation) are
optional. `ai-context` uses them when they are available. It uses its Bash interface when they are not available.

## Install project context

Go to the project and run the installer:

```bash
cd /path/to/project
ai-context install
```

The command shows a compact preview and asks for approval. It writes the configuration to the current project after you
approve it.

To list every path in the preview:

```bash
ai-context install --dry-run --verbose
```

## Install global context

Run:

```bash
ai-context install --global
```

This command installs shared configuration in your home directory. The preview shows each target area before you approve
it.

The global install manages `~/.claude/CLAUDE.md` as an import file. Its complete content is `@~/.agents/AGENTS.md`. If
the file contains other text, the installer shows a replacement and asks for approval.

## Control an installation

Use these options after `ai-context install`:

| Option             | Result                                                |
|--------------------|-------------------------------------------------------|
| `--global`         | Install global configuration                          |
| `--dry-run`        | Preview changes and stop                              |
| `--verbose`        | List every path in the preview                        |
| `--no-interaction` | Apply the preview without a prompt                    |
| `--force`          | Replace changed files that `ai-context` manages       |
| `--replace-config` | Replace complete Claude and Codex configuration files |

By default, the installer merges `.claude/settings.json`, `.codex/config.toml`, and `.codex/hooks.json`. Use
`--replace-config` only when you want to remove configuration that is not part of `ai-context`.

## Check the installation

Check the current project:

```bash
ai-context doctor
```

Check the global configuration:

```bash
ai-context doctor --global
```

The report checks the required tools, target files, instruction import, configuration syntax, safety settings, and
rollback history. If it finds a problem, it shows the repair steps and exits with a non-zero status.

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

Each install and rollback saves the previous state. A restore can put old files back and remove files that did not exist
in the selected version.

## Update ai-context

Pull the latest release from the cloned repository:

```bash
git -C "$HOME/.local/share/ai-context" pull --ff-only
```

Run `ai-context install` or `ai-context install --global` again to preview and apply the update.

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

Task treats `task install help` as two separate tasks. Use `task install:help` for command help. Use the `ai-context`
command when you need to combine install options such as `--global`, `--force`, or `--replace-config`.

## Skill layout

`resources/payload/.agents/skills/` holds the skills. Write them there. The files in
`resources/payload/.claude/skills/` are thin adapters that exist only because Claude Code looks in `.claude/skills/`.
Each one points at a skill in `.agents` and does not copy its content, so a second harness costs another adapter rather
than another copy of the skill.

A skill uses the parts of this structure that it needs:

| Path          | Holds                                                                         |
|---------------|-------------------------------------------------------------------------------|
| `SKILL.md`    | The trigger, the workflow, the rules that always apply, and links to the rest |
| `references/` | Rules for one language, framework, or task type                               |
| `examples/`   | Finished examples of the output                                               |
| `assets/`     | Templates to fill in                                                          |
| `scripts/`    | Automated checks                                                              |

A rule that applies every time the skill runs goes in `SKILL.md`. A small skill stays one file. Do not split it to match
the shape of a larger one.

Run `task test` after changing a skill. It needs [ShellCheck](https://www.shellcheck.net/).

## Evals

`evals/` holds trigger and behaviour test data for these skills. The installer does not copy it into a project.
[evals/README.md](evals/README.md) describes the schema and how a runner reads it.

`task test` validates the corpus. It does not run the cases against a model.

Running the cases costs real model calls. Run them with the model and reasoning effort you work at. A run against a
cheaper model, or at a lower effort, measures a setup you do not use and tells you nothing about yours.

## License

MIT. See [LICENSE.md](LICENSE.md).
