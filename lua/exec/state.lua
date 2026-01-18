local M = {
  ns = vim.api.nvim_create_namespace "Exec",
  term_ns = vim.api.nvim_create_namespace "ExecTerm",
  xpad = 2,
  w = 50,
  h = 20,
  current_view = "term", -- "term" or "commands"

  last_mode = nil,
  cwd = nil,
  resetting = false, -- flag to prevent cleanup when intentionally reloading UI

  volt_buf = nil, -- main UI buffer
  win = nil, -- main UI window

  tabs = {}, -- each tab: { id, buf, cwd, commands = {} }
  active_tab = 1,

  -- current active terminal
  term_buf = nil,
  term_win = nil,

  container_win = nil, -- outer container for padding
  container_buf = nil,
  term_h = 15,

  footer_buf = nil,
  footer_win = nil,
  footer_h = 1,
  cursor_timer = nil,

  edit_buf = nil,
  edit_win = nil,
  edit_container_buf = nil,
  edit_container_win = nil,
  edit_volt_buf = nil,
  edit_volt_win = nil,
  edit_footer_buf = nil,
  edit_footer_win = nil,

  help_buf = nil,
  help_return_view = nil, -- "term" or "commands"
  help_prev_buf = nil, -- buffer ID to restore

  job_id = nil, -- current terminal job ID

  -- WIP
  config = {
    mode = "float", -- default mode e.g float, split, full
    mapping = true,
    border = false,
    size = {
      h = 60,
      w = 50,
    },
    split_direction = "split", -- "split" or "vsplit"
    split_size = nil, -- size in lines for split window

    terminal = "", -- custom terminal e.g. "pwsh", "zsh", "cmd"
    edit_key = "p",
    use_file_dir = false,
  },
}

return M
