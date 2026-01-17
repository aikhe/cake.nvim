local volt = require "volt"
local voltui = require "volt.ui"
local state = require "exec.state"
local utils = require "exec.utils"

local M = {}

---Opens the editor UI for commands
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
  
  -- Dynamic sizing (same as main UI)
  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))
  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))
  
  local border_h = 2
  local total_borders = border_h * 3
  
  -- Update term_h (reusing state.term_h for editor height consistency)
  state.term_h = target_total_h - header_h - state.footer_h - total_borders
  if state.term_h < 1 then state.term_h = 1 end

  local total_h = header_h + state.term_h + state.footer_h + total_borders
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

  vim.api.nvim_set_option_value("modified", false, { buf = state.edit_buf })
  
  local container_border = state.config.border and "single" or { " ", " ", " ", " ", " ", " ", " ", " " }
  state.edit_container_buf = vim.api.nvim_create_buf(false, true)

  local container_opts = {
    relative = "editor",
    width = state.w,
    height = state.term_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + header_h + border_h,
    style = "minimal",
    border = container_border,
  }

  state.edit_container_win = vim.api.nvim_open_win(state.edit_container_buf, false, container_opts)
  vim.api.nvim_win_set_hl_ns(state.edit_container_win, state.term_ns)

  local term_w = state.w - (state.xpad * 2)
  local term_col = container_opts.col + state.xpad + (state.config.border and 1 or 0)

  local editor_opts = {
    relative = "editor",
    width = term_w,
    height = state.term_h,
    col = term_col,
    row = container_opts.row + (state.config.border and 1 or 0),
    style = "minimal",
    border = "none",
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

  -- Setup cursor events for tracking
  utils.setup_cursor_events(state.edit_buf)

  -- 5. Cleanup logic
  local function close_all()
    local function sc(w) if w and vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end end
    sc(state.edit_volt_win)
    sc(state.edit_win)
    sc(state.edit_container_win)
    sc(state.edit_footer_win)
    state.edit_volt_win = nil
    state.edit_win = nil
    state.edit_container_win = nil
    state.edit_container_buf = nil
    state.edit_footer_win = nil
    state.edit_volt_buf = nil
    -- state.edit_buf = nil (Persist this buffer)
    state.edit_footer_buf = nil

    if state.cursor_timer then
      state.cursor_timer:stop()
      state.cursor_timer = nil
    end
  end

  local mappings_config = {
    bufs = { state.edit_volt_buf, state.edit_footer_buf },
    winclosed_event = true,
    after_close = close_all,
  }

  volt.mappings(mappings_config)

  -- Ghost window fix: Close UI if edit window is closed via :q
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.edit_win),
    once = true,
    callback = function()
      if state.resetting then return end
      
      pcall(function()
        vim.schedule(function()
          -- Use direct close utility instead of unreliable feedkeys
          require("volt.utils").close(mappings_config)
        end)
      end)
    end,
  })

  -- 6. Keymaps
  local close_ui = function()
      require("volt.utils").close(mappings_config)
  end

  vim.keymap.set("n", "q", close_ui, { buffer = state.edit_buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Esc>", close_ui, { buffer = state.edit_buf, silent = true, nowait = true })

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

  -- Reset resetting flag to allow cleanup on exit
  state.resetting = false
end

return M
