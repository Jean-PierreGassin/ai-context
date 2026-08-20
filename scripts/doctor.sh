#!/usr/bin/env bash
set -uo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly force_install=false
readonly is_dry_run=false
readonly is_interactive=false
source "$repository_root/scripts/lib.sh"

failures=0
warnings=0
results=
target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly target_root
readonly payload_root="$repository_root/resources/payload"
state_root="$(resolve_state_root)"
readonly state_root

if [[ "$scope" == global ]]; then
  readonly agents_path="$target_root/.agents/AGENTS.md"
  readonly claude_path="$target_root/.claude/CLAUDE.md"
  readonly claude_import='@~/.agents/AGENTS.md'
  readonly agents_display="$home_display/.agents/AGENTS.md"
  readonly claude_display="$home_display/.claude/CLAUDE.md"
  readonly skills_display="$home_display/.agents/skills/"
else
  readonly agents_path="$target_root/AGENTS.md"
  readonly claude_path="$target_root/CLAUDE.md"
  readonly claude_import='@AGENTS.md'
  readonly agents_display='AGENTS.md'
  readonly claude_display='CLAUDE.md'
  readonly skills_display='.agents/skills/'
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
missing_installation=
if [[ -f "$agents_path" ]]; then installed_parts=$((installed_parts + 1)); else missing_installation+="$agents_display, "; fi
if [[ -d "$skills_path" ]]; then installed_parts=$((installed_parts + 1)); else missing_installation+="$skills_display, "; fi
if [[ -f "$claude_path" ]]; then installed_parts=$((installed_parts + 1)); else missing_installation+="$claude_display, "; fi
if [[ "$installed_parts" -eq 0 ]]; then
  installation_state=missing
  add_result 'Installation' 'MISSING' "Missing: ${missing_installation%, }"
  failures=$((failures + 1))
elif [[ "$installed_parts" -lt 3 ]]; then
  installation_state=partial
  add_result 'Installation' 'FAIL' "Missing: ${missing_installation%, }"
  failures=$((failures + 1))
else
  installation_state=installed
  add_result 'Installation' 'PASS' 'Instructions and shared tools found'
fi

if [[ "$installation_state" == installed ]]; then
  if grep -Fq "$claude_import" "$claude_path"; then
    add_result 'Claude import' 'PASS' "$claude_import"
  else
    add_result 'Claude import' 'FAIL' "Expected $claude_import in $claude_display"
    failures=$((failures + 1))
  fi

  config_errors=
  [[ -f "$claude_settings" ]] && jq empty "$claude_settings" >/dev/null 2>&1 || config_errors+='.claude/settings.json, '
  [[ -f "$codex_hooks" ]] && jq empty "$codex_hooks" >/dev/null 2>&1 || config_errors+='.codex/hooks.json, '
  if [[ -f "$codex_settings" ]] && command -v python3 >/dev/null 2>&1; then
    python3 -c 'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
      "$codex_settings" >/dev/null 2>&1 || config_errors+='.codex/config.toml, '
  else
    config_errors+='.codex/config.toml, '
  fi
  if [[ -n "$config_errors" ]]; then
    has_invalid_configuration=true
    add_result 'Configuration' 'FAIL' "Invalid or missing: ${config_errors%, }"
    failures=$((failures + 1))
  else
    add_result 'Configuration' 'PASS' 'Claude JSON, Codex JSON, and TOML are valid'

    safety_errors=
    jq -e '(.permissions.deny // []) | index("Read(auth.json)") != null' \
      "$claude_settings" >/dev/null 2>&1 || safety_errors+='.claude/settings.json deny rules, '
    python3 -c \
      'import pathlib, sys, tomllib; data=tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); assert "project-edit" in data.get("permissions", {})' \
      "$codex_settings" >/dev/null 2>&1 || safety_errors+='.codex/config.toml permissions, '
    if [[ -n "$safety_errors" ]]; then
      add_result 'Safety settings' 'FAIL' "Missing: ${safety_errors%, }"
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
  install_options=
  if [[ "$scope" == global ]]; then
    install_options=' --global'
  fi
  error "doctor found $failures problem(s) and $warnings warning(s)"
  printf 'Resolution:\n'
  if [[ "${has_invalid_configuration:-false}" == true ]]; then
    printf '  1. Fix the invalid files above, or review a full replacement:\n'
    printf '     ai-context install%s --replace-config --dry-run\n' "$install_options"
  else
    printf '  1. Review the repair: ai-context install%s --dry-run\n' "$install_options"
  fi
  printf '  2. Apply the repair: ai-context install%s\n' "$install_options"
  printf '  3. Check again: ai-context doctor%s\n' "$install_options"
  exit 1
fi
success "doctor passed with $warnings warning(s)"
