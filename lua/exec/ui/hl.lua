local api = vim.api
local get_hl = require("volt.utils").get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "exec.state"

return function(ns)
  local bg

  if vim.g.base46_cache then
    bg = dofile(vim.g.base46_cache .. "colors").black
  else
    bg = get_hl("Normal").bg
  end

  local transparent = not bg
  if transparent then bg = "#000000" end

  if state.config.border then
    local border_fg = lighten(bg, 15)
    api.nvim_set_hl(ns, "Normal", { bg = bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = border_fg, bg = bg })

    api.nvim_set_hl(state.term_ns, "Normal", { bg = bg })
    api.nvim_set_hl(state.term_ns, "FloatBorder", { fg = border_fg, bg = bg })
  else
    local window_bg = lighten(bg, 2)
    api.nvim_set_hl(ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = window_bg, bg = window_bg })

    api.nvim_set_hl(state.term_ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(
      state.term_ns,
      "FloatBorder",
      { fg = window_bg, bg = window_bg }
    )
  end

  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  local blue = get_hl("Function").fg
  local grey = get_hl("Comment").fg
  local white = get_hl("Normal").fg
  api.nvim_set_hl(ns, "ExecTitle", { fg = blue, bold = true })
  api.nvim_set_hl(ns, "ExecLabel", { fg = grey })
  api.nvim_set_hl(ns, "ExecKey", { fg = white, bg = lighten(bg, 10) })

  local tab_bg = state.config.border and bg or lighten(bg, 2)
  api.nvim_set_hl(ns, "ExecTabActive", { fg = white, bg = tab_bg, bold = true })
  api.nvim_set_hl(ns, "ExecTabInactive", { fg = grey, bg = tab_bg })
end
