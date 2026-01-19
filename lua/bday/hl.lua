local api = vim.api
local volt_utils = require "volt.utils"
local get_hl = volt_utils.get_hl
local mix = require("volt.color").mix
local lighten = require("volt.color").change_hex_lightness
local state = require "bday.state"

return function(ns)
  local bg
  if vim.g.base46_cache then
    bg = dofile(vim.g.base46_cache .. "colors").black
  else
    bg = get_hl("Normal").bg
  end

  local transparent = not bg
  if transparent then bg = "#000000" end

  local border_content = lighten(bg, 15)
  local white = get_hl("Normal").fg
  local commentfg = get_hl("CommentFg").fg
  local exblue = get_hl("ExBlue").fg

  if state.config.border then
    api.nvim_set_hl(ns, "Normal", { bg = bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = white, bg = bg })
    api.nvim_set_hl(ns, "BdayHeaderBorder", { fg = white, bg = bg })

    api.nvim_set_hl(state.term_ns, "Normal", { bg = bg })
    api.nvim_set_hl(
      state.term_ns,
      "FloatBorder",
      { fg = border_content, bg = bg }
    )
  else
    local window_bg = lighten(bg, 2)
    api.nvim_set_hl(ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(ns, "FloatBorder", { fg = window_bg, bg = window_bg })
    api.nvim_set_hl(ns, "BdayHeaderBorder", { fg = window_bg, bg = window_bg })

    api.nvim_set_hl(state.term_ns, "Normal", { bg = window_bg })
    api.nvim_set_hl(
      state.term_ns,
      "FloatBorder",
      { fg = window_bg, bg = window_bg }
    )
  end

  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  local function set_shared(target_ns)
    api.nvim_set_hl(target_ns, "BdayTitle", { fg = exblue, bold = true })
    api.nvim_set_hl(target_ns, "BdayLabel", { fg = commentfg })
    api.nvim_set_hl(target_ns, "BdayKey", { fg = white, bg = lighten(bg, 10) })
  end

  set_shared(ns)
  set_shared(state.term_ns)

  local tab_bg_active = state.config.border and bg or lighten(bg, 2)
  local tab_bg_inactive = state.config.border and bg or lighten(bg, 2)

  api.nvim_set_hl(
    ns,
    "BdayTabActive",
    { fg = white, bg = tab_bg_active, bold = true }
  )
  api.nvim_set_hl(
    ns,
    "BdayTabInactive",
    { fg = commentfg, bg = tab_bg_inactive }
  )
end
