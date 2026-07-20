# Agnostic Agentic Engineering Context

[![Latest Version on Packagist](https://img.shields.io/packagist/v/jean-pierre-gassin/ai-context.svg?style=flat-square)](https://packagist.org/packages/jean-pierre-gassin/ai-context)
[![Total Downloads](https://img.shields.io/packagist/dt/jean-pierre-gassin/ai-context.svg?style=flat-square)](https://packagist.org/packages/jean-pierre-gassin/ai-context)
[![License](https://img.shields.io/packagist/l/jean-pierre-gassin/ai-context.svg?style=flat-square)](LICENSE.md)

This package installs a shared set of agent skills and workflow guidance into any project. Claude Code and any Open
Agent Specification harness read the same files, so there is nothing to keep in sync by hand.

## Installation

```bash
composer require --dev jean-pierre-gassin/ai-context
vendor/bin/ai-context
```

## Updates + auto installing

Updates follow the same two steps:

```bash
composer update jean-pierre-gassin/ai-context
vendor/bin/ai-context
```

To have this package automatically install after an update, wire the installer into your root `composer.json`:

```json
{
  "scripts": {
    "post-install-cmd": [
      "JeanPierreGassin\\AiContext\\Support\\ComposerScriptHandler::install"
    ],
    "post-update-cmd": [
      "JeanPierreGassin\\AiContext\\Support\\ComposerScriptHandler::install"
    ]
  }
}
```

## Usage

| Option                   | Effect                                             |
|--------------------------|----------------------------------------------------|
| `--force`, `-f`          | Overwrite modified files without asking            |
| `--no-interaction`, `-n` | Never prompt; leave modified files alone           |
| `--project-dir`          | Install somewhere other than the current directory |

Default behaviour will prompt for anything destructive. With no terminal to prompt on, `--no-interaction` is assumed, so
CI and container builds don't stall.

## What's included

| Path                                                                   | Purpose                                            |
|------------------------------------------------------------------------|----------------------------------------------------|
| `AGENTS.md`                                                            | The canonical workflow guidance                    |
| `CLAUDE.md`                                                            | A one-line include of `AGENTS.md`                  |
| `.agents/skills/*`                                                     | The skills themselves, in portable form            |
| `.claude/skills/*`                                                     | Thin Claude Code stubs pointing at the same skills |
| `.claude/settings.json`, `hooks/*`, `output-styles/*`, `statusline.sh` | Claude Code harness setup                          |
| `.codex/config.toml`                                                   | Codex approvals, sandbox, and secret-file denies   |

## Skills

| Skill                       | Use it when                                                                               |
|-----------------------------|-------------------------------------------------------------------------------------------|
| `write-code`                | Writing, editing, or reviewing code in any language or framework                          |
| `write-tests`               | Writing, editing, or reviewing tests, in any language or framework                        |
| `write-plan`                | Tracking a multi-step task across a session, as thin vertical slices with a restore point |
| `write-ticket`              | Writing a ticket for a story, bug, task, or investigation                                 |
| `write-pr`                  | Opening, drafting, or editing a pull request                                              |
| `git-commit`                | Committing, staging, splitting a diff, or writing the message itself                      |
| `orchestrate-investigation` | Investigating, researching, or finding a root cause                                       |

`.agents/skills/*` holds the real content, using only the frontmatter the Open Agent Specification defines.
`.claude/skills/*` holds a stub per skill carrying any Claude-specific fields and a pointer back to the canonical file.

## Lives alongside your projects

The installer tries its best to only touch the files it deploys. Skills of your own sit beside the packaged ones in the
same directories, stay tracked by git, and are never read, moved, or rewritten.

__Note: If you have a skill with a conflicting name, the installer will prompt to overwrite it.__

Every packaged skill directory carries its own `.gitignore`, which ignores the skill's contents and that ignore file
with them, allowing you to have a "clean" project without dirtying commits on update (unless there are major changes to
settings or CLAUDE/AGENTS.md).

## Contributing

Pull requests and issues are welcome on [GitHub](https://github.com/Jean-PierreGassin/ai-context).

## Credits

- [Jean-Pierre Gassin](https://github.com/Jean-PierreGassin)
- [All Contributors](https://github.com/Jean-PierreGassin/ai-context/contributors)

## License

MIT. See [LICENSE.md](LICENSE.md).
