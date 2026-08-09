#!/usr/bin/env bash
set -uo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

failures=0
warnings=0
if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
  readonly target_root="${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
  readonly agents_path="$target_root/.codex/AGENTS.md"
  readonly claude_path="$target_root/.claude/CLAUDE.md"
  readonly claude_import='@~/.codex/AGENTS.md'
  readonly skills_path="$target_root/.agents/skills"
  readonly claude_settings="$target_root/.claude/settings.json"
  readonly codex_settings="$target_root/.codex/config.toml"
else
  readonly target_root="$AI_CONTEXT_CALLER_DIR"
  readonly agents_path="$target_root/AGENTS.md"
  readonly claude_path="$target_root/CLAUDE.md"
  readonly claude_import='@AGENTS.md'
  readonly skills_path="$target_root/.agents/skills"
  readonly claude_settings="$target_root/.claude/settings.json"
  readonly codex_settings="$target_root/.codex/config.toml"
fi

pass_check() { info "ok: $1"; }
fail_check() { error "fail: $1"; failures=$((failures + 1)); }
warn_check() { warn "warn: $1"; warnings=$((warnings + 1)); }

render_header 'ai-context doctor' "$AI_CONTEXT_SCOPE" "$target_root"

if command -v jq >/dev/null 2>&1; then
  pass_check 'jq is available'
else
  fail_check 'jq is required'
fi

if command -v python3 >/dev/null 2>&1 \
  && python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 11))' >/dev/null 2>&1; then
  pass_check 'Python 3.11 or newer is available'
else
  fail_check 'Python 3.11 or newer is required'
fi

command -v task >/dev/null 2>&1 && pass_check 'Task is available' || warn_check 'Task is not available; direct shell execution is active'
command -v gum >/dev/null 2>&1 && pass_check 'Gum is available' || warn_check 'Gum is not available; plain terminal output is active'

if [[ -d "$target_root" && -w "$target_root" ]]; then
  pass_check 'target is writable'
else
  fail_check 'target is not writable'
fi

[[ -f "$agents_path" ]] && pass_check 'AGENTS.md is installed' || fail_check 'AGENTS.md is missing'
[[ -d "$skills_path" ]] && pass_check 'shared skills are installed' || fail_check 'shared skills are missing'

if [[ -f "$claude_path" ]] && grep -Fq "$claude_import" "$claude_path"; then
  pass_check 'Claude imports the shared instructions'
else
  fail_check 'Claude does not import the shared instructions'
fi

if [[ -f "$claude_settings" ]] && jq empty "$claude_settings" >/dev/null 2>&1; then
  pass_check 'Claude settings contain valid JSON'
  if jq -e '.permissions.deny | index("Read(auth.json)") != null' "$claude_settings" >/dev/null 2>&1; then
    pass_check 'Claude safety settings are installed'
  else
    fail_check 'Claude safety settings are incomplete'
  fi
else
  fail_check 'Claude settings are missing or invalid'
fi

if [[ -f "$codex_settings" ]] && python3 -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$codex_settings" >/dev/null 2>&1; then
  pass_check 'Codex settings contain valid TOML'
  if python3 -c 'import pathlib, sys, tomllib; data=tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); assert "project-edit" in data.get("permissions", {})' "$codex_settings" >/dev/null 2>&1; then
    pass_check 'Codex permission profile is installed'
  else
    fail_check 'Codex permission profile is incomplete'
  fi
else
  fail_check 'Codex settings are missing or invalid'
fi

command -v codex >/dev/null 2>&1 && pass_check 'Codex CLI is available' || warn_check 'Codex CLI is not available'
command -v claude >/dev/null 2>&1 && pass_check 'Claude Code is available' || warn_check 'Claude Code is not available'

if [[ "$failures" -gt 0 ]]; then
  error "doctor found $failures failure(s) and $warnings warning(s)"
  exit 1
fi
success "doctor passed with $warnings warning(s)"
