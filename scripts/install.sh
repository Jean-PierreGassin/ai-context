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
temporary_root=

readonly payload_root="$repository_root/resources/payload"
readonly legacy_ownership="$repository_root/resources/previous-owned-skill-paths.txt"
readonly retired_managed_files="$repository_root/resources/retired-managed-files.txt"
target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly target_root

desired_skill_paths() {
  find "$payload_root/.agents/skills" "$payload_root/.claude/skills" -type f -print \
    | sed "s|^$payload_root/||" \
    | sort
  if [[ "$scope" == project ]]; then
    find "$payload_root/.agents/skills" "$payload_root/.claude/skills" -mindepth 1 -maxdepth 1 -type d -print \
      | sed "s|^$payload_root/||" \
      | sed 's|$|/.gitignore|' \
      | sort
  fi
}

remove_empty_skill_parents() {
  local parent_path="$1" skill_root="$2"
  while [[ "$parent_path" != "$target_root/$skill_root" ]]; do
    rmdir "$parent_path" 2>/dev/null || break
    parent_path="$(dirname "$parent_path")"
  done
}

reject_symlinked_skill_parent() {
  local parent_path display_path="$2"
  parent_path="$(dirname "$1")"
  while [[ "$parent_path" != "$target_root" ]]; do
    if [[ -L "$parent_path" ]]; then
      record_failure "refused symlinked parent for owned file $display_path"
      return 0
    fi
    parent_path="$(dirname "$parent_path")"
  done
  return 1
}

remove_stale_owned_skills() {
  local stale_path target_path display_path skill_root
  local previous_paths desired_paths
  previous_paths="$temporary_root/owned"
  desired_paths="$temporary_root/desired"
  if ! python3 "$repository_root/scripts/state.py" ownership \
    --scope "$scope" --target "$target_root" --payload "$payload_root" \
    --state-root "$(resolve_state_root)" --legacy-ownership "$legacy_ownership" >"$previous_paths"; then
    rm -f "$previous_paths" "$desired_paths"
    return 1
  fi
  desired_skill_paths | sort >"$desired_paths"

  while IFS= read -r stale_path; do
    [[ -n "$stale_path" ]] || continue
    target_path="$target_root/$stale_path"
    if [[ "$scope" == global ]]; then display_path="$home_display/$stale_path"; else display_path="$stale_path"; fi
    if reject_symlinked_skill_parent "$target_path" "$display_path"; then continue; fi
    if [[ -d "$target_path" && ! -L "$target_path" ]]; then
      record_failure "refused directory at owned file path $display_path"
      continue
    fi
    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then continue; fi
    record_change "removed $display_path"
    if [[ "$is_dry_run" == true ]]; then continue; fi
    rm -f -- "$target_path"
    case "$stale_path" in
      .agents/skills/*) skill_root='.agents/skills' ;;
      .claude/skills/*) skill_root='.claude/skills' ;;
    esac
    remove_empty_skill_parents "$(dirname "$target_path")" "$skill_root"
  done < <(comm -23 "$previous_paths" "$desired_paths")
  rm -f "$previous_paths" "$desired_paths"
}

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
  skill_ignore="$temporary_root/ignore"
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
  global_instructions="$temporary_root/agents"
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
  global_skill_adapter="$temporary_root/adapter"
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
  global_claude_instructions="$temporary_root/instructions"
  printf '@~/.agents/AGENTS.md\n' >"$global_claude_instructions"
  copy_managed_file "$global_claude_instructions" "$target_root/.claude/CLAUDE.md" "$home_display/.claude/CLAUDE.md"
  rm -f "$global_claude_instructions"

  local global_claude_settings global_codex_hooks
  global_claude_settings="$temporary_root/claude-settings"
  global_codex_hooks="$temporary_root/codex-hooks"
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
  local retired_display_prefix=
  if [[ "$scope" == global ]]; then retired_display_prefix="$home_display/"; fi

  remove_stale_owned_skills
  remove_retired_managed_files "$retired_managed_files" "$target_root" "$retired_display_prefix"
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
  local snapshot_id snapshot_state snapshot_restore snapshot_remove saved_version_message snapshot_payload_root

  state_root="$(resolve_state_root)"
  readonly state_root
  snapshot_payload_root="$temporary_root/snapshot-payload"
  build_snapshot_payload "$payload_root" "$retired_managed_files" "$snapshot_payload_root"
  if [[ "$failure_count" -gt 0 ]]; then return 1; fi

  snapshot_id="$(python3 "$repository_root/scripts/state.py" snapshot \
    --scope "$scope" \
    --target "$target_root" \
    --payload "$snapshot_payload_root" \
    --state-root "$state_root" \
    --legacy-ownership "$legacy_ownership")"
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
  python3 "$repository_root/scripts/state.py" set-ownership \
    --scope "$scope" --target "$target_root" --payload "$payload_root" --state-root "$state_root"
  printf '\n'
  success "Installed: $changed_count changed, $skipped_count unchanged"
  if ! command -v plannotator >/dev/null 2>&1; then
    warn 'Plannotator and its managed Codex Stop hook are required for automatic plan review. Install Plannotator from https://plannotator.ai.'
  elif ! python3 -c '
import json, pathlib, sys
hooks_path = pathlib.Path(sys.argv[1])
if not hooks_path.is_file():
    raise SystemExit(1)
data = json.loads(hooks_path.read_text())
commands = (
    hook.get("command", "")
    for group in data.get("hooks", {}).get("Stop", [])
    for hook in group.get("hooks", [])
    if hook.get("type") == "command"
)
raise SystemExit(0 if any(command == "plannotator" or command.endswith("/plannotator") for command in commands) else 1)
' "$HOME/.codex/hooks.json"; then
    warn 'Plannotator is installed, but its managed Codex Stop hook is missing. Re-run the Plannotator installer to enable automatic browser opening and feedback.'
  fi
}

main() {
  temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ai-context-install.XXXXXX")"
  trap 'rm -rf -- "$temporary_root"' EXIT

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
