local config = require "cake.config"

---@type CakeState
local M = {
  ns = vim.api.nvim_create_namespace "Cake",
  term_ns = vim.api.nvim_create_namespace "CakeTerm",
  xpad = 2,
  ypad = -2,
  split_ypad = 1,
  w = 50,
  h = 20,
  current_view = "term",

  last_mode = nil,
  is_split = false,
  split = {
    direction = nil,
    last_sizes = {
      splith = nil,
      splitv = nil,
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
