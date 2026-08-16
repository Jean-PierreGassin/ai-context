#!/usr/bin/env bash
set -euo pipefail

unset CDPATH
repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root

error() {
  printf '%s\n' "$*" >&2
}

collect_scripts() {
  printf '%s\0' "$repository_root/bin/ai-context"
  find "$repository_root/scripts" "$repository_root/tests" -type f -name '*.sh' -print0 | sort -z
}

main() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    error 'shellcheck is required: https://www.shellcheck.net/'
    return 1
  fi

  local scripts=()
  local script
  while IFS= read -r -d '' script; do
    scripts+=("$script")
  done < <(collect_scripts)

  shellcheck "${scripts[@]}"
  printf 'shell tests passed (%d scripts)\n' "${#scripts[@]}"
}

main "$@"
