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

exec "$AI_CONTEXT_ROOT/scripts/$command_name.sh"
