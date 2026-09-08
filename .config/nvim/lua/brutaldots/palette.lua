-- The BrutalDots palette, and which half of it is current.
--
-- Its own module because the colourscheme and the lualine theme both need it.
-- Syntax colours are the two kitty palettes; surfaces are Config/Theme.qml's.
-- See AGENTS.md "nvim" and "The terminal".

local M = {}

local palettes = {
  light = {
    bg      = "#FAF0E6", -- Theme base, and what kitty paints
    float   = "#F5EBE6", -- Theme surface
    panel   = "#EFE0D6", -- Theme mantle: statusline, sidebars
    deep    = "#E8E0D0", -- Theme crust
    fg      = "#161110",
    comment = "#726c6a",
    dim     = "#565250",
    red     = "#a50d00", red_hi     = "#da1100",
    green   = "#255c27", green_hi   = "#2b7c2e",
    orange  = "#883900", orange_hi  = "#b84d00",
    blue    = "#005295", blue_hi    = "#006fc8",
    magenta = "#802b8f", magenta_hi = "#b130c7",
    cyan    = "#1f5853", cyan_hi    = "#237870",
  },
  dark = {
    bg      = "#2A2320", -- Theme mantle, and what kitty paints
    float   = "#3E342F", -- Theme base: raised
    panel   = "#332B27", -- Theme surface
    deep    = "#201A17", -- Theme crust
    fg      = "#F4EADF",
    comment = "#948880",
    dim     = "#E0D5CA",
    red     = "#FF8A80", red_hi     = "#FFB9B3",
    green   = "#A5D6A7", green_hi   = "#C8E6C9",
    orange  = "#F79E5D", orange_hi  = "#F9BB8E",
    blue    = "#90CAF9", blue_hi    = "#C0E1FC",
    magenta = "#CE93D8", magenta_hi = "#DFB8E6",
    cyan    = "#80CBC4", cyan_hi    = "#A4DAD5",
  },
}

local settings_path = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config"))
  .. "/brutaldots/settings.json"

--- Which mode the shell is in.
---
--- Falls back to `background` when there is no settings.json, so the file is
--- useful on a machine that has the colourscheme but not the rest of the rice.
local function read_mode()
  local ok, content = pcall(vim.fn.readfile, settings_path)
  if ok and content and #content > 0 then
    local decoded_ok, decoded = pcall(vim.json.decode, table.concat(content, "\n"))
    if decoded_ok and type(decoded) == "table" and type(decoded.theme) == "table" then
      if decoded.theme.dark ~= nil then
        return decoded.theme.dark and "dark" or "light"
      end
    end
  end
  return vim.o.background == "light" and "light" or "dark"
end


M.palettes = palettes
M.settings_path = settings_path

--- Which mode the shell is in.
---
--- Falls back to `background` when there is no settings.json, so this is still
--- useful on a machine that has the colourscheme but not the rest of the rice.
function M.mode()
  return read_mode()
end

--- The current half of the palette.
function M.current(mode)
  return palettes[mode or read_mode()] or palettes.dark
end

return M
