#!/usr/bin/env bash
set -euo pipefail

readonly scope="${1:?scope is required}"
readonly caller_dir="${2:?caller directory is required}"
readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly force_install=false
readonly is_dry_run=false
readonly is_interactive=false
source "$repository_root/scripts/lib.sh"

readonly target_root="$(resolve_target_root "$scope" "$caller_dir")"
readonly state_root="$(resolve_state_root)"

history_output="$(python3 "$repository_root/scripts/state.py" history \
  --scope "$scope" \
  --target "$target_root" \
  --payload "$repository_root/resources/payload" \
  --state-root "$state_root")"

if [[ -z "$history_output" ]]; then
  info "no saved versions for $scope target $target_root"
  exit 0
fi

render_history "$history_output"
