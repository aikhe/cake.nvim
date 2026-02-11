local state = require "cake.state"
local highlights = require "cake.ui.highlights"

local M = {}

-- shared init: highlights, terminal, guard
local function init_common()
  local terminal = require "cake.core.terminal"

  require "volt.highlights"
  require "cake.ui.highlights"(state.ns)

  state.current_view = "term"
  terminal.init()

  return state.term.buf ~= nil
end

---@param mode? "float"|"splitv"|"splith"
function M.open(mode)
  mode = mode or "float"

  if not init_common() then return end

  if mode == "splitv" or mode == "splith" then
    require("cake.ui.split").open(mode)
  else
    require("cake.ui.float").open()
  end

  vim.schedule(function()
    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_set_current_win(state.term.win)
    end
  end)

  state.resetting = false
end

function M.close()
  if state.is_split then
    -- persist terminal buffer before closing
    if state.term.buf and vim.api.nvim_buf_is_valid(state.term.buf) then
      vim.api.nvim_set_option_value(
        "bufhidden",
        "hide",
        { buf = state.term.buf }
      )
    end

    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_win_close(state.term.win, true)
    elseif state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
      vim.api.nvim_win_close(state.header.win, true)
    elseif
      state.term.container_win
      and vim.api.nvim_win_is_valid(state.term.container_win)
    then
      vim.api.nvim_win_close(state.term.container_win, true)
    end
  else
    if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
      require("volt").close(state.header.buf)
    end
  end
end

---navigate from the split container
---@param direction "h"|"j"|"k"|"l"
function M.navigate(direction)
  if
    not state.term.container_win
    or not vim.api.nvim_win_is_valid(state.term.container_win)
  then
    vim.cmd("wincmd " .. direction)
    return
  end

  local current_float = vim.api.nvim_get_current_win()

  vim.api.nvim_set_current_win(state.term.container_win)
  vim.cmd("wincmd " .. direction)

  -- didn't move (hit edge), restore focus to float
  local new_win = vim.api.nvim_get_current_win()
  if new_win == state.term.container_win then
    vim.api.nvim_set_current_win(current_float)
  end
end

return M
