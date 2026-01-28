local M = {}

local state = require "cake.state"
local config = require "cake.config"
local utils = require "cake.utils"

---@param opts CakeConfig?
function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", config.defaults, opts or {})
  state.setup_done = true
end

---@param opts? {mode?: "float"|"split", reset?: boolean}
function M.open(opts)
  opts = opts or {}
  state.last_mode = opts.mode or state.last_mode or state.config.mode

  if opts.reset then require("cake.core.terminal").reset_buf() end

  local volt = require "volt"
  if
    state.edit.header_buf and vim.api.nvim_buf_is_valid(state.edit.header_buf)
  then
    volt.close(state.edit.header_buf)
  end
  if
    state.cwd_edit.header_buf
    and vim.api.nvim_buf_is_valid(state.cwd_edit.header_buf)
  then
    volt.close(state.cwd_edit.header_buf)
  end
  if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
    volt.close(state.header.buf)
  end

  if not opts.reset then state.cwd = utils.get_context_cwd() end

  state.prev_win = vim.api.nvim_get_current_win()

  require("cake.ui").open()

  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(state.header.win),
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

function M.toggle()
  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    require("volt").close(state.header.buf)

    if vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
  else
    M.open { mode = state.last_mode }
  end
end

function M.open_float() M.open { mode = "float", reset = true } end

return M
