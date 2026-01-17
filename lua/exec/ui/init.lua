local state = require "exec.state"
local utils = require "exec.utils"

local M = {}

---Open the main terminal UI
M.open = function()
  local volt = require "volt"
  state.current_view = "term"

  -- Initialize tabs if needed
  utils.init_term()

  -- 1. Create Volt buffer and generate layout to get height
  state.volt_buf = vim.api.nvim_create_buf(false, true)
  local layout = require "exec.ui.layout"

  volt.gen_data {
    {
      buf = state.volt_buf,
      layout = layout.main_layout,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  state.h = require("volt.state")[state.volt_buf].h

  -- 2. Calculate dynamic dimensions
  -- Width based on config percentage
  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))

  -- Total target height based on config percentage
  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))

  local border_h = 2 -- Single border height (1 top + 1 bottom)
  local total_borders = border_h * 3 -- Header + Term + Footer borders

  -- Calculate terminal height to fill the remaining space
  -- term_h = total - header - footer - borders
  state.term_h = target_total_h - state.h - state.footer_h - total_borders

  -- Safety check for min height
  if state.term_h < 1 then state.term_h = 1 end

  local total_h = state.h + state.term_h + state.footer_h + total_borders
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
  require "exec.ui.hl"(state.ns)
  vim.api.nvim_win_set_hl_ns(state.win, state.ns)

  -- 5. Handle Terminal (Container + Inner Terminal)
  local container_border = state.config.border and "single" or { " ", " ", " ", " ", " ", " ", " ", " " }
  state.container_buf = vim.api.nvim_create_buf(false, true) -- Empty buffer for container padding

  local container_opts = {
    relative = "editor",
    width = state.w,
    height = state.term_h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + state.h + border_h,
    style = "minimal",
    border = container_border,
  }

  state.container_win = vim.api.nvim_open_win(state.container_buf, false, container_opts)
  -- Use term namespace for container background (padding color)
  vim.api.nvim_win_set_hl_ns(state.container_win, state.term_ns)

  -- Inner Terminal Options (offset by xpad)
  local term_w = state.w - (state.xpad * 2)
  local term_col = container_opts.col + state.xpad + 1

  local term_opts = {
    relative = "editor",
    width = term_w,
    height = state.term_h,
    col = term_col,
    row = container_opts.row + 1,
    style = "minimal",
    border = "none",
  }

  state.term_win = vim.api.nvim_open_win(state.term_buf, true, term_opts)
  vim.api.nvim_win_set_hl_ns(state.term_win, state.term_ns)
  vim.api.nvim_set_current_win(state.term_win)

  -- 6. Create Footer window
  state.footer_buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.footer_buf,
      layout = layout.footer_layout,
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
    local tab = state.tabs[state.active_tab]
    local cmds = (tab and tab.commands) or {}
    utils.exec_in_buf(state.term_buf, cmds, state.config.terminal, state.cwd)
  end

  -- 7. Setup Volt Mappings for cleanup
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
      
      safe_close(state.container_win)
      state.container_win = nil
      state.container_buf = nil

      safe_close(state.footer_win)
      state.footer_win = nil
      state.footer_buf = nil

      if state.cursor_timer then
        state.cursor_timer:stop()
        state.cursor_timer = nil
      end
    end,
  }

  -- Note: User can use :q to quit (no q keybind)

  volt.run(state.volt_buf, {
    h = state.h,
    w = state.w,
  })

  -- Ghost window fix: Close UI if terminal window is closed via :q
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term_win),
    once = true,
    callback = function()
      if state.resetting then return end

      pcall(function()
        vim.schedule(function()
          if state.volt_buf and vim.api.nvim_buf_is_valid(state.volt_buf) then
            volt.close(state.volt_buf)
          end
        end)
      end)
    end,
  })

  vim.schedule(function()
    if state.term_win and vim.api.nvim_win_is_valid(state.term_win) then
      vim.api.nvim_set_current_win(state.term_win)
    end
  end)
end

return M
