local M = {}

local state = require "exec.state"
local utils = require "exec.utils"

M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})

  if state.mapping then require "exec.mappings"() end
end

M.open = function(mode)
  state.mode = mode or state.mode or "float"
  state.prev_win = vim.api.nvim_get_current_win()
  state.buf = state.buf or vim.api.nvim_create_buf(false, true)

  if state.mode == "float" then
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
  else
    vim.cmd(state.config.split_direction or "split")
    state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win, state.buf)
    if state.config.split_size then vim.cmd("resize " .. state.config.split_size) end
  end

  utils.exec_in_buf(state.buf, state.config.cmd)
end

M.toggle = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
    if vim.api.nvim_win_is_valid(state.prev_win) then vim.api.nvim_set_current_win(state.prev_win) end
    state.win = nil
  else
    M.open()
  end
end

return M
