#!/usr/bin/env bash
set -euo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
readonly requested_snapshot_id="${3:-}"
readonly is_interactive="${4:?interactive setting is required}"
unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly force_install=false
readonly is_dry_run=false
source "$repository_root/scripts/lib.sh"

target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly target_root
state_root="$(resolve_state_root)"
readonly state_root

render_header 'ai-context rollback' "$scope" "$target_root"

select_snapshot() {
  local history_output="$1"
  local selected_snapshot

  if command -v gum >/dev/null 2>&1; then
    selected_snapshot="$(
      printf '%s\n' "$history_output" | gum choose --header 'Select a saved version to restore'
    )" || return 1
  else
    local choice snapshot_count
    snapshot_count="$(printf '%s\n' "$history_output" | wc -l | tr -d ' ')"
    printf 'Select a saved version to restore:\n' >&2
    printf '%s\n' "$history_output" \
      | awk -F '\t' '{printf "  %d) %s | before %s | restore %s, remove %s | %s\n", NR, $2, $3, $4, $5, $1}' >&2
    printf 'Choice [1-%s]: ' "$snapshot_count" >&2
    read -r choice
    case "$choice" in
      ''|*[!0-9]*) return 1 ;;
    esac
    ((choice >= 1 && choice <= snapshot_count)) || return 1
    selected_snapshot="$(printf '%s\n' "$history_output" | sed -n "${choice}p")"
  fi

  printf '%s\n' "${selected_snapshot%%$'\t'*}"
}

snapshot_id="$requested_snapshot_id"
history_output="$(python3 "$repository_root/scripts/state.py" history \
  --scope "$scope" \
  --target "$target_root" \
  --payload "$repository_root/resources/payload" \
  --state-root "$state_root")"
if [[ -z "$history_output" ]]; then
  error "no snapshots for $scope target $target_root"
  exit 1
fi
if [[ -z "$snapshot_id" ]]; then
  if [[ -t 0 && -t 1 ]]; then
    snapshot_id="$(select_snapshot "$history_output")" || {
      error 'no snapshot selected'
      exit 1
    }
  else
    snapshot_id="${history_output%%$'\n'*}"
    snapshot_id="${snapshot_id%%$'\t'*}"
  fi
fi

selected_state="$(printf '%s\n' "$history_output" | awk -F '\t' -v snapshot_id="$snapshot_id" '$1 == snapshot_id {print; exit}')"
if [[ -z "$selected_state" ]]; then
  error "snapshot not found: $snapshot_id"
  exit 1
fi
IFS=$'\t' read -r _ selected_created selected_action selected_restore selected_remove _ <<<"$selected_state"
render_section 'Restore preview'
render_detail 'Version' "$snapshot_id"
render_detail 'Created' "$selected_created"
render_detail 'Saved before' "$selected_action"
render_detail 'Restore existing' "$selected_restore path(s)"
render_detail 'Remove new' "$selected_remove path(s)"
if ! confirm_action 'Continue with rollback?'; then
  info 'rollback cancelled; no files or snapshots were changed'
  exit 0
fi

rollback_arguments=(
  rollback
  --scope "$scope"
  --target "$target_root"
  --payload "$repository_root/resources/payload"
  --state-root "$state_root"
  --snapshot-id "$snapshot_id"
)

rollback_output="$(python3 "$repository_root/scripts/state.py" "${rollback_arguments[@]}")"
restored_snapshot="${rollback_output%%$'\t'*}"
safety_snapshot="${rollback_output#*$'\t'}"
printf '\n'
success "Restored: $restored_snapshot"
info "Undo version: $safety_snapshot"
