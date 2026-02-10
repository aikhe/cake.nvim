local api = vim.api
require "volt.highlights"
local volt_utils = require "volt.utils"
local get_hl = volt_utils.get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "cake.state"

local M = {}

M._get_highlights = function()
  return {
    { name = "CakeTitle", link = "Title", desc = "header title" },
    { name = "CakeLabel", link = "Comment", desc = "labels in ui" },
    { name = "CakeKey", link = "Special", desc = "keybind indicators" },
    { name = "CakeTabActive", link = "Title", desc = "active tab" },
    { name = "CakeTabInactive", link = "Comment", desc = "inactive tabs" },
    { name = "CakeSplitNormal", link = "Normal", desc = "split background" },
  }
end

function M.set_colors()
  for _, hl in ipairs(M._get_highlights()) do
    if hl.link then
      vim.api.nvim_set_hl(0, hl.name, { default = true, link = hl.link })
    end
  end
end

local function get_bg()
  if vim.g.base46_cache then
    return dofile(vim.g.base46_cache .. "colors").black
  end
  return get_hl("Normal").bg
end

function M.apply_float(ns)
  local bg = get_bg()
  local win_bg = state.config.border and bg or lighten(bg, 2)
  local text_light = get_hl("Normal").fg
  local commentfg = get_hl("CommentFg").fg
  local exblue = get_hl("ExBlue").fg

  local is_split_border = state.is_split and state.config.border
  local target_namespaces = { ns, state.term_ns }

  for _, target_ns in ipairs(target_namespaces) do
    local normal_bg = is_split_border and "NONE" or win_bg
    local tab_bg = is_split_border and "NONE" or win_bg

    api.nvim_set_hl(target_ns, "Normal", { bg = normal_bg })
    api.nvim_set_hl(target_ns, "CakeTitle", { fg = exblue, bold = true })
    api.nvim_set_hl(target_ns, "CakeLabel", { fg = commentfg })
    api.nvim_set_hl(
      target_ns,
      "CakeKey",
      { fg = text_light, bg = is_split_border and "NONE" or lighten(bg, 10) }
    )
    api.nvim_set_hl(
      target_ns,
      "CakeTabActive",
      { fg = text_light, bg = tab_bg, bold = true }
    )
    api.nvim_set_hl(
      target_ns,
      "CakeTabInactive",
      { fg = commentfg, bg = tab_bg }
    )
  end

  api.nvim_set_hl(0, "CakeNormal", { bg = win_bg, fg = text_light })

  local border_bg = is_split_border and "NONE" or win_bg
  local term_border_fg = state.config.border and lighten(bg, 15) or win_bg

  api.nvim_set_hl(ns, "FloatBorder", { fg = term_border_fg, bg = border_bg })
  api.nvim_set_hl(
    state.term_ns,
    "FloatBorder",
    { fg = term_border_fg, bg = border_bg }
  )
  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })
end

function M.apply_split(win)
  local winhl = "WinSeparator:Normal,VertSplit:Normal"
  vim.api.nvim_set_option_value("winhighlight", winhl, { win = win })
end

function M.apply_help_win(win)
  local prev_winhl =
    vim.api.nvim_get_option_value("winhighlight", { win = win })

  local bg = get_bg()
  local win_bg = state.config.border and bg or lighten(bg, 2)
  local text_light = get_hl("Normal").fg
  api.nvim_set_hl(0, "CakeNormal", { bg = win_bg, fg = text_light })

  vim.api.nvim_set_option_value(
    "winhighlight",
    "Normal:CakeNormal,NormalNC:CakeNormal,SignColumn:CakeNormal,EndOfBuffer:CakeNormal",
    { win = win }
  )
  return prev_winhl
end

return setmetatable(M, {
  __call = function(_, ns) M.apply_float(ns) end,
})
