-- BrutalDots colourscheme.
--
-- Colours live in lua/brutaldots/palette.lua, shared with the lualine theme.
-- Mode follows the shell and is watched, not read once. See AGENTS.md "nvim".

local M = {}

local palette = require("brutaldots.palette")
local settings_path = palette.settings_path

local function highlights(c)
  return {
    -- Editor ------------------------------------------------------------
    Normal       = { fg = c.fg, bg = c.bg },
    NormalNC     = { fg = c.fg, bg = c.bg },
    NormalFloat  = { fg = c.fg, bg = c.float },
    FloatBorder  = { fg = c.dim, bg = c.float },
    FloatTitle   = { fg = c.fg, bg = c.float, bold = true },
    Cursor       = { fg = c.bg, bg = c.fg },
    lCursor      = { fg = c.bg, bg = c.fg },
    CursorLine   = { bg = c.panel },
    CursorColumn = { bg = c.panel },
    ColorColumn  = { bg = c.panel },
    CursorLineNr = { fg = c.orange, bold = true },
    LineNr       = { fg = c.comment },
    SignColumn   = { bg = c.bg },
    FoldColumn   = { fg = c.comment, bg = c.bg },
    Folded       = { fg = c.comment, bg = c.panel },
    VertSplit    = { fg = c.deep },
    WinSeparator = { fg = c.deep },
    Visual       = { bg = c.deep },
    VisualNOS    = { bg = c.deep },
    Search       = { fg = c.bg, bg = c.orange },
    IncSearch    = { fg = c.bg, bg = c.red },
    CurSearch    = { fg = c.bg, bg = c.red },
    MatchParen   = { fg = c.red, bold = true },
    NonText      = { fg = c.comment },
    Whitespace   = { fg = c.deep },
    SpecialKey   = { fg = c.comment },
    Directory    = { fg = c.blue, bold = true },
    Title        = { fg = c.orange, bold = true },
    Conceal      = { fg = c.comment },
    EndOfBuffer  = { fg = c.bg },
    QuickFixLine = { bg = c.panel, bold = true },
    Pmenu        = { fg = c.fg, bg = c.float },
    PmenuSel     = { fg = c.bg, bg = c.blue, bold = true },
    PmenuSbar    = { bg = c.panel },
    PmenuThumb   = { bg = c.comment },
    WildMenu     = { fg = c.bg, bg = c.blue },
    StatusLine   = { fg = c.fg, bg = c.panel },
    StatusLineNC = { fg = c.comment, bg = c.panel },
    TabLine      = { fg = c.comment, bg = c.deep },
    TabLineSel   = { fg = c.fg, bg = c.bg, bold = true },
    TabLineFill  = { bg = c.deep },
    ErrorMsg     = { fg = c.red, bold = true },
    WarningMsg   = { fg = c.orange, bold = true },
    ModeMsg      = { fg = c.fg, bold = true },
    MoreMsg      = { fg = c.green },
    Question     = { fg = c.green },
    MsgArea      = { fg = c.fg },

    -- Syntax ------------------------------------------------------------
    Comment      = { fg = c.comment, italic = true },
    Constant     = { fg = c.orange },
    String       = { fg = c.green },
    Character    = { fg = c.green },
    Number       = { fg = c.magenta },
    Boolean      = { fg = c.magenta },
    Float        = { fg = c.magenta },
    Identifier   = { fg = c.fg },
    Function     = { fg = c.blue, bold = true },
    Statement    = { fg = c.red },
    Conditional  = { fg = c.red },
    Repeat       = { fg = c.red },
    Label        = { fg = c.red },
    Operator     = { fg = c.cyan },
    Keyword      = { fg = c.red },
    Exception    = { fg = c.red },
    PreProc      = { fg = c.magenta },
    Include      = { fg = c.magenta },
    Define       = { fg = c.magenta },
    Macro        = { fg = c.magenta },
    Type         = { fg = c.cyan, bold = true },
    StorageClass = { fg = c.cyan },
    Structure    = { fg = c.cyan },
    Typedef      = { fg = c.cyan },
    Special      = { fg = c.orange },
    Delimiter    = { fg = c.dim },
    Underlined   = { underline = true },
    Error        = { fg = c.red, bold = true },
    Todo         = { fg = c.bg, bg = c.orange, bold = true },

    -- Treesitter --------------------------------------------------------
    ["@variable"]            = { fg = c.fg },
    ["@variable.builtin"]    = { fg = c.red, italic = true },
    ["@variable.parameter"]  = { fg = c.orange },
    ["@variable.member"]     = { fg = c.blue },
    ["@constant"]            = { fg = c.orange },
    ["@constant.builtin"]    = { fg = c.magenta },
    ["@module"]              = { fg = c.cyan },
    ["@string"]              = { fg = c.green },
    ["@string.escape"]       = { fg = c.magenta },
    ["@string.special"]      = { fg = c.magenta },
    ["@character"]           = { fg = c.green },
    ["@number"]              = { fg = c.magenta },
    ["@boolean"]             = { fg = c.magenta },
    ["@function"]            = { fg = c.blue, bold = true },
    ["@function.builtin"]    = { fg = c.cyan, bold = true },
    ["@function.call"]       = { fg = c.blue },
    ["@function.method"]     = { fg = c.blue },
    ["@constructor"]         = { fg = c.cyan },
    ["@keyword"]             = { fg = c.red },
    ["@keyword.function"]    = { fg = c.red },
    ["@keyword.return"]      = { fg = c.red, bold = true },
    ["@keyword.operator"]    = { fg = c.cyan },
    ["@keyword.import"]      = { fg = c.magenta },
    ["@type"]                = { fg = c.cyan, bold = true },
    ["@type.builtin"]        = { fg = c.cyan },
    ["@property"]            = { fg = c.blue },
    ["@field"]               = { fg = c.blue },
    ["@operator"]            = { fg = c.cyan },
    ["@punctuation.bracket"] = { fg = c.dim },
    ["@punctuation.delimiter"] = { fg = c.dim },
    ["@punctuation.special"] = { fg = c.magenta },
    ["@comment"]             = { fg = c.comment, italic = true },
    ["@comment.todo"]        = { fg = c.bg, bg = c.orange, bold = true },
    ["@comment.warning"]     = { fg = c.bg, bg = c.orange, bold = true },
    ["@comment.error"]       = { fg = c.bg, bg = c.red, bold = true },
    ["@tag"]                 = { fg = c.red },
    ["@tag.attribute"]       = { fg = c.orange },
    ["@tag.delimiter"]       = { fg = c.dim },
    ["@markup.heading"]      = { fg = c.orange, bold = true },
    ["@markup.link"]         = { fg = c.blue, underline = true },
    ["@markup.raw"]          = { fg = c.green },
    ["@markup.list"]         = { fg = c.red },
    ["@markup.strong"]       = { bold = true },
    ["@markup.italic"]       = { italic = true },

    -- Diagnostics -------------------------------------------------------
    DiagnosticError = { fg = c.red },
    DiagnosticWarn  = { fg = c.orange },
    DiagnosticInfo  = { fg = c.blue },
    DiagnosticHint  = { fg = c.cyan },
    DiagnosticOk    = { fg = c.green },
    DiagnosticUnderlineError = { undercurl = true, sp = c.red },
    DiagnosticUnderlineWarn  = { undercurl = true, sp = c.orange },
    DiagnosticUnderlineInfo  = { undercurl = true, sp = c.blue },
    DiagnosticUnderlineHint  = { undercurl = true, sp = c.cyan },
    DiagnosticVirtualTextError = { fg = c.red, bg = c.panel },
    DiagnosticVirtualTextWarn  = { fg = c.orange, bg = c.panel },
    DiagnosticVirtualTextInfo  = { fg = c.blue, bg = c.panel },
    DiagnosticVirtualTextHint  = { fg = c.cyan, bg = c.panel },

    -- LSP ---------------------------------------------------------------
    LspReferenceText  = { bg = c.deep },
    LspReferenceRead  = { bg = c.deep },
    LspReferenceWrite = { bg = c.deep, underline = true },
    LspInlayHint      = { fg = c.comment, bg = c.panel, italic = true },

    -- Diff and git ------------------------------------------------------
    DiffAdd    = { fg = c.green, bg = c.panel },
    DiffChange = { fg = c.orange, bg = c.panel },
    DiffDelete = { fg = c.red, bg = c.panel },
    DiffText   = { fg = c.bg, bg = c.orange },
    Added      = { fg = c.green },
    Changed    = { fg = c.orange },
    Removed    = { fg = c.red },
    GitSignsAdd    = { fg = c.green },
    GitSignsChange = { fg = c.orange },
    GitSignsDelete = { fg = c.red },

    -- Telescope ---------------------------------------------------------
    TelescopeNormal       = { fg = c.fg, bg = c.float },
    TelescopeBorder       = { fg = c.dim, bg = c.float },
    TelescopeTitle        = { fg = c.bg, bg = c.orange, bold = true },
    TelescopePromptNormal = { fg = c.fg, bg = c.panel },
    TelescopePromptBorder = { fg = c.panel, bg = c.panel },
    TelescopePromptTitle  = { fg = c.bg, bg = c.red, bold = true },
    TelescopePreviewTitle = { fg = c.bg, bg = c.green, bold = true },
    TelescopeResultsTitle = { fg = c.bg, bg = c.blue, bold = true },
    TelescopeSelection    = { bg = c.deep, bold = true },
    TelescopeMatching     = { fg = c.orange, bold = true },

    -- nvim-tree ---------------------------------------------------------
    NvimTreeNormal        = { fg = c.fg, bg = c.deep },
    NvimTreeNormalNC      = { fg = c.fg, bg = c.deep },
    NvimTreeWinSeparator  = { fg = c.deep, bg = c.deep },
    NvimTreeRootFolder    = { fg = c.orange, bold = true },
    NvimTreeFolderName    = { fg = c.blue },
    NvimTreeOpenedFolderName = { fg = c.blue, bold = true },
    NvimTreeFolderIcon    = { fg = c.orange },
    NvimTreeSpecialFile   = { fg = c.magenta, underline = true },
    NvimTreeGitDirty      = { fg = c.orange },
    NvimTreeGitNew        = { fg = c.green },
    NvimTreeGitDeleted    = { fg = c.red },
    NvimTreeIndentMarker  = { fg = c.comment },
    NvimTreeCursorLine    = { bg = c.panel },

    -- bufferline --------------------------------------------------------
    BufferLineFill            = { bg = c.deep },
    BufferLineBackground      = { fg = c.comment, bg = c.deep },
    BufferLineBufferSelected  = { fg = c.fg, bg = c.bg, bold = true },
    BufferLineBufferVisible   = { fg = c.dim, bg = c.deep },
    BufferLineSeparator       = { fg = c.deep, bg = c.deep },
    BufferLineSeparatorSelected = { fg = c.deep, bg = c.bg },
    BufferLineIndicatorSelected = { fg = c.orange, bg = c.bg },
    BufferLineModified          = { fg = c.green, bg = c.deep },
    BufferLineModifiedSelected  = { fg = c.green, bg = c.bg },

    -- nvim-cmp ----------------------------------------------------------
    CmpItemAbbr           = { fg = c.fg },
    CmpItemAbbrDeprecated = { fg = c.comment, strikethrough = true },
    CmpItemAbbrMatch      = { fg = c.orange, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.orange },
    CmpItemKind           = { fg = c.magenta },
    CmpItemMenu           = { fg = c.comment },
    CmpItemKindFunction   = { fg = c.blue },
    CmpItemKindMethod     = { fg = c.blue },
    CmpItemKindVariable   = { fg = c.fg },
    CmpItemKindKeyword    = { fg = c.red },
    CmpItemKindSnippet    = { fg = c.green },

    -- indent-blankline --------------------------------------------------
    IblIndent = { fg = c.deep },
    IblScope  = { fg = c.comment },

    -- which-key ---------------------------------------------------------
    WhichKey          = { fg = c.orange, bold = true },
    WhichKeyGroup     = { fg = c.blue },
    WhichKeyDesc      = { fg = c.fg },
    WhichKeySeparator = { fg = c.comment },
    WhichKeyFloat     = { bg = c.float },
    WhichKeyBorder    = { fg = c.dim, bg = c.float },
  }
end

--- Paint. Clearing first is what makes re-applying on a mode change clean.
function M.load(mode)
  mode = mode or palette.mode()
  local c = palette.current(mode)

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.o.background = mode
  vim.g.colors_name = "brutaldots"

  for group, spec in pairs(highlights(c)) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- The 16 terminal colours nvim hands to :terminal, so a shell opened inside
  -- the editor matches the editor.
  local ansi = {
    c.bg, c.red, c.green, c.orange, c.blue, c.magenta, c.cyan, c.fg,
    c.comment, c.red_hi, c.green_hi, c.orange_hi, c.blue_hi, c.magenta_hi,
    c.cyan_hi, c.fg,
  }
  for i, colour in ipairs(ansi) do
    vim.g["terminal_color_" .. (i - 1)] = colour
  end

  -- lualine caches its theme table, so a mode flip needs it re-read. Its own
  -- config is passed straight back so nothing the user set is lost.
  local ok, lualine = pcall(require, "lualine")
  if ok and vim.g.loaded_lualine then
    local cfg = lualine.get_config()
    if cfg and cfg.options and cfg.options.theme == "brutaldots" then
      lualine.setup(cfg)
    end
  end
end

--- Repaint when the shell's mode changes.
---
--- A watcher rather than a poll, and re-armed every time because writers that
--- replace a file rather than write through it (which is what an atomic save
--- is) break the original watch: the inode the handle points at is gone.
local watcher
local function watch()
  if watcher then
    watcher:stop()
  end
  watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end
  watcher:start(settings_path, {}, function()
    vim.schedule(function()
      if vim.g.colors_name == "brutaldots" then
        M.load()
      end
      watch()
    end)
  end)
end

M.load()
if vim.uv.fs_stat(settings_path) then
  watch()
end

return M
