local M = {
  last_mode = nil,
  commands = {},
  cwd = nil,
  edit_win = nil, -- command editor window ID
  job_id = nil, -- current terminal job ID

  config = {
    mode = "float", -- default mode e.g float, split, full
    mapping = true,

    border = "single", -- e.g single, double, none
    size = {
      h = 50,
      w = 50,
    },
    split_direction = "split", -- "split" or "vsplit"
    split_size = nil, -- size in lines for split window

    terminal = "", -- custom terminal (e.g. "pwsh", "zsh", "cmd")
    edit_key = "p", -- key to edit commands
  },
}

return M
