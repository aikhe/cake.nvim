local api = vim.api
local volt_utils = require "volt.utils"
local get_hl = volt_utils.get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "bday.state"

return function(ns)
  local bg
  if vim.g.base46_cache then
    bg = dofile(vim.g.base46_cache .. "colors").black
  else
    bg = get_hl("Normal").bg
  end

  local win_bg = state.config.border and bg or lighten(bg, 2)
  local text_light = get_hl("Normal").fg
  local commentfg = get_hl("CommentFg").fg
  local exblue = get_hl("ExBlue").fg

  local target_namespaces = { ns, state.term_ns }

  for _, target_ns in ipairs(target_namespaces) do
    api.nvim_set_hl(target_ns, "Normal", { bg = win_bg })
    api.nvim_set_hl(target_ns, "BdayHeaderBorder", { fg = win_bg, bg = win_bg })

    api.nvim_set_hl(target_ns, "BdayTitle", { fg = exblue, bold = true })
    api.nvim_set_hl(target_ns, "BdayLabel", { fg = commentfg })
    api.nvim_set_hl(
      target_ns,
      "BdayKey",
      { fg = text_light, bg = lighten(bg, 10) }
    )
  end

  local term_border_fg = state.config.border and lighten(bg, 15) or win_bg
  api.nvim_set_hl(ns, "FloatBorder", { fg = win_bg, bg = win_bg })
  api.nvim_set_hl(
    state.term_ns,
    "FloatBorder",
    { fg = term_border_fg, bg = win_bg }
  )
  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  api.nvim_set_hl(
    ns,
    "BdayTabActive",
    { fg = text_light, bg = win_bg, bold = true }
  )
  api.nvim_set_hl(ns, "BdayTabInactive", { fg = commentfg, bg = win_bg })
end
