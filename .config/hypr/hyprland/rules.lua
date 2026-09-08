-- Window and layer rules.

-- ── Windows ─────────────────────────────────────────────────────────────────
-- Blur is off globally, so nothing needs a no_blur rule.

-- File dialogs and other transient choosers float, centred.
local dialogs = {
    "^(Open File)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Select a File)(.*)$",
    "^(Save As)(.*)$",
    "^(File Upload)(.*)$",
    "^(Choose wallpaper)(.*)$"
}

for _, title in ipairs(dialogs) do
    hl.window_rule({ match = { title = title }, float = true })
    hl.window_rule({ match = { title = title }, center = true })
    hl.window_rule({ match = { title = title }, size = { "(monitor_w*0.55)", "(monitor_h*0.60)" } })
end

-- Small utility windows are more useful floating.
hl.window_rule({ match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor)$" }, center = true })

-- The shell registers its own polkit agent, so this only matters to anyone who
-- keeps an external one running; it costs nothing to leave in place.
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, center = true })

-- Picture-in-picture should float, stay on top and follow you between workspaces.
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })

-- Games and video get the frame out of the way.
hl.window_rule({ match = { fullscreen = true }, border_size = 0 })
hl.window_rule({ match = { fullscreen = true }, rounding = 0 })
hl.window_rule({ match = { fullscreen = true }, no_shadow = true })

-- Never let a window steal focus mid-typing from a splash screen.
hl.window_rule({ match = { class = "^(steam)$", title = "^()$" }, no_focus = true })

-- ── Layers ──────────────────────────────────────────────────────────────────
-- The shell paints its own shadows and is fully opaque, so Hyprland must not
-- add blur behind any of its surfaces.
hl.layer_rule({ match = { namespace = "brutaldots-.*" }, blur = false })

-- The volume/brightness overlay appears and disappears constantly; animating it
-- just makes it feel laggy.
hl.layer_rule({ match = { namespace = "brutaldots-osd" }, no_anim = true })

-- The idle veil fades itself in and is removed the instant you move; a slide
-- animation on top of that reads as a stutter.
hl.layer_rule({ match = { namespace = "brutaldots-dim" }, no_anim = true })
