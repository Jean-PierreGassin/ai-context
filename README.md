# AI Context

Shared AI-assistant context for projects that use `AGENTS.md`, `.agents/skills`, `.claude/skills`, or similar local guidance files.

The package ships a small baseline of workflow guidance and reusable skills. It installs regular files into the consuming project, keeps existing project files intact by default, and can be wired into Composer's normal install/update lifecycle.

## Installation

Add the installer to your root `composer.json` scripts:

```json
{
  "scripts": {
    "post-install-cmd": [
      "JeanPierreGassin\\AiContext\\Installer::installFromComposer"
    ],
    "post-update-cmd": [
      "JeanPierreGassin\\AiContext\\Installer::installFromComposer"
    ]
  }
}
```

Then require the package:

```bash
composer require jean-pierre-gassin/ai-context
```

Run Composer as usual after that:

```bash
composer install
composer update jean-pierre-gassin/ai-context
```

## What It Adds

- `AGENTS.md`
- `CLAUDE.md`
- `.agents/skills/*`
- `.claude/skills/*`
- `.claude/settings.json`
- `.claude/output-styles/*`
- `.codex/config.toml`
- Managed ignore files for package-owned skills

## One Source, Multiple Agents

This package lets you use both Claude Code and agents that rely on the Open Agent Specification (e.g. Codex) without maintaining two separate configurations or skillsets:

- `.agents/skills/*` holds the canonical skill content, using only the `name`/`description` frontmatter fields that the Open Agent Specification defines.
- `.claude/skills/*` holds a thin stub per skill (matching frontmatter, plus any Claude-specific fields such as `context`/`agent`) that points back to the matching file under `.agents/skills/*`, so Claude Code reads the same content without duplicating it.
- `AGENTS.md` holds the canonical guidance; `CLAUDE.md` just includes it via `@AGENTS.md`.

Update a skill or the guidance once, and every supported agent stays in sync.

## Existing Projects

The installer is conservative:

- Identical files are skipped silently.
- Changed files require a `y` or `yes` confirmation before overwrite.
- Installed files are copied, not symlinked.
- Managed `.gitignore` entries only cover the skill names provided by this package and the managed ignore file itself.
- Project-specific skills and local guidance can still be tracked normally.
