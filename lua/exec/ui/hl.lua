local api = vim.api
local mix = require("volt.color").mix
local get_hl = require("volt.utils").get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "exec.state"

return function(ns)
  local bg

  if vim.g.base46_cache then
    local colors = dofile(vim.g.base46_cache .. "colors")
    bg = colors.black
  else
    bg = get_hl("Normal").bg
  end

  local transparent = not bg

  if transparent then
    bg = "#000000"
  end

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
    api.nvim_set_hl(state.term_ns, "Normal", { bg = term_bg })
    api.nvim_set_hl(state.term_ns, "FloatBorder", { fg = term_bg, bg = term_bg })
  end

  -- FoldColumn for terminal padding (used for side padding if needed)
  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  -- Custom highlights for exec.nvim
  api.nvim_set_hl(ns, "ExecTitle", { fg = "#cdd6f4", bold = true })
  api.nvim_set_hl(ns, "ExecAccent", { fg = "#f38ba8" })
  api.nvim_set_hl(ns, "ExecLabel", { fg = "#9399b2" })
  api.nvim_set_hl(ns, "ExecKey", { fg = "#cdd6f4", bg = lighten(bg, 10) })
  api.nvim_set_hl(ns, "ExecTabActive", { fg = "#cdd6f4", bg = lighten(bg, 15), bold = true })
  api.nvim_set_hl(ns, "ExecTabInactive", { fg = "#9399b2", bg = lighten(bg, 5) })
end
