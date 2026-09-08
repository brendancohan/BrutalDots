-- Monitors, window frame, motion and input.
--
-- The frame deliberately mirrors the shell's own surfaces: 2px ink borders and
-- a hard, un-blurred shadow offset down and to the right.

-- ── Monitors ────────────────────────────────────────────────────────────────
-- Sensible default for any setup; override in custom/general.lua or let
-- nwg-displays write monitors.lua.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})

hl.config({
    general = {
        border_size = 2,
        gaps_in = 6,
        gaps_out = 14,

        col = {
            active_border = "rgba(161110ff)",
            inactive_border = "rgba(16111066)"
        },

        resize_on_border = true,
        allow_tearing = false,

        snap = {
            enabled = true,
            window_gap = 6,
            monitor_gap = 14
        }
    },

    decoration = {
        rounding = 12,
        -- 2 = a true circle-arc corner; the shell uses the same curve.
        rounding_power = 2.0,
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        -- The signature: an un-blurred block of ink offset down and right.
        shadow = {
            enabled = true,
            sharp = true,
            range = 6,
            render_power = 1,
            offset = { 5, 5 },
            color = "rgba(161110ff)",
            color_inactive = "rgba(16111055)"
        },

        -- Brutalism is opaque. Blur and dimming both undercut the look.
        blur = {
            enabled = false
        },
        dim_inactive = false
    },

    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        }
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        focus_on_activate = true
    },

    animations = {
        enabled = true
    }
})

-- ── Motion ──────────────────────────────────────────────────────────────────
-- Short and blunt, matching the shell's own animation timings.
hl.curve("brutal", {
    type = "bezier",
    points = { { 0.2, 0.9 }, { 0.3, 1.0 } }
})

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "brutal", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "brutal", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "brutal", style = "slide" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3, bezier = "brutal" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 3, bezier = "brutal" })
hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "brutal" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "brutal", style = "slide" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 2, bezier = "brutal", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2, bezier = "brutal", style = "fade" })

-- ── Gestures ────────────────────────────────────────────────────────────────
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
