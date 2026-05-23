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
- `.codex/config.toml`
- Managed ignore files for package-owned skills

The `.claude` skill files point back to the matching `.agents` skills, so the main skill content stays in one place.

## Existing Projects

The installer is conservative:

- Identical files are skipped silently.
- Changed files require a `y` or `yes` confirmation before overwrite.
- Installed files are copied, not symlinked.
- Managed `.gitignore` entries only cover the skill names provided by this package and the managed ignore file itself.
- Project-specific skills and local guidance can still be tracked normally.
