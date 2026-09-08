#!/usr/bin/env bash
# Everything the desktop needs installed, and the shell it runs in.
#
# Sourced by ../install.sh; not run on its own.

# ── Dependencies ─────────────────────────────────────────────────────────────

# The two things there is no point continuing without.
require_core() {
missing=()
for cmd in quickshell hyprctl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    warn "missing required commands: ${missing[*]}"
    warn "install quickshell and hyprland first"
    exit 1
fi
}

# Everything the shell can use, grouped by what breaks without it so the report
# names the feature rather than just the binary. What is missing is collected
# and offered for installation below: a fresh install should come up with the
# whole thing working, not with a list of things to go and fetch.
MISSING_CMDS=()
MISSING_PKGS=()

check_group() {
    local feature="$1"; shift
    local absent=()
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || absent+=("$cmd")
    done
    if ((${#absent[@]})); then
        warn "$feature needs: ${absent[*]}"
        MISSING_CMDS+=("${absent[@]}")
    fi
    return 0
}

check_optional() {
check_group "shell"              zsh
check_group "terminal theme"     kitty
check_group "shell prompt"       starship
check_group "terminal fetch"     fastfetch
check_group "editor theme"       nvim
check_group "media controls"     playerctl
check_group "media visualiser"   cava
check_group "volume keys"        wpctl
check_group "brightness keys"    brightnessctl
check_group "weather"            curl
check_group "quick links"        xdg-open
check_group "files keybind"      nautilus
check_group "clipboard history"  cliphist wl-copy wl-paste
check_group "screenshots"        grim slurp
check_group "shot annotation"    satty
check_group "screen recording"   wf-recorder
check_group "colour picker"      hyprpicker
check_group "night light"        hyprsunset
check_group "lock and suspend hooks" gdbus

# Everything above is installed below rather than merely reported. The runtime
# guards stay regardless: a feature whose tool vanishes later still switches
# itself off instead of erroring.

if ! fc-list : family 2>/dev/null | grep -i "JetBrainsMono Nerd Font" >/dev/null; then
    warn "JetBrainsMono Nerd Font not found — icons and text will not render correctly"
    MISSING_PKGS+=(ttf-jetbrains-mono-nerd)
fi

}
# The command is usually the package name; these are the ones where it is not.
pkg_for() {
    case "$1" in
        hyprctl)          printf 'hyprland\n' ;;
        nvim)             printf 'neovim\n' ;;
        wpctl)            printf 'wireplumber\n' ;;
        xdg-open)         printf 'xdg-utils\n' ;;
        wl-copy|wl-paste) printf 'wl-clipboard\n' ;;
        gdbus)            printf 'glib2\n' ;;
        *)                printf '%s\n' "$1" ;;
    esac
}

# The packages are not optional. These dotfiles are opinionated about what the
# desktop contains, so a fresh install brings the whole set in rather than
# coming up half-lit and leaving the user to work out which piece is missing.
# The only way to decline is to install them yourself beforehand, at which
# point there is nothing here to do.
install_missing() {
    local pkgs=() seen=" " cmd pkg

    for cmd in ${MISSING_CMDS[@]+"${MISSING_CMDS[@]}"}; do
        pkg="$(pkg_for "$cmd")"
        [[ "$seen" == *" $pkg "* ]] || { pkgs+=("$pkg"); seen+="$pkg "; }
    done
    for pkg in ${MISSING_PKGS[@]+"${MISSING_PKGS[@]}"}; do
        [[ "$seen" == *" $pkg "* ]] || { pkgs+=("$pkg"); seen+="$pkg "; }
    done
    ((${#pkgs[@]})) || return 0

    # Not being on Arch is only a problem if something is actually absent —
    # anyone who installed the set by hand never reaches this.
    if ! command -v pacman >/dev/null 2>&1; then
        die "these are required and there is no pacman to install them: ${pkgs[*]}"
    fi

    printf '\n'
    say "installing what is missing: ${pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${pkgs[@]}" \
        || die "could not install: ${pkgs[*]}"
    return 0
}


# Shell rc files this run created, and ones it has already moved aside. The
# "nothing is touched without a backup first" rule exists to protect *your*
# data: a file we wrote ourselves a moment ago holds none, and backing it up
# only litters the home directory with a copy of our own template. Backing the
# same file up twice in one run is the same mistake — the copy worth keeping is
# the one taken before the first edit, not the one taken between two of ours.
SEEDED_RCS=()
BACKED_UP_RCS=()

rc_backup() {
    local rc="$1" seen
    for seen in ${SEEDED_RCS[@]+"${SEEDED_RCS[@]}"} \
                ${BACKED_UP_RCS[@]+"${BACKED_UP_RCS[@]}"}; do
        if [[ "$seen" == "$rc" ]]; then return 0; fi
    done
    cp -a "$rc" "$rc.bak.$(date +%Y%m%d%H%M%S)"
    BACKED_UP_RCS+=("$rc")
    return 0
}

# zsh is the shell these dots are written for: the prompt's `vimcmd_symbol` is
# a zsh vi-mode indicator, and the rc blocks further down only ever *append* to
# a file that already exists. On a machine that has never run zsh there is no
# ~/.zshrc for them to land in, so they would be skipped in silence and the
# prompt would simply never appear. Create it first, then adopt the shell.
setup_zsh() {
    local zsh_path rc current
    zsh_path="$(command -v zsh || true)"
    [[ -n "$zsh_path" ]] || return 0

    rc="$HOME/.zshrc"
    if [[ ! -e "$rc" ]]; then
        # Deliberately small. Everything here is what makes zsh usable rather
        # than merely present — landing someone in a shell with no completion
        # and no history is worse than leaving them on bash. Anything beyond
        # this is the user's to add.
        cat > "$rc" <<'ZSHRC'
# Created by the BrutalDots installer because there was no ~/.zshrc.
# It is yours now — edit freely; the installer will not overwrite it.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups share_history

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

bindkey -e
ZSHRC
        SEEDED_RCS+=("$rc")
        say "created $rc"
    fi

    # chsh refuses a shell that is not listed, and says so unhelpfully.
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        warn "$zsh_path is not in /etc/shells — leaving the login shell alone"
        return 0
    fi

    # Compare the files, not the strings. On a merged-/usr system the passwd
    # entry says /bin/zsh while `command -v` says /usr/bin/zsh — the same file
    # by two names — and a string compare would chsh on every single run.
    current="$(getent passwd "$USER" | cut -d: -f7)"
    resolve() { realpath -- "$1" 2>/dev/null || printf '%s' "$1"; }
    if [[ "$(resolve "$current")" == "$(resolve "$zsh_path")" ]]; then
        return 0
    fi

    say "setting your login shell to $zsh_path (was $current)"
    if sudo chsh -s "$zsh_path" "$USER"; then
        say "that takes effect at your next login; run: exec zsh  to switch now"
    else
        warn "could not change the login shell — chsh -s $zsh_path"
    fi
    return 0
}
