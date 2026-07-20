#!/usr/bin/env bash
# Cross-platform notification sound for Claude Code hooks.
# Plays the first working backend for the current OS, then falls back to the
# terminal bell. Always exits 0 so a missing audio backend never blocks a hook.

set -u

play_macos() {
    command -v afplay >/dev/null 2>&1 || return 1

    for sound in "${CLAUDE_HOOK_SOUND:-}" /System/Library/Sounds/Blow.aiff /System/Library/Sounds/Ping.aiff; do
        [ -n "$sound" ] && [ -f "$sound" ] && afplay "$sound" && return 0
    done

    return 1
}

play_linux() {
    local sound="${CLAUDE_HOOK_SOUND:-}"

    if [ -z "$sound" ]; then
        for candidate in \
            /usr/share/sounds/freedesktop/stereo/complete.oga \
            /usr/share/sounds/freedesktop/stereo/bell.oga \
            /usr/share/sounds/alsa/Front_Center.wav; do
            [ -f "$candidate" ] && sound="$candidate" && break
        done
    fi

    if [ -n "$sound" ] && [ -f "$sound" ]; then
        command -v paplay >/dev/null 2>&1 && paplay "$sound" && return 0
        command -v pw-play >/dev/null 2>&1 && pw-play "$sound" && return 0
        command -v ffplay >/dev/null 2>&1 && ffplay -nodisp -autoexit -loglevel quiet "$sound" && return 0
        command -v aplay >/dev/null 2>&1 && aplay -q "$sound" && return 0
    fi

    command -v canberra-gtk-play >/dev/null 2>&1 && canberra-gtk-play -i complete && return 0

    return 1
}

play_windows() {
    local powershell
    powershell=$(command -v powershell.exe || command -v pwsh.exe) || return 1

    local sound="${CLAUDE_HOOK_SOUND:-C:\\Windows\\Media\\notify.wav}"

    "$powershell" -NoProfile -NonInteractive -Command \
        "(New-Object Media.SoundPlayer '$sound').PlaySync()" >/dev/null 2>&1 && return 0

    "$powershell" -NoProfile -NonInteractive -Command '[console]::beep(880, 200)' >/dev/null 2>&1 && return 0

    return 1
}

case "$(uname -s 2>/dev/null)" in
    Darwin) play_macos ;;
    Linux)
        # WSL can reach the Windows audio stack; native Linux cannot.
        if grep -qi microsoft /proc/version 2>/dev/null; then
            play_windows || play_linux
        else
            play_linux
        fi
        ;;
    MINGW* | MSYS* | CYGWIN*) play_windows ;;
    *) false ;;
esac || printf '\a' >&2

exit 0
