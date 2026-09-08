#!/usr/bin/env bash
# The installer's banner.
#
# Sourced by ../install.sh; not run on its own.

# The same four rules the shell obeys: an opaque surface, a hard border, a hard
# offset shadow, and flat colour. The shadow is a column down the right and a
# row along the bottom, each shifted one cell — a terminal casting it down and
# to the right.
#
# Every glyph is one cell in JetBrainsMono Nerd Font, verified in both weights.
# One that is not would fall through to whatever fontconfig offers next and take
# the alignment of every row with it.
banner() {
    # No terminal, or not enough of one. The box is 66 columns; narrower than
    # that and every row wraps, which turns the shadow into confetti.
    [[ -t 1 ]] || return 0
    local cols
    cols="$(tput cols 2>/dev/null || printf 80)"
    if (( cols < 67 )); then
        say "BrutalDots — Fezzik the Giant"
        return 0
    fi

    # ANSI indices, not truecolour. These marks sit on the terminal's own
    # background, which the shell does not own, so they have to be colours the
    # terminal repaints when its palette flips. Index 3 is #883900 on the light
    # BrutalDots palette and #F79E5D on the dark one — the readable end of the
    # same hue either way. Pinning the pastel instead would give 1.87:1 on a
    # cream terminal, which is a banner you cannot read.
    #
    # The shadow takes index 0 for the same reason it is black in the shell: a
    # cast shadow must be darker than what it falls on, and index 8 is *lighter*
    # than a dark terminal's background, so it would read as a glow. On a very
    # dark terminal it is nearly invisible instead, which is the same ceiling
    # dark mode hits everywhere else and the right way to miss.
    local ink block shade dim off
    ink=$'\033[1m'
    block=$'\033[33m'
    shade=$'\033[30m'
    dim=$'\033[2m'
    off=$'\033[0m'

    local line body=(
        "         █████  █████  █████  █████  █████  █   █         "
        "         █      █         ██     ██    █    █  █          "
        "         ████   ████     ██     ██     █    ███           "
        "         █      █       ██     ██      █    █  █          "
        "         █      █████  █████  █████  █████  █   █         "
        "                                                          "
        "█████  █   █  █████      █████  █████  █████  █   █  █████"
        "  █    █   █  █          █        █    █   █  ██  █    █  "
        "  █    █████  ████       █  ██    █    █████  █ █ █    █  "
        "  █    █   █  █          █   █    █    █   █  █  ██    █  "
        "  █    █   █  █████      █████  █████  █   █  █   █    █  "
    )

    printf '%s\n' "${ink}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${off}"
    for line in "${body[@]}"; do
        printf '%s\n' "${ink}┃${off}   ${block}${line}${off}   ${ink}┃${off}${shade}█${off}"
    done
    printf '%s\n' "${ink}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${off}${shade}█${off}"
    printf '%s\n' "${ink}┃${off}   ${dim}                   BRUTALDOTS INSTALLER                   ${off}   ${ink}┃${off}${shade}█${off}"
    printf '%s\n' "${ink}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${off}${shade}█${off}"
    printf '%s\n' " ${shade}██████████████████████████████████████████████████████████████████${off}"
    printf '\n'
}
