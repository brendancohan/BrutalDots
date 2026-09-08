#!/usr/bin/env bash
# kitty, starship, fastfetch and the nvim colourscheme.
#
# Sourced by ../install.sh; not run on its own.

install_terminal() {
# ── Terminal ─────────────────────────────────────────────────────────────────
# kitty is the terminal the shell launches by default, so its colours ship here
# too. Only the palette is installed: these files set colours and nothing else,
# and brutaldots.conf is included at the *end* of kitty.conf so it wins the theme
# while leaving your font, padding, keybinds and kittens exactly as they were.
#
# There are two palettes and a one-line pointer between them. The shell rewrites
# the pointer when you toggle dark mode and sends kitty SIGUSR1, so this is the
# one file here that is not simply overwritten: re-running the installer must not
# drag a dark session back into the light.
if [[ -d "$KITTY_DIR" || -e "$KITTY_DIR/kitty.conf" ]]; then
    backup="$KITTY_DIR.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$KITTY_DIR" "$backup"
    say "backed up $KITTY_DIR"
    say "  -> $backup"
fi

mkdir -p "$KITTY_DIR"
for f in brutaldots.conf brutaldots-light.conf brutaldots-dark.conf; do
    cp "$REPO/.config/kitty/$f" "$KITTY_DIR/$f"
done
say "installed the kitty palettes in $KITTY_DIR"

# The mode is preserved, not the file: rewriting it in the current format is
# what migrates a pointer written by an older version. Only an *uncommented*
# include counts — the light pointer names the dark palette in a comment.
kitty_mode="light"
if [[ -e "$KITTY_DIR/brutaldots-mode.conf" ]] \
    && grep -q '^[[:space:]]*include[[:space:]]\+brutaldots-dark\.conf' \
        "$KITTY_DIR/brutaldots-mode.conf"; then
    kitty_mode="dark"
fi

cp "$REPO/.config/kitty/brutaldots-mode.conf" "$KITTY_DIR/brutaldots-mode.conf"
if [[ "$kitty_mode" == "dark" ]]; then
    printf '\ninclude brutaldots-dark.conf\n' >> "$KITTY_DIR/brutaldots-mode.conf"
fi
say "installed $KITTY_DIR/brutaldots-mode.conf ($kitty_mode)"

if [[ ! -e "$KITTY_DIR/kitty.conf" ]]; then
    # No config of your own: write a starting point that already includes the
    # theme. An existing one is never overwritten.
    cp "$REPO/.config/kitty/kitty.conf" "$KITTY_DIR/kitty.conf"
    say "wrote a starter $KITTY_DIR/kitty.conf"
elif ! grep -q '^[[:space:]]*include[[:space:]]\+brutaldots\.conf' "$KITTY_DIR/kitty.conf"; then
    printf '\n# BrutalDots colours. Last, so it wins the theme.\ninclude brutaldots.conf\n' \
        >> "$KITTY_DIR/kitty.conf"
    say "added the theme include to your $KITTY_DIR/kitty.conf"
else
    say "$KITTY_DIR/kitty.conf already includes the theme"
fi

# A theme left behind by another rice is not removed — that file is yours — but
# it is worth knowing it is still there, overridden by ours below it.
stale="$(grep -nE '^[[:space:]]*include.*(generated|theme|colou?rs)' \
    "$KITTY_DIR/kitty.conf" | grep -v brutaldots || true)"
if [[ -n "$stale" ]]; then
    warn "another theme is still included in kitty.conf:"
    while IFS= read -r line; do warn "  $line"; done <<< "$stale"
    warn "ours is included after it and wins, but you can delete those lines"
fi

if command -v kitty >/dev/null 2>&1; then
    if ! kitty +runpy "from kitty.config import load_config; load_config('$KITTY_DIR/kitty.conf')" \
        >/dev/null 2>&1; then
        warn "kitty could not parse $KITTY_DIR/kitty.conf — check it before relying on it"
    fi
fi

# ── Prompt ───────────────────────────────────────────────────────────────────
# starship has no include mechanism, so unlike kitty this is the whole file and
# not a fragment layered on top. Yours is copied aside first, every time.
if [[ -e "$STARSHIP_TOML" ]] && ! grep -q 'BrutalDots prompt' "$STARSHIP_TOML"; then
    backup="$STARSHIP_TOML.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$STARSHIP_TOML" "$backup"
    say "backed up your prompt"
    say "  -> $backup"
fi

mkdir -p "$(dirname "$STARSHIP_TOML")"
cp "$REPO/.config/starship.toml" "$STARSHIP_TOML"
say "installed $STARSHIP_TOML"

# starship only runs if the shell is told to start it. Appending is additive and
# guarded, so it stays harmless if starship is uninstalled later.
init_line() { printf 'command -v starship >/dev/null 2>&1 && eval "$(starship init %s)"\n' "$1"; }
for sh in zsh bash; do
    rc="$HOME/.${sh}rc"
    [[ -e "$rc" ]] || continue
    if grep -q 'starship init' "$rc"; then
        say "$rc already starts starship"
    else
        rc_backup "$rc"
        { printf '\n# BrutalDots prompt\n'; init_line "$sh"; } >> "$rc"
        say "added the starship init to $rc"
    fi
done

if command -v starship >/dev/null 2>&1; then
    if ! STARSHIP_CONFIG="$STARSHIP_TOML" starship print-config >/dev/null 2>&1; then
        warn "starship could not parse $STARSHIP_TOML"
    fi
fi

# The blocks are drawn with Nerd Font glyphs. Without one you get tofu boxes in
# an otherwise working prompt, which looks like a bug and is not one.
if command -v fc-list >/dev/null 2>&1; then
    # grep -c, not grep -q: under `set -o pipefail` a -q match kills fc-list
    # with SIGPIPE, the pipeline reports 141, and the test fires backwards.
    nerd="$(fc-list 2>/dev/null | grep -ci 'nerd font' || true)"
    if [[ "$nerd" == "0" ]]; then
        warn "no Nerd Font found — the prompt's icons will render as boxes"
        warn "install ttf-jetbrains-mono-nerd (or any Nerd Font) to fix that"
    fi
fi

# ── Fetch ────────────────────────────────────────────────────────────────────
# The banner a new terminal opens on. Its own file rather than a fragment,
# like starship's, because fastfetch has no include mechanism either.
if [[ -e "$FASTFETCH_DIR/config.jsonc" ]] \
    && ! grep -q 'BrutalDots fetch' "$FASTFETCH_DIR/config.jsonc"; then
    backup="$FASTFETCH_DIR/config.jsonc.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$FASTFETCH_DIR/config.jsonc" "$backup"
    say "backed up your fastfetch config"
    say "  -> $backup"
fi

mkdir -p "$FASTFETCH_DIR"
cp "$REPO/.config/fastfetch/config.jsonc" "$FASTFETCH_DIR/config.jsonc"
say "installed $FASTFETCH_DIR/config.jsonc"

if command -v fastfetch >/dev/null 2>&1; then
    if ! fastfetch --config "$FASTFETCH_DIR/config.jsonc" >/dev/null 2>&1; then
        warn "fastfetch could not parse its config — check it before relying on it"
    fi
fi

for sh in zsh bash; do
    rc="$HOME/.${sh}rc"
    [[ -e "$rc" ]] || continue
    if grep -q 'BrutalDots fetch' "$rc"; then
        say "$rc already runs the fetch"
    else
        rc_backup "$rc"
        {
            printf '\n# BrutalDots fetch. Delete these three lines to stop it.\n'
            printf 'case $- in *i*)\n'
            printf '    command -v fastfetch >/dev/null 2>&1 && fastfetch\n'
            printf 'esac\n'
        } >> "$rc"
        say "added the fetch to $rc"
    fi
done

if command -v nvim >/dev/null 2>&1; then
    mkdir -p "$NVIM_DIR/colors" "$NVIM_DIR/lua/brutaldots" "$NVIM_DIR/lua/lualine/themes"
    cp "$REPO/.config/nvim/colors/brutaldots.lua"                "$NVIM_DIR/colors/brutaldots.lua"
    cp "$REPO/.config/nvim/lua/brutaldots/palette.lua"           "$NVIM_DIR/lua/brutaldots/palette.lua"
    cp "$REPO/.config/nvim/lua/lualine/themes/brutaldots.lua"    "$NVIM_DIR/lua/lualine/themes/brutaldots.lua"
    say "installed the nvim colourscheme in $NVIM_DIR"

    if ! nvim --headless -u NONE \
        --cmd "set rtp+=$NVIM_DIR" -c 'colorscheme brutaldots' -c quit >/dev/null 2>&1; then
        warn "nvim could not load the colourscheme — check it before relying on it"
    fi

    if ! grep -rqs 'colorscheme.*brutaldots\|colorscheme("brutaldots")' "$NVIM_DIR"; then
        say "to use it, put this in your init.lua:  vim.cmd.colorscheme('brutaldots')"
        say "and for the statusline:  require('lualine').setup { options = { theme = 'brutaldots' } }"
    fi
else
    say "nvim not installed — skipped the editor theme"
fi
}
