#!/usr/bin/env bash
set -euo pipefail

source "$AI_CONTEXT_ROOT/scripts/lib.sh"

AI_CONTEXT_REPLACE_CONFIG="${AI_CONTEXT_REPLACE_CONFIG:-false}"

AI_CONTEXT_CHANGED=0
AI_CONTEXT_SKIPPED=0
AI_CONTEXT_FAILURES=0
export AI_CONTEXT_CHANGED AI_CONTEXT_SKIPPED AI_CONTEXT_FAILURES

readonly payload_root="$AI_CONTEXT_ROOT/resources/payload"
if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
  readonly target_root="${AI_CONTEXT_HOME_OVERRIDE:-$HOME}"
else
  readonly target_root="$AI_CONTEXT_CALLER_DIR"
fi

install_project() {
  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/"}"
    case "$relative_path" in
      CLAUDE.md|.claude/settings.json|.codex/config.toml|.codex/hooks.json) continue ;;
    esac
    copy_managed_file "$source_path" "$target_root/$relative_path" "$relative_path"
  done < <(find "$payload_root" -type f -print0 | sort -z)

  ensure_import "$target_root/CLAUDE.md" '@AGENTS.md' 'CLAUDE.md'
  install_structured_configuration "$payload_root/.claude/settings.json" ''

  local skill_directory skill_ignore
  skill_ignore="$(mktemp "${TMPDIR:-/tmp}/ai-context-ignore.XXXXXX")"
  printf '# Installed and owned by ai-context. Ignores this file too.\n*\n' >"$skill_ignore"
  for skill_directory in "$payload_root/.agents/skills"/* "$payload_root/.claude/skills"/*; do
    [[ -d "$skill_directory" ]] || continue
    local relative_skill="${skill_directory#"$payload_root/"}"
    copy_managed_file "$skill_ignore" "$target_root/$relative_skill/.gitignore" "$relative_skill/.gitignore"
  done
  rm -f "$skill_ignore"
}

install_global() {
  copy_managed_file "$payload_root/AGENTS.md" "$target_root/.codex/AGENTS.md" '~/.codex/AGENTS.md'

  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.agents/"}"
    copy_managed_file "$source_path" "$target_root/.agents/$relative_path" "~/.agents/$relative_path"
  done < <(find "$payload_root/.agents" -type f -print0 | sort -z)

  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.claude/"}"
    case "$relative_path" in settings.json) continue ;; esac
    copy_managed_file "$source_path" "$target_root/.claude/$relative_path" "~/.claude/$relative_path"
  done < <(find "$payload_root/.claude" -type f -print0 | sort -z)

  ensure_import "$target_root/.claude/CLAUDE.md" '@~/.codex/AGENTS.md' '~/.claude/CLAUDE.md'

  local global_claude_settings
  global_claude_settings="$(mktemp "${TMPDIR:-/tmp}/ai-context-claude.XXXXXX")"
  sed -e 's|\$CLAUDE_PROJECT_DIR/.agents/|\$HOME/.agents/|g' \
    -e 's|\$CLAUDE_PROJECT_DIR/.claude/|\$HOME/.claude/|g' \
    "$payload_root/.claude/settings.json" >"$global_claude_settings"
  install_structured_configuration "$global_claude_settings" '~/'
  rm -f "$global_claude_settings"
}

install_structured_configuration() {
  local claude_settings_source="$1"
  local display_prefix="$2"
  if [[ "$AI_CONTEXT_REPLACE_CONFIG" == true ]]; then
    replace_config_file "$claude_settings_source" "$target_root/.claude/settings.json" "${display_prefix}.claude/settings.json"
    replace_config_file "$payload_root/.codex/config.toml" "$target_root/.codex/config.toml" "${display_prefix}.codex/config.toml"
    replace_config_file "$payload_root/.codex/hooks.json" "$target_root/.codex/hooks.json" "${display_prefix}.codex/hooks.json"
  else
    merge_json_file "$claude_settings_source" "$target_root/.claude/settings.json" "${display_prefix}.claude/settings.json"
    merge_toml_file "$payload_root/.codex/config.toml" "$target_root/.codex/config.toml" "${display_prefix}.codex/config.toml"
    merge_json_file "$payload_root/.codex/hooks.json" "$target_root/.codex/hooks.json" "${display_prefix}.codex/hooks.json"
  fi
}

run_install() {
  if [[ "$AI_CONTEXT_SCOPE" == global ]]; then
    install_global
  else
    install_project
  fi
}

readonly requested_dry_run="$AI_CONTEXT_DRY_RUN"
AI_CONTEXT_DRY_RUN=true
AI_CONTEXT_PLANNING=true
export AI_CONTEXT_DRY_RUN AI_CONTEXT_PLANNING

render_header 'ai-context install' "$AI_CONTEXT_SCOPE" "$target_root"
if [[ "$AI_CONTEXT_REPLACE_CONFIG" == true ]]; then
  config_action='Replace all managed settings in'
else
  config_action='Merge managed settings into'
fi
if [[ "$requested_dry_run" == true ]]; then
  snapshot_action='Do not write files or save a rollback snapshot'
else
  snapshot_action='After approval, record existing and new paths so rollback can restore or remove them'
fi
render_install_plan "$AI_CONTEXT_SCOPE" "$target_root" "$config_action" "$snapshot_action"
printf 'Changes:\n'
run_install

if [[ "$AI_CONTEXT_FAILURES" -gt 0 ]]; then
  error "plan failed: $AI_CONTEXT_FAILURES failure(s), $AI_CONTEXT_CHANGED change(s), $AI_CONTEXT_SKIPPED skipped"
  exit 1
fi
success "plan complete: $AI_CONTEXT_CHANGED change(s), $AI_CONTEXT_SKIPPED skipped"

if [[ "$requested_dry_run" == true ]]; then
  success "dry run complete: $AI_CONTEXT_CHANGED change(s), $AI_CONTEXT_SKIPPED skipped"
  exit 0
fi

if ! confirm_action 'Apply this installation plan?'; then
  info 'installation cancelled; no files or snapshots were changed'
  exit 0
fi

AI_CONTEXT_CHANGED=0
AI_CONTEXT_SKIPPED=0
AI_CONTEXT_FAILURES=0
AI_CONTEXT_DRY_RUN=false
AI_CONTEXT_PLANNING=false
export AI_CONTEXT_CHANGED AI_CONTEXT_SKIPPED AI_CONTEXT_FAILURES AI_CONTEXT_DRY_RUN AI_CONTEXT_PLANNING

readonly state_root="${AI_CONTEXT_STATE_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/ai-context}"
snapshot_id="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" snapshot \
  --scope "$AI_CONTEXT_SCOPE" \
  --target "$target_root" \
    --payload "$payload_root" \
    --state-root "$state_root")"
snapshot_state="$(python3 "$AI_CONTEXT_ROOT/scripts/state.py" history \
  --scope "$AI_CONTEXT_SCOPE" \
  --target "$target_root" \
  --payload "$payload_root" \
  --state-root "$state_root" | awk -F '\t' -v snapshot_id="$snapshot_id" '$1 == snapshot_id {print; exit}')"
IFS=$'\t' read -r _ _ _ snapshot_restore snapshot_remove <<<"$snapshot_state"
info "saved pre-install version $snapshot_id; rollback will restore $snapshot_restore existing path(s) and remove $snapshot_remove new path(s)"

run_install
if [[ "$AI_CONTEXT_FAILURES" -gt 0 ]]; then
  error "installation failed: $AI_CONTEXT_FAILURES failure(s), $AI_CONTEXT_CHANGED change(s), $AI_CONTEXT_SKIPPED skipped"
  exit 1
fi
success "installation complete: $AI_CONTEXT_CHANGED change(s), $AI_CONTEXT_SKIPPED skipped"
