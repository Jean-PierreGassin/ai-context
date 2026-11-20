#!/bin/sh
input="$(cat)"

case "$input" in
  *git*) ;;
  *) exit 0 ;;
esac

printf '%s' "$input" | exec python3 -I -X pycache_prefix="${XDG_CACHE_HOME:-$HOME/.cache}/agent-hooks" "$(dirname "$0")/agent_hooks/main.py" block-no-verify "$@"
