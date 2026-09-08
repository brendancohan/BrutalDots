#!/usr/bin/env bash
# Putting the previous configuration back.
#
# Self-guarding: it returns immediately unless --uninstall was passed, so
# the entrypoint calls it unconditionally and the check lives in one place.
#
# Sourced by ../install.sh; not run on its own.

run_uninstall() {
# ── Uninstall ────────────────────────────────────────────────────────────────
# Nothing here deletes without first moving the live copy aside, so a wrong
# guess about which backup to restore is still recoverable.
if [[ "$ACTION" == "uninstall" ]]; then
    if [[ -z "$RESTORE_FROM" ]]; then
        # Newest first. The timestamp suffix sorts lexicographically.
        RESTORE_FROM="$(ls -d "$HYPR_DIR".bak.* 2>/dev/null | sort | tail -1 || true)"
    fi

    if [[ -L "$TARGET" ]]; then
        rm "$TARGET"
        say "removed the symlink at $TARGET"
    elif [[ -d "$TARGET" ]]; then
        aside="$TARGET.removed.$(date +%Y%m%d%H%M%S)"
        mv "$TARGET" "$aside"
        say "moved $TARGET aside"
        say "  -> $aside"
    fi

    if [[ -z "$RESTORE_FROM" ]]; then
        warn "no $HYPR_DIR.bak.* found, so nothing was restored."
        warn "removing only the two paths BrutalDots owns:"
        warn "  $HYPR_DIR/hyprland.lua and $HYPR_DIR/hyprland/"
        rm -rf "$HYPR_DIR/hyprland.lua" "$HYPR_DIR/hyprland"
    elif [[ ! -d "$RESTORE_FROM" ]]; then
        warn "not a directory: $RESTORE_FROM"
        exit 1
    else
        aside="$HYPR_DIR.brutaldots.$(date +%Y%m%d%H%M%S)"
        mv "$HYPR_DIR" "$aside"
        cp -a "$RESTORE_FROM" "$HYPR_DIR"
        say "restored $HYPR_DIR from $RESTORE_FROM"
        say "the BrutalDots config is at $aside if you want it back"
    fi

    if [[ -e "$KITTY_DIR/brutaldots.conf" ]]; then
        rm -f "$KITTY_DIR"/brutaldots.conf "$KITTY_DIR"/brutaldots-light.conf \
              "$KITTY_DIR"/brutaldots-dark.conf "$KITTY_DIR"/brutaldots-mode.conf
        # The include is left in place: removing a line from a file that is
        # yours is not this script's call, and kitty ignores a missing include.
        say "removed the kitty palettes from $KITTY_DIR"
        warn "the 'include brutaldots.conf' line in kitty.conf is now inert —"
        warn "delete it, or restore from a $KITTY_DIR.bak.* copy"
    fi

    if [[ -e "$NVIM_DIR/colors/brutaldots.lua" ]]; then
        rm -f "$NVIM_DIR/colors/brutaldots.lua" \
              "$NVIM_DIR/lua/brutaldots/palette.lua" \
              "$NVIM_DIR/lua/lualine/themes/brutaldots.lua"
        rmdir "$NVIM_DIR/lua/brutaldots" 2>/dev/null || true
        say "removed the nvim colourscheme"
        warn "if your init.lua still says colorscheme 'brutaldots', point it at another"
    fi

    if [[ -e "$FASTFETCH_DIR/config.jsonc" ]] \
        && grep -q 'BrutalDots fetch' "$FASTFETCH_DIR/config.jsonc"; then
        rm -f "$FASTFETCH_DIR/config.jsonc"
        say "removed $FASTFETCH_DIR/config.jsonc"
        newest="$(ls -1dt "$FASTFETCH_DIR"/config.jsonc.bak.* 2>/dev/null | head -1 || true)"
        [[ -n "$newest" ]] && warn "your previous fetch config is at $newest"
        # The rc block stays: it is guarded on fastfetch existing and on the
        # shell being interactive, so it is inert without the config, and
        # editing a file that is yours is not this script's call.
        warn "the 'BrutalDots fetch' block in your shell rc is now inert — delete it if you want"
    fi

    if [[ -e "$STARSHIP_TOML" ]] && grep -q 'BrutalDots prompt' "$STARSHIP_TOML"; then
        rm -f "$STARSHIP_TOML"
        say "removed $STARSHIP_TOML"
        newest="$(ls -1dt "$STARSHIP_TOML".bak.* 2>/dev/null | head -1 || true)"
        [[ -n "$newest" ]] && warn "your previous prompt is at $newest"
        # The `starship init` line stays: it is in a file that is yours, and it
        # is harmless with no starship.toml -- starship falls back to defaults.
    fi

    uninstall_sddm

    warn "log out and back in, or restart Hyprland, for this to take effect"
    say "your settings at ~/.config/brutaldots/ were left alone"
    exit 0
fi

}
