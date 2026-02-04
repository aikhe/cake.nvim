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

  -- close split if active
  if state.is_split then
    require("cake.ui.split").close()
  end

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

local function close_float()
  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    require("volt").close(state.header.buf)
  end
end

function M.toggle()
  -- handle split mode: close and remember direction
  if state.is_split then
    require("cake.ui.split").close()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
    return
  end

  -- handle float mode
  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    close_float()
    if vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
    return
  end

  -- reopen last mode
  if state.split_direction then
    -- reopen split with last direction
    state.prev_win = vim.api.nvim_get_current_win()
    state.cwd = require("cake.utils").get_context_cwd()
    state.is_split = true
    require("cake.ui.split").open(state.split_direction)
  else
    M.open { mode = state.last_mode }
  end
end

function M.open_float()
  state.split_direction = nil
  M.open { mode = "float", reset = true }
end

function M.open_split_h()
  close_float()
  state.prev_win = vim.api.nvim_get_current_win()
  state.cwd = require("cake.utils").get_context_cwd()
  state.is_split = true
  state.split_direction = "horizontal"
  require("cake.ui.split").open("horizontal")
end

function M.open_split_v()
  close_float()
  state.prev_win = vim.api.nvim_get_current_win()
  state.cwd = require("cake.utils").get_context_cwd()
  state.is_split = true
  state.split_direction = "vertical"
  require("cake.ui.split").open("vertical")
end

return M
