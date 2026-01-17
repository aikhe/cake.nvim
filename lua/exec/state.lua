local M = {
  ns = vim.api.nvim_create_namespace "Exec",
  term_ns = vim.api.nvim_create_namespace "ExecTerm",
  xpad = 2,
  w = 50,
  h = 20,
  current_view = "term", -- "term" or "commands"

  last_mode = nil,
  cwd = nil,
  resetting = false, -- Flag to prevent cleanup when intentionally reloading UI

  volt_buf = nil, -- Main UI buffer
  win = nil, -- Main UI window

  -- Tab management
  -- Each tab: { id, buf, cwd, commands = {} }
  tabs = {},
  active_tab = 1, -- Current active tab index

  -- Terminal state (current active terminal)
  term_buf = nil,
  term_win = nil,
  container_win = nil, -- Outer container for padding
  container_buf = nil,
  term_h = 15,

  -- Footer state
  footer_buf = nil,
  footer_win = nil,
  footer_h = 1,
  cursor_timer = nil,

  -- Edit UI state
  edit_buf = nil,
  edit_win = nil,
  edit_container_buf = nil,
  edit_container_win = nil,
  edit_volt_buf = nil,
  edit_volt_win = nil,
  edit_footer_buf = nil,
  edit_footer_win = nil,

  job_id = nil, -- current terminal job ID

  config = {
    mode = "float", -- default mode e.g float, split, full
    mapping = true,
    border = false, -- false = invisible border (using colors as padding), true = visible border
    size = {
      h = 60,
      w = 50,
    },
    split_direction = "split", -- "split" or "vsplit"
    split_size = nil, -- size in lines for split window

    terminal = "", -- custom terminal (e.g. "pwsh", "zsh", "cmd")
    edit_key = "p", -- key to edit commands
    use_file_dir = false, -- use current file directory instead of CWD
  },
}

M.w_with_pad = M.w - (2 * M.xpad)

return M
