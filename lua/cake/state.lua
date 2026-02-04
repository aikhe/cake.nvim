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

local config = require "cake.config"

---@class CakeState
local M = {
  ns = vim.api.nvim_create_namespace "Cake",
  term_ns = vim.api.nvim_create_namespace "CakeTerm",
  xpad = 2,
  ypad = 0,
  w = 50,
  h = 20,
  current_view = "term",

  last_mode = nil,
  cwd = nil,
  resetting = false,
  setup_done = false,
  prev_win = nil,

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
