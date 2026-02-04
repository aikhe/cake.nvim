local api = vim.api
local volt_utils = require "volt.utils"
local get_hl = volt_utils.get_hl
local lighten = require("volt.color").change_hex_lightness
local state = require "cake.state"

local M = {}

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

  local target_namespaces = { ns, state.term_ns }

  for _, target_ns in ipairs(target_namespaces) do
    api.nvim_set_hl(target_ns, "Normal", { bg = win_bg })
    api.nvim_set_hl(target_ns, "CakeTitle", { fg = exblue, bold = true })
    api.nvim_set_hl(target_ns, "CakeLabel", { fg = commentfg })
    api.nvim_set_hl(
      target_ns,
      "CakeKey",
      { fg = text_light, bg = lighten(bg, 10) }
    )
  end

  local term_border_fg = state.config.border and lighten(bg, 15) or win_bg
  local header_border_fg = state.config.border and text_light or win_bg

  api.nvim_set_hl(ns, "FloatBorder", { fg = header_border_fg, bg = win_bg })
  api.nvim_set_hl(
    state.term_ns,
    "FloatBorder",
    { fg = term_border_fg, bg = win_bg }
  )
  api.nvim_set_hl(state.term_ns, "FoldColumn", { bg = "NONE" })

  api.nvim_set_hl(
    ns,
    "CakeTabActive",
    { fg = text_light, bg = win_bg, bold = true }
  )
  api.nvim_set_hl(ns, "CakeTabInactive", { fg = commentfg, bg = win_bg })
end

function M.apply_split(win)
  local bg = get_bg()
  local win_bg = lighten(bg, 2)

  -- set window-local highlights
  vim.api.nvim_win_set_option(
    win,
    "winhighlight",
    "Normal:CakeSplitNormal,WinSeparator:Normal,VertSplit:Normal"
  )

  -- define highlight groups
  api.nvim_set_hl(0, "CakeSplitNormal", { bg = win_bg })

  -- legacy: separators use normal directly
end

-- backward compatibility
return setmetatable(M, {
  __call = function(_, ns) M.apply_float(ns) end,
})
