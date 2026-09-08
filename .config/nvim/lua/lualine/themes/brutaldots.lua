-- BrutalDots statusline.
--
-- The mode block is a flat accent with ink on it, the same rule the prompt and
-- the bar follow. Colours are shared with the colourscheme.

local palette = require("brutaldots.palette")
local c = palette.current()

-- Ink on the accent in light mode, and on the accent in dark mode too: these
-- are the terminal palette's colours, which are dark on cream and pastel on
-- near-black, so the block's own background is the thing that flips.
local on_accent = c.bg

local function block(colour)
  return {
    a = { fg = on_accent, bg = colour, gui = "bold" },
    b = { fg = c.fg, bg = c.panel },
    c = { fg = c.comment, bg = c.bg },
  }
end

return {
  normal   = block(c.blue),
  insert   = block(c.green),
  visual   = block(c.magenta),
  replace  = block(c.red),
  command  = block(c.orange),
  terminal = block(c.cyan),
  inactive = {
    a = { fg = c.comment, bg = c.panel },
    b = { fg = c.comment, bg = c.panel },
    c = { fg = c.comment, bg = c.bg },
  },
}
