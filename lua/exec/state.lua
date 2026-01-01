local M = {
  mapping = true,
  mode = "float", -- default mode e.g float, split, full

  config = {
    border = "single", -- e.g single, double, none
    size = {
      h = 50, -- height percentage
      w = 50, -- width percentage
    },
    cmd = nil, -- command to execute (nil = open shell)
    split_direction = "split", -- "split" or "vsplit"
    split_size = nil, -- size in lines for split window
    terminal = "powershell", -- custom terminal (e.g. "pwsh", "zsh", "cmd")
  },
}

return M
