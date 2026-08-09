#!/usr/bin/env bash
set -euo pipefail

readonly task_sentinel="${1:-}"
readonly caller_dir="${2:?caller directory is required}"
readonly command_name="${3:?command name is required}"
case "$command_name" in
  install|doctor|history|rollback) ;;
  *)
    printf 'ai-context: unsupported task command: %s\n' "$command_name" >&2
    exit 1
    ;;
esac

if [[ -n "$task_sentinel" ]]; then
  : >"$task_sentinel"
fi

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$repository_root/bin/ai-context" --task-run --caller-dir "$caller_dir" "$command_name" "${@:4}"
