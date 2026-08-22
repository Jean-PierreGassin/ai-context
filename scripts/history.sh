#!/usr/bin/env bash
set -euo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly force_install=false
readonly is_dry_run=false
readonly is_interactive=false
source "$repository_root/scripts/lib.sh"

target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly target_root
state_root="$(resolve_state_root)"
readonly state_root

main() {
  local history_output

  render_header 'ai-context history' "$scope" "$target_root"

  history_output="$(python3 "$repository_root/scripts/state.py" history \
    --scope "$scope" \
    --target "$target_root" \
    --payload "$repository_root/resources/payload" \
    --state-root "$state_root")"

  if [[ -z "$history_output" ]]; then
    printf '\n'
    info 'No saved versions.'
    return 0
  fi

  render_history "$history_output"
  printf '\n'
  info "Found $(printf '%s\n' "$history_output" | wc -l | tr -d ' ') saved version(s)."
}

main "$@"
