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

  if opts.reset then utils.reset_buf() end

  if state.edit_volt_buf and vim.api.nvim_buf_is_valid(state.edit_volt_buf) then
    require("volt").close(state.edit_volt_buf)
  end

  if state.volt_buf and vim.api.nvim_buf_is_valid(state.volt_buf) then
    require("volt").close(state.volt_buf)
  end

  local current_file = vim.fn.expand "%:p"
  if current_file ~= "" then
    state.cwd = vim.fn.fnamemodify(current_file, ":h")
  else
    state.cwd = vim.fn.getcwd()
  end

  print(state.cwd)

  state.prev_win = vim.api.nvim_get_current_win()
  utils.new_term()

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
        if state.edit_win and vim.api.nvim_win_is_valid(state.edit_win) then
          vim.api.nvim_win_close(state.edit_win, true)
        end

        state.edit_win = nil
      end,
    })
  end
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

return M
