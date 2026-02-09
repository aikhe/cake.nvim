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

---@param opts? {mode?: "float"|"splitv"|"splith", reset?: boolean}
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

  if state.last_mode == "splitv" then
    ui.float.close()
    ui.split.close()

    state.split.direction = "splitv"
    state.is_split = true
    ui.split.open "splitv"
  elseif state.last_mode == "splith" then
    ui.float.close()
    ui.split.close()

    state.split.direction = "splith"
    state.is_split = true
    ui.split.open "splith"
  elseif state.last_mode == "float" then
    ui.split.close()
    ui.float.open()
  else
    ui.float.open()
  end

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
  if state.is_split then
    ui.split.close()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      vim.api.nvim_set_current_win(state.prev_win)
    end
    return
  end

  if state.header.win and vim.api.nvim_win_is_valid(state.header.win) then
    ui.float.close()
    if vim.api.nvim_win_is_valid(state.prev_win) then
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

  -- load tabs if empty
  if #state.tabs == 0 then
    local saved = session.load_tabs()
    if #saved > 0 then
      for _, t in ipairs(saved) do
        tabs.create { cwd = t.cwd, commands = t.commands or {} }
      end
    end
  end

  -- resolve target tab (default to active tab or 1)
  local tab_idx = opts.tab or state.active_tab
  if tab_idx < 1 then tab_idx = 1 end

  -- validate tab exists
  if tab_idx > #state.tabs then
    vim.notify("Tab " .. tab_idx .. " does not exist", vim.log.levels.ERROR)
    return
  end

  local tab = state.tabs[tab_idx]

  -- validate tab has commands
  if not tab.commands or #tab.commands == 0 then
    vim.notify("Tab " .. tab_idx .. " has no commands", vim.log.levels.ERROR)
    return
  end

  -- switch to target tab
  state.active_tab = tab_idx
  state.term.buf = tab.buf
  state.cwd = tab.cwd

  -- reset buffer for fresh execution
  terminal.reset_buf()

  -- open in specified mode
  M.open { mode = opts.mode, reset = true }
end

return M
