local state = require "cake.state"
local config = require "cake.config"
local utils = require "cake.utils"
local ui = require "cake.ui"

local M = {}

---@param opts CakeConfig?
function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", config.defaults, opts or {})
  state.setup_done = true

  require("cake.ui.highlights").set_colors()

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function() require("cake.ui.highlights").set_colors() end,
  })
end

-- close any open volt edit/header buffers (for cleanup)
local function close_volt_bufs()
  local volt = require "volt"
  for _, buf in ipairs {
    state.edit.header_buf,
    state.cwd_edit.header_buf,
    state.header.buf,
  } do
    if buf and vim.api.nvim_buf_is_valid(buf) then volt.close(buf) end
  end
end

---@param opts? {mode?: "float"|"splitv"|"splith", reset?: boolean}
function M.open(opts)
  opts = opts or {}

  state.last_mode = opts.mode or state.last_mode or state.config.mode

  if opts.reset then require("cake.core.terminal").reset_buf() end

  close_volt_bufs()

  if not opts.reset then state.cwd = utils.get_context_cwd() end

  state.prev_win = vim.api.nvim_get_current_win()

  ui.win.close()
  ui.win.open(state.last_mode)

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
end

function M.toggle()
  if
    state.is_split
    or (state.header.win and vim.api.nvim_win_is_valid(state.header.win))
  then
    ui.win.close()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
    return
  end

  M.open { mode = state.last_mode or state.config.mode }
end

---@param opts? {tab?: number, mode?: "float"|"splitv"|"splith"}
function M.run(opts)
  opts = opts or {}
  local terminal = require "cake.core.terminal"
  local session = require "cake.core.session"
  local tabs = require "cake.core.tabs"

  if #state.tabs == 0 then
    local saved = session.load_tabs()
    if #saved > 0 then
      for _, t in ipairs(saved) do
        tabs.create { cwd = t.cwd, commands = t.commands or {} }
      end
    end
  end

  local tab_idx = opts.tab or state.active_tab
  if tab_idx < 1 then tab_idx = 1 end

  if tab_idx > #state.tabs then
    vim.notify("Tab " .. tab_idx .. " does not exist", vim.log.levels.ERROR)
    return
  end

  local tab = state.tabs[tab_idx]

  if not tab.commands or #tab.commands == 0 then
    vim.notify("Tab " .. tab_idx .. " has no commands", vim.log.levels.ERROR)
    return
  end

  state.active_tab = tab_idx
  state.term.buf = tab.buf
  state.cwd = tab.cwd

  terminal.reset_buf()

  M.open { mode = opts.mode, reset = true }
end

return M
