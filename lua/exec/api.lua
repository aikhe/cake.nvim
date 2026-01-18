local M = {}

local state = require "exec.state"

M.exec_float = function() require("exec.ui").open() end

-- WIP
M.exec_split = function()
  if not state.term_buf or not vim.api.nvim_buf_is_valid(state.term_buf) then
    require("exec.utils").init_term()
  end

  vim.cmd(state.config.split_direction or "split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.term_buf)

  if state.config.split_size then
    vim.cmd("resize " .. state.config.split_size)
  end
end

M.edit_cmds = function()
  state.resetting = true
  require("exec.ui.edit").open()
end

return M
