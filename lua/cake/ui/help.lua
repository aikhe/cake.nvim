local volt = require "volt"
local layout = require "cake.ui.layout"
local state = require "cake.state"

local M = {}

function M.open()
  if state.current_view == "help" then return end

  state.help.return_view = state.current_view

  local target_win = (state.current_view == "term") and state.term.win
    or state.edit.win
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then return end

  state.help.prev_buf = vim.api.nvim_win_get_buf(target_win)

  state.current_view = "help"

  if not state.help.buf or not vim.api.nvim_buf_is_valid(state.help.buf) then
    state.help.buf = vim.api.nvim_create_buf(false, true)
  else
    vim.api.nvim_set_option_value("modifiable", true, { buf = state.help.buf })
  end

  volt.gen_data {
    {
      buf = state.help.buf,
      layout = layout.help,
      xpad = 0,
      ns = state.term_ns,
    },
  }

  local help_h = require("volt.state")[state.help.buf].h
  local win_width = vim.api.nvim_win_get_width(target_win)
  volt.set_empty_lines(state.help.buf, help_h, win_width)

  volt.redraw(state.help.buf, "all")

  vim.api.nvim_set_option_value("wrap", false, { win = target_win })
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.help.buf })

  vim.api.nvim_win_set_buf(target_win, state.help.buf)

  -- disable line numbers in split mode
  if state.is_split then
    vim.api.nvim_set_option_value("number", false, { win = target_win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = target_win })
  end

  local footer_buf = (state.help.return_view == "term") and state.footer.buf
    or state.edit.footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.footer,
        xpad = state.xpad,
        ns = state.term_ns,
      },
    }

    volt.redraw(footer_buf, "footer")
  end

  state.help.prev_winhl =
    require("cake.ui.highlights").apply_help_win(target_win)

  require "cake.mappings"(state.help.buf, "help")
end

function M.close()
  if state.current_view ~= "help" then return end

  local target_win = (state.help.return_view == "term") and state.term.win
    or state.edit.win

  if
    target_win
    and vim.api.nvim_win_is_valid(target_win)
    and state.help.prev_winhl
  then
    vim.api.nvim_set_option_value(
      "winhighlight",
      state.help.prev_winhl,
      { win = target_win }
    )
    state.help.prev_winhl = nil
  end

  if
    target_win
    and vim.api.nvim_win_is_valid(target_win)
    and state.help.prev_buf
    and vim.api.nvim_buf_is_valid(state.help.prev_buf)
  then
    vim.api.nvim_win_set_buf(target_win, state.help.prev_buf)
  end

  local footer_buf = (state.help.return_view == "term") and state.footer.buf
    or state.edit.footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.footer,
        xpad = state.xpad,
        ns = state.term_ns,
      },
    }

    volt.redraw(footer_buf, "footer")
  end

  state.current_view = state.help.return_view
  state.help.return_view = nil
  state.help.prev_buf = nil
end

return M
