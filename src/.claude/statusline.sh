#!/usr/bin/env bash
# Spaceship-style status line for Claude Code — two-line layout
# Line 1: dir (cyan) · git branch/dirty marker (magenta/yellow)
# Line 2: context window bar (colour-coded, red at >=50%) · session cost · model
#
# Cost is read directly from .cost.total_cost_usd supplied by Claude Code.

input=$(cat)

# ---------------------------------------------------------------------------
# Colours (ANSI — the status line renders in a real terminal)
# ---------------------------------------------------------------------------
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
WHITE='\033[37m'

BOLD_RED='\033[1;31m'
BOLD_YELLOW='\033[1;33m'
BOLD_GREEN='\033[1;32m'

# ---------------------------------------------------------------------------
# Parse JSON input — single jq call for performance
# ---------------------------------------------------------------------------
_parse=$(echo "$input" | jq -r '[
  (.workspace.current_dir // .cwd // ""),
  (.model.display_name // ""),
  (.model.id // ""),
  (.context_window.used_percentage | if . != null then tostring else "" end),
  (.context_window.context_window_size | if . != null then tostring else "" end),
  (.cost.total_cost_usd | if . != null then tostring else "" end)
] | join("")')

IFS=$'\x1f' read -r cwd model_name model_id used ctx_size total_cost <<< "$_parse"

# ---------------------------------------------------------------------------
# LINE 1 — Directory segment (cyan)
# ---------------------------------------------------------------------------
short_cwd="${cwd/#$HOME/~}"
dir_part="${CYAN}${short_cwd}${RESET}"

# ---------------------------------------------------------------------------
# LINE 1 — Git segment (magenta branch + yellow dirty marker)
# ---------------------------------------------------------------------------
git_part=""
if git -C "$cwd" rev-parse --git-dir 2>/dev/null 1>/dev/null; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null \
             || ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            git_part=" ${DIM}on${RESET} ${MAGENTA}${branch}${RESET} ${BOLD_YELLOW}!${RESET}"
        else
            git_part=" ${DIM}on${RESET} ${MAGENTA}${branch}${RESET}"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# LINE 2 — Model segment (blue)
# ---------------------------------------------------------------------------
model_part="${BLUE}${model_name}${RESET}"

# ---------------------------------------------------------------------------
# LINE 2 — Context window bar (colour-coded; red at >=50% — time to /compact)
# ---------------------------------------------------------------------------
context_line=""
if [ -n "$used" ]; then
    used_int=${used%.*}

    # Colour thresholds: green < 50, yellow 50-74, red >= 75
    # Red starts at 50% so you are prompted to /compact before it's critical
    if [ "$used_int" -ge 75 ]; then
        ctx_colour="${BOLD_RED}"
        ctx_label=" ${BOLD_RED}COMPACT NOW${RESET}"
    elif [ "$used_int" -ge 50 ]; then
        ctx_colour="${RED}"
        ctx_label=" ${RED}consider /compact${RESET}"
    else
        ctx_colour="${BOLD_GREEN}"
        ctx_label=""
    fi

    # 20-char bar for finer granularity
    filled=$(( used_int / 5 ))
    empty=$(( 20 - filled ))
    bar=""
    i=0
    while [ $i -lt $filled ]; do
        bar="${bar}#"
        i=$(( i + 1 ))
    done
    i=0
    while [ $i -lt $empty ]; do
        bar="${bar}-"
        i=$(( i + 1 ))
    done

    ctx_size_label=""
    if [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
        ctx_size_k=$(( ctx_size / 1000 ))
        ctx_size_label="/${ctx_size_k}k"
    fi

    context_line="${ctx_colour}ctx ${used_int}%${RESET}${ctx_size_label} [${ctx_colour}${bar}${RESET}]${ctx_label}"
fi

# ---------------------------------------------------------------------------
# LINE 2 — Session cost (from .cost.total_cost_usd supplied by Claude Code)
# ---------------------------------------------------------------------------
cost_line=""
if [ -n "$total_cost" ] && [ "$total_cost" != "null" ]; then
    cost_display=$(awk -v c="$total_cost" 'BEGIN { if (c+0 < 0.01) printf "<$0.01"; else printf "$%.2f", c+0 }')
    if [ -n "$cost_display" ]; then
        cost_line="${DIM}session cost:${RESET} ${WHITE}${cost_display}${RESET}"
    fi
fi

# ---------------------------------------------------------------------------
# Compose and print
# Line 1: dir · git
# Line 2: ctx bar · cost · model  (only when data is available)
#
# Both lines are emitted in a single printf "%b" call so that tmux pane
# splits do not swallow the second line. The %b flag is required on line 1
# so that \033 escape sequences inside the expanded variables are rendered.
# ---------------------------------------------------------------------------
line1="${dir_part}${git_part}"

# Build line 2 from its components, inserting " · " separators as needed
line2=""

# context bar
if [ -n "$context_line" ]; then
    line2="${context_line}"
fi

# cost
if [ -n "$cost_line" ]; then
    if [ -n "$line2" ]; then
        line2="${line2}  ${DIM}|${RESET}  ${cost_line}"
    else
        line2="${cost_line}"
    fi
fi

# model
if [ -n "$line2" ]; then
    line2="${line2}  ${DIM}|${RESET}  ${model_part}"
else
    line2="${model_part}"
fi


if [ -n "$line2" ]; then
    printf "%b\n%b\n" "${line1}" "${line2}"
else
    printf "%b\n" "${line1}"
fi
