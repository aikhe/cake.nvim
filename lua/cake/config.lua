local M = {}

---@type CakeConfig
M.defaults = {
  terminal = "",
  title = " cake.nvim",
  border = false,
  use_file_dir = false,

  mode = "float",
  size = { h = 60, w = 50 },
  split = { w = 50, h = 25 },

  mappings = {
    new_tab = "n",
    edit_commands = "m",
    edit_cwd = ";",
    rerun = "r",
    kill_tab = "x",
    next_tab = "<C-n>",
    prev_tab = "<C-p>",
    esc_esc = true,
  },
}

return M
