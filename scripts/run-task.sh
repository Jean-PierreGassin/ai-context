#!/usr/bin/env bash
set -euo pipefail

readonly command_name="${1:?command name is required}"
case "$command_name" in
  install|doctor|history|rollback) ;;
  *)
    printf 'ai-context: unsupported task command: %s\n' "$command_name" >&2
    exit 1
    ;;
esac

if [[ -n "${AI_CONTEXT_TASK_SENTINEL:-}" ]]; then
  : >"$AI_CONTEXT_TASK_SENTINEL"
fi

if [[ -n "${AI_CONTEXT_ROOT:-}" ]]; then
  exec "$AI_CONTEXT_ROOT/scripts/$command_name.sh"
fi

readonly repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec env AI_CONTEXT_SKIP_TASK=true "$repository_root/bin/ai-context" "$command_name" "${@:2}"
