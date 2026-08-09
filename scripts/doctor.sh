#!/usr/bin/env bash
set -uo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly force_install=false
readonly is_dry_run=false
readonly is_interactive=false
source "$repository_root/scripts/lib.sh"

failures=0
warnings=0
results=
readonly target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly payload_root="$repository_root/resources/payload"
readonly state_root="$(resolve_state_root)"

if [[ "$scope" == global ]]; then
  readonly agents_path="$target_root/.codex/AGENTS.md"
  readonly claude_path="$target_root/.claude/CLAUDE.md"
  readonly claude_import='@~/.codex/AGENTS.md'
else
  readonly agents_path="$target_root/AGENTS.md"
  readonly claude_path="$target_root/CLAUDE.md"
  readonly claude_import='@AGENTS.md'
fi
readonly skills_path="$target_root/.agents/skills"
readonly claude_settings="$target_root/.claude/settings.json"
readonly codex_settings="$target_root/.codex/config.toml"
readonly codex_hooks="$target_root/.codex/hooks.json"

add_result() {
  results+="$1"$'\t'"$2"$'\t'"$3"$'\n'
}

render_header 'ai-context doctor' "$scope" "$target_root"

missing_tools=
command -v jq >/dev/null 2>&1 || missing_tools+='jq '
if ! command -v python3 >/dev/null 2>&1 \
  || ! python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 11))' >/dev/null 2>&1; then
  missing_tools+='Python-3.11+ '
fi
if [[ -n "$missing_tools" ]]; then
  add_result 'Required tools' 'FAIL' "Install ${missing_tools% }"
  failures=$((failures + 1))
else
  add_result 'Required tools' 'PASS' 'jq and Python 3.11+'
fi

optional_tools=
command -v task >/dev/null 2>&1 || optional_tools+='Task '
command -v gum >/dev/null 2>&1 || optional_tools+='Gum '
if [[ -n "$optional_tools" ]]; then
  add_result 'Optional UI' 'WARN' "${optional_tools% } missing; shell fallback is active"
  warnings=$((warnings + 1))
else
  add_result 'Optional UI' 'PASS' 'Task and Gum'
fi

agent_tools=
command -v codex >/dev/null 2>&1 || agent_tools+='Codex '
command -v claude >/dev/null 2>&1 || agent_tools+='Claude '
if [[ -n "$agent_tools" ]]; then
  add_result 'Agent CLIs' 'WARN' "${agent_tools% } not found"
  warnings=$((warnings + 1))
else
  add_result 'Agent CLIs' 'PASS' 'Codex and Claude'
fi

if [[ -d "$target_root" && -w "$target_root" ]]; then
  add_result 'Target' 'PASS' 'Writable'
else
  add_result 'Target' 'FAIL' 'Directory is missing or not writable'
  failures=$((failures + 1))
fi

installed_parts=0
[[ -f "$agents_path" ]] && installed_parts=$((installed_parts + 1))
[[ -d "$skills_path" ]] && installed_parts=$((installed_parts + 1))
[[ -f "$claude_path" ]] && installed_parts=$((installed_parts + 1))
if [[ "$installed_parts" -eq 0 ]]; then
  installation_state=missing
  add_result 'Installation' 'MISSING' 'No managed installation found'
  failures=$((failures + 1))
elif [[ "$installed_parts" -lt 3 ]]; then
  installation_state=partial
  add_result 'Installation' 'FAIL' 'Managed installation is incomplete'
  failures=$((failures + 1))
else
  installation_state=installed
  add_result 'Installation' 'PASS' 'Instructions and shared tools found'
fi

if [[ "$installation_state" == installed ]]; then
  if grep -Fq "$claude_import" "$claude_path"; then
    add_result 'Claude import' 'PASS' "$claude_import"
  else
    add_result 'Claude import' 'FAIL' 'Shared instructions are not imported'
    failures=$((failures + 1))
  fi

  config_errors=
  [[ -f "$claude_settings" ]] && jq empty "$claude_settings" >/dev/null 2>&1 || config_errors+='Claude JSON; '
  [[ -f "$codex_hooks" ]] && jq empty "$codex_hooks" >/dev/null 2>&1 || config_errors+='Codex hooks; '
  if [[ -f "$codex_settings" ]] && command -v python3 >/dev/null 2>&1; then
    python3 -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
      "$codex_settings" >/dev/null 2>&1 || config_errors+='Codex TOML; '
  else
    config_errors+='Codex TOML; '
  fi
  if [[ -n "$config_errors" ]]; then
    add_result 'Configuration' 'FAIL' "Invalid or missing: ${config_errors%; }"
    failures=$((failures + 1))
  else
    add_result 'Configuration' 'PASS' 'Claude JSON, Codex JSON, and TOML are valid'

    safety_errors=
    jq -e '(.permissions.deny // []) | index("Read(auth.json)") != null' \
      "$claude_settings" >/dev/null 2>&1 || safety_errors+='Claude deny rules; '
    python3 -c \
      'import pathlib, sys, tomllib; data=tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); assert "project-edit" in data.get("permissions", {})' \
      "$codex_settings" >/dev/null 2>&1 || safety_errors+='Codex permissions; '
    if [[ -n "$safety_errors" ]]; then
      add_result 'Safety settings' 'FAIL' "Missing: ${safety_errors%; }"
      failures=$((failures + 1))
    else
      add_result 'Safety settings' 'PASS' 'Claude deny rules and Codex permissions'
    fi
  fi
else
  add_result 'Configuration' 'SKIP' 'Install context first'
fi

history_count=0
if command -v python3 >/dev/null 2>&1; then
  history_count="$(python3 "$repository_root/scripts/state.py" history \
    --scope "$scope" --target "$target_root" --payload "$payload_root" --state-root "$state_root" 2>/dev/null \
    | wc -l | tr -d ' ')"
fi
add_result 'Rollback history' 'INFO' "$history_count saved version(s)"

render_doctor_results "${results%$'\n'}"
if [[ "$failures" -gt 0 ]]; then
  if [[ "$scope" == global ]]; then
    next_command='ai-context install --global --dry-run'
  else
    next_command='ai-context install --dry-run'
  fi
  error "doctor found $failures problem(s) and $warnings warning(s)"
  printf 'Next: %s\n' "$next_command"
  exit 1
fi
success "doctor passed with $warnings warning(s)"
