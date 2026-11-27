#!/bin/sh
if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/agents/block-shell-edits" ]; then
  cat >/dev/null
  exit 0
fi

exec python3 -I -X pycache_prefix="${XDG_CACHE_HOME:-$HOME/.cache}/agent-hooks" "$(dirname "$0")/agent_hooks/main.py" block-shell-edits "$@"
