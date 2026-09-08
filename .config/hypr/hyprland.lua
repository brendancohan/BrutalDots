-- ─────────────────────────────────────────────────────────────────────────────
-- BrutalDots — Hyprland configuration
--
-- This is the main config; Hyprland loads ~/.config/hypr/hyprland.lua directly.
-- Edit the files under hyprland/ to change behaviour, or drop your own
-- overrides in custom/ — those are loaded last and are never overwritten by an
-- update.
-- ─────────────────────────────────────────────────────────────────────────────

HOME = os.getenv("HOME")

-- Resolve this file's own directory rather than assuming ~/.config/hypr, so the
-- config works from an installed location and from a git checkout alike
-- (scripts/test-nested.sh loads it straight out of the repo).
CONFIG_DIR = (debug.getinfo(1, "S").source:sub(2):match("(.*)/[^/]*$")) or "."

function is_file_exists(path)
    local f = io.open(path, "r")
    if f == nil then return false end
    io.close(f)
    return true
end

-- Optional modules must never take the whole config down with them.
local function require_optional(module, path)
    if not is_file_exists(path) then return end
    local ok, err = pcall(require, module)
    if not ok then
        print("BrutalDots: failed to load " .. module .. ": " .. tostring(err))
    end
end

local function require_custom(name)
    require_optional("custom." .. name, CONFIG_DIR .. "/custom/" .. name .. ".lua")
end

-- ── Configuration ───────────────────────────────────────────────────────────
require("hyprland.env")
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.keybinds")

-- ── Your overrides ──────────────────────────────────────────────────────────
-- Loaded last, so these win over everything above. custom/execs.lua is for your
-- own autostarts; hl.on handlers stack, so it runs alongside the shell launch.
require_custom("env")
require_custom("execs")
require_custom("general")
require_custom("rules")
require_custom("keybinds")

-- nwg-displays writes these; loaded last so they win over the defaults above.
require_optional("monitors", CONFIG_DIR .. "/monitors.lua")
require_optional("workspaces", CONFIG_DIR .. "/workspaces.lua")
