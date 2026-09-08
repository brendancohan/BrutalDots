#!/usr/bin/env bash
# The interactive feature checklist.
#
# Sourced by ../install.sh; not run on its own.

# ── Feature checklist ────────────────────────────────────────────────────────
# Only drawn when there is a terminal for it; otherwise the defaults apply and
# the script stays scriptable. Adding an entry is one add_feature line plus a
# feature_on guard where it installs.

FEATURE_KEY=(); FEATURE_LABEL=(); FEATURE_NOTE=(); FEATURE_ON=(); FEATURE_FIXED=()

# add_feature <key> <label> <note> <on:1|0> <fixed:1|0>
# A fixed entry is shown so the list tells the whole story, but cannot be
# unticked — the shell is what this repo *is*.
add_feature() {
    FEATURE_KEY+=("$1"); FEATURE_LABEL+=("$2"); FEATURE_NOTE+=("$3")
    FEATURE_ON+=("$4");  FEATURE_FIXED+=("$5")
}

feature_on() {
    local i
    for i in "${!FEATURE_KEY[@]}"; do
        if [[ "${FEATURE_KEY[i]}" == "$1" && "${FEATURE_ON[i]}" == 1 ]]; then
            return 0
        fi
    done
    return 1
}

# Reads _cursor from its caller, which is bash's dynamic scoping working as
# intended rather than an accident.
_checklist_draw() {
    local i box mark
    for i in "${!FEATURE_KEY[@]}"; do
        box="[ ]"; [[ "${FEATURE_ON[i]}" == 1 ]] && box="[x]"
        mark=" ";  [[ "$i" == "$_cursor" ]] && mark=">"
        # A locked row is dimmed so it reads as something you are being told
        # rather than something you failed to untick.
        if [[ "${FEATURE_FIXED[i]}" == 1 ]]; then
            printf '\033[K \033[1m%s\033[0m \033[2m%s %s  %s\033[0m\n' \
                "$mark" "$box" "${FEATURE_LABEL[i]}" "${FEATURE_NOTE[i]}"
        else
            printf '\033[K \033[1m%s\033[0m %s %s  \033[2m%s\033[0m\n' \
                "$mark" "$box" "${FEATURE_LABEL[i]}" "${FEATURE_NOTE[i]}"
        fi
    done
    printf '\033[K\n'
    printf '\033[K\033[2m   up/down move - space toggles - enter installs - q cancels\033[0m\n'
}

choose_features() {
    local _cursor=0 key rest n=${#FEATURE_KEY[@]}

    printf '\033[1m::\033[0m What should be installed?\n\n'
    printf '\033[?25l'; _cursor_hidden=1
    while true; do
        _checklist_draw
        IFS= read -rsn1 key || key=""
        case "$key" in
            $'\033')
                rest=""
                IFS= read -rsn2 -t 0.05 rest || true
                case "$rest" in
                    '[A') (( _cursor > 0 ))     && _cursor=$(( _cursor - 1 )) || true ;;
                    '[B') (( _cursor < n - 1 )) && _cursor=$(( _cursor + 1 )) || true ;;
                    *) printf '\033[?25h'; _cursor_hidden=0; return 1 ;;
                esac ;;
            k) (( _cursor > 0 ))     && _cursor=$(( _cursor - 1 )) || true ;;
            j) (( _cursor < n - 1 )) && _cursor=$(( _cursor + 1 )) || true ;;
            ' ')
                if [[ "${FEATURE_FIXED[_cursor]}" != 1 ]]; then
                    FEATURE_ON[_cursor]=$(( 1 - FEATURE_ON[_cursor] ))
                fi ;;
            q|Q) printf '\033[?25h'; _cursor_hidden=0; return 1 ;;
            '') break ;;
        esac
        printf '\033[%dA' "$(( n + 2 ))"
    done
    printf '\033[?25h'; _cursor_hidden=0
}

