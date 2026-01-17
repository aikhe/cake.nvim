local volt = require "volt"
local voltui = require "volt.ui"
local state = require "exec.state"
local utils = require "exec.utils"

local M = {}

M.open = function()
  state.current_view = "commands"
  vim.cmd("stopinsert")
  
  -- If terminal UI is open, close it first to avoid clutter
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    volt.close(state.volt_buf)
  end

  -- 1. Create Header
  local layout = require "exec.ui.layout"
  state.edit_volt_buf = vim.api.nvim_create_buf(false, true)
  
  volt.gen_data {
    {
      buf = state.edit_volt_buf,
      layout = layout.edit_header_layout,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local header_h = require("volt.state")[state.edit_volt_buf].h
  local border_h = 2
  local total_h = header_h + border_h + state.term_h + border_h + state.footer_h + border_h
  local start_row = math.floor((vim.o.lines - total_h) / 2)

  local header_opts = {
    relative = "editor",
    width = state.w,
    height = header_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row,
    style = "minimal",
    border = "single",
  }
  state.edit_volt_win = vim.api.nvim_open_win(state.edit_volt_buf, false, header_opts)
  vim.api.nvim_win_set_hl_ns(state.edit_volt_win, state.ns)

  -- 2. Create/Reuse the actual Text Buffer (Editor)
  if not state.edit_buf or not vim.api.nvim_buf_is_valid(state.edit_buf) then
    state.edit_buf = vim.api.nvim_create_buf(false, true)
    -- Check if name is taken, if so, just use what it has or ignore
    pcall(vim.api.nvim_buf_set_name, state.edit_buf, "Exec Commands Edit")
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.edit_buf })
  end
  
  -- Load current tab's commands
  local tab = state.tabs[state.active_tab]
  local cmds = (tab and tab.commands) or {}
  vim.api.nvim_buf_set_lines(state.edit_buf, 0, -1, false, cmds)
  vim.api.nvim_set_option_value("modified", false, { buf = state.edit_buf })

  local editor_opts = {
    relative = "editor",
    width = state.w,
    height = state.term_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h,
    style = "minimal",
    border = "single",
  }
  state.edit_win = vim.api.nvim_open_win(state.edit_buf, true, editor_opts)
  -- Use term namespace for background consistency
  vim.api.nvim_win_set_hl_ns(state.edit_win, state.term_ns)

  -- 3. Create Footer
  state.edit_footer_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.edit_footer_buf,
      layout = layout.edit_footer_layout,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local footer_opts = {
    relative = "editor",
    width = state.w,
    height = state.footer_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h + state.term_h + border_h,
    style = "minimal",
    border = "single",
  }
  state.edit_footer_win = vim.api.nvim_open_win(state.edit_footer_buf, false, footer_opts)
  vim.api.nvim_win_set_hl_ns(state.edit_footer_win, state.ns)

  require("volt.events").add { state.edit_volt_buf, state.edit_footer_buf }

  -- Set focus to the editor window
  vim.schedule(function()
    if state.edit_win and vim.api.nvim_win_is_valid(state.edit_win) then
      vim.api.nvim_set_current_win(state.edit_win)
    end
  end)

  -- 4. Apply Volt run for highlights
  volt.run(state.edit_volt_buf, { h = header_h, w = state.w })
  volt.run(state.edit_footer_buf, { h = state.footer_h, w = state.w })

  -- 5. Cleanup logic
  local function close_all()
    local function sc(w) if w and vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end end
    sc(state.edit_volt_win)
    sc(state.edit_win)
    sc(state.edit_footer_win)
    state.edit_volt_win = nil
    state.edit_win = nil
    state.edit_footer_win = nil
    state.edit_volt_buf = nil
    -- state.edit_buf = nil (Persist this buffer)
    state.edit_footer_buf = nil
  end

  volt.mappings {
    bufs = { state.edit_volt_buf, state.edit_footer_buf },
    winclosed_event = true,
    after_close = close_all,
  }

  -- Ghost window fix: Close UI if edit window is closed via :q
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.edit_win),
    once = true,
    callback = function()
      if state.resetting then return end
      
      pcall(function()
        vim.schedule(function()
          if state.edit_volt_buf and vim.api.nvim_buf_is_valid(state.edit_volt_buf) then
            volt.close(state.edit_volt_buf)
          end
        end)
      end)
    end,
  })

  -- 6. Keymaps
  vim.keymap.set("n", "p", function()
    require("exec").open()
  end, { buffer = state.edit_buf, silent = true })

  vim.keymap.set("n", "<C-s>", function()
    local lines = vim.api.nvim_buf_get_lines(state.edit_buf, 0, -1, false)
    local tab = state.tabs[state.active_tab]
    if tab then
      tab.commands = {}
      for _, line in ipairs(lines) do
        if line ~= "" then table.insert(tab.commands, line) end
      end
      require("exec.utils").save_tabs()
      vim.api.nvim_set_option_value("modified", false, { buf = state.edit_buf })
      print "Commands saved!"
    end
  end, { buffer = state.edit_buf, silent = true })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.edit_buf,
    callback = function()
       vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-s>", true, false, true), "m", false)
    end
  })
end

return M
