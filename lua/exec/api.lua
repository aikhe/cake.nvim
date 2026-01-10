local M = {}

local state = require "exec.state"

M.exec_float = function()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    require("exec.utils").new_term()
  end

  local conf = state.config
  local h = math.floor(vim.o.lines * (conf.size.h / 100))
  local w = math.floor(vim.o.columns * (conf.size.w / 100))

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row = (vim.o.lines - h) / 2 - 1,
    col = (vim.o.columns - w) / 2,
    width = w,
    height = h,
    style = "minimal",
    border = conf.border,
  })

  vim.cmd "stopinsert"
end

M.exec_split = function()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    require("exec.utils").new_term()
  end

  vim.cmd(state.config.split_direction or "split")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  if state.config.split_size then
    vim.cmd("resize " .. state.config.split_size)
  end

  vim.cmd "stopinsert"
end

return M
