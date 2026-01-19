local state = require "bday.state"
local utils = require "bday.utils"

local M = {}

M.open = function()
  local volt = require "volt"
  state.current_view = "term"

  require("bday.api").init_term()

  state.volt_buf = vim.api.nvim_create_buf(false, true)
  local layout = require "bday.layout"

  volt.gen_data {
    {
      buf = state.volt_buf,
      layout = layout.header,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  state.h = require("volt.state")[state.volt_buf].h

  state.w = math.floor(vim.o.columns * (state.config.size.w / 100))

  local target_total_h = math.floor(vim.o.lines * (state.config.size.h / 100))

  local border_h = 2
  local total_borders = border_h * 3

  state.term.h = target_total_h - state.h - state.footer.h - total_borders

  if state.term.h < 1 then state.term.h = 1 end

  local total_h = state.h + state.term.h + state.footer.h + total_borders
  local start_row = math.floor((vim.o.lines - total_h) / 2)

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

  require "volt.highlights"
  require "bday.hl"(state.ns)
  vim.api.nvim_win_set_hl_ns(state.win, state.ns)

  -- window for border
  local container_border = state.config.border and "single"
    or { " ", " ", " ", " ", " ", " ", " ", " " }
  state.container.buf = vim.api.nvim_create_buf(false, true)

  local container_opts = {
    relative = "editor",
    width = state.w,
    height = state.term.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + state.h + border_h,
    style = "minimal",
    border = container_border,
  }

  state.container.win =
    vim.api.nvim_open_win(state.container.buf, false, container_opts)
  vim.api.nvim_win_set_hl_ns(state.container.win, state.term_ns)

  -- inner terminal
  local term_w = state.w - (state.xpad * 2)
  local term_col = container_opts.col + state.xpad + 1

  local term_opts = {
    relative = "editor",
    width = term_w,
    height = state.term.h,
    col = term_col,
    row = container_opts.row + 1,
    style = "minimal",
    border = "none",
  }

  state.term.win = vim.api.nvim_open_win(state.term.buf, true, term_opts)
  vim.api.nvim_win_set_hl_ns(state.term.win, state.term_ns)
  vim.api.nvim_set_current_win(state.term.win)

  -- footer
  state.footer.buf = vim.api.nvim_create_buf(false, true)

  volt.gen_data {
    {
      buf = state.footer.buf,
      layout = layout.footer,
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local footer_opts = {
    relative = "editor",
    width = state.w,
    height = state.footer.h,
    col = (vim.o.columns - state.w) / 2,
    row = start_row + state.h + border_h + state.term.h + border_h,
    style = "minimal",
    border = "single",
  }

  state.footer.win = vim.api.nvim_open_win(state.footer.buf, false, footer_opts)
  vim.api.nvim_win_set_hl_ns(state.footer.win, state.ns)

  require("volt.events").add { state.volt_buf, state.footer.buf }

  volt.run(state.footer.buf, {
    h = state.footer.h,
    w = state.w,
  })

  -- start terminal job
  if vim.bo[state.term.buf].buftype ~= "terminal" then
    local tab = state.tabs[state.active_tab]
    local cmds = (tab and tab.commands) or {}
    require("bday.api").bday_in_buf(
      state.term.buf,
      cmds,
      state.config.terminal,
      state.cwd
    )
  end

  -- volt mappings for cleanup
  volt.mappings {
    bufs = { state.volt_buf, state.footer.buf },
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

      safe_close(state.term.win)
      state.term.win = nil

      safe_close(state.container.win)
      state.container.win = nil
      state.container.buf = nil

      safe_close(state.footer.win)
      state.footer.win = nil
      state.footer.buf = nil

      if state.footer.cursor_timer then
        state.footer.cursor_timer:stop()
        state.footer.cursor_timer = nil
      end
    end,
  }

  volt.run(state.volt_buf, {
    h = state.h,
    w = state.w,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.term.win),
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
    if state.term.win and vim.api.nvim_win_is_valid(state.term.win) then
      vim.api.nvim_set_current_win(state.term.win)
    end
  end)
end

return M
