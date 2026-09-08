#!/usr/bin/env bash
# The Quickshell config and the Hyprland configuration it expects.
#
# Sourced by ../install.sh; not run on its own.

install_shell() {
# ── Install the shell ────────────────────────────────────────────────────────
mkdir -p "$QS_DIR"

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
    warn "$TARGET already exists — moving it to $backup"
    mv "$TARGET" "$backup"
fi

if [[ "$MODE" == "link" ]]; then
    ln -s "$REPO/.config/quickshell/brutal" "$TARGET"
    say "linked $TARGET -> $REPO/.config/quickshell/brutal"
else
    cp -r "$REPO/.config/quickshell/brutal" "$TARGET"
    say "copied config to $TARGET"
fi

# ── Hyprland configuration ───────────────────────────────────────────────────
# BrutalDots ships a complete Hyprland config. The whole of ~/.config/hypr is
# snapshotted first — not just the files being replaced — because hyprlock,
# hypridle and your custom/ overrides live there too and are easy to lose track
# of. The snapshot is a copy, so custom/ keeps working in place.
#
# BrutalDots does its own locking and idle handling and never starts hyprlock or
# hypridle, so those files stay on disk but stop having any effect.
mkdir -p "$HYPR_DIR"

if [[ -n "$(ls -A "$HYPR_DIR" 2>/dev/null)" ]]; then
    backup="$HYPR_DIR.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$HYPR_DIR" "$backup"
    say "backed up all of $HYPR_DIR"
    say "  -> $backup"
    warn "restore with: rm -rf '$HYPR_DIR' && cp -a '$backup' '$HYPR_DIR'"
fi

# Replace only the two paths BrutalDots owns; everything else stays put.
# Staged and renamed rather than removed and copied back -- a rename is atomic,
# and Hyprland reloads the instant the file changes. See AGENTS.md.
staged_lua="$HYPR_DIR/.hyprland.lua.new"
staged_dir="$HYPR_DIR/.hyprland.new"
rm -rf "$staged_dir" "$staged_lua"
cp "$REPO/.config/hypr/hyprland.lua" "$staged_lua"
cp -r "$REPO/.config/hypr/hyprland" "$staged_dir"
rm -rf "$HYPR_DIR/hyprland"
mv "$staged_dir" "$HYPR_DIR/hyprland"
mv "$staged_lua" "$HYPR_DIR/hyprland.lua"
say "installed $HYPR_DIR/hyprland.lua and hyprland/"

if [[ -e "$HYPR_DIR/hyprland.conf" ]]; then
    warn "a hyprland.conf is still present — remove or rename it so Hyprland"
    warn "picks up hyprland.lua (.conf support is removed in Hyprland 0.57)"
fi

# Overrides written for a different rice will still be loaded, and win.
if [[ -d "$HYPR_DIR/custom" ]] && [[ -n "$(ls -A "$HYPR_DIR/custom" 2>/dev/null)" ]]; then
    warn "$HYPR_DIR/custom/ already has overrides — these load last and win."
    warn "review them: settings like dim_inactive will fight the theme."
fi

say "your overrides go in $HYPR_DIR/custom/{env,execs,general,rules,keybinds}.lua"

# Two daemons BrutalDots replaces. Leaving them running is not harmful, but the
# result is two lock screens and two sets of idle timings disagreeing.
for leftover in hypridle hyprlock; do
    if pgrep -x "$leftover" >/dev/null 2>&1; then
        warn "$leftover is running — BrutalDots handles that itself now."
        warn "it will not be started again after you log out and back in."
    fi
done
}
