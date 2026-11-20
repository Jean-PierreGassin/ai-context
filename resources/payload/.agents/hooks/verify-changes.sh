#!/bin/sh
config="${XDG_CONFIG_HOME:-$HOME/.config}/agents"

case "$1" in
  handoff) configured=yes ;;
  turn) [ -f "$config/verify-changes" ] || [ -f "$config/response-rules" ] && configured=yes ;;
  *) [ -f "$config/verify-changes" ] || [ -f "$config/weakening" ] && configured=yes ;;
esac

if [ -z "$configured" ]; then
  cat >/dev/null
  exit 0
fi

exec python3 -I -X pycache_prefix="${XDG_CACHE_HOME:-$HOME/.cache}/agent-hooks" "$(dirname "$0")/agent_hooks/main.py" verify-changes "$@"
