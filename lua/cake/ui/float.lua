local state = require "cake.state"

local M = {}

function M.open()
  local volt = require "volt"
  local layout = require "cake.ui.layout"
  local terminal = require "cake.core.terminal"

  require "volt.highlights"
  require "cake.ui.highlights"(state.ns)

  state.current_view = "term"
  terminal.init()

  if not state.term.buf then return end

  -- setup data & sizing
  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))
  state.header.buf = vim.api.nvim_create_buf(false, true)
  state.footer.buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.header.buf,
      layout = layout.header,
      xpad = state.xpad,
      ns = state.ns,
    },
    {
      buf = state.footer.buf,
      layout = layout.footer,
      xpad = state.xpad,
      ns = state.term_ns,
    },
  }

  state.h = require("volt.state")[state.header.buf].h
  state.footer.h = require("volt.state")[state.footer.buf].h

  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))
  local border_h = 2
  local total_borders = border_h * 3

  state.term.h = target_total_h - state.h - state.footer.h - total_borders
  if state.term.h < 1 then state.term.h = 1 end

  local total_h = state.h + state.term.h + state.footer.h + total_borders
  local start_row = math.floor((vim.o.lines - total_h) / 2) - 1
  local col = (vim.o.columns - state.w) / 2

  -- header window
  state.header.win = vim.api.nvim_open_win(state.header.buf, false, {
    relative = "editor",
    width = state.w,
    height = state.h,
    col = col,
    row = start_row,
    style = "minimal",
    border = "single",
  })

  vim.api.nvim_win_set_hl_ns(state.header.win, state.ns)

  -- term container
  local container_border = state.config.border and "single"
    or { " ", " ", " ", " ", " ", " ", " ", " " }
  state.container.buf = vim.api.nvim_create_buf(false, true)
  state.container.win = vim.api.nvim_open_win(state.container.buf, false, {
    relative = "editor",
    width = state.w,
    height = state.term.h,
    col = col,
    row = start_row + state.h + border_h,
    style = "minimal",
    border = container_border,
  })
  vim.api.nvim_win_set_hl_ns(state.container.win, state.term_ns)

  -- inner term
  state.term.win = vim.api.nvim_open_win(state.term.buf, true, {
    relative = "editor",
    width = state.w - (state.xpad * 2),
    height = state.term.h,
    col = col + state.xpad + 1,
    row = start_row + state.h + border_h + 1,
    style = "minimal",
    border = "none",
  })
  vim.api.nvim_win_set_hl_ns(state.term.win, state.term_ns)

  -- footer window
  state.footer.win = vim.api.nvim_open_win(state.footer.buf, false, {
    relative = "editor",
    width = state.w,
    height = state.footer.h,
    col = col,
    row = start_row + state.h + border_h + state.term.h + border_h,
    style = "minimal",
    border = "single",
  })
  vim.api.nvim_win_set_hl_ns(state.footer.win, state.term_ns)

  -- finalize ui
  require("volt.events").add { state.header.buf, state.footer.buf }
  volt.run(state.header.buf, { h = state.h, w = state.w })
  volt.run(state.footer.buf, { h = state.footer.h, w = state.w })

  if vim.bo[state.term.buf].buftype ~= "terminal" then
    local tab = state.tabs[state.active_tab]
    terminal.run_in_buf(
      state.term.buf,
      tab and tab.commands or {},
      state.config.terminal,
      state.cwd
    )
  end

  -- clean up & events
  volt.mappings {
    bufs = { state.header.buf, state.footer.buf },
    winclosed_event = true,
    after_close = function()
      local pclose = function(win)
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end

      -- enforce persistence before closing float
      if state.term.buf and vim.api.nvim_buf_is_valid(state.term.buf) then
        vim.api.nvim_set_option_value(
          "bufhidden",
          "hide",
          { buf = state.term.buf }
        )
      end

      pclose(state.header.win)
      pclose(state.term.win)
      pclose(state.container.win)
      pclose(state.footer.win)
      state.header.win, state.header.buf = nil, nil
      state.term.win = nil
      state.container.win, state.container.buf = nil, nil
      state.footer.win, state.footer.buf = nil, nil

      if state.footer.cursor_timer then
        state.footer.cursor_timer:stop()
        state.footer.cursor_timer = nil
      end
    end,
  }

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.win),
    once = true,
    callback = function()
      if state.resetting then return end
      vim.schedule(function()
        if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
          volt.close(state.header.buf)
        end
      end)
    end,
  })

  vim.schedule(function()
    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_set_current_win(state.term.win)
    end
  end)
end

function M.close()
  if state.header.buf and vim.api.nvim_buf_is_valid(state.header.buf) then
    require("volt").close(state.header.buf)
  end
end

return M
