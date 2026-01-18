local api = vim.api
local mix = require("volt.color").mix
local get_hl = require("volt.utils").get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "exec.state"

return function(ns)
  local bg
  local colors = {}

  -- 1. Extract Colors
  if vim.g.base46_cache then
    local base46_colors = dofile(vim.g.base46_cache .. "colors")
    bg = base46_colors.black
    colors.red = base46_colors.red
    colors.green = base46_colors.green
    colors.blue = base46_colors.blue
    colors.yellow = base46_colors.yellow
    colors.purple = base46_colors.purple
    colors.cyan = base46_colors.cyan
    colors.orange = base46_colors.orange
    colors.grey = base46_colors.grey
    colors.white = base46_colors.white
  else
    bg = get_hl("Normal").bg

    -- Fallback map
    local function fetch(group, fallback)
      local val = get_hl(group).fg
      return val or fallback
    end

    colors.red = fetch("DiagnosticError", "#ff5555")
    colors.green = fetch("String", "#50fa7b")
    colors.blue = fetch("Function", "#8be9fd")
    colors.yellow = fetch("DiagnosticWarn", "#f1fa8c")
    colors.purple = fetch("Keyword", "#bd93f9")
    colors.cyan = fetch("DiagnosticHint", "#8be9fd")
    colors.orange = fetch("Constant", "#ffb86c")
    colors.grey = fetch("Comment", "#6272a4")
    colors.white = fetch("Normal", "#f8f8f2")
  end

  -- Handle Transparency
  local transparent = not bg
  if transparent then bg = "#000000" end

  -- 2. Setup Backgrounds & Borders
  if state.config.border then
    -- Visible border: window bg same as editor, border is lighter
    local border_fg = lighten(bg, 15)
    api.nvim_set_hl(ns, "Normal", { bg = bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = border_fg, bg = bg })
    -- Terminal same as main window when border is visible
    api.nvim_set_hl(state.term_ns, "Normal", { bg = bg })
    api.nvim_set_hl(state.term_ns, "FloatBorder", { fg = border_fg, bg = bg })
  else
    -- Invisible border (typr style): window bg is slightly lighter, border matches
    local window_bg = lighten(bg, 2)
    api.nvim_set_hl(ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = window_bg, bg = window_bg })
    -- Terminal darker when border is invisible
    local term_bg = lighten(bg, -2) -- Darker than editor bg
    api.nvim_set_hl(state.term_ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(
      state.term_ns,
      "FloatBorder",
      { fg = window_bg, bg = window_bg }
    )
  end

  -- FoldColumn for terminal padding
  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  -- 3. Custom Highlights for exec.nvim
  -- Map derived colors to Exec groups
  api.nvim_set_hl(ns, "ExecTitle", { fg = colors.blue, bold = true })
  api.nvim_set_hl(ns, "ExecAccent", { fg = colors.red })
  api.nvim_set_hl(ns, "ExecLabel", { fg = colors.grey })

  -- Key: White text on slightly lighter bg
  api.nvim_set_hl(ns, "ExecKey", { fg = colors.white, bg = lighten(bg, 10) })

  -- tabs
  if state.config.border then
    api.nvim_set_hl(
      ns,
      "ExecTabActive",
      { fg = colors.white, bg = bg, bold = true }
    )
    api.nvim_set_hl(ns, "ExecTabInactive", { fg = colors.grey, bg = bg })
  else
    api.nvim_set_hl(
      ns,
      "ExecTabActive",
      { fg = colors.white, bg = lighten(bg, 2), bold = true }
    )
    api.nvim_set_hl(
      ns,
      "ExecTabInactive",
      { fg = colors.grey, bg = lighten(bg, 2) }
    )
  end

  -- Window
  api.nvim_set_hl(
    ns,
    "ExecWinActive",
    { fg = colors.white, bg = lighten(bg, 14), bold = true }
  )
  api.nvim_set_hl(
    ns,
    "ExecWinInactive",
    { fg = colors.grey, bg = lighten(bg, 4) }
  )

  -- Expose generic palette for custom usage if needed
  api.nvim_set_hl(ns, "ExecRed", { fg = colors.red })
  api.nvim_set_hl(ns, "ExecGreen", { fg = colors.green })
  api.nvim_set_hl(ns, "ExecBlue", { fg = colors.blue })
  api.nvim_set_hl(ns, "ExecYellow", { fg = colors.yellow })
  api.nvim_set_hl(ns, "ExecPurple", { fg = colors.purple })
  api.nvim_set_hl(ns, "ExecCyan", { fg = colors.cyan })
  api.nvim_set_hl(ns, "ExecOrange", { fg = colors.orange })
  api.nvim_set_hl(ns, "ExecGrey", { fg = colors.grey })
end
