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
      .agents/skills/*|.claude/skills/*)
        copy_managed_skill_file "$source_path" "$target_root/$relative_path" "$relative_path"
        continue
        ;;
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
  local global_instructions
  global_instructions="$(mktemp "${TMPDIR:-/tmp}/ai-context-agents.XXXXXX")"
  absolutise_agents_paths "$payload_root/AGENTS.md" "$global_instructions"
  copy_managed_file "$global_instructions" "$target_root/.agents/AGENTS.md" "$home_display/.agents/AGENTS.md"
  copy_managed_file "$global_instructions" "$target_root/.codex/AGENTS.md" "$home_display/.codex/AGENTS.md"
  rm -f "$global_instructions"

  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.agents/"}"
    case "$relative_path" in
      skills/*)
        copy_managed_skill_file \
          "$source_path" \
          "$target_root/.agents/$relative_path" \
          "$home_display/.agents/$relative_path"
        ;;
      *)
        copy_managed_file \
          "$source_path" \
          "$target_root/.agents/$relative_path" \
          "$home_display/.agents/$relative_path"
        ;;
    esac
  done < <(find "$payload_root/.agents" -type f -print0 | sort -z)

  local global_skill_adapter
  global_skill_adapter="$(mktemp "${TMPDIR:-/tmp}/ai-context-adapter.XXXXXX")"
  while IFS= read -r -d '' source_path; do
    local relative_path="${source_path#"$payload_root/.claude/"}"
    case "$relative_path" in
      settings.json) continue ;;
      skills/*/SKILL.md)
        absolutise_agents_paths "$source_path" "$global_skill_adapter"
        copy_managed_skill_file \
          "$global_skill_adapter" \
          "$target_root/.claude/$relative_path" \
          "$home_display/.claude/$relative_path"
        continue
        ;;
    esac
    copy_managed_file "$source_path" "$target_root/.claude/$relative_path" "$home_display/.claude/$relative_path"
  done < <(find "$payload_root/.claude" -type f -print0 | sort -z)
  rm -f "$global_skill_adapter"

  local global_claude_instructions
  global_claude_instructions="$(mktemp "${TMPDIR:-/tmp}/ai-context-instructions.XXXXXX")"
  printf '@~/.agents/AGENTS.md\n' >"$global_claude_instructions"
  copy_managed_file "$global_claude_instructions" "$target_root/.claude/CLAUDE.md" "$home_display/.claude/CLAUDE.md"
  rm -f "$global_claude_instructions"

  local global_claude_settings global_codex_hooks
  global_claude_settings="$(mktemp "${TMPDIR:-/tmp}/ai-context-claude.XXXXXX")"
  global_codex_hooks="$(mktemp "${TMPDIR:-/tmp}/ai-context-codex-hooks.XXXXXX")"
  # shellcheck disable=SC2016 # the patterns match, and emit, literal $CLAUDE_PROJECT_DIR and $HOME text
  sed -e 's|\$CLAUDE_PROJECT_DIR/.agents/|\$HOME/.agents/|g' \
    -e 's|\$CLAUDE_PROJECT_DIR/.claude/|\$HOME/.claude/|g' \
    "$payload_root/.claude/settings.json" >"$global_claude_settings"
  # shellcheck disable=SC2016 # the pattern and replacement contain literal command and environment substitutions
  sed 's|\$(git rev-parse --show-toplevel)/\.agents/hooks/|$HOME/.agents/hooks/|g' \
    "$payload_root/.codex/hooks.json" >"$global_codex_hooks"
  install_structured_configuration "$global_claude_settings" "$home_display/" "$global_codex_hooks"
  rm -f "$global_claude_settings" "$global_codex_hooks"
}

install_structured_configuration() {
  local claude_settings_source="$1"
  local display_prefix="$2"
  local codex_hooks_source="${3:-$payload_root/.codex/hooks.json}"
  if [[ "$replace_config" == true ]]; then
    replace_config_file "$claude_settings_source" "$target_root/.claude/settings.json" "${display_prefix}.claude/settings.json"
    replace_config_file "$payload_root/.codex/config.toml" "$target_root/.codex/config.toml" "${display_prefix}.codex/config.toml"
    replace_config_file "$codex_hooks_source" "$target_root/.codex/hooks.json" "${display_prefix}.codex/hooks.json"
  else
    merge_json_file "$claude_settings_source" "$target_root/.claude/settings.json" "${display_prefix}.claude/settings.json"
    merge_toml_file "$payload_root/.codex/config.toml" "$target_root/.codex/config.toml" "${display_prefix}.codex/config.toml"
    merge_json_file "$codex_hooks_source" "$target_root/.codex/hooks.json" "${display_prefix}.codex/hooks.json"
  fi
}

run_install() {
  if [[ "$scope" == global ]]; then
    install_global
  else
    install_project
  fi
}

plan_installation() {
  is_dry_run=true
  is_planning=true

  render_header 'ai-context install' "$scope" "$target_root"
  run_install
  render_change_summary

  if [[ "$failure_count" -gt 0 ]]; then
    error "plan failed: $failure_count failure(s), $changed_count change(s), $skipped_count skipped"
    return 1
  fi
  printf '\n'
  success "Preview: $changed_count change(s), $skipped_count unchanged"
}

save_pre_install_version() {
  local snapshot_id snapshot_state snapshot_restore snapshot_remove saved_version_message

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
}

apply_installation() {
  changed_count=0
  skipped_count=0
  failure_count=0
  is_dry_run=false
  is_planning=false

  render_section 'Applying changes'
  save_pre_install_version
  run_install

  if [[ "$failure_count" -gt 0 ]]; then
    error "installation failed: $failure_count failure(s), $changed_count change(s), $skipped_count skipped"
    return 1
  fi
  printf '\n'
  success "Installed: $changed_count changed, $skipped_count unchanged"
}

main() {
  plan_installation

  if [[ "$requested_dry_run" == true ]]; then
    info 'Dry run only, no files or snapshots changed.'
    return 0
  fi

  if [[ "$is_interactive" == true && (! -t 0 || ! -t 1) ]]; then
    render_section 'Next step'
    printf '  Run again with --no-interaction to apply this preview.\n'
    return 0
  fi

  if ! confirm_action 'Apply this installation plan?'; then
    info 'installation cancelled; no files or snapshots were changed'
    return 0
  fi

  apply_installation
}

main "$@"
