local M = {}

local api = require "exec.api"
local state = require "exec.state"
local utils = require "exec.utils"

M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})

  if state.config.mapping then require "exec.mappings"() end
end

M.open = function(opts)
  opts = opts or {}
  state.last_mode = opts.mode or state.last_mode or state.config.mode

  if opts.reset then
    utils.reset_buf()
  end

  state.prev_win = vim.api.nvim_get_current_win()
  utils.new_term()

  if state.last_mode == "float" then
    api.exec_float()
  else
    api.exec_split()
  end
end

M.toggle = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)

    if vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end

    state.win = nil
  else
    M.open { mode = state.last_mode }
  end
end

return M
