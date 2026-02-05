---@class CakeTab
---@field id number tab identifier
---@field buf number buffer handle
---@field cwd string working directory
---@field commands string[] list of commands

---@class CakeWindowState
---@field buf number|nil buffer handle
---@field win number|nil window handle

---@class CakeHeaderState : CakeWindowState

---@class CakeTermState : CakeWindowState
---@field h number height
---@field job_id number|nil job id
---@field container_win number|nil container window handle (for split mode)
---@field container_buf number|nil container buffer handle (for split mode)

---@class CakeFooterState : CakeWindowState
---@field h number height
---@field cursor_timer userdata|nil timer for cursor updates

---@class CakeEditState : CakeWindowState
---@field container_buf number|nil
---@field container_win number|nil
---@field header_buf number|nil
---@field header_win number|nil
---@field footer_buf number|nil
---@field footer_win number|nil

---@class CakeHelpState
---@field buf number|nil
---@field return_view "term"|"commands"|nil
---@field prev_buf number|nil

---@class CakeSplitState
---@field direction "horizontal"|"vertical"|nil
---@field last_sizes { horizontal: number|nil, vertical: number|nil }

local config = require "cake.config"

---@class CakeState
---@field ns number namespace for UI highlights
---@field term_ns number namespace for terminal highlights
---@field xpad number horizontal padding
---@field ypad number vertical padding (floating)
---@field split_ypad number vertical padding (split mode)
---@field w number current layout width
---@field h number current layout height
---@field current_view "term"|"commands"|"edit"|"help" current active view
---@field last_mode string|nil last nvim mode
---@field is_split boolean whether we are in split mode
---@field split CakeSplitState split specific state
---@field cwd string|nil current working directory
---@field resetting boolean flags to prevent loops during reset
---@field setup_done boolean whether setup has been called
---@field prev_win number|nil window handle before opening cake
---@field mask_win number|nil window handle for split separator mask
---@field header CakeHeaderState
---@field tabs CakeTab[]
---@field active_tab number index of the active tab
---@field term CakeTermState
---@field container CakeWindowState main container window
---@field footer CakeFooterState
---@field edit CakeEditState
---@field cwd_edit CakeEditState
---@field help CakeHelpState
---@field config CakeConfig merged configuration

---@type CakeState
local M = {
  ns = vim.api.nvim_create_namespace "Cake",
  term_ns = vim.api.nvim_create_namespace "CakeTerm",
  xpad = 2,
  ypad = 0,
  split_ypad = 1,
  w = 50,
  h = 20,
  current_view = "term",

  last_mode = nil,
  is_split = false,
  split = {
    direction = nil, -- horizontal or vertical
    last_sizes = {
      horizontal = nil, -- width for vsplit (side-by-side)
      vertical = nil, -- height for split (stacked)
    },
  },
  cwd = nil,
  resetting = false,
  setup_done = false,
  prev_win = nil,
  mask_win = nil,

  ---@type CakeHeaderState
  header = {
    buf = nil,
    win = nil,
  },

  ---@type CakeTab[]
  tabs = {},
  active_tab = 1,

  ---@type CakeTermState
  term = {
    buf = nil,
    win = nil,
    container_win = nil,
    container_buf = nil,
    h = 15,
    job_id = nil,
  },

  ---@type CakeWindowState
  container = {
    buf = nil,
    win = nil,
  },

  ---@type CakeFooterState
  footer = {
    buf = nil,
    win = nil,
    h = 1,
    cursor_timer = nil,
  },

  ---@type CakeEditState
  edit = {
    buf = nil,
    win = nil,
    container_buf = nil,
    container_win = nil,
    header_buf = nil,
    header_win = nil,
    footer_buf = nil,
    footer_win = nil,
  },

  ---@type CakeEditState
  cwd_edit = {
    buf = nil,
    win = nil,
    container_buf = nil,
    container_win = nil,
    header_buf = nil,
    header_win = nil,
    footer_buf = nil,
    footer_win = nil,
  },

  ---@type CakeHelpState
  help = {
    buf = nil,
    return_view = nil,
    prev_buf = nil,
  },

  ---@type CakeConfig
  config = vim.deepcopy(config.defaults),
}

return M
