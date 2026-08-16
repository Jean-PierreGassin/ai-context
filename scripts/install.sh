#!/usr/bin/env bash
set -euo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
readonly force_install="${3:?force setting is required}"
readonly requested_dry_run="${4:?dry-run setting is required}"
readonly is_interactive="${5:?interactive setting is required}"
readonly replace_config="${6:?replace-config setting is required}"
readonly is_verbose="${7:-false}"
unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
source "$repository_root/scripts/lib.sh"

changed_count=0
skipped_count=0
failure_count=0
planned_targets=
is_dry_run="$requested_dry_run"
is_planning=false

readonly payload_root="$repository_root/resources/payload"
target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly target_root

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
  copy_managed_file "$payload_root/AGENTS.md" "$target_root/.codex/AGENTS.md" "$home_display/.codex/AGENTS.md"

  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.agents/"}"
    copy_managed_file "$source_path" "$target_root/.agents/$relative_path" "$home_display/.agents/$relative_path"
  done < <(find "$payload_root/.agents" -type f -print0 | sort -z)

  local global_skill_adapter
  global_skill_adapter="$(mktemp "${TMPDIR:-/tmp}/ai-context-adapter.XXXXXX")"
  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.claude/"}"
    case "$relative_path" in
      settings.json) continue ;;
      skills/*/SKILL.md)
        sed "s|\`\.agents/skills/|\`~/.agents/skills/|g" "$source_path" >"$global_skill_adapter"
        match_file_mode "$source_path" "$global_skill_adapter"
        copy_managed_file "$global_skill_adapter" "$target_root/.claude/$relative_path" "$home_display/.claude/$relative_path"
        continue
        ;;
    esac
    copy_managed_file "$source_path" "$target_root/.claude/$relative_path" "$home_display/.claude/$relative_path"
  done < <(find "$payload_root/.claude" -type f -print0 | sort -z)
  rm -f "$global_skill_adapter"

  local global_claude_instructions
  global_claude_instructions="$(mktemp "${TMPDIR:-/tmp}/ai-context-instructions.XXXXXX")"
  printf '@~/.codex/AGENTS.md\n' >"$global_claude_instructions"
  copy_managed_file "$global_claude_instructions" "$target_root/.claude/CLAUDE.md" "$home_display/.claude/CLAUDE.md"
  rm -f "$global_claude_instructions"

  local global_claude_settings
  global_claude_settings="$(mktemp "${TMPDIR:-/tmp}/ai-context-claude.XXXXXX")"
  # shellcheck disable=SC2016 # the patterns match, and emit, literal $CLAUDE_PROJECT_DIR and $HOME text
  sed -e 's|\$CLAUDE_PROJECT_DIR/.agents/|\$HOME/.agents/|g' \
    -e 's|\$CLAUDE_PROJECT_DIR/.claude/|\$HOME/.claude/|g' \
    "$payload_root/.claude/settings.json" >"$global_claude_settings"
  install_structured_configuration "$global_claude_settings" "$home_display/"
  rm -f "$global_claude_settings"
}

install_structured_configuration() {
  local claude_settings_source="$1"
  local display_prefix="$2"
  if [[ "$replace_config" == true ]]; then
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
  if [[ "$scope" == global ]]; then
    install_global
  else
    install_project
  fi
}

is_dry_run=true
is_planning=true

render_header 'ai-context install' "$scope" "$target_root"
render_install_plan "$scope" "$target_root"
run_install
render_change_summary

if [[ "$failure_count" -gt 0 ]]; then
  error "plan failed: $failure_count failure(s), $changed_count change(s), $skipped_count skipped"
  exit 1
fi
success "plan complete: $changed_count change(s), $skipped_count skipped"

if [[ "$requested_dry_run" == true ]]; then
  success "dry run complete: $changed_count change(s), $skipped_count skipped"
  exit 0
fi

if [[ "$is_interactive" == true && (! -t 0 || ! -t 1) ]]; then
  info 'preview complete; use --no-interaction to apply changes without a prompt'
  exit 0
fi

if ! confirm_action 'Apply this installation plan?'; then
  info 'installation cancelled; no files or snapshots were changed'
  exit 0
fi

changed_count=0
skipped_count=0
failure_count=0
is_dry_run=false
is_planning=false

state_root="$(resolve_state_root)"
readonly state_root
snapshot_id="$(python3 "$repository_root/scripts/state.py" snapshot \
  --scope "$scope" \
  --target "$target_root" \
    --payload "$payload_root" \
    --state-root "$state_root")"
snapshot_state="$(python3 "$repository_root/scripts/state.py" history \
  --scope "$scope" \
  --target "$target_root" \
  --payload "$payload_root" \
  --state-root "$state_root" | awk -F '\t' -v snapshot_id="$snapshot_id" '$1 == snapshot_id {print; exit}')"
IFS=$'\t' read -r _ _ _ snapshot_restore snapshot_remove <<<"$snapshot_state"
saved_version_message="saved pre-install version $snapshot_id; "
saved_version_message+="rollback will restore $snapshot_restore existing path(s) and remove $snapshot_remove new path(s)"
info "$saved_version_message"

run_install
if [[ "$failure_count" -gt 0 ]]; then
  error "installation failed: $failure_count failure(s), $changed_count change(s), $skipped_count skipped"
  exit 1
fi
success "installation complete: $changed_count change(s), $skipped_count skipped"
