#!/usr/bin/env bash
# Author: Jean-Pierre Gassin (https://github.com/Jean-PierreGassin)
#
# Custom status line for Claude Code with a two-line layout
# Line 1: dir (cyan) // branch (magenta) · git state counts
# Line 2: context window bar (green, then gold, then red) · session cost · model

input=$(cat)

# ---------------------------------------------------------------------------
# Colours (ANSI — the status line renders in a real terminal)
# ---------------------------------------------------------------------------
RESET='\033[0m'

CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
WHITE='\033[97m'

BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_WHITE='\033[1;97m'

GOLD='\033[38;2;255;193;7m'

# ---------------------------------------------------------------------------
# Parse JSON input — single jq call for performance
# ---------------------------------------------------------------------------
_parse=$(echo "${input}" | jq -r '[
  (.session_id // ""),
  (.workspace.current_dir // .cwd // ""),
  (.model.display_name // ""),
  (.context_window.used_percentage | if . != null then tostring else "" end),
  (.context_window.context_window_size | if . != null then tostring else "" end),
  (.context_window.total_input_tokens | if . != null then tostring else "" end),
  (.cost.total_cost_usd | if . != null then tostring else "" end),
  (.effort.level // "")
] | join("")')

IFS=$'\x1f' read -r session_id cwd model_name used ctx_size ctx_tokens total_cost effort <<< "${_parse}"

# ---------------------------------------------------------------------------
# LINE 1 — Directory segment (cyan)
# ---------------------------------------------------------------------------
short_cwd="${cwd/#${HOME}/~}"
dir_part="${CYAN}${short_cwd}${RESET}"

# ---------------------------------------------------------------------------
# LINE 1 — Git segment (grey // separator, magenta branch, state counts)
# ---------------------------------------------------------------------------
git_here() {
    git -C "${cwd}" --no-optional-locks "$@" 2>/dev/null
}

append_git_state() {
    local symbol="$1" count="$2" colour="$3"
    if [[ "${count:-0}" -gt 0 ]]; then
        git_state="${git_state} ${colour}${symbol}${count}${RESET}"
    fi
}

git_part=""
status_output="$(git_here status --porcelain --branch)"
if [[ -n "${status_output}" ]]; then
    branch_header="${status_output%%$'\n'*}"
    branch_header="${branch_header#\#\# }"

    status_lines=""
    if [[ "${status_output}" == *$'\n'* ]]; then
        status_lines="${status_output#*$'\n'}"
    fi

    branch="${branch_header%%...*}"
    branch="${branch%% *}"
    case "${branch_header}" in
        'HEAD (no branch)') branch="$(git_here rev-parse --short HEAD)" ;;
        'No commits yet on '*) branch="${branch_header#No commits yet on }" ;;
    esac

    ahead_count=0
    behind_count=0
    if [[ "${branch_header}" =~ ahead\ ([0-9]+) ]]; then
        ahead_count="${BASH_REMATCH[1]}"
    fi
    if [[ "${branch_header}" =~ behind\ ([0-9]+) ]]; then
        behind_count="${BASH_REMATCH[1]}"
    fi

    conflict_count=0
    changed_count=0
    while IFS= read -r status_line; do
        case "${status_line}" in
            '') continue ;;
            DD*|AU*|UD*|UA*|DU*|AA*|UU*) conflict_count=$(( conflict_count + 1 )) ;;
            *) changed_count=$(( changed_count + 1 )) ;;
        esac
    done <<< "${status_lines}"

    behind_main_count=0
    for candidate in origin/main origin/master; do
        if [[ "${candidate#origin/}" == "${branch}" ]]; then
            break
        fi
        candidate_count="$(git_here rev-list --count "HEAD..${candidate}")"
        if [[ -n "${candidate_count}" ]]; then
            behind_main_count="${candidate_count}"
            break
        fi
    done

    git_state=""
    append_git_state '!' "${conflict_count}" "${BOLD_RED}"
    append_git_state '*' "${changed_count}" "${YELLOW}"
    append_git_state '↑' "${ahead_count}" "${GREEN}"
    append_git_state '↓' "${behind_count}" "${CYAN}"
    append_git_state '⑂' "${behind_main_count}" "${MAGENTA}"

    git_part=" // ${MAGENTA}${branch}${RESET}"
    if [[ -n "${git_state}" ]]; then
        git_part="${git_part} ${git_state}"
    fi
fi

# ---------------------------------------------------------------------------
# LINE 2 — Model segment (blue) with reasoning effort when supplied
# ---------------------------------------------------------------------------
model_part="${BLUE}${model_name}${RESET}"
if [[ -n "${effort}" ]]; then
    model_part="${model_part} - ${BLUE}${effort}${RESET}"
fi

# ---------------------------------------------------------------------------
# LINE 2 — Context window bar (green, then gold, then red — time to /compact)
# ---------------------------------------------------------------------------
CONTEXT_COMPACT_NOW_PERCENT=75
CONTEXT_COMPACT_SOON_PERCENT=40
CONTEXT_WATCH_TOKENS=150000
CONTEXT_WATCH_PERCENT=25
CONTEXT_BAR_CELLS=20

CONTEXT_CALM_MESSAGES=(
    'plenty of runway'
    'wide open spaces'
    'the window is young'
    'no notes'
    'living within our means'
)

CONTEXT_WATCH_MESSAGES=(
    'keep half an eye on it'
    'filling up nicely'
    'start landing the plane'
    'getting chunky in here'
    'plan your exit'
)

CONTEXT_COMPACT_SOON_MESSAGES=(
    'compact or start a new session'
    'the walls are closing in'
    'time to /compact'
    'wrap it up'
    'running low'
)

CONTEXT_COMPACT_NOW_MESSAGES=(
    'COMPACT NOW'
    'OUT OF ROAD'
    'IT IS TIME'
    'ABANDON SESSION'
    'NO ROOM LEFT'
)

context_line=""
if [[ -n "${used}" ]]; then
    used_int="${used%.*}"
    ctx_tokens_int="${ctx_tokens%.*}"

    if [[ "${used_int}" -ge "${CONTEXT_COMPACT_NOW_PERCENT}" ]]; then
        ctx_colour="${BOLD_RED}"
        ctx_messages=("${CONTEXT_COMPACT_NOW_MESSAGES[@]}")
    elif [[ "${used_int}" -ge "${CONTEXT_COMPACT_SOON_PERCENT}" ]]; then
        ctx_colour="${RED}"
        ctx_messages=("${CONTEXT_COMPACT_SOON_MESSAGES[@]}")
    elif [[ "${ctx_tokens_int:-0}" -ge "${CONTEXT_WATCH_TOKENS}" \
            || "${used_int}" -ge "${CONTEXT_WATCH_PERCENT}" ]]; then
        ctx_colour="${GOLD}"
        ctx_messages=("${CONTEXT_WATCH_MESSAGES[@]}")
    else
        ctx_colour="${BOLD_GREEN}"
        ctx_messages=("${CONTEXT_CALM_MESSAGES[@]}")
    fi

    message_seed="$(printf '%s%s' "${session_id}" "${ctx_colour}" | cksum)"
    message_seed="${message_seed%% *}"
    message_index=$(( message_seed % ${#ctx_messages[@]} ))
    ctx_label=" ${ctx_colour}${ctx_messages[${message_index}]}${RESET}"

    filled_cells=$(( used_int * CONTEXT_BAR_CELLS / 100 ))
    if [[ "${filled_cells}" -gt "${CONTEXT_BAR_CELLS}" ]]; then
        filled_cells="${CONTEXT_BAR_CELLS}"
    fi
    empty_cells=$(( CONTEXT_BAR_CELLS - filled_cells ))
    bar="$(printf '%*s' "${filled_cells}" '' | tr ' ' '#')"
    bar="${bar}$(printf '%*s' "${empty_cells}" '' | tr ' ' '-')"

    ctx_size_label=""
    if [[ "${ctx_size}" =~ ^[0-9]+$ && "${ctx_size}" -gt 0 ]]; then
        ctx_size_label="/$(( ctx_size / 1000 ))k"
    fi

    context_line="${ctx_colour}ctx ${used_int}%${RESET}${ctx_size_label} [${ctx_colour}${bar}${RESET}]${ctx_label}"
fi

# ---------------------------------------------------------------------------
# LINE 2 — Session cost (from .cost.total_cost_usd supplied by Claude Code)
# ---------------------------------------------------------------------------
cost_line=""
if [[ -n "${total_cost}" && "${total_cost}" != "null" ]]; then
    cost_display="$(awk -v c="${total_cost}" 'BEGIN { if (c+0 < 0.01) printf "<$0.01"; else printf "$%.2f", c+0 }')"
    if [[ -n "${cost_display}" ]]; then
        cost_line="${WHITE}session cost:${RESET} ${BOLD_WHITE}${cost_display}${RESET}"
    fi
fi

# ---------------------------------------------------------------------------
# Compose and print
# ---------------------------------------------------------------------------
line1="${dir_part}${git_part}"

line2=""
if [[ -n "${context_line}" ]]; then
    line2="${context_line}"
fi

if [[ -n "${cost_line}" ]]; then
    if [[ -n "${line2}" ]]; then
        line2="${line2}  |  ${cost_line}"
    else
        line2="${cost_line}"
    fi
fi

if [[ -n "${line2}" ]]; then
    line2="${line2}  |  ${model_part}"
else
    line2="${model_part}"
fi

if [[ -n "${line2}" ]]; then
    printf '%b\n%b\n' "${line1}" "${line2}"
else
    printf '%b\n' "${line1}"
fi
