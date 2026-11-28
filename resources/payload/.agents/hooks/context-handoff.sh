#!/bin/sh
exec python3 -I -X pycache_prefix="${XDG_CACHE_HOME:-$HOME/.cache}/agent-hooks" "$(dirname "$0")/agent_hooks/main.py" context-handoff "$@"
