local M = {
  ns = vim.api.nvim_create_namespace "Cake",
  term_ns = vim.api.nvim_create_namespace "CakeTerm",
  xpad = 2,
  w = 50,
  h = 20,
  current_view = "term",

  last_mode = nil,
  cwd = nil,
  resetting = false,
  setup_done = false,

  header = {
    buf = nil,
    win = nil,
  },

  tabs = {}, -- each tab: { id, buf, cwd, commands = {} }
  active_tab = 1,

  term = {
    buf = nil,
    win = nil,
    h = 15,
    job_id = nil,
  },

  container = {
    buf = nil,
    win = nil,
  },

  footer = {
    buf = nil,
    win = nil,
    h = 1,
    cursor_timer = nil,
  },

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

  help = {
    buf = nil,
    return_view = nil, -- "term" or "commands"
    prev_buf = nil, -- buffer ID to restore
  },

  config = {
    terminal = "",
    title = " cake.nvim",
    border = false,
    size = {
      h = 60,
      w = 50,
    },
    use_file_dir = false,

    mappings = {
      edit_commands = "m",
      edit_cwd = ";",
      new_tab = "n",
      rerun = "r",
      kill_tab = "x",
      next_tab = "<C-n>",
      prev_tab = "<C-p>",
    },

    -- WIP
    mode = "float", -- default mode e.g float, split, full
    -- style = "fancy", -- fancy, minimal
    -- split_direction = "h", -- "v" or "h"
    -- split_size = nil, -- size in lines for split window
    -- run_at_start = true -- run commands at open on float & split
  },
}

return M
