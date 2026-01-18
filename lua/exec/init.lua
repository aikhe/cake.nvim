local M = {}

local api = require "exec.api"
local state = require "exec.state"
local utils = require "exec.utils"

---@param opts table? configuration options
M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})
  state.setup_done = true
end

---@param opts table? { mode: 'float'|'split', reset: boolean }
M.open = function(opts)
  opts = opts or {}
  state.last_mode = opts.mode or state.last_mode or state.config.mode

  if opts.reset then utils.reset_buf() end

  if state.edit.volt_buf and vim.api.nvim_buf_is_valid(state.edit.volt_buf) then
    require("volt").close(state.edit.volt_buf)
  end

  if state.volt_buf and vim.api.nvim_buf_is_valid(state.volt_buf) then
    require("volt").close(state.volt_buf)
  end

  if not opts.reset then state.cwd = utils.get_context_cwd() end

  state.prev_win = vim.api.nvim_get_current_win()

  if state.last_mode == "float" then
    api.exec_float()
  else
    api.exec_split()
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(state.win),
      once = true,

      callback = function()
        if state.edit.win and vim.api.nvim_win_is_valid(state.edit.win) then
          vim.api.nvim_win_close(state.edit.win, true)
        end

        state.edit.win = nil
      end,
    })
  end

  state.resetting = false
end

M.toggle = function()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    require("volt").close(state.volt_buf)

    if vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
  else
    M.open { mode = state.last_mode }
  end
end

M.open_float = function() M.open { mode = "float", reset = true } end

M.open_split = function() M.open { mode = "split", reset = true } end

return M
