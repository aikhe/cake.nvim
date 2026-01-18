local M = {}

local volt = require "volt"
local layout = require "exec.ui.layout"
local state = require "exec.state"

M.open = function()
  if state.current_view == "help" then return end

  state.help_return_view = state.current_view

  local target_win = (state.current_view == "term") and state.term_win
    or state.edit_win
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then return end

  state.help_prev_buf = vim.api.nvim_win_get_buf(target_win)

  state.current_view = "help"

  if not state.help_buf or not vim.api.nvim_buf_is_valid(state.help_buf) then
    state.help_buf = vim.api.nvim_create_buf(false, true)

    local help_text = {
      "",
      "  Keybindings",
      "  -----------",
      "",
      "  p      Edit Commands",
      "  n      New Tab",
      "  x      Kill Tab",
      "  r      Rerun Commands",
      "  :w     Save Tab/Commands",
      "  1-9    Switch Tab",
      "  ?      Help",
      "  q      Quit",
      "",
    }

    vim.api.nvim_buf_set_lines(state.help_buf, 0, -1, false, help_text)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.help_buf })
    vim.api.nvim_set_option_value(
      "filetype",
      "exec_help",
      { buf = state.help_buf }
    )
  end

  vim.api.nvim_win_set_buf(target_win, state.help_buf)

  local footer_buf = (state.help_return_view == "term") and state.footer_buf
    or state.edit_footer_buf

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = layout.help,
        xpad = state.xpad,
        ns = state.ns,
      },
    }

    volt.redraw(footer_buf, "help_footer")
  end

  local opts = { buffer = state.help_buf, noremap = true, silent = true }

  local close_help = function() M.close() end

  vim.keymap.set("n", "q", close_help, opts)
  vim.keymap.set("n", "<Esc>", close_help, opts)
end

M.close = function()
  if state.current_view ~= "help" then return end

  local target_win = (state.help_return_view == "term") and state.term_win
    or state.edit_win

  if
    target_win
    and vim.api.nvim_win_is_valid(target_win)
    and state.help_prev_buf
    and vim.api.nvim_buf_is_valid(state.help_prev_buf)
  then
    vim.api.nvim_win_set_buf(target_win, state.help_prev_buf)
  end

  local footer_buf = (state.help_return_view == "term") and state.footer_buf
    or state.edit_footer_buf
  local footer_layout = (state.help_return_view == "term") and layout.footer
    or layout.edit_footer
  local footer_key = (state.help_return_view == "term") and "footer"
    or "edit_footer"

  if footer_buf and vim.api.nvim_buf_is_valid(footer_buf) then
    volt.gen_data {
      {
        buf = footer_buf,
        layout = footer_layout,
        xpad = state.xpad,
        ns = state.ns,
      },
    }

    volt.redraw(footer_buf, footer_key)
  end

  state.current_view = state.help_return_view
  state.help_return_view = nil
  state.help_prev_buf = nil
end

return M
