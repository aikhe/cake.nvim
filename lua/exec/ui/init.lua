local voltui = require "volt.ui"
local state = require "exec.state"
local utils = require "exec.utils"

local M = {}

M.title = function()
  local width = state.w - (state.xpad * 2) - 4
  local term_hl = state.current_tab == "term" and "ExecTabActive" or "ExecTabInactive"
  local cmds_hl = state.current_tab == "commands" and "ExecTabActive" or "ExecTabInactive"

  local line = {
    { "  ", "ExecAccent" },
    { "Exec  ", "ExecTitle" },
    { " Term ", term_hl, {
      click = function()
        -- Already on term tab, maybe just refresh or do nothing
      end
    } },
    { "  ", "" },
    { " Commands ", cmds_hl, {
      click = function()
        vim.cmd("stopinsert")
        vim.schedule(function()
          state.current_tab = "commands"
          require("exec.api").edit_cmds()
        end)
      end
    } },
  }

  local lines = { voltui.hpad(line, width) }
  voltui.border(lines)
  return lines
end

M.separator = function()
  return {
    {
      { string.rep("─", state.w - (state.xpad * 2)), "ExecLabel" },
    },
  }
end

M.footer = function()
  local width = state.w - (state.xpad * 2)
  local key = function(char) return { " " .. char .. " ", "ExecKey" } end
  local txt = function(str) return { str, "ExecLabel" } end

  local line = {
    key "ESC",
    txt " Close  ",
    key "r",
    txt " Reset  ",
    { "_pad_", "" },
    key "p",
    txt " Edit  ",
  }

  return { voltui.hpad(line, width) }
end

M.open = function()
  local volt = require "volt"
  state.current_tab = "term"
  -- 1. Create Volt buffer and generate layout to get height
  state.volt_buf = vim.api.nvim_create_buf(false, true)
  local layout = require "exec.ui.layout"

  volt.gen_data {
    {
      buf = state.volt_buf,
      layout = layout,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  state.h = require("volt.state")[state.volt_buf].h

  -- 2. Calculate total height
  -- Total height = Volt window height + border + Terminal height + border + Footer height + border
  local border_h = 2
  local total_h = state.h + border_h + state.term_h + border_h + state.footer_h + border_h
  local start_row = math.floor((vim.o.lines - total_h) / 2)

  -- 3. Create Volt window (Header)
  local main_opts = {
    relative = "editor",
    width = state.w,
    height = state.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row,
    style = "minimal",
    border = "single",
  }

  state.win = vim.api.nvim_open_win(state.volt_buf, false, main_opts)

  -- 4. Apply highlights
  require("exec.ui.hl")(state.ns)
  vim.api.nvim_win_set_hl_ns(state.win, state.ns)

  -- 5. Handle Terminal
  if not state.term_buf or not vim.api.nvim_buf_is_valid(state.term_buf) then
    state.term_buf = vim.api.nvim_create_buf(false, true)
  end

  local term_opts = {
    relative = "editor",
    width = state.w,
    height = state.term_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + state.h + border_h,
    style = "minimal",
    border = "single",
  }

  state.term_win = vim.api.nvim_open_win(state.term_buf, true, term_opts)
  vim.api.nvim_win_set_hl_ns(state.term_win, state.term_ns)
  vim.api.nvim_set_current_win(state.term_win)

  -- 6. Create Footer window
  state.footer_buf = vim.api.nvim_create_buf(false, true)
  local footer_layout = require "exec.ui.footer_layout"

  volt.gen_data {
    {
      buf = state.footer_buf,
      layout = footer_layout,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local footer_opts = {
    relative = "editor",
    width = state.w,
    height = state.footer_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + state.h + border_h + state.term_h + border_h,
    style = "minimal",
    border = "single",
  }

  state.footer_win = vim.api.nvim_open_win(state.footer_buf, false, footer_opts)
  vim.api.nvim_win_set_hl_ns(state.footer_win, state.ns)

  require("volt.events").add { state.volt_buf, state.footer_buf }

  volt.run(state.footer_buf, {
    h = state.footer_h,
    w = state.w,
  })

  -- Start terminal job if not already running
  if vim.bo[state.term_buf].buftype ~= "terminal" then
    utils.exec_in_buf(state.term_buf, state.commands, state.config.terminal, state.cwd)
  end

  -- 7. Setup Volt Mappings for cleanup
  -- We remove state.term_buf from here to prevent volt.close from deleting it
  volt.mappings {
    bufs = { state.volt_buf, state.footer_buf },
    winclosed_event = true,
    after_close = function()
      local function safe_close(win)
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end

      safe_close(state.win)
      state.win = nil
      state.volt_buf = nil

      safe_close(state.term_win)
      state.term_win = nil
      -- Keep state.term_buf to persist its state
      -- state.term_buf = nil 

      safe_close(state.footer_win)
      state.footer_win = nil
      state.footer_buf = nil
    end,
  }

  -- 8. Add mappings to term buffer to close UI since it's no longer in volt.mappings
  local term_opts = { buffer = state.term_buf, silent = true }
  vim.keymap.set("n", "q", function() volt.close(state.volt_buf) end, term_opts)
  vim.keymap.set("n", "<Esc>", function() volt.close(state.volt_buf) end, term_opts)

  -- 9. Finalize Volt UI (Main window)
  volt.run(state.volt_buf, {
    h = state.h,
    w = state.w,
  })
  
  vim.schedule(function()
    if state.term_win and vim.api.nvim_win_is_valid(state.term_win) then
      vim.api.nvim_set_current_win(state.term_win)
    end
  end)
end

return M
