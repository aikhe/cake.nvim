local M = {}

local state = require "exec.state"

---Opens a floating terminal window with exec.nvim using Volt UI
M.exec_float = function()
  require("exec.ui").open()
end

---Opens the terminal in a split window
M.exec_split = function()
  if not state.term_buf or not vim.api.nvim_buf_is_valid(state.term_buf) then
    require("exec.utils").new_term()
  end

  vim.cmd(state.config.split_direction or "split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.term_buf)

  if state.config.split_size then
    vim.cmd("resize " .. state.config.split_size)
  end
end

---Opens a Volt-powered floating window to edit the current list of commands
M.edit_cmds = function()
  state.resetting = true
  require("exec.ui.edit").open()
end

return M
