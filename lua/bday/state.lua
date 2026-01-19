local M = {
  ns = vim.api.nvim_create_namespace "Bday",
  term_ns = vim.api.nvim_create_namespace "BdayTerm",
  xpad = 2,
  w = 50,
  h = 20,
  current_view = "term",

  last_mode = nil,
  cwd = nil,
  resetting = false,
  setup_done = false,

  volt_buf = nil,
  win = nil,

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
    volt_buf = nil,
    volt_win = nil,
    footer_buf = nil,
    footer_win = nil,
  },

  help = {
    buf = nil,
    return_view = nil, -- "term" or "commands"
    prev_buf = nil, -- buffer ID to restore
  },

  config = {

    terminal = "", -- custom terminal e.g. "powershell", "zsh", "cmd"
    border = false,
    size = {
      h = 60,
      w = 50,
    },
    edit_key = "m",
    use_file_dir = false,

    -- WIP
    mode = "float", -- default mode e.g float, split, full
    -- split_direction = "h", -- "v" or "h"
    -- split_size = nil, -- size in lines for split window
    -- bday_at_start = true -- run commands at open
  },
}

M.w_with_pad = M.w - (2 * M.xpad)

return M
