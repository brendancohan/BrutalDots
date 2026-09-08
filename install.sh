#!/usr/bin/env bash
# BrutalDots installer.
#
# Copies (or links) the Quickshell config into place and installs the Hyprland
# configuration. An existing hyprland.lua / hyprland/ pair is backed up first.
#
# Run with no options and it asks, as a checklist, which parts you want. The
# shell and its Hyprland config are always installed; the SDDM login screen is
# optional because it is the one piece that writes outside your home directory.
#
# sudo is invoked for two things: that greeter, and installing any packages the
# shell expects but cannot find. Both are announced before they happen.

set -euo pipefail

# Where the repo is. Run from a checkout that is just this script's directory.
# Piped into bash there is no file to ask — and this script is not self
# contained, it sources install/*.sh and copies .config/ — so fetch a checkout
# and hand over to the copy inside it.
#
# `${BASH_SOURCE[0]-}` with the dash: piped, the array is empty, and plain
# `${BASH_SOURCE[0]}` under `set -u` aborts before we can do anything useful.
if [[ -n "${BASH_SOURCE[0]-}" && -f "${BASH_SOURCE[0]}" ]]; then
    REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    REPO=""
fi

if [[ -z "$REPO" || ! -d "$REPO/install" || ! -d "$REPO/.config" ]]; then
    _url="${BRUTALDOTS_REPO:-https://github.com/fezzik-the-giant/BrutalDots.git}"
    _branch="${BRUTALDOTS_BRANCH:-main}"
    _cache="${BRUTALDOTS_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/brutaldots/checkout}"

    command -v git >/dev/null 2>&1 || {
        printf 'xx git is required to fetch BrutalDots\n' >&2; exit 1; }

    if [[ -d "$_cache/.git" ]]; then
        printf ':: updating %s\n' "$_cache"
        # A cache this script owns, so local edits are discarded rather than
        # allowed to fail the run. Anyone editing BrutalDots cloned it himself
        # and runs ./install.sh --link, never arriving here.
        git -C "$_cache" fetch -q --depth 1 origin "$_branch" \
            || { printf 'xx could not reach %s\n' "$_url" >&2; exit 1; }
        git -C "$_cache" reset -q --hard FETCH_HEAD
        git -C "$_cache" clean -qfd
    else
        printf ':: fetching BrutalDots into %s\n' "$_cache"
        mkdir -p "$(dirname "$_cache")"
        git clone -q --depth 1 --branch "$_branch" "$_url" "$_cache" \
            || { printf 'xx could not clone %s\n' "$_url" >&2; exit 1; }
    fi

    [[ -f "$_cache/install.sh" && -d "$_cache/install" ]] \
        || { printf 'xx %s does not look like BrutalDots\n' "$_cache" >&2; exit 1; }

    # Re-exec the fetched copy so BASH_SOURCE points at a real file and every
    # path below resolves normally. Piped, stdin is this script rather than the
    # keyboard: give the terminal back or the checklist silently takes defaults.
    # `-r /dev/tty` only stats it. With no controlling terminal — a container,
    # CI — the node is there and opening it still fails with ENXIO, so try the
    # open itself and fall through to a non-interactive run when it fails.
    if [[ ! -t 0 ]] && { : < /dev/tty; } 2>/dev/null; then
        exec bash "$_cache/install.sh" "$@" < /dev/tty
    fi
    exec bash "$_cache/install.sh" "$@"
fi
QS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
TARGET="$QS_DIR/brutal"
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
KITTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
STARSHIP_TOML="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
FASTFETCH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
MODE="copy"

# Only used if the login screen is selected.
SDDM_SRC="$REPO/sddm/brutaldots"
SHELL_SRC="$REPO/.config/quickshell/brutal"
SDDM_THEME_NAME="brutaldots"
SDDM_THEME_DIR="/usr/share/sddm/themes/$SDDM_THEME_NAME"
SDDM_CONF="/etc/sddm.conf"
WESTON_INI="/etc/sddm/weston.ini"
COMPOSITOR_DROPIN="/etc/sddm.conf.d/20-brutaldots-compositor.conf"
# The greeter's own config, kept outside the root-owned theme directory so the
# shell can rewrite one line of it when you toggle dark mode.
GREETER_STATE="/var/lib/brutaldots/theme.conf"

usage() {
    # Unquoted delimiter, so the paths below are expanded on purpose. That also
    # means backticks and $(...) in this text would be *run* — keep it free of
    # both.
    cat <<USAGE
Usage: ./install.sh [--link] [--yes] [--uninstall [BACKUP]] [--help]

With no options it copies the configuration into place and draws a checklist of
what else to install. The Hyprland and Quickshell configuration is always
installed; the login screen is the one choice on that list.

Any package the shell needs and cannot find is installed with pacman. That is
not optional: these dotfiles are opinionated about what the desktop contains.
Install the packages yourself beforehand and there is nothing left to do.

  --link        Symlink the configuration out of this checkout instead of
                copying it, so edits here are live. For working on BrutalDots;
                a plain install should be a copy, which is the default.
  --yes         Take the defaults rather than drawing the checklist. Assumed
                when there is no terminal to draw on.
  --uninstall   Put your previous Hyprland config back and remove the shell.
                Restores the newest $HYPR_DIR.bak.* unless you name one.
  --help        Show this message.

The login screen follows whatever palette your session is in, so there is
nothing to choose at install time — toggle it with SUPER + SHIFT + T.

For working on the greeter itself:

  --build-sddm DIR [light|dark]
                    Assemble the SDDM theme into DIR and stop. The palette
                    defaults to your session; name one to pin it, which is what
                    the test harness does so its output does not depend on the
                    machine it runs on.
  --test-sddm       Assemble it and open it in SDDM's own greeter, in a window.
                    Needs no privileges and changes nothing — it is the only way
                    to look at the login screen without logging out.
USAGE
}

ACTION="install"
RESTORE_FROM=""
# true/false. Only --build-sddm sets it, so a test can pin the palette;
# an ordinary install always follows the session.
SDDM_MODE=""
ASSUME_YES=0
BUILD_SDDM_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --link) MODE="link"; shift ;;
        --uninstall)
            ACTION="uninstall"
            shift
            # An optional backup path may follow, but not another flag.
            if [[ $# -gt 0 && "$1" != --* ]]; then RESTORE_FROM="$1"; shift; fi
            ;;
        --yes|-y)  ASSUME_YES=1; shift ;;
        --test-sddm) ACTION="test-sddm"; shift ;;
        --build-sddm)
            ACTION="build-sddm"
            shift
            [[ $# -gt 0 && "$1" != --* ]] || { echo "--build-sddm needs a directory" >&2; exit 1; }
            BUILD_SDDM_DIR="$1"; shift
            # An optional palette may follow, so a test build is reproducible
            # rather than whatever this machine happens to be set to.
            if [[ $# -gt 0 && "$1" != --* ]]; then
                case "$1" in
                    light) SDDM_MODE="false" ;;
                    dark)  SDDM_MODE="true" ;;
                    *) echo "--build-sddm palette must be light or dark" >&2; exit 1 ;;
                esac
                shift
            fi ;;
        --help|-h) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage; exit 1 ;;
    esac
done


# ── Modules ──────────────────────────────────────────────────────────────────
for _module in common banner greeter checklist uninstall packages shell terminal; do
    # shellcheck source=/dev/null
    source "$REPO/install/$_module.sh"
done
unset _module

if [[ "$ACTION" == "install" ]]; then
    banner
fi

# ── Working on the greeter ───────────────────────────────────────────────────
if [[ "$ACTION" == "build-sddm" ]]; then
    build_sddm "$BUILD_SDDM_DIR" "$(sddm_current_mode)"
    exit 0
fi

if [[ "$ACTION" == "test-sddm" ]]; then
    greeter="$(command -v sddm-greeter-qt6 || command -v sddm-greeter || true)"
    [[ -n "$greeter" ]] || die "no sddm-greeter binary found — is sddm installed?"
    preview="${TMPDIR:-/tmp}/brutaldots-sddm-preview"
    build_sddm "$preview" "$(sddm_current_mode)"
    say "opening the greeter in a window — close it or press Ctrl-C when done"
    say "the power buttons are missing from a preview because SDDM reports them"
    say "unavailable without its daemon, which is exactly what a preview is"
    "$greeter" --test-mode --theme "$preview"
    exit 0
fi

run_uninstall

# ── Run ──────────────────────────────────────────────────────────────────────
require_core
check_optional
install_missing
setup_zsh

# ── What to install ──────────────────────────────────────────────────────────
# Defaults are chosen so that re-running the installer keeps whatever you
# already have: if the greeter is installed, it stays ticked.
sddm_note="the lock screen, at boot — needs sudo"
sddm_default=0
[[ -d "$SDDM_THEME_DIR" ]] && sddm_default=1
if ! command -v sddm >/dev/null 2>&1; then
    sddm_note="sddm is not installed on this machine"
    sddm_default=0
fi
add_feature shell "Hyprland + Quickshell config" "always installed"  1 1
add_feature sddm  "SDDM login screen"            "$sddm_note" "$sddm_default" 0

# Drawn whenever there is a terminal for it. The greeter is chosen here and
# nowhere else, so there is one place to look for the answer.
if [[ -t 0 && -t 1 ]] && (( ! ASSUME_YES )); then
    choose_features || { say "nothing was installed"; exit 0; }
    printf '\n'
fi

if feature_on sddm && ! command -v sddm >/dev/null 2>&1; then
    die "the login screen was selected but sddm is not installed"
fi

install_shell
install_terminal

if [[ ! -r /etc/pam.d/login ]]; then
    warn "/etc/pam.d/login is missing — set lock.pamConfig in settings.json to a"
    warn "file that exists, or the lock screen will not accept your password"
fi

# ── Login screen ─────────────────────────────────────────────────────────────
if feature_on sddm; then
    install_sddm
fi

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
    if hyprctl reload >/dev/null 2>&1; then
        say "reloaded Hyprland"
    else
        warn "could not reload Hyprland; run 'hyprctl reload' yourself"
    fi
fi

say "installation complete!"
say "settings live in ~/.config/brutaldots/settings.json"
