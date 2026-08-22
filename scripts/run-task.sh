#!/usr/bin/env bash
set -euo pipefail

main() {
  local task_sentinel="${1:-}"
  local caller_dir="${2:?caller directory is required}"
  local command_name="${3:?command name is required}"
  local repository_root

  case "$command_name" in
    install|doctor|history|rollback) ;;
    *)
      printf 'ai-context: unsupported task command: %s\n' "$command_name" >&2
      return 1
      ;;
  esac

  if [[ -n "$task_sentinel" ]]; then
    : >"$task_sentinel"
  fi

  unset CDPATH
  repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  exec "$repository_root/bin/ai-context" --task-run --caller-dir "$caller_dir" "$command_name" "${@:4}"
}

main "$@"
